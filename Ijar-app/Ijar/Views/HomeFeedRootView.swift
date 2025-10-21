import SwiftUI
import RevenueCatUI

struct HomeFeedRootView: View {
    @StateObject private var coordinator = HomeFeedCoordinator()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "has_completed_onboarding")

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            CardSwipeView()
                .environmentObject(coordinator)
                .navigationDestination(for: HomeFeedDestination.self) { destination in
                    coordinator.build(destination)
                }
                .task(id: "paywall-check") {
                    await subscriptionManager.checkSubscriptionStatus()

                    if subscriptionManager.shouldShowPaywall() {
                        showPaywall = true
                    }
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView(displayCloseButton: true)
                        .onPurchaseCompleted { _ in
                            showPaywall = false
                        }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                }
        }
    }
}
