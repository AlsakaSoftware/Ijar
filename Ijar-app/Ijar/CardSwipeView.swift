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
        VStack(spacing: 20) {
            // Top section with greeting
            TimeBasedGreeting()
            
            if propertyService.properties.isEmpty {
                emptyStateView
            } else {
                // Main card area - expand to fill available space
                cardStackSection
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1) // Give this priority in space allocation

                
                // Bottom controls - fixed size
                VStack(spacing: 12) {
                    propertyCounter
                    actionButtons
                }
            }
        }
        .padding(.bottom, 30)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.warmCream
                .ignoresSafeArea() // Only background extends to edges
        )
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 0) // Ensure content starts below notch
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 0) // Ensure content ends above home indicator
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
    
    // MARK: - View Components
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
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
            
            Spacer()
            Spacer() // Extra spacer to keep it centered but slightly above middle
        }
        .frame(maxWidth: .infinity)
    }
    
    private var cardStackSection: some View {
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
                    await MainActor.run {
                        withAnimation(.none) {
                            propertyService.removeTopProperty()
                        }
                    }
                    await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
                }
            },
            onSwipeRight: { property in
                Task {
                    await MainActor.run {
                        withAnimation(.none) {
                            propertyService.removeTopProperty()
                        }
                    }
                    await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
                }
            },
            dragDirection: $dragDirection
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 60) {
            dismissButton
            saveButton
        }
    }
    
    private var dismissButton: some View {
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
    }
    
    private var saveButton: some View {
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
    
    private var propertyCounter: some View {
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
    
    private func saveCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
            Task {
                await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
                await MainActor.run {
                    propertyService.removeTopProperty()
                }
            }
        }
    }
    
    private func dismissCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
            Task {
                await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
                await MainActor.run {
                    propertyService.removeTopProperty()
                }
            }
        }
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        CardSwipeView()
            .environmentObject(HomeFeedCoordinator())
    }
    .previewDevice("iPhone 15 Pro")
}

#Preview("iPhone SE") {
    NavigationStack {
        CardSwipeView()
            .environmentObject(HomeFeedCoordinator())
    }
    .previewDevice("iPhone SE (3rd generation)")
}

#Preview("iPhone 15 Pro Max") {
    NavigationStack {
        CardSwipeView()
            .environmentObject(HomeFeedCoordinator())
    }
    .previewDevice("iPhone 15 Pro Max")
}

