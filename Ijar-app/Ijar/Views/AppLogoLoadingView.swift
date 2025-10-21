import SwiftUI

struct AppLogoLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.warmCream
                .ignoresSafeArea()

            // App logo with pulsing animation
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 35)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .rusticOrange.opacity(0.15),
                                .rusticOrange.opacity(0.05),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 130, height: 130)
                    .scaleEffect(isAnimating ? 1.08 : 0.98)
                    .opacity(isAnimating ? 0.4 : 0.8)

                // Logo image
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .rusticOrange.opacity(0.2), radius: 15, y: 8)
                    .scaleEffect(isAnimating ? 1.03 : 1.0)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    AppLogoLoadingView()
}
