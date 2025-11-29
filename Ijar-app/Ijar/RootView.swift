import SwiftUI
import UserNotifications

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    @EnvironmentObject var notificationService: NotificationService
    
    var body: some View {
        RootContentView(notificationService: notificationService, coordinator: coordinator)
            .onAppear {
                notificationService.checkNotificationStatus()
            }
    }
}

struct RootContentView: View {
    let notificationService: NotificationService
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var authService: AuthenticationService

    init(notificationService: NotificationService, coordinator: AppCoordinator) {
        self.notificationService = notificationService
        self.coordinator = coordinator
        _authService = StateObject(wrappedValue: AuthenticationService(notificationService: notificationService))
    }
    
    var body: some View {
        Group {
            if authService.isLoading {
                // Show loading state while checking authentication
                AppLogoLoadingView()
            } else if authService.isAuthenticated {
                TabView(selection: $coordinator.selectedTab) {
                    HomeFeedRootView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(AppDestination.homeFeed)

                    SavedPropertiesRootView()
                        .tabItem {
                            Image(systemName: "heart.fill")
                            Text("Saved")
                        }
                        .tag(AppDestination.savedProperties)

                    BrowseRootView()
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Browse")
                        }
                        .tag(AppDestination.browse)

                    ProfileRootView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(AppDestination.profile)
                }
                .accentColor(.rusticOrange)
                .environmentObject(authService)
                .environmentObject(coordinator)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Clear notification badge when app enters foreground
                    Task {
                        try? await UNUserNotificationCenter.current().setBadgeCount(0)
                    }
                }
            } else {
                SignInView()
                    .environmentObject(authService)
            }
        }
    }
}
