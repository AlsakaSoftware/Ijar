import SwiftUI

struct SaveSearchExplainerCard: View {
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.rusticOrange)

                VStack(alignment: .leading, spacing: 3) {
                    Text("We'll find homes for you")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.coffeeBean)

                    Text("Delivered to your feed daily")
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }

                Spacer()
            }
            .padding(16)
            .background(Color.warmCream.opacity(0.3))

            // Features list
            VStack(spacing: 10) {
                FeatureRow(
                    icon: "bell.fill",
                    text: "Fresh properties delivered throughout the day",
                    subtext: "We'll continuously find matches for you"
                )

                FeatureRow(
                    icon: "hand.draw.fill",
                    text: "Swipe through your personalized feed",
                    subtext: "Build your shortlist effortlessly"
                )

                FeatureRow(
                    icon: "checkmark.circle.fill",
                    text: "Find your home faster",
                    subtext: "No manual searching through dozens of listings"
                )
            }
            .padding(16)

            // Action button
            Button {
                onSave()
            } label: {
                HStack(spacing: 8) {
                    Text("Start Monitoring")
                        .font(.system(size: 15, weight: .semibold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.rusticOrange, Color.warmRed],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let text: String
    let subtext: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.rusticOrange)
                .frame(width: 18)
                .offset(y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.coffeeBean)

                Text(subtext)
                    .font(.system(size: 13))
                    .foregroundColor(.warmBrown.opacity(0.7))
            }

            Spacer()
        }
    }
}
