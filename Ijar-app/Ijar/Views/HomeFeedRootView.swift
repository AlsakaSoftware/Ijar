import SwiftUI

struct HomeFeedRootView: View {
    @StateObject private var coordinator = HomeFeedCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            CardSwipeView()
                .environmentObject(coordinator)
                .navigationDestination(for: HomeFeedDestination.self) { destination in
                    coordinator.build(destination)
                }
        }
    }
}