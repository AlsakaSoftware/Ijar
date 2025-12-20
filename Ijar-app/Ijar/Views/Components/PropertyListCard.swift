import SwiftUI
import Kingfisher

/// A unified property card used in both SavedPropertiesView and BrowseResultsView
struct PropertyListCard: View {
    let property: Property
    let isSaved: Bool
    let onTap: () -> Void
    let onSaveToggle: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Property Image
                ZStack(alignment: .topTrailing) {
                    propertyImage
                    saveButton
                }

                // Property Details
                VStack(alignment: .leading, spacing: 12) {
                    // Price and features row
                    HStack(alignment: .top) {
                        Text(property.price)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.coffeeBean)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "bed.double")
                                .font(.system(size: 14))
                            Text(property.bedroomText)
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

    @ViewBuilder
    private var propertyImage: some View {
        if let firstImage = property.images.first,
           let imageURL = URL(string: firstImage) {
            KFImage(imageURL)
                .placeholder {
                    Rectangle()
                        .fill(Color.warmBrown.opacity(0.1))
                        .frame(height: 200)
                        .overlay(ProgressView())
                }
                .onFailure { _ in }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
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
    }

    private var saveButton: some View {
        LikeButton(isLiked: isSaved, isLoading: false, action: onSaveToggle)
            .padding(12)
    }
}

/// A property card with built-in save behavior - shows GroupPickerSheet when save is tapped
struct SaveablePropertyCard: View {
    let property: Property
    let propertyService: PropertyService
    let savedPropertyRepository: SavedPropertyRepository
    let onTap: () -> Void
    var onRemove: (() -> Void)? = nil  // Called when property is unsaved (for list removal)

    @State private var showingSheet = false
    @State private var previousSavedState: Bool = false

    init(
        property: Property,
        propertyService: PropertyService = PropertyService(),
        savedPropertyRepository: SavedPropertyRepository = .shared,
        onTap: @escaping () -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.property = property
        self.propertyService = propertyService
        self.savedPropertyRepository = savedPropertyRepository
        self.onTap = onTap
        self.onRemove = onRemove
    }

    private var isSaved: Bool {
        savedPropertyRepository.isSaved(property.id)
    }

    var body: some View {
        PropertyListCard(
            property: property,
            isSaved: isSaved,
            onTap: onTap,
            onSaveToggle: { showingSheet = true }
        )
        .onAppear {
            previousSavedState = isSaved
        }
        .onChange(of: isSaved) { _, newValue in
            // Only call onRemove when transitioning from saved to unsaved
            if previousSavedState && !newValue {
                onRemove?()
            }
            previousSavedState = newValue
        }
        .groupPickerSheet(
            isPresented: $showingSheet,
            property: property,
            propertyService: propertyService,
            savedPropertyRepository: savedPropertyRepository
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        PropertyListCard(
            property: Property(
                id: "1",
                images: [],
                price: "£2,500 pcm",
                bedrooms: 2,
                bathrooms: 1,
                address: "123 Example Street, London",
                area: "Canary Wharf",
                rightmoveUrl: nil,
                agentPhone: nil,
                agentName: nil,
                branchName: nil,
                latitude: nil,
                longitude: nil
            ),
            isSaved: false,
            onTap: {},
            onSaveToggle: {}
        )

        PropertyListCard(
            property: Property(
                id: "2",
                images: [],
                price: "£3,000 pcm",
                bedrooms: 3,
                bathrooms: 2,
                address: "456 Another Road, London",
                area: "Greenwich",
                rightmoveUrl: nil,
                agentPhone: nil,
                agentName: nil,
                branchName: nil,
                latitude: nil,
                longitude: nil
            ),
            isSaved: true,
            onTap: {},
            onSaveToggle: {}
        )
    }
    .padding()
    .background(Color.warmCream)
}
