import SwiftUI

struct OnboardingCompleteStep: View {
    let onComplete: () -> Void

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title centered
            Text("All done! Let's see what catches your eye.")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.coffeeBean)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

            Spacer()

            // Button
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onComplete()
            } label: {
                Text("Start browsing")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.rusticOrange)
                    )
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                showContent = true
            }
        }
    }
}

#Preview {
    OnboardingCompleteStep {
        print("Done")
    }
    .background(Color.warmCream)
}
