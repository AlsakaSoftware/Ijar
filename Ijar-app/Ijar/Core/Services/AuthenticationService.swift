import Foundation
import AuthenticationServices
import Supabase
import RevenueCat

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isGuestMode = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasCompletedOnboarding = false

    private let supabase: SupabaseClient
    private let notificationService: NotificationService
    private let userRepository: UserRepository

    init(notificationService: NotificationService, userRepository: UserRepository = UserRepository()) {
        self.userRepository = userRepository
        self.notificationService = notificationService
        // Initialize Supabase client using ConfigManager
        let config = ConfigManager.shared

        guard let url = URL(string: config.supabaseURL) else {
            fatalError("Invalid Supabase URL in configuration")
        }

        supabase = SupabaseClient(supabaseURL: url, supabaseKey: config.supabaseAnonKey)

        #if DEBUG
        config.debugPrint()
        #endif

        // Check if user was in guest mode
        self.isGuestMode = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isGuestMode)

        // Start with loading state
        self.isLoading = true

        // Check if user is already signed in
        checkAuthStatus()
    }

    private func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                self.isAuthenticated = true
                self.user = session.user

                // Fetch onboarding status from Supabase
                await fetchOnboardingStatus()
            } catch {
                self.isAuthenticated = false
                self.user = nil
            }

            // Done checking auth
            self.isLoading = false
        }
    }

    private func fetchOnboardingStatus() async {
        do {
            if let userRow = try await userRepository.fetchCurrentUser() {
                self.hasCompletedOnboarding = userRow.hasCompletedOnboarding
                // Sync local cache
                UserDefaults.standard.set(userRow.hasCompletedOnboarding, forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
            }
        } catch {
            // Fall back to local value if fetch fails
            self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
            #if DEBUG
            print("⚠️ Failed to fetch onboarding status: \(error.localizedDescription)")
            #endif
        }
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        error = nil
        
        do {
            guard let identityToken = credential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                throw AuthError.invalidCredentials
            }
            
            // Sign in with Supabase using Apple ID token
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )
            
            self.user = session.user
            self.isAuthenticated = true

            // Save user ID to UserDefaults for device token registration
            UserDefaults.standard.set(session.user.id.uuidString, forKey: "currentUserId")

            // Ensure user row exists in users table and fetch onboarding status
            do {
                try await userRepository.upsertUser()
                await fetchOnboardingStatus()
            } catch {
                #if DEBUG
                print("⚠️ Failed to upsert user row: \(error.localizedDescription)")
                #endif
            }

            // Login to RevenueCat with user ID AFTER main sign-in flow completes
            // This will migrate anonymous user to identified user if needed
            Task {
                // Ensure RevenueCat is configured by accessing SubscriptionManager first
                _ = SubscriptionManager.shared

                // Verify it's actually configured
                guard Purchases.isConfigured else {
                    print("❌ RevenueCat not configured, skipping login")
                    return
                }

                do {
                    let (customerInfo, _) = try await Purchases.shared.logIn(session.user.id.uuidString)
                    print("✅ RevenueCat logged in user: \(session.user.id.uuidString)")
                    print("   Active entitlements: \(customerInfo.entitlements.active.keys)")

                    // Update subscription status
                    await SubscriptionManager.shared.checkSubscriptionStatus()
                } catch {
                    print("⚠️ RevenueCat login failed: \(error.localizedDescription)")
                }
            }
            
        } catch {
            self.error = error.localizedDescription
            self.isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true

        do {
            // Remove device token from server
            if let userId = user?.id.uuidString {
                await notificationService.removeDeviceToken(for: userId)
            }

            // Log out from RevenueCat
            do {
                _ = try await Purchases.shared.logOut()
                print("✅ RevenueCat logged out")
            } catch {
                print("⚠️ RevenueCat logout failed: \(error.localizedDescription)")
            }

            try await supabase.auth.signOut()
            self.user = nil
            self.isAuthenticated = false

            // Clear saved user ID
            UserDefaults.standard.removeObject(forKey: "currentUserId")
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Guest Mode

    /// Returns true if user is in guest mode and not authenticated
    var isInGuestMode: Bool {
        isGuestMode && !isAuthenticated
    }

    func continueAsGuest() {
        isGuestMode = true
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isGuestMode)
    }

    func exitGuestMode() {
        isGuestMode = false
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isGuestMode)
        // Clear guest onboarding state
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
        // Clear guest preferences
        GuestPreferencesStore.shared.clear()
    }

    /// Exit guest mode but keep onboarding progress (used after successful conversion)
    func exitGuestModeKeepProgress() {
        isGuestMode = false
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isGuestMode)
        // Keep hasCompletedPreferencesOnboarding = true so user goes to main tabs
    }

    /// Convert guest session to authenticated user by saving their preferences to the database
    func convertGuestToAuthenticatedUser() async {
        guard GuestPreferencesStore.shared.hasValidPreferences,
              let query = GuestPreferencesStore.shared.toSearchQuery() else {
            #if DEBUG
            print("⚠️ Guest conversion: No valid preferences to convert")
            #endif
            exitGuestMode()
            return
        }

        let searchQueryService = SearchQueryService()
        let liveSearchService = LiveSearchService()

        #if DEBUG
        print("🔄 Guest conversion: Creating query '\(query.name)' in database")
        #endif

        // 1. Save the query to database
        let success = await searchQueryService.createQuery(query)

        guard success else {
            #if DEBUG
            print("❌ Guest conversion: Failed to create query")
            #endif
            // Still exit guest mode, but user will need to redo onboarding
            exitGuestMode()
            return
        }

        #if DEBUG
        print("✅ Guest conversion: Query created, persisting properties")
        #endif

        // 2. Call onboarding search to persist properties with query association
        await liveSearchService.onboardingSearch(queryId: query.id.uuidString, query: query)

        #if DEBUG
        print("✅ Guest conversion: Properties persisted")
        #endif

        // 3. Clear guest store and exit guest mode (keeping onboarding progress)
        GuestPreferencesStore.shared.clear()
        exitGuestModeKeepProgress()
    }

    func deleteAccount() async throws {
        isLoading = true
        error = nil

        guard let userId = user?.id else {
            throw AuthError.noUserFound
        }

        do {
            #if DEBUG
            print("🗑️ Starting account deletion for user: \(userId.uuidString)")
            #endif

            // Remove device token from server
            await notificationService.removeDeviceToken(for: userId.uuidString)

            // Call the database function to delete the account
            // This uses SECURITY DEFINER to run with elevated privileges
            try await supabase.rpc("delete_user_account").execute()

            #if DEBUG
            print("✅ Account deleted successfully")
            #endif

            // Sign out from Supabase to clear cached session
            try await supabase.auth.signOut()

            // Sign out locally
            self.user = nil
            self.isAuthenticated = false

            // Clear saved user ID and local data
            UserDefaults.standard.removeObject(forKey: "currentUserId")

        } catch {
            #if DEBUG
            print("❌ Account deletion failed: \(error.localizedDescription)")
            #endif
            self.error = "Failed to delete account. Please try again."
            throw error
        }

        isLoading = false
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case noUserFound

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid Apple ID credentials"
        case .noUserFound:
            return "No user found"
        }
    }
}
