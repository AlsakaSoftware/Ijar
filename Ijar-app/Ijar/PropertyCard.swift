import SwiftUI

struct PropertyCard: View {
    let property: Property
    let onTap: () -> Void
    var dragAmount: CGSize = .zero
    @State private var currentImageIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Image indicators at top
            HStack(spacing: 4) {
                ForEach(0..<property.images.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.5))
                        .frame(width: index == currentImageIndex ? 24 : 16, height: 3)
                        .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                        .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(property.price)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.warmCream)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("\(property.bedrooms)")
                            Image(systemName: "bed.double")
                        }
                        HStack(spacing: 4) {
                            Text("\(property.bathrooms)")
                            Image(systemName: "shower")
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.warmCream.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                // Address
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.address)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.warmCream)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    HStack {
                        Text(property.area)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.warmCream.opacity(0.7))
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        Spacer()
                        
                        Button(action: onTap) {
                            HStack(spacing: 6) {
                                Text("View")
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.coffeeBean)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.warmCream.opacity(0.95))
                                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: 350, maxHeight: .infinity) 
        .aspectRatio(0.65, contentMode: .fit)
        .background {
            imagesCarousel
                .background(Color.warmCream)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .coffeeBean.opacity(0.08), radius: 16, y: 8)
        .overlay {
            ZStack {
                // Tap zones for image navigation
                HStack(spacing: 0) {
                    // Left tap zone
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if currentImageIndex > 0 {
                                currentImageIndex -= 1
                            }
                        }
                    
                    // Right tap zone
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if currentImageIndex < property.images.count - 1 {
                                currentImageIndex += 1
                            }
                        }
                }
                
                // Swipe indicator overlay
                swipeIndicatorOverlay
            }
        }

    }
    
    private var imagesCarousel: some View {
        ZStack {
            TabView(selection: $currentImageIndex) {
                ForEach(0..<property.images.count, id: \.self) { index in
                    AsyncImage(url: URL(string: property.images[index])) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.warmCream,
                                        Color.warmBrown
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.coffeeBean)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.warmCream,
                                    Color.warmBrown
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.coffeeBean.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Gradient overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // Swipe indicator overlay
    @ViewBuilder
    private var swipeIndicatorOverlay: some View {
        ZStack {
            // Left swipe indicator (Pass) - shows on RIGHT corner
            if dragAmount.width < -30 {
                HStack {
                    Spacer()
                    
                    VStack {
                        Image(systemName: "xmark")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.warmCream)
                            .background(
                                Circle()
                                    .fill(Color.warmBrown.opacity(0.85))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.warmCream.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                                    .frame(width: 70, height: 70)
                            )
                        
                        Spacer()
                    }
//                    .padding(.top, 40)
//                    .padding(.trailing, 30)
                }
                .opacity(min(abs(dragAmount.width) / 80.0, 1.0))
            }
            
            // Right swipe indicator (Save) - shows on LEFT corner
            if dragAmount.width > 30 {
                HStack {
                    VStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.warmCream)
                            .background(
                                Circle()
                                    .fill(Color.rusticOrange.opacity(0.85))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.warmCream.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                                    .frame(width: 70, height: 70)
                            )
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                    .padding(.leading, 30)
                    
                    Spacer()
                }
                .opacity(min(dragAmount.width / 80.0, 1.0))
            }
        }
        .allowsHitTesting(false)
    }
    
}

#Preview {
    VStack {
        PropertyCard(
            property: Property(
                images: [
                    "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&q=80",
                    "https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800&q=80",
                    "https://images.unsplash.com/photo-1560185009-5bf9f2849dbe?w=800&q=80"
                ],
                price: "£2,500/month",
                bedrooms: 3,
                bathrooms: 2,
                address: "123 Canary Wharf",
                area: "London E14"
            ),
            onTap: {
                print("Details tapped")
            }
        )
        .background(Color.warmCream)
    }
    .padding()
}

