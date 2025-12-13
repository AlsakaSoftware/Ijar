import SwiftUI

/// Reusable benefit row for guest mode sign-up prompts
/// Supports two styles: simple (icon + text) and detailed (icon + title + subtitle)
struct GuestBenefitRow: View {
    let icon: String
    let text: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: subtitle != nil ? .top : .center, spacing: subtitle != nil ? 16 : 12) {
            Image(systemName: icon)
                .font(.system(size: subtitle != nil ? 20 : 16))
                .foregroundColor(.rusticOrange)
                .frame(width: subtitle != nil ? 28 : 24)

            if let subtitle = subtitle {
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.coffeeBean)

                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
            } else {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(.coffeeBean)
            }

            Spacer()
        }
    }
}

#Preview("Simple") {
    VStack(spacing: 14) {
        GuestBenefitRow(icon: "heart.fill", text: "Save your favorite properties")
        GuestBenefitRow(icon: "bell.fill", text: "Get notified of new matches")
        GuestBenefitRow(icon: "sparkles", text: "Personalized recommendations")
    }
    .padding()
    .background(Color.warmCream)
}

#Preview("With Subtitle") {
    VStack(spacing: 20) {
        GuestBenefitRow(icon: "heart.fill", text: "Save properties", subtitle: "Keep track of your favorites")
        GuestBenefitRow(icon: "bell.fill", text: "Get notified", subtitle: "New matches sent to your phone")
        GuestBenefitRow(icon: "sparkles", text: "Personalized feed", subtitle: "Properties tailored to you")
    }
    .padding()
    .background(Color.warmCream)
}
