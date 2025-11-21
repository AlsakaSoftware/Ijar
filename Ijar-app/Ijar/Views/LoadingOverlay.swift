import SwiftUI

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()

            CircularLoadingView()
        }
    }
}

#Preview {
    LoadingOverlay()
}
