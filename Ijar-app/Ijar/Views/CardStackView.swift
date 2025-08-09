import SwiftUI
import UIKit

enum SwipeDirection {
    case left, right, none
}

struct CardStackView<Content: View, Overlay: View>: View {
    let items: [Property]
    @Binding var topItem: Int
    let maxVisibleCards: Int = 3
    let cardContent: (Property, Bool, CGSize) -> Content
    let leftOverlay: () -> Overlay
    let rightOverlay: () -> Overlay
    let onSwipeLeft: (Property) -> Void
    let onSwipeRight: (Property) -> Void
    @Binding var dragDirection: SwipeDirection
    
    @State private var dragAmount = CGSize.zero
    @State private var lastHapticDirection: SwipeDirection = .none
    @State private var cardRotations: [String: Double] = [:]
    @State private var isAnimatingSwipe = false
    @State private var isDragging = false
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        ZStack {
            // Render only visible cards
            ForEach(Array(items.prefix(maxVisibleCards).enumerated()), id: \.element.id) { stackIndex, property in
                let isTopCard = stackIndex == 0
                
                cardContent(property, isTopCard, isTopCard ? dragAmount : .zero)
                    .scaleEffect(cardScale(for: stackIndex))
                    .offset(cardOffset(for: stackIndex))
                    .rotationEffect(cardRotation(for: stackIndex, propertyId: property.id))
                    .opacity(cardOpacity(for: stackIndex))
                    .zIndex(Double(maxVisibleCards - stackIndex))
                    .animation(isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.75), value: dragAmount)
                    .gesture(isTopCard ? swipeGesture : nil)
                    .onAppear {
                        // Generate a random tilt for background cards if not already set
                        if cardRotations[property.id] == nil && stackIndex > 0 {
                            cardRotations[property.id] = Double.random(in: -5...5)
                        }
                    }
            }
            
        }
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
            return 1
        } else {
            return 0.90
        }
    }
    
    private func cardRotation(for stackIndex: Int, propertyId: String) -> Angle {
        if stackIndex == 0 {
            // Top card rotation based on drag - now considers vertical movement too
            let horizontalRotation = Double(dragAmount.width) / 25
            let verticalInfluence = Double(dragAmount.height) / 100 // Subtle influence from vertical drag
            let totalRotation = horizontalRotation - verticalInfluence
            return .degrees(min(max(totalRotation, -15), 15))
        } else {
            // Background cards have their pre-assigned random tilt
            let randomTilt = cardRotations[propertyId] ?? 0
            return .degrees(randomTilt)
        }
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
                isDragging = true
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.95, blendDuration: 0)) {
                    // Allow free dragging in both X and Y axes
                    dragAmount = value.translation
                    
                    let newDirection: SwipeDirection
                    if value.translation.width > 40 {
                        newDirection = .right
                    } else if value.translation.width < -40 {
                        newDirection = .left
                    } else {
                        newDirection = .none
                    }
                    
                    // Trigger haptic feedback when crossing direction threshold
                    if newDirection != lastHapticDirection && newDirection != .none {
                        impactFeedback.impactOccurred()
                        lastHapticDirection = newDirection
                    } else if newDirection == .none && lastHapticDirection != .none {
                        lastHapticDirection = .none
                    }
                    
                    dragDirection = newDirection
                }
            }
            .onEnded { value in
                isDragging = false
                let threshold: CGFloat = 90
                let velocity = value.predictedEndLocation.x - value.location.x
                
                if value.translation.width > threshold || velocity > 150 {
                    // Swipe right - save
                    selectionFeedback.selectionChanged() // Success haptic
                    if topItem < items.count {
                        let property = items[topItem]
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            dragAmount = CGSize(width: 400, height: value.translation.height / 2)
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSwipeRight(property)
                            resetDrag()
                        }
                    }
                } else if value.translation.width < -threshold || velocity < -150 {
                    // Swipe left - dismiss
                    selectionFeedback.selectionChanged() // Success haptic
                    if topItem < items.count {
                        let property = items[topItem]
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            dragAmount = CGSize(width: -400, height: value.translation.height / 2)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSwipeLeft(property)
                            resetDrag()
                        }
                    }
                } else {
                    // Snap back - subtle haptic
                    impactFeedback.impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        resetDrag()
                    }
                }
            }
    }
    
    private func resetDrag() {
        dragAmount = .zero
        dragDirection = .none
        lastHapticDirection = .none
        isDragging = false
    }
    
}
