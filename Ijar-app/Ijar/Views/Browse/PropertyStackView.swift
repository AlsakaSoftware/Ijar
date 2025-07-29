import SwiftUI

struct PropertyStackView: View {
    let properties: [QueryProperty]
    let currentIndex: Int
    let dragAmount: CGSize
    let dragDirection: PropertyBrowserView.SwipeDirection
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            ForEach(Array(properties.enumerated()), id: \.element.id) { index, queryProperty in
                if index >= currentIndex && index < currentIndex + 3 {
                    PropertyCardView(queryProperty: queryProperty)
                        .offset(cardOffset(for: index))
                        .scaleEffect(cardScale(for: index))
                        .rotationEffect(cardRotation(for: index))
                        .opacity(cardOpacity(for: index))
                        .zIndex(Double(properties.count - index))
                        .onTapGesture {
                            if index == currentIndex {
                                onTap()
                            }
                        }
                }
            }
            
            // Swipe indicators
            if currentIndex < properties.count {
                SwipeIndicatorView(dragDirection: dragDirection, dragAmount: dragAmount)
            }
        }
    }
    
    private func cardOffset(for index: Int) -> CGSize {
        if index == currentIndex {
            return dragAmount
        } else {
            let verticalOffset = CGFloat(index - currentIndex) * 10
            return CGSize(width: 0, height: verticalOffset)
        }
    }
    
    private func cardScale(for index: Int) -> CGFloat {
        if index == currentIndex {
            return 1.0
        } else {
            return 1.0 - (CGFloat(index - currentIndex) * 0.05)
        }
    }
    
    private func cardRotation(for index: Int) -> Angle {
        if index == currentIndex {
            return .degrees(Double(dragAmount.width) / 10)
        }
        return .zero
    }
    
    private func cardOpacity(for index: Int) -> Double {
        if index == currentIndex {
            return 1.0
        } else if index == currentIndex + 1 {
            return 0.9
        } else {
            return 0.5
        }
    }
}

struct SwipeIndicatorView: View {
    let dragDirection: PropertyBrowserView.SwipeDirection
    let dragAmount: CGSize
    
    var body: some View {
        VStack {
            HStack {
                // Like indicator
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .opacity(dragDirection == .right ? Double(dragAmount.width / 100) : 0)
                    .animation(.easeInOut(duration: 0.2), value: dragDirection)
                
                Spacer()
                
                // Dismiss indicator
                Image(systemName: "xmark")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .opacity(dragDirection == .left ? Double(-dragAmount.width / 100) : 0)
                    .animation(.easeInOut(duration: 0.2), value: dragDirection)
            }
            .padding(.horizontal, 40)
            .padding(.top, 100)
            
            Spacer()
        }
    }
}