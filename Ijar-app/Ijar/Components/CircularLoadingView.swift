import SwiftUI

struct CircularLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                Color.rusticOrange,
                style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round
                )
            )
            .frame(width: 28, height: 28)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularLoadingView()
        CircularLoadingView()
        CircularLoadingView()
    }
    .padding()
    .background(Color.warmCream)
}
