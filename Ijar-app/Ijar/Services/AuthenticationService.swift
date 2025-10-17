import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase: SupabaseClient
    private let notificationService: NotificationService
    
    init(notificationService: NotificationService) {
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
        
        // Check if user is already signed in
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                self.isAuthenticated = true
                self.user = session.user
            } catch {
                self.isAuthenticated = false
                self.user = nil
            }
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
            
            // Register for push notifications and save device token
            await registerForNotifications()
            
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
    
    private func registerForNotifications() async {
        guard let user = user else { 
            print("❌ No user found for notification registration")
            return 
        }
        
        print("📱 Starting notification registration for user: \(user.id.uuidString)")
        
        // Request notification permission
        let granted = await notificationService.requestNotificationPermission()
        print("🔔 Notification permission granted: \(granted)")
        
        if granted {
            // Check if we have a saved device token
            if let tokenData = UserDefaults.standard.data(forKey: "deviceToken") {
                let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
                print("✅ Found saved device token: \(tokenString)")
                await notificationService.saveDeviceToken(tokenData, for: user.id.uuidString)
            } else {
                print("⚠️ No device token found in UserDefaults")
                // Try to register for remote notifications again
                print("📲 Requesting remote notification registration...")
                await UIApplication.shared.registerForRemoteNotifications()
            }
        }
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
