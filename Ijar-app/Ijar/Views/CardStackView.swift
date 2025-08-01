import SwiftUI

enum SwipeDirection {
    case left, right, none
}

struct CardStackView<Content: View, Overlay: View>: View {
    let items: [Property]
    @Binding var topItem: Int
    let maxVisibleCards: Int = 3
    let cardContent: (Property, Bool) -> Content
    let leftOverlay: () -> Overlay
    let rightOverlay: () -> Overlay
    let onSwipeLeft: (Property) -> Void
    let onSwipeRight: (Property) -> Void
    @Binding var dragDirection: SwipeDirection
    
    @State private var dragAmount = CGSize.zero
    
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
                    .animation(isTopCard ? .interactiveSpring(response: 0.3, dampingFraction: 0.8) : .none, value: dragAmount)
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
            let dragScale = 1.0 - (abs(dragAmount.width) / 2000.0)
            return max(0.92, dragScale)
        } else if stackIndex == 1 {
            return 0.95
        } else {
            return 0.90
        }
    }
    
    private func cardRotation(for stackIndex: Int) -> Angle {
        if stackIndex == 0 {
            let rotation = Double(dragAmount.width) / 25
            return .degrees(min(max(rotation, -12), 12))
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
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                    dragAmount = CGSize(width: value.translation.width, height: 0)
                    
                    if value.translation.width > 30 {
                        dragDirection = .right
                    } else if value.translation.width < -30 {
                        dragDirection = .left
                    } else {
                        dragDirection = .none
                    }
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let velocity = value.predictedEndLocation.x - value.location.x
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if value.translation.width > threshold || velocity > 200 {
                        // Swipe right - save
                        dragAmount = CGSize(width: 500, height: 0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            if topItem < items.count {
                                onSwipeRight(items[topItem])
                            }
                            resetDrag()
                        }
                    } else if value.translation.width < -threshold || velocity < -200 {
                        // Swipe left - dismiss
                        dragAmount = CGSize(width: -500, height: 0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
