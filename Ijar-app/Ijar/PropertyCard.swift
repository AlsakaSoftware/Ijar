import SwiftUI

struct PropertyCard: View {
    let property: Property
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
                                        .background(Color(.systemGray5))
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
                                        .background(Color(.systemGray5))
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
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: index == currentImageIndex ? 30 : 20, height: 3)
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
                    HStack {
                        Text(property.price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Label("\(property.bedrooms)", systemImage: "bed.double")
                            Label("\(property.bathrooms)", systemImage: "shower")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }
                    
                    Text(property.address)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(property.area)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .cornerRadius(20)
            .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 50)
    }
}