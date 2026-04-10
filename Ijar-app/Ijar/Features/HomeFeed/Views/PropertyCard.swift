import SwiftUI
import Kingfisher

struct PropertyCard: View {
    let property: Property
    let onTap: () -> Void
    var dragAmount: CGSize = .zero
    var saveProgress: CGFloat = 0
    var passProgress: CGFloat = 0
    var detailsProgress: CGFloat = 0
    @State private var currentImageIndex = 0
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image indicators at top
            imageIndicators
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
                            Text(property.bedroomText)
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
                    
                    Text(property.area)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.warmCream.opacity(0.7))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)

            VStack(spacing: 4) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.warmCream)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.9 : 0.7)

                Text("Swipe up for details")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.warmCream.opacity(0.9))
            }
            .padding(.bottom, 12)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .aspectRatio(0.65, contentMode: .fit)
        .background {
            imagesCarousel
                .background(Color.warmCream)
        }
        .clipShape(RoundedRectangle(cornerRadius: CardConstants.cornerRadius))
        .overlay {
            // Swipe overlays
            ZStack {
                SaveOverlay(progress: saveProgress)
                PassOverlay(progress: passProgress)
                DetailsOverlay(progress: detailsProgress)
            }
            .clipShape(RoundedRectangle(cornerRadius: CardConstants.cornerRadius))
        }
        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
        .shadow(color: .black.opacity(0.06), radius: 4, x: dynamicShadowX * 0.3, y: 4)
        .shadow(color: .black.opacity(0.08), radius: 16, x: dynamicShadowX, y: 12)
        // 3D perspective tilt based on horizontal drag
        .rotation3DEffect(
            .degrees(Double(-dragAmount.width) / 40),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragAmount)
        .overlay {
            imageTapZones
        }

    }

    // MARK: - Dynamic Shadow

    private var dynamicShadowX: CGFloat {
        // Shadow shifts opposite to drag direction (like light source is fixed)
        let maxOffset: CGFloat = 8
        let normalizedDrag = dragAmount.width / 150
        return -normalizedDrag.clamped(to: -1...1) * maxOffset
    }

    private var imagesCarousel: some View {
        ZStack {
            TabView(selection: $currentImageIndex) {
                ForEach(0..<property.images.count, id: \.self) { index in
                    KFImage(URL(string: property.images[index]))
                        .placeholder {
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
                        }
                        .resizable()
                        .fade(duration: 0.25)
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
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
    
    // MARK: - Image Indicators

    private var imageIndicators: some View {
        GeometryReader { geometry in
            let maxWidth = geometry.size.width - 40 // Account for padding
            let imageCount = property.images.count

            // Dynamic sizing based on available space
            let (indicatorWidth, indicatorHeight, spacing) = calculateIndicatorDimensions(
                imageCount: imageCount,
                maxWidth: maxWidth
            )

            HStack(spacing: spacing) {
                ForEach(0..<imageCount, id: \.self) { index in
                    let isSelected = index == currentImageIndex
                    let isCompressed = indicatorWidth <= 8 // Becomes dot-like when compressed

                    // Shape morphs from capsule to circle based on compression
                    if isCompressed {
                        Circle()
                            .fill(isSelected ? Color.white : Color.white.opacity(0.5))
                            .frame(
                                width: isSelected ? indicatorWidth * 1.3 : indicatorWidth,
                                height: isSelected ? indicatorHeight * 1.3 : indicatorHeight
                            )
                            .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                            .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                    } else {
                        Capsule()
                            .fill(isSelected ? Color.white : Color.white.opacity(0.5))
                            .frame(
                                width: isSelected ? indicatorWidth * 1.5 : indicatorWidth,
                                height: indicatorHeight
                            )
                            .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                            .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                    }
                }
            }
            .frame(maxWidth: maxWidth)
            .frame(width: geometry.size.width, height: 10, alignment: .center)
        }
        .frame(height: 10)
    }

    private func calculateIndicatorDimensions(
        imageCount: Int,
        maxWidth: CGFloat
    ) -> (width: CGFloat, height: CGFloat, spacing: CGFloat) {
        // Start with ideal sizes
        let idealWidth: CGFloat = 24
        let idealHeight: CGFloat = 3
        let idealSpacing: CGFloat = 4

        // Calculate total width needed with ideal sizes
        let idealTotalWidth = CGFloat(imageCount) * idealWidth + CGFloat(imageCount - 1) * idealSpacing

        // If it fits, use ideal sizes
        if idealTotalWidth <= maxWidth {
            return (width: idealWidth, height: idealHeight, spacing: idealSpacing)
        }

        // Otherwise, compress proportionally
        let compressionRatio = maxWidth / idealTotalWidth

        // Calculate compressed sizes
        var width = idealWidth * compressionRatio
        var spacing = idealSpacing * compressionRatio
        var height = idealHeight

        // Minimum sizes to maintain visibility
        let minWidth: CGFloat = 3
        let minSpacing: CGFloat = 1.5
        let minHeight: CGFloat = 3

        // If we're getting too small, adjust
        if width < minWidth {
            width = minWidth
            // Recalculate spacing to fit
            let remainingSpace = maxWidth - (CGFloat(imageCount) * width)
            spacing = max(minSpacing, remainingSpace / CGFloat(imageCount - 1))
        }

        // When width gets small enough, transition to square dots
        if width <= 8 {
            height = width // Make it square for dot appearance
        }

        // Ensure minimums
        width = max(minWidth, width)
        height = max(minHeight, height)
        spacing = max(minSpacing, spacing)

        return (width: width, height: height, spacing: spacing)
    }

    private var imageTapZones: some View {
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
    }
}

#Preview("Few Images") {
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

#Preview("Many Images") {
    VStack {
        PropertyCard(
            property: Property(
                images: Array(repeating: "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&q=80", count: 20),
                price: "£3,500/month",
                bedrooms: 4,
                bathrooms: 3,
                address: "456 Isle of Dogs",
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

#Preview("Save Overlay") {
    VStack {
        PropertyCard(
            property: Property(
                images: ["https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&q=80"],
                price: "£2,500/month",
                bedrooms: 3,
                bathrooms: 2,
                address: "123 Canary Wharf",
                area: "London E14"
            ),
            onTap: {},
            saveProgress: 0.8
        )
        .background(Color.warmCream)
    }
    .padding()
}

#Preview("Pass Overlay") {
    VStack {
        PropertyCard(
            property: Property(
                images: ["https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&q=80"],
                price: "£2,500/month",
                bedrooms: 3,
                bathrooms: 2,
                address: "123 Canary Wharf",
                area: "London E14"
            ),
            onTap: {},
            passProgress: 0.8
        )
        .background(Color.warmCream)
    }
    .padding()
}

