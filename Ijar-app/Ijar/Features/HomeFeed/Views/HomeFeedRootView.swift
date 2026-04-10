import SwiftUI
import RevenueCatUI

struct HomeFeedRootView: View {
    @StateObject private var coordinator = HomeFeedCoordinator()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            CardSwipeView()
                .environmentObject(coordinator)
                .navigationDestination(for: HomeFeedDestination.self) { destination in
                    coordinator.build(destination)
                }
                .onceTask {
                    await subscriptionManager.checkSubscriptionStatus()
                }
        }
    }
}
