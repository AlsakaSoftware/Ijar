import SwiftUI

class AppCoordinator: ObservableObject {
    @Published var selectedTab: AppDestination = .homeFeed
    
    func navigate(to destination: AppDestination) {
        selectedTab = destination
    }
}