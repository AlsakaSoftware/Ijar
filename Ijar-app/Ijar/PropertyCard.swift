import SwiftUI

struct PropertyCard: View {
    let property: Property
    let onTap: () -> Void
    @State private var currentImageIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Image carousel
                ZStack(alignment: .top) {
                    TabView(selection: $currentImageIndex) {
                        ForEach(0..<property.images.count, id: \.self) { index in
                            AsyncImage(url: URL(string: property.images[index])) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.warmCream)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                case .failure(_):
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.warmCream)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentImageIndex)
                    
                    // Image indicators
                    HStack(spacing: 4) {
                        ForEach(0..<property.images.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentImageIndex ? Color.warmCream : Color.warmCream.opacity(0.4))
                                .frame(width: index == currentImageIndex ? 24 : 16, height: 3)
                                .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 16)
                    
                    // Tap zones
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
                    .frame(height: geometry.size.height * 0.7)
                }
                
                // Property details
                VStack(alignment: .leading, spacing: 8) {
                    // Price and bed/bath info
                    HStack {
                        Text(property.price)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.warmCream)
                        
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
                    }
                    
                    // Address and Details button
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(property.address)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.warmCream)
                            
                            Text(property.area)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.warmCream.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button(action: onTap) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                Text("Details")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.coffeeBean)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.warmCream.opacity(0.95))
                                    .shadow(color: .coffeeBean.opacity(0.3), radius: 6, y: 3)
                            )
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.coffeeBean.opacity(0.9),
                            Color.warmBrown.opacity(0.7),
                            Color.clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .cornerRadius(20)
            .shadow(color: .coffeeBean.opacity(0.08), radius: 16, y: 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 50)
    }
}

#Preview {
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
    .frame(height: 600)
    .background(Color.warmCream)
}

