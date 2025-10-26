import SwiftUI
import RevenueCatUI

/// A reusable view modifier that shows an alert and paywall when user hits a premium limit
struct UpgradePromptModifier: ViewModifier {
    @Binding var limitMessage: String?
    @Binding var showPaywall: Bool
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showPaywall) {
                PaywallView(displayCloseButton: true)
                    .onPurchaseCompleted { _ in
                        showPaywall = false
                        Task {
                            await subscriptionManager.checkSubscriptionStatus()
                        }
                    }
            }
            .alert("Premium Required", isPresented: .constant(limitMessage != nil)) {
                Button("See offerings") {
                    limitMessage = nil
                    showPaywall = true
                }
                Button("Cancel", role: .cancel) {
                    limitMessage = nil
                }
            } message: {
                if let message = limitMessage {
                    Text(message)
                }
            }
    }
}

extension View {
    /// Adds upgrade prompt functionality to a view
    /// - Parameters:
    ///   - limitMessage: Binding to optional string that triggers the alert when set
    ///   - showPaywall: Binding to bool that controls paywall presentation
    /// - Returns: Modified view with upgrade prompt capability
    func upgradePrompt(limitMessage: Binding<String?>, showPaywall: Binding<Bool>) -> some View {
        modifier(UpgradePromptModifier(limitMessage: limitMessage, showPaywall: showPaywall))
    }
}
