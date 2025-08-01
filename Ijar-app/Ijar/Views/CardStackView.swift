import SwiftUI

struct CardStackView<Content: View, Overlay: View>: View {
    let items: [Property]
    @Binding var topItem: Int
    let maxVisibleCards: Int = 3
    let cardContent: (Property, Bool) -> Content
    let leftOverlay: () -> Overlay
    let rightOverlay: () -> Overlay
    let onSwipeLeft: (Property) -> Void
    let onSwipeRight: (Property) -> Void
    
    @State private var dragAmount = CGSize.zero
    @State private var dragDirection: SwipeDirection = .none
    
    enum SwipeDirection {
        case left, right, none
    }
    
    var body: some View {
        ZStack {
            // Render only visible cards
            ForEach(Array(items.prefix(maxVisibleCards).enumerated()), id: \.element.id) { stackIndex, property in
                let isTopCard = stackIndex == 0
                
                cardContent(property, isTopCard)
                    .scaleEffect(cardScale(for: stackIndex))
                    .offset(cardOffset(for: stackIndex))
                    .rotationEffect(cardRotation(for: stackIndex))
                    .opacity(cardOpacity(for: stackIndex))
                    .zIndex(Double(maxVisibleCards - stackIndex))
                    .allowsHitTesting(isTopCard)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragAmount)
            }
            
            // Swipe indicators
            if dragDirection != .none && !items.isEmpty {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.rusticOrange)
                        .opacity(dragDirection == .right ? min(1.0, Double(dragAmount.width / 100)) : 0)
                        .rotationEffect(.degrees(dragDirection == .right ? -15 : 0))
                    
                    Spacer()
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 50))
                        .foregroundColor(.warmBrown)
                        .opacity(dragDirection == .left ? min(1.0, Double(-dragAmount.width / 100)) : 0)
                        .rotationEffect(.degrees(dragDirection == .left ? 15 : 0))
                }
                .padding(.horizontal, 60)
                .allowsHitTesting(false)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragDirection)
            }
        }
        .gesture(swipeGesture)
    }
    
    
    private func cardOffset(for stackIndex: Int) -> CGSize {
        if stackIndex == 0 {
            return dragAmount
        } else {
            let verticalOffset = CGFloat(stackIndex) * 8
            return CGSize(width: 0, height: verticalOffset)
        }
    }
    
    private func cardScale(for stackIndex: Int) -> CGFloat {
        if stackIndex == 0 {
            let dragScale = 1.0 - (abs(dragAmount.width) / 1500.0)
            return max(0.9, dragScale)
        } else if stackIndex == 1 {
            return 0.95
        } else {
            return 0.90
        }
    }
    
    private func cardRotation(for stackIndex: Int) -> Angle {
        if stackIndex == 0 {
            let rotation = Double(dragAmount.width) / 20
            return .degrees(min(max(rotation, -15), 15))
        }
        return .zero
    }
    
    private func cardOpacity(for stackIndex: Int) -> Double {
        if stackIndex == 0 {
            return 1.0
        } else if stackIndex == 1 {
            return 0.8
        } else if stackIndex == 2 {
            return 0.6
        } else {
            return 0.0
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragAmount = value.translation
                
                if value.translation.width > 30 {
                    dragDirection = .right
                } else if value.translation.width < -30 {
                    dragDirection = .left
                } else {
                    dragDirection = .none
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let velocity = value.predictedEndLocation.x - value.location.x
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if value.translation.width > threshold || velocity > 200 {
                        // Swipe right - save
                        dragAmount = CGSize(width: 500, height: 100)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if topItem < items.count {
                                onSwipeRight(items[topItem])
                            }
                            resetDrag()
                        }
                    } else if value.translation.width < -threshold || velocity < -200 {
                        // Swipe left - dismiss
                        dragAmount = CGSize(width: -500, height: 100)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if topItem < items.count {
                                onSwipeLeft(items[topItem])
                            }
                            resetDrag()
                        }
                    } else {
                        resetDrag()
                    }
                }
            }
    }
    
    private func resetDrag() {
        dragAmount = .zero
        dragDirection = .none
    }
}
