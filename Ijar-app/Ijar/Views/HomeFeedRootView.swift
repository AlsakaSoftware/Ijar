import SwiftUI
import RevenueCatUI

struct HomeFeedRootView: View {
    @StateObject private var coordinator = HomeFeedCoordinator()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            CardSwipeView()
                .environmentObject(coordinator)
                .navigationDestination(for: HomeFeedDestination.self) { destination in
                    coordinator.build(destination)
                }
                .onAppear {
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()

                        if !subscriptionManager.isSubscribed {
                            showPaywall = true
                        }
                    }
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView(displayCloseButton: true)
                        .onPurchaseCompleted { _ in
                            showPaywall = false
                        }
                }
        }
    }
}