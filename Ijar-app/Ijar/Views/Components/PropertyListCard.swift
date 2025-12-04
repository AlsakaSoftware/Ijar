import SwiftUI
import Kingfisher

/// A unified property card used in both SavedPropertiesView and BrowseResultsView
struct PropertyListCard: View {
    let property: Property
    let isSaved: Bool
    let onTap: () -> Void
    let onSaveToggle: () -> Void

    @State private var isPressed = false
    @State private var showingUnsaveConfirmation = false
    @State private var isLoading = false

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
        .alert("Remove from favorites?", isPresented: $showingUnsaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                isLoading = true
                onSaveToggle()
            }
        } message: {
            Text("This property will be removed from your saved list")
        }
        .onChange(of: isSaved) { _, _ in
            isLoading = false
        }
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
        LikeButton(isLiked: isSaved, isLoading: isLoading, action: handleSaveToggle)
            .padding(12)
    }

    private func handleSaveToggle() {
        if isSaved {
            // Show confirmation before removing
            showingUnsaveConfirmation = true
        } else {
            // Save immediately with animation
            isLoading = true
            onSaveToggle()
            // Reset loading after a brief delay (the parent will update isSaved)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
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
