import SwiftUI

struct CardSwipeView: View {
    @EnvironmentObject var coordinator: HomeFeedCoordinator
    @StateObject private var propertyService = PropertyService()
    @State private var selectedProperty: Property?
    @State private var showingPropertyDetails = false
    @State private var dragDirection: SwipeDirection = .none
    @State private var buttonPressed: SwipeDirection = .none
    @State private var ambientAnimation = false
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    
    var body: some View {
        ZStack {
            Color.warmCream
                .ignoresSafeArea()
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.warmBrown.opacity(0.002),
                            Color.clear,
                            Color.rusticOrange.opacity(0.001),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            VStack(spacing: 20) {
                TimeBasedGreeting()
                    .padding(20)
                
                VStack(spacing: 16) {
                    if propertyService.properties.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60, weight: .light))
                                .foregroundStyle(Color.sunsetGradient)
                            
                            Text("All caught up")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.coffeeBean)
                            
                            Text("We'll notify you as soon as new homes are ready to explore")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.warmBrown.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        CardStackView(
                            items: propertyService.properties,
                            topItem: .constant(0),
                            cardContent: { property, isTopCard in
                                PropertyCard(property: property) {
                                    if isTopCard {
                                        selectedProperty = property
                                        showingPropertyDetails = true
                                    }
                                }
                            },
                            leftOverlay: { EmptyView() },
                            rightOverlay: { EmptyView() },
                            onSwipeLeft: { property in
                                Task {
                                    let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
                                }
                            },
                            onSwipeRight: { property in
                                Task {
                                    let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
                                }
                            },
                            dragDirection: $dragDirection
                        )
                        .frame(maxWidth: .infinity)
                        
                        HStack(spacing: 60) {
                            Button(action: {
                                impactFeedback.impactOccurred()
                                buttonPressed = .left
                                dismissCard()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    buttonPressed = .none
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.warmBrown)
                                    .frame(width: 54, height: 54)
                                    .background(
                                        Circle()
                                            .fill(Color.warmCream)
                                            .shadow(color: .warmBrown.opacity((dragDirection == .left || buttonPressed == .left) ? 0.4 : 0.1), radius: (dragDirection == .left || buttonPressed == .left) ? 16 : 8, y: 2)
                                    )
                                    .scaleEffect((dragDirection == .left || buttonPressed == .left) ? 1.1 : 1.0)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.warmBrown.opacity((dragDirection == .left || buttonPressed == .left) ? 0.3 : 0), lineWidth: 2)
                                            .scaleEffect((dragDirection == .left || buttonPressed == .left) ? 1.2 : 1.0)
                                            .opacity((dragDirection == .left || buttonPressed == .left) ? 0.6 : 0)
                                    )
                            }
                            .disabled(propertyService.properties.isEmpty)
                            .animation(.easeOut(duration: 0.15), value: dragDirection)
                            .animation(.easeOut(duration: 0.15), value: buttonPressed)
                            
                            Button(action: {
                                selectionFeedback.selectionChanged()
                                buttonPressed = .right
                                saveCard()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    buttonPressed = .none
                                }
                            }) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.rusticOrange)
                                    .frame(width: 54, height: 54)
                                    .background(
                                        Circle()
                                            .fill(Color.warmCream)
                                            .shadow(color: .rusticOrange.opacity((dragDirection == .right || buttonPressed == .right) ? 0.4 : 0.15), radius: (dragDirection == .right || buttonPressed == .right) ? 16 : 8, y: 2)
                                    )
                                    .scaleEffect((dragDirection == .right || buttonPressed == .right) ? 1.1 : 1.0)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.rusticOrange.opacity((dragDirection == .right || buttonPressed == .right) ? 0.3 : 0), lineWidth: 2)
                                            .scaleEffect((dragDirection == .right || buttonPressed == .right) ? 1.2 : 1.0)
                                            .opacity((dragDirection == .right || buttonPressed == .right) ? 0.6 : 0)
                                    )
                            }
                            .disabled(propertyService.properties.isEmpty)
                            .animation(.easeOut(duration: 0.15), value: dragDirection)
                            .animation(.easeOut(duration: 0.15), value: buttonPressed)
                        }
                        .padding(.vertical, 20)
                        
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.rusticOrange)
                                    .frame(width: 8, height: 8)
                                
                                Text("\(propertyService.properties.count) left")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.coffeeBean)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.warmCream)
                                    .shadow(color: .rusticOrange.opacity(0.15), radius: 4, y: 2)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.rusticOrange.opacity(0.2), lineWidth: 1.5)
                                    )
                            )
                            .scaleEffect(ambientAnimation ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: ambientAnimation)
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showingPropertyDetails) {
            if let property = selectedProperty {
                PropertyDetailView(property: property)
            }
        }
        .task {
            await propertyService.loadPropertiesForUser()
            ambientAnimation = true
        }
        .refreshable {
            await propertyService.loadPropertiesForUser()
        }
    }
    
    private func saveCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
            Task {
                let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
            }
        }
    }
    
    private func dismissCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
            Task {
                let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
            }
        }
    }
}

#Preview {
    CardSwipeView()
        .environmentObject(HomeFeedCoordinator())
}

