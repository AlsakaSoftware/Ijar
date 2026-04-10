import SwiftUI
import RevenueCatUI

struct PremiumUpgradeBanner: View {
    @Binding var showPaywall: Bool

    var body: some View {
        Button(action: {
            showPaywall = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to Premium")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("House hunt on easy mode")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.rusticOrange, Color.warmRed],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.rusticOrange.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
