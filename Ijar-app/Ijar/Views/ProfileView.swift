import SwiftUI
import RevenueCatUI

struct ProfileView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var notificationService: NotificationService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingDeleteConfirmation = false
    @State private var showingPaywall = false


    var body: some View {
        VStack(spacing: 30) {
            if authService.isInGuestMode {
                guestModeContent
            } else {
                authenticatedContent
            }
        }
        .overlay {
            if authService.isLoading {
                LoadingOverlay()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(displayCloseButton: true)
                .onPurchaseCompleted { customerInfo in
                    subscriptionManager.updateSubscriptionStatus(from: customerInfo)
                    showingPaywall = false
                }
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await authService.deleteAccount()
                    } catch {
                        // Error is already set in authService
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This will permanently delete all your searches, saved properties, and account data. This action cannot be undone.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var guestModeContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Title and subtitle - Hinge style
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create your free account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.coffeeBean)

                        Text("You're currently browsing as a guest. Sign up to unlock all features.")
                            .font(.system(size: 17))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                    .padding(.horizontal, 24)

                    // Benefits section
                    VStack(alignment: .leading, spacing: 20) {
                        GuestBenefitRow(icon: "heart.fill", text: "Save properties", subtitle: "Keep track of your favorites")
                        GuestBenefitRow(icon: "bell.fill", text: "Get notified", subtitle: "New matches sent to your phone")
                        GuestBenefitRow(icon: "sparkles", text: "Personalized feed", subtitle: "Properties tailored to you")
                        GuestBenefitRow(icon: "magnifyingglass", text: "Multiple searches", subtitle: "Monitor different areas")
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 100)
                }
            }

            // Bottom button section
            VStack(spacing: 12) {
                SignInWithAppleButtonView()
                    .padding(.horizontal, 24)

                #if DEBUG
                Button(action: {
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isGuestMode)
                }) {
                    Text("Reset (Debug)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.4))
                }
                #endif
            }
            .padding(.vertical, 16)
            .background(Color.warmCream)
        }
    }


    private var authenticatedContent: some View {
        VStack(spacing: 30) {
            // Premium upgrade banner (only show if not subscribed)
            if !subscriptionManager.isSubscribed {
                PremiumUpgradeBanner(showPaywall: $showingPaywall)
                    .padding(.horizontal)
                    .padding(.top, 20)
            }

            // Main actions
            VStack(spacing: 0) {
                ProfileMenuRow(
                    icon: "sparkles",
                    title: "For You Areas",
                    subtitle: "Add areas to get personalized property matches",
                    action: {
                        appCoordinator.profilePath.append(ProfileDestination.searchQueries)
                    }
                )

                Divider()
                    .padding(.leading, 60)

                ProfileMenuRow(
                    icon: "mappin.circle.fill",
                    title: "Places That Matter",
                    subtitle: "Your work, gym, and other important spots",
                    action: {
                        appCoordinator.profilePath.append(ProfileDestination.savedLocations)
                    }
                )
            }
            .background(Color.warmCream)
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 16) {
                // Sign out button
                Button(action: {
                    Task {
                        await authService.signOut()
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.warmRed)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .stroke(Color.warmRed, lineWidth: 1)
                    )
                }

                // Delete account button
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Text("Delete Account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.6))
                }

                #if DEBUG
                // Debug: Reset onboarding
                Button(action: {
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
                }) {
                    Text("Reset Onboarding (Debug)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.4))
                }
                #endif
            }
            .padding(.bottom, 30)
        }
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.rusticOrange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.coffeeBean)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.warmBrown.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.warmBrown.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    let notificationService = NotificationService()
    return ProfileView()
        .environmentObject(ProfileCoordinator())
        .environmentObject(AuthenticationService(notificationService: notificationService))
        .environmentObject(notificationService)
}
