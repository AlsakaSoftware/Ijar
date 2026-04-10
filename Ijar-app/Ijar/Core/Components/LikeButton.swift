import SwiftUI

/// A reusable heart-shaped like/save button with consistent styling
struct LikeButton: View {
    let isLiked: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)

                        Image(systemName: "heart")
                            .font(.system(size: 32))
                            .foregroundColor(.coffeeBean.opacity(0.3))

                        if isLiked {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.rusticOrange)
                        }
                    }
                }
            }
            .frame(width: 32, height: 32)
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
