import SwiftUI

/// A reusable heart-shaped like/save button with consistent styling
struct LikeButton: View {
    let isLiked: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 28, height: 28)
            } else {
                ZStack {
                    // White filled heart as background
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)

                    // Border heart (always visible)
                    Image(systemName: "heart")
                        .font(.system(size: 32))
                        .foregroundColor(.coffeeBean.opacity(0.3))

                    // Orange fill when liked
                    if isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.rusticOrange)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.warmBrown
        VStack(spacing: 20) {
            LikeButton(isLiked: false, isLoading: false) {}
            LikeButton(isLiked: true, isLoading: false) {}
            LikeButton(isLiked: false, isLoading: true) {}
        }
    }
}
