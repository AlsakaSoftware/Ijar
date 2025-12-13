import SwiftUI
import UserNotifications

// MARK: - Initial Properties Store

class InitialPropertiesStore: ObservableObject {
    @Published var properties: [Property] = []

    func clear() {
        properties = []
    }
}

// MARK: - Root View

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var initialPropertiesStore = InitialPropertiesStore()
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        RootContentView(
            notificationService: notificationService,
            coordinator: coordinator,
            initialPropertiesStore: initialPropertiesStore
        )
        .onAppear {
            notificationService.checkNotificationStatus()
        }
    }
}

struct RootContentView: View {
    let notificationService: NotificationService
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var initialPropertiesStore: InitialPropertiesStore
    @StateObject private var authService: AuthenticationService
    @State private var hasCompletedPreferencesOnboarding: Bool

    init(notificationService: NotificationService, coordinator: AppCoordinator, initialPropertiesStore: InitialPropertiesStore) {
        self.notificationService = notificationService
        self.coordinator = coordinator
        self.initialPropertiesStore = initialPropertiesStore
        _authService = StateObject(wrappedValue: AuthenticationService(notificationService: notificationService))

        _hasCompletedPreferencesOnboarding = State(
            initialValue: UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
        )
    }

    var body: some View {
        ZStack {
            if authService.isLoading {
                AppLogoLoadingView()
            } else if authService.isAuthenticated {
                if hasCompletedPreferencesOnboarding {
                    mainTabView
                } else {
                    PreferencesOnboardingView(isGuestMode: false) { properties in
                        initialPropertiesStore.properties = properties
                        withAnimation(.easeOut(duration: 0.3)) {
                            hasCompletedPreferencesOnboarding = true
                        }
                    }
                }
            } else if authService.isGuestMode {
                if hasCompletedPreferencesOnboarding {
                    mainTabView
                } else {
                    PreferencesOnboardingView(isGuestMode: true) { properties in
                        initialPropertiesStore.properties = properties
                        GuestPreferencesStore.shared.properties = properties
                        withAnimation(.easeOut(duration: 0.3)) {
                            hasCompletedPreferencesOnboarding = true
                        }
                    }
                }
            } else {
                SignInView()
                    .environmentObject(authService)
                    .environmentObject(coordinator)
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $coordinator.selectedTab) {
            HomeFeedRootView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("For You")
                }
                .tag(AppDestination.homeFeed)

            BrowseRootView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag(AppDestination.browse)

            SavedPropertiesRootView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Saved")
                }
                .tag(AppDestination.savedProperties)

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
        .environmentObject(initialPropertiesStore)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Clear notification badge when app enters foreground
            Task {
                try? await UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
    }
}
