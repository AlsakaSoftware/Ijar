import SwiftUI
import UIKit

enum SwipeDirection {
    case left, right, none
}

struct CardStackView<Content: View>: View {
    let items: [Property]
    @Binding var topItem: Int
    let maxVisibleCards: Int = 3
    let cardContent: (Property, Bool, CGSize, CGFloat, CGFloat, CGFloat) -> Content // property, isTop, drag, saveProgress, passProgress, detailsProgress
    let onSwipeLeft: (Property) -> Void
    let onSwipeRight: (Property) -> Void
    var onSwipeUp: ((Property) -> Void)? = nil
    @Binding var dragDirection: SwipeDirection
    @Binding var showTutorial: Bool

    @State private var dragAmount = CGSize.zero
    @State private var dragStartingLocation: CGPoint? = nil
    @State private var lastHapticDirection: SwipeDirection = .none
    @State private var cardRotations: [String: Double] = [:]
    @State private var isDragging = false
    @State private var isTutorialAnimating = false
    @State private var cardSize: CGSize = CGSize(width: 300, height: 600)

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // Swipe thresholds - threshold for haptic feedback
    private let hapticThreshold: CGFloat = 95

    var body: some View {
        ZStack {
            ForEach(Array(items.prefix(maxVisibleCards).enumerated()), id: \.element.id) { stackIndex, property in
                let isTopCard = stackIndex == 0

                cardContent(
                    property,
                    isTopCard,
                    isTopCard ? dragAmount : .zero,
                    isTopCard ? rightOverlayProgress : 0,
                    isTopCard ? leftOverlayProgress : 0,
                    isTopCard ? detailsOverlayProgress : 0
                )
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
            dragAmount = CGSize(width: CardConstants.horizontalActionThreshold + 20, height: 0)
        }

        try? await Task.sleep(nanoseconds: 900_000_000)

        // Swipe left demo - past action threshold to show overlay
        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
            dragAmount = CGSize(width: -(CardConstants.horizontalActionThreshold + 20), height: 0)
        }

        try? await Task.sleep(nanoseconds: 900_000_000)

        // Return to center
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            dragAmount = .zero
        }

        isTutorialAnimating = false
        showTutorial = false
    }

    // MARK: - Overlay Progress (0 to 1 based on swipe distance)

    private var rightOverlayProgress: CGFloat {
        // Don't show if pure vertical swipe (details animation)
        let isPureVertical = abs(dragAmount.width) < CardConstants.pureVerticalMaxWidth && dragAmount.height < -30
        guard !isPureVertical else { return 0 }
        guard dragAmount.width > CardConstants.horizontalProgressStart else { return 0 }

        let effectiveDrag = dragAmount.width - CardConstants.horizontalProgressStart
        let effectiveRange = CardConstants.horizontalActionThreshold - CardConstants.horizontalProgressStart
        return min(1.0, effectiveDrag / effectiveRange)
    }

    private var leftOverlayProgress: CGFloat {
        // Don't show if pure vertical swipe (details animation)
        let isPureVertical = abs(dragAmount.width) < CardConstants.pureVerticalMaxWidth && dragAmount.height < -30
        guard !isPureVertical else { return 0 }
        guard dragAmount.width < -CardConstants.horizontalProgressStart else { return 0 }

        let effectiveDrag = abs(dragAmount.width) - CardConstants.horizontalProgressStart
        let effectiveRange = CardConstants.horizontalActionThreshold - CardConstants.horizontalProgressStart
        return min(1.0, effectiveDrag / effectiveRange)
    }

    private var detailsOverlayProgress: CGFloat {
        // Only show for pure vertical swipe (swipe up for details)
        let isPureVertical = abs(dragAmount.width) < CardConstants.pureVerticalMaxWidth
        guard isPureVertical else { return 0 }
        guard dragAmount.height < -CardConstants.verticalProgressStart else { return 0 }

        let effectiveDrag = abs(dragAmount.height) - CardConstants.verticalProgressStart
        let effectiveRange = CardConstants.verticalActionThreshold - CardConstants.verticalProgressStart
        return min(1.0, effectiveDrag / effectiveRange)
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
            return .zero
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
            let threshold = hapticThreshold * 2.5
            let dragProportion = Double(dragAmount.width / threshold)
            let clampedProportion = max(-1, min(1, dragProportion))

            return .degrees(clampedProportion * CardConstants.cardRotationMax)
        } else {
            return .zero
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
                if value.translation.width > hapticThreshold {
                    newDirection = .right
                } else if value.translation.width < -hapticThreshold {
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

                let horizontalThreshold = CardConstants.horizontalActionThreshold
                let verticalThreshold = CardConstants.verticalActionThreshold
                let horizontalVelocity = value.predictedEndLocation.x - value.location.x
                let verticalVelocity = value.predictedEndLocation.y - value.location.y

                // Check for swipe up first
                let isVerticalSwipe = value.translation.height < -verticalThreshold || verticalVelocity < -150
                let isPureVertical = abs(value.translation.width) < CardConstants.pureVerticalMaxWidth

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
