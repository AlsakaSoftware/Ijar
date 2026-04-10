import SwiftUI

enum AppRoute {
    case homeFeed
    case savedProperties
    case profile(ProfileDestination?)
}

class AppCoordinator: ObservableObject {
    @Published var selectedTab: AppDestination = .homeFeed
    @Published var profilePath = NavigationPath()
    @Published var homeFeedPath = NavigationPath()
    @Published var savedPropertiesPath = NavigationPath()

    func navigate(to route: AppRoute) {
        switch route {
        case .homeFeed:
            selectedTab = .homeFeed
        case .savedProperties:
            selectedTab = .savedProperties
        case .profile(let destination):
            selectedTab = .profile
            if let destination = destination {
                profilePath = NavigationPath()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.profilePath.append(destination)
                }
            }
        }
    }
}
