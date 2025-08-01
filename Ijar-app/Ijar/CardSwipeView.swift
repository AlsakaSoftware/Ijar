import SwiftUI

struct CardSwipeView: View {
    @EnvironmentObject var coordinator: HomeFeedCoordinator
    @StateObject private var propertyService = PropertyService()
    @State private var selectedProperty: Property?
    @State private var showingPropertyDetails = false
    @State private var dragDirection: SwipeDirection = .none
    @State private var buttonPressed: SwipeDirection = .none
    
    var body: some View {
        ZStack {
            Color.warmCream
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Ijar")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.coffeeBean)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Card Stack
                Spacer()
                
                if propertyService.properties.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(Color.sunsetGradient)
                        
                        Text("All caught up")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.coffeeBean)
                        
                        Text("Check back tomorrow for new listings")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.warmBrown.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Button(action: { 
                            Task {
                                await propertyService.loadPropertiesForUser()
                            }
                        }) {
                            Text("Start Over")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.warmCream)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.rusticOrange))
                        }
                        .padding(.top, 10)
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
#if DEBUG
                            print("🔥 CardSwipeView: Swiped LEFT on property \(property.id)")
                            print("🔥 Properties count before swipe: \(propertyService.properties.count)")
#endif
                            Task {
                                let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
#if DEBUG
                                print("🔥 CardSwipeView: Track action result: \(success)")
                                print("🔥 Properties count after swipe: \(propertyService.properties.count)")
#endif
                            }
                        },
                        onSwipeRight: { property in
#if DEBUG
                            print("🔥 CardSwipeView: Swiped RIGHT on property \(property.id)")
                            print("🔥 Properties count before swipe: \(propertyService.properties.count)")
#endif
                            Task {
                                let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
#if DEBUG
                                print("🔥 CardSwipeView: Track action result: \(success)")
                                print("🔥 Properties count after swipe: \(propertyService.properties.count)")
#endif
                            }
                        },
                        dragDirection: $dragDirection
                    )
                }
                
                // Action buttons
                HStack(spacing: 60) {
                    Button(action: {
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
                .padding(.vertical, 30)
                
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
        }
        .refreshable {
            await propertyService.loadPropertiesForUser()
        }
    }
    
    private func saveCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
#if DEBUG
            print("🔥 CardSwipeView: BUTTON SAVE on property \(property.id)")
            print("🔥 Properties count before button: \(propertyService.properties.count)")
#endif
            Task {
                let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
#if DEBUG
                print("🔥 CardSwipeView: Button track result: \(success)")
                print("🔥 Properties count after button: \(propertyService.properties.count)")
#endif
            }
        }
    }
    
    private func dismissCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
#if DEBUG
            print("🔥 CardSwipeView: BUTTON DISMISS on property \(property.id)")
            print("🔥 Properties count before button: \(propertyService.properties.count)")
#endif
            Task {
                let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
#if DEBUG
                print("🔥 CardSwipeView: Button track result: \(success)")
                print("🔥 Properties count after button: \(propertyService.properties.count)")
#endif
            }
        }
    }
}
