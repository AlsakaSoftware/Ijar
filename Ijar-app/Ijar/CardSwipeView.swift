import SwiftUI

struct CardSwipeView: View {
    @EnvironmentObject var coordinator: HomeFeedCoordinator
    @StateObject private var propertyService = PropertyService()
    @State private var currentIndex = 0
    @State private var dragAmount = CGSize.zero
    @State private var dragDirection: SwipeDirection = .none
    @State private var selectedProperty: Property?
    @State private var showingPropertyDetails = false
    
    enum SwipeDirection {
        case left, right, none
    }
    
    var body: some View {
        ZStack {
            Color.warmCream
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("Ijar")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.coffeeBean)
                    Spacer()
                }
                .padding()
                
                // Cards
                ZStack {
                    if currentIndex >= propertyService.properties.count {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60, weight: .light))
                                .foregroundStyle(
                                    Color.sunsetGradient
                                )
                            
                            Text("All caught up")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.coffeeBean)
                            
                            Text("Check back tomorrow for new listings")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.warmBrown.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Button(action: { currentIndex = 0 }) {
                                Text("Start Over")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.warmCream)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(Color.rusticOrange)
                                    )
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                    } else {
                        ForEach(Array(propertyService.properties.enumerated()), id: \.element.id) { index, property in
                            if index >= currentIndex && index < currentIndex + 3 {
                                PropertyCard(property: property) {
                                    // Only allow details for the current (top) card
                                    if index == currentIndex {
                                        selectedProperty = property
                                        showingPropertyDetails = true
                                    }
                                }
                                .offset(cardOffset(for: index))
                                .scaleEffect(cardScale(for: index))
                                .rotationEffect(cardRotation(for: index))
                                .opacity(cardOpacity(for: index))
                                .zIndex(Double(propertyService.properties.count - index))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: dragAmount)
                            }
                        }
                        
                        // Swipe indicators
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.rusticOrange)
                                .opacity(dragDirection == .right ? min(1.0, Double(dragAmount.width / 100)) : 0)
                                .rotationEffect(.degrees(dragDirection == .right ? -15 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragDirection)
                            
                            Spacer()
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 60))
                                .foregroundColor(.warmBrown)
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
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.warmBrown)
                            .frame(width: 54, height: 54)
                            .background(
                                Circle()
                                    .fill(Color.warmCream)
                                    .shadow(color: .warmBrown.opacity(0.1), radius: 8, y: 2)
                            )
                    }
                    .disabled(currentIndex >= propertyService.properties.count)
                    
                    Button(action: saveCard) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.rusticOrange)
                            .frame(width: 54, height: 54)
                            .background(
                                Circle()
                                    .fill(Color.warmCream)
                                    .shadow(color: .rusticOrange.opacity(0.15), radius: 8, y: 2)
                            )
                    }
                    .disabled(currentIndex >= propertyService.properties.count)
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingPropertyDetails) {
            if let property = selectedProperty {
                PropertyDetailView(property: property)
            }
        }
        .task {
            await propertyService.loadPropertiesForUser()
        }
        .refreshable {
            currentIndex = 0
            await propertyService.loadPropertiesForUser()
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
        if currentIndex < propertyService.properties.count {
            let property = propertyService.properties[currentIndex]
            print("Saved: \(property.address)")
            
            Task {
                await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
            }
        }
        currentIndex += 1
    }
    
    private func dismissCard() {
        if currentIndex < propertyService.properties.count {
            let property = propertyService.properties[currentIndex]
            print("Dismissed: \(property.address)")
            
            Task {
                await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
            }
        }
        currentIndex += 1
    }
}