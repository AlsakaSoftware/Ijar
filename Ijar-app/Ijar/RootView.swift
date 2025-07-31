import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
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
                    
                    ProfileRootView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(AppDestination.profile)
                }
                .accentColor(.rusticOrange)
                .environmentObject(authService)
            } else {
                SignInView()
                    .environmentObject(authService)
            }
        }
    }
}