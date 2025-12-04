import SwiftUI

struct OnboardingCompleteStep: View {
    let onComplete: () -> Void

    @State private var contentOpacity: Double = 0

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

            Spacer()

            // Button
            Button {
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
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1
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
