import SwiftUI
import UIKit

enum SwipeDirection {
    case left, right, none
}

struct CardStackView<Content: View, LeftOverlay: View, RightOverlay: View>: View {
    let items: [Property]
    @Binding var topItem: Int
    let maxVisibleCards: Int = 3
    let cardContent: (Property, Bool, CGSize) -> Content
    let leftOverlay: () -> LeftOverlay
    let rightOverlay: () -> RightOverlay
    let onSwipeLeft: (Property) -> Void
    let onSwipeRight: (Property) -> Void
    var onSwipeUp: ((Property) -> Void)? = nil
    @Binding var dragDirection: SwipeDirection
    var showTutorial: Bool = false

    @State private var dragAmount = CGSize.zero
    @State private var dragStartingLocation: CGPoint? = nil
    @State private var lastHapticDirection: SwipeDirection = .none
    @State private var cardRotations: [String: Double] = [:]
    @State private var isDragging = false
    @State private var isTutorialAnimating = false
    @State private var cardSize: CGSize = CGSize(width: 300, height: 600)

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // Swipe thresholds
    private let xThreshold: CGFloat = 95

    var body: some View {
        ZStack {
            ForEach(Array(items.prefix(maxVisibleCards).enumerated()), id: \.element.id) { stackIndex, property in
                let isTopCard = stackIndex == 0

                cardContent(property, isTopCard, isTopCard ? dragAmount : .zero)
                    .overlay {
                        // Swipe overlays on top card only
                        if isTopCard {
                            ZStack {
                                rightOverlay()
                                    .opacity(rightOverlayOpacity)

                                leftOverlay()
                                    .opacity(leftOverlayOpacity)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .allowsHitTesting(false)
                        }
                    }
                .scaleEffect(cardScale(for: stackIndex))
                .offset(cardOffset(for: stackIndex))
                .rotationEffect(
                    cardRotation(for: stackIndex, propertyId: property.id),
                    anchor: isTopCard ? rotationAnchor : .center
                )
                .opacity(cardOpacity(for: stackIndex))
                .zIndex(Double(maxVisibleCards - stackIndex))
                .animation(isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.75), value: dragAmount)
                .gesture(isTopCard ? swipeGesture : nil)
                .allowsHitTesting(isTopCard)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            if isTopCard {
                                cardSize = geo.size
                            }
                        }
                    }
                )
                .onAppear {
                    if cardRotations[property.id] == nil && stackIndex > 0 {
                        cardRotations[property.id] = Double.random(in: -5...5)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .coordinateSpace(name: "card")
        .task(id: showTutorial) {
            guard showTutorial && !isTutorialAnimating else { return }
            await runTutorialAnimation()
        }
    }

    // MARK: - Tutorial Animation

    private func runTutorialAnimation() async {
        isTutorialAnimating = true

        // Wait a moment before starting
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Swipe right demo - past action threshold to show overlay
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            dragAmount = CGSize(width: actionThreshold + 20, height: 0)
        }

        try? await Task.sleep(nanoseconds: 900_000_000)

        // Swipe left demo - past action threshold to show overlay
        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
            dragAmount = CGSize(width: -(actionThreshold + 20), height: 0)
        }

        try? await Task.sleep(nanoseconds: 900_000_000)

        // Return to center
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            dragAmount = .zero
        }

        isTutorialAnimating = false
    }

    // MARK: - Overlay Opacity (only show when past action threshold, not when swiping up)

    private let actionThreshold: CGFloat = 100

    private var rightOverlayOpacity: Double {
        // Don't show if swiping up (details animation)
        guard dragAmount.height > -30 else { return 0 }
        guard dragAmount.width > actionThreshold else { return 0 }
        return 1.0
    }

    private var leftOverlayOpacity: Double {
        // Don't show if swiping up (details animation)
        guard dragAmount.height > -30 else { return 0 }
        guard dragAmount.width < -actionThreshold else { return 0 }
        return 1.0
    }

    // MARK: - Rotation Anchor (based on drag start point)

    private var rotationAnchor: UnitPoint {
        guard let startLocation = dragStartingLocation else { return .center }
        let unitX = startLocation.x / cardSize.width
        let unitY = startLocation.y / cardSize.height
        return UnitPoint(x: unitX.clamped(to: 0...1), y: unitY.clamped(to: 0...1))
    }

    // MARK: - Card Transforms

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
            let maxAngle: Double = 20
            let threshold = xThreshold * 2
            let dragProportion = Double(dragAmount.width / threshold)
            let clampedProportion = max(-1, min(1, dragProportion))

            // If dragging from bottom half, invert rotation for natural feel
            let halfHeight = cardSize.height / 2
            let isDraggingBottom = (dragStartingLocation?.y ?? halfHeight) > halfHeight

            return .degrees((isDraggingBottom ? -1 : 1) * clampedProportion * maxAngle)
        } else {
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

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("card"))
            .onChanged { value in
                // Capture drag start location on first touch
                if dragStartingLocation == nil {
                    dragStartingLocation = value.startLocation
                }

                isDragging = true
                dragAmount = value.translation

                let newDirection: SwipeDirection
                if value.translation.width > xThreshold {
                    newDirection = .right
                } else if value.translation.width < -xThreshold {
                    newDirection = .left
                } else {
                    newDirection = .none
                }

                // Haptic when crossing threshold
                if newDirection != lastHapticDirection && newDirection != .none {
                    impactFeedback.impactOccurred()
                    lastHapticDirection = newDirection
                } else if newDirection == .none && lastHapticDirection != .none {
                    lastHapticDirection = .none
                }

                dragDirection = newDirection
            }
            .onEnded { value in
                isDragging = false

                let horizontalThreshold: CGFloat = 100
                let verticalThreshold: CGFloat = 120
                let horizontalVelocity = value.predictedEndLocation.x - value.location.x
                let verticalVelocity = value.predictedEndLocation.y - value.location.y

                // Check for swipe up first
                let isVerticalSwipe = value.translation.height < -verticalThreshold || verticalVelocity < -150
                let isPureVertical = abs(value.translation.width) < 80

                if isVerticalSwipe && isPureVertical {
                    if let onSwipeUp = onSwipeUp, topItem < items.count {
                        let property = items[topItem]
                        selectionFeedback.selectionChanged()
                        onSwipeUp(property)
                        resetDrag()
                    } else {
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            resetDrag()
                        }
                    }
                } else if value.translation.width > horizontalThreshold || horizontalVelocity > 150 {
                    // Swipe right - save
                    selectionFeedback.selectionChanged()
                    if topItem < items.count {
                        let property = items[topItem]
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragAmount = CGSize(width: 500, height: value.translation.height * 0.3)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSwipeRight(property)
                            resetDrag()
                        }
                    }
                } else if value.translation.width < -horizontalThreshold || horizontalVelocity < -150 {
                    // Swipe left - pass
                    selectionFeedback.selectionChanged()
                    if topItem < items.count {
                        let property = items[topItem]
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragAmount = CGSize(width: -500, height: value.translation.height * 0.3)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSwipeLeft(property)
                            resetDrag()
                        }
                    }
                } else {
                    // Snap back
                    impactFeedback.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        resetDrag()
                    }
                }
            }
    }

    private func resetDrag() {
        dragAmount = .zero
        dragStartingLocation = nil
        dragDirection = .none
        lastHapticDirection = .none
        isDragging = false
    }
}

// MARK: - Helper Extension

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
