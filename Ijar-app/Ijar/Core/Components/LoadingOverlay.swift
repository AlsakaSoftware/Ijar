import SwiftUI

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()

            ProgressView()
                .scaleEffect(1.5)
                .tint(.rusticOrange)
        }
    }
}

#Preview {
    LoadingOverlay()
}
