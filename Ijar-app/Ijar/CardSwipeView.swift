import SwiftUI

struct CardSwipeView: View {
    @State private var properties = Property.mockProperties
    @State private var currentIndex = 0
    @State private var dragAmount = CGSize.zero
    @State private var dragDirection: SwipeDirection = .none
    
    enum SwipeDirection {
        case left, right, none
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("Ijar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                
                // Cards
                ZStack {
                    if currentIndex >= properties.count {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "house.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("No More Properties")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Check back tomorrow for fresh listings")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { currentIndex = 0 }) {
                                Label("Start Over", systemImage: "arrow.clockwise")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(20)
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                    } else {
                        ForEach(Array(properties.enumerated()), id: \.element.id) { index, property in
                            if index >= currentIndex && index < currentIndex + 3 {
                                PropertyCard(property: property)
                                    .offset(cardOffset(for: index))
                                    .scaleEffect(cardScale(for: index))
                                    .rotationEffect(cardRotation(for: index))
                                    .opacity(cardOpacity(for: index))
                                    .zIndex(Double(properties.count - index))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: dragAmount)
                            }
                        }
                        
                        // Swipe indicators
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .opacity(dragDirection == .right ? min(1.0, Double(dragAmount.width / 100)) : 0)
                                .rotationEffect(.degrees(dragDirection == .right ? -15 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragDirection)
                            
                            Spacer()
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                                .opacity(dragDirection == .left ? min(1.0, Double(-dragAmount.width / 100)) : 0)
                                .rotationEffect(.degrees(dragDirection == .left ? 15 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragDirection)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 100)
                    }
                }
                .gesture(dragGesture)
                
                // Action buttons
                HStack(spacing: 60) {
                    Button(action: dismissCard) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.red))
                    }
                    .disabled(currentIndex >= properties.count)
                    
                    Button(action: saveCard) {
                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.green))
                    }
                    .disabled(currentIndex >= properties.count)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    var dragGesture: some Gesture {
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
                        dragAmount = CGSize(width: 500, height: 100)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            saveCard()
                            dragAmount = .zero
                            dragDirection = .none
                        }
                    } else if value.translation.width < -threshold || velocity < -200 {
                        dragAmount = CGSize(width: -500, height: 100)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismissCard()
                            dragAmount = .zero
                            dragDirection = .none
                        }
                    } else {
                        dragAmount = .zero
                        dragDirection = .none
                    }
                }
            }
    }
    
    private func cardOffset(for index: Int) -> CGSize {
        if index == currentIndex {
            return dragAmount
        } else {
            let verticalOffset = CGFloat(index - currentIndex) * 8
            let horizontalOffset = CGFloat(index - currentIndex) * 2
            return CGSize(width: horizontalOffset, height: verticalOffset)
        }
    }
    
    private func cardScale(for index: Int) -> CGFloat {
        if index == currentIndex {
            let dragScale = 1.0 - (abs(dragAmount.width) / 1000.0)
            return max(0.85, dragScale)
        } else {
            return 1.0 - (CGFloat(index - currentIndex) * 0.03)
        }
    }
    
    private func cardRotation(for index: Int) -> Angle {
        if index == currentIndex {
            let rotation = Double(dragAmount.width) / 15
            return .degrees(min(max(rotation, -20), 20))
        } else if index == currentIndex + 1 {
            return .degrees(Double(index - currentIndex) * -2)
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
    
    private func saveCard() {
        print("Saved: \(properties[currentIndex].address)")
        currentIndex += 1
    }
    
    private func dismissCard() {
        print("Dismissed: \(properties[currentIndex].address)")
        currentIndex += 1
    }
}