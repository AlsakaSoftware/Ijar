import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "hand.point.up.left.fill",
            title: "Swipe to Find Your Home",
            description: "Swipe right on properties you love, left on ones you don't.",
            accentColor: .rusticOrange
        ),
        OnboardingPage(
            icon: "clock.fill",
            title: "Fresh Properties Twice Daily",
            description: "We search at 9 AM and 6 PM daily. Get notified when we find something special.",
            accentColor: .rusticOrange
        ),
        OnboardingPage(
            icon: "magnifyingglass.circle.fill",
            title: "Explore Multiple Areas",
            description: "Add search areas in Settings. Set your location, price range, bedrooms, and more.",
            accentColor: .rusticOrange,
            screenshotName: "onboarding3"
        ),
        OnboardingPage(
            icon: "mappin.circle.fill",
            title: "Places That Matter",
            description: "Save locations in Settings. Each property shows journey times to your important places.",
            accentColor: .rusticOrange,
            screenshotName: "onboarding4"
        )
    ]

    var body: some View {
        ZStack {
            Color.warmCream.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button with matching background
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                .background(Color.warmCream.opacity(0.3))

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.rusticOrange : Color.warmBrown.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Bottom button
                if currentPage == pages.count - 1 {
                    Button(action: completeOnboarding) {
                        HStack {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.warmCream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.rusticOrange)
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.rusticOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.rusticOrange, lineWidth: 2)
                                .background(Color.white)
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        isPresented = false
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
