import SwiftUI

struct SavedPropertiesView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    @StateObject private var propertyService = PropertyService()
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            if propertyService.isLoading && propertyService.savedProperties.isEmpty {
                loadingView
            } else if propertyService.savedProperties.isEmpty {
                emptyStateView
            } else {
                savedPropertiesList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .navigationTitle("Your Favorites")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(.rusticOrange)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !propertyService.savedProperties.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.rusticOrange)

                        Text("\(propertyService.savedProperties.count)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.coffeeBean)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.warmCream)
                            .shadow(color: .rusticOrange.opacity(0.1), radius: 3, y: 1)
                    )
                }
            }
        }
        .task {
            await propertyService.loadSavedProperties()
            withAnimation(.easeOut(duration: 0.4)) {
                animateContent = true
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated loading indicator
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.rusticOrange.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .offset(x: CGFloat(index - 1) * 30)
                        .scaleEffect(animateContent ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animateContent
                        )
                }
            }
            
            Text("Finding your saved homes...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.warmBrown)
            
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated heart icon
            ZStack {
                Circle()
                    .fill(Color.rusticOrange.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateContent)
                
                Image(systemName: "heart.slash")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.rusticOrange, Color.warmRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animateContent ? 0 : -10))
                    .animation(.spring(response: 0.8, dampingFraction: 0.5), value: animateContent)
            }
            
            VStack(spacing: 12) {
                Text("No favorites yet")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.coffeeBean)
                
                Text("Heart the homes you love, and\nwe'll keep them here for you")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.warmBrown.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var savedPropertiesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(propertyService.savedProperties.enumerated()), id: \.element.id) { index, property in
                    SavedPropertyCard(property: property) {
                        coordinator.navigate(to: .propertyDetail(property: property))
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 50)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.1),
                        value: animateContent
                    )
                }
            }
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
    }
}

struct SavedPropertyCard: View {
    let property: Property
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Property Image
                ZStack(alignment: .topTrailing) {
                    if let firstImage = property.images.first,
                       let imageURL = URL(string: firstImage) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                            case .empty:
                                ShimmerView()
                                    .frame(height: 200)
                            case .failure:
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.warmCream, Color.warmBrown.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 200)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.warmBrown.opacity(0.4))
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    // Saved badge
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                        Text("Saved")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.rusticOrange)
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    )
                    .padding(12)
                }
                
                // Property Details
                VStack(alignment: .leading, spacing: 12) {
                    // Price and features row
                    HStack(alignment: .top) {
                        Text(property.price)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.coffeeBean)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "bed.double")
                                    .font(.system(size: 14))
                                Text("\(property.bedrooms)")
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "shower")
                                    .font(.system(size: 14))
                                Text("\(property.bathrooms)")
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.8))
                    }
                    
                    // Address
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.address)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.warmBrown)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if !property.area.isEmpty {
                            Text(property.area)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.warmBrown.opacity(0.7))
                        }
                    }
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .coffeeBean.opacity(isPressed ? 0.12 : 0.06),
                        radius: isPressed ? 6 : 10,
                        y: isPressed ? 3 : 5
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// Shimmer loading effect
struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.warmBrown.opacity(0.1),
                Color.warmBrown.opacity(0.2),
                Color.warmBrown.opacity(0.1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: isAnimating ? 200 : -200)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SavedPropertiesView()
        .environmentObject(SavedPropertiesCoordinator())
}
