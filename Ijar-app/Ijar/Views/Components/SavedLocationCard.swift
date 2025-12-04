import SwiftUI

struct SavedLocationCard: View {
    let location: SavedLocation
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.coffeeBean)

                    Text(location.postcode)
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.6))
                }

                Spacer()

                HStack(spacing: 16) {
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.rusticOrange)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: onDelete) {
                        Text("Remove")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    let location = SavedLocation(
        name: "Office",
        postcode: "E14 5AB",
        latitude: 51.5054,
        longitude: -0.0235
    )

    return VStack {
        SavedLocationCard(
            location: location,
            onEdit: {},
            onDelete: {}
        )
    }
    .padding(.horizontal, 24)
    .background(Color.warmCream)
}
