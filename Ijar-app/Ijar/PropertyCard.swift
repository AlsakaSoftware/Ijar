import SwiftUI
import Kingfisher

struct PropertyCard: View {
    let property: Property
    let onTap: () -> Void
    var dragAmount: CGSize = .zero
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
                    
                    Text(property.area)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.warmCream.opacity(0.7))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)

            // Swipe up indicator - moved from overlay
            if abs(dragAmount.width) < 10 && dragAmount.height >= 0 {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.warmCream)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.9 : 0.7)

                    Text("Details")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.warmCream.opacity(0.9))
                }
                .padding(.bottom, 12)
                .opacity(dragAmount.height < -30 ? max(0, 1.0 - ((abs(dragAmount.height) - 30.0) / 90.0)) : 1.0)
                .offset(y: min(0, dragAmount.height / 3))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragAmount)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }
            }
        }
        .aspectRatio(0.65, contentMode: .fit)
        .background {
            imagesCarousel
                .background(Color.warmCream)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(swipeUpBorderEffect)
        .shadow(color: {
                    let isUpwardMovement = dragAmount.height < -60
                    let horizontalThreshold: CGFloat = isUpwardMovement ? 195 : 130

                    if dragAmount.height < -50 {
                        return .rusticOrange.opacity(0.3)
                    } else if dragAmount.width > horizontalThreshold {
                        return .rusticOrange.opacity(0.25)
                    } else if dragAmount.width < -horizontalThreshold {
                        return .warmBrown.opacity(0.15)
                    } else {
                        return .coffeeBean.opacity(0.08)
                    }
                }(),
                radius: {
                    let isUpwardMovement = dragAmount.height < -60
                    let horizontalThreshold: CGFloat = isUpwardMovement ? 195 : 130
                    return (abs(dragAmount.width) > horizontalThreshold || dragAmount.height < -50) ? 20 : 16
                }(),
                y: 8)
        .scaleEffect(dragAmount.height < -50 ? 0.95 : 1.0)
        .rotationEffect(.degrees(dragAmount.height < -30 ? Double(dragAmount.height + 30) / 15 : 0), anchor: .bottom)
        .offset(y: dragAmount.height < -30 ? dragAmount.height / 4 : 0)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragAmount)
        .overlay(alignment: .bottom) {
            releaseToViewFeedback
        }
        .overlay {
            imageTapZones
        }

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
                        .onFailure { _ in
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

    // MARK: - Overlay Components

    private var swipeUpBorderEffect: some View {
        let isUpwardMovement = dragAmount.height < -60
        let horizontalThreshold: CGFloat = isUpwardMovement ? 195 : 130

        return RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: {
                        // Swipe up - orange glow
                        if dragAmount.height < -30 {
                            return [
                                Color.rusticOrange.opacity(min(0.8, abs(dragAmount.height) / 150.0)),
                                Color.warmCream.opacity(min(0.6, abs(dragAmount.height) / 200.0))
                            ]
                        }
                        // Swipe right (save) - rustic orange glow
                        else if dragAmount.width > horizontalThreshold {
                            return [
                                Color.rusticOrange.opacity(min(0.7, dragAmount.width / 150)),
                                Color.warmCream.opacity(min(0.5, dragAmount.width / 200))
                            ]
                        }
                        // Swipe left (reject) - subtle brown glow
                        else if dragAmount.width < -horizontalThreshold {
                            return [
                                Color.warmBrown.opacity(min(0.4, abs(dragAmount.width) / 200.0)),
                                Color.coffeeBean.opacity(min(0.3, abs(dragAmount.width) / 250.0))
                            ]
                        }
                        // No swipe
                        else {
                            return [Color.clear, Color.clear]
                        }
                    }(),
                    startPoint: dragAmount.height < -30 ? .top : .leading,
                    endPoint: dragAmount.height < -30 ? .bottom : .trailing
                ),
                lineWidth: (abs(dragAmount.width) > horizontalThreshold || dragAmount.height < -30) ? 2 : 0
            )
    }

    @ViewBuilder
    private var releaseToViewFeedback: some View {
        // Only show if primarily swiping up (not left or right)
        if dragAmount.height < -60 && abs(dragAmount.width) < 40 {
            VStack {
                Spacer()

                ZStack {
                    // Background glow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.rusticOrange.opacity(0.3),
                                    Color.rusticOrange.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 150)
                        .blur(radius: 20)

                    VStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.warmCream)
                            .shadow(color: .black.opacity(0.3), radius: 10)

                        Text("Release to view")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.warmCream)
                            .shadow(radius: 5)
                    }
                    .offset(y: 30)
                }
            }
            .opacity(min(1.0, (abs(dragAmount.height) - 60.0) / 60.0))
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: dragAmount)
        }
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

    // Swipe indicator overlay (currently empty, kept for potential future use)
    @ViewBuilder
    private var swipeIndicatorOverlay: some View {
        EmptyView()
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

