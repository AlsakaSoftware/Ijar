import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 15) {
                Spacer()

                // Icon or Screenshot
                if let screenshotName = page.screenshotName {
                    // Show screenshot with background - responsive to screen size
                    let imageHeight = min(450, geometry.size.height * 0.7)
                    let imageWidth = imageHeight * (2.0 / 3.0)

                    Image(screenshotName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageWidth, height: imageHeight)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.accentColor.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: .coffeeBean.opacity(0.15), radius: 20, y: 10)
                        .padding(.bottom, 8)
                } else {
                    // Show icon if no screenshot
                    Image(systemName: page.icon)
                        .font(.system(size: 100))
                        .foregroundColor(page.accentColor)
                        .padding(.bottom, 16)
                }

                // Title
                Text(page.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.coffeeBean)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Description
                Text(page.description)
                    .font(.system(size: 15))
                    .foregroundColor(.warmBrown.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                Spacer()
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let screenshotName: String? // Optional screenshot image name

    init(icon: String, title: String, description: String, accentColor: Color, screenshotName: String? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
        self.screenshotName = screenshotName
    }
}
