
import SwiftUI

struct SearchQueryCard: View {
    let query: SearchQuery
    let onToggleActive: () -> Void
    let onEdit: (SearchQuery) -> Void
    let onDuplicate: (SearchQuery) -> Void
    let onDelete: (SearchQuery) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Paused banner
            if !query.active {
                HStack(spacing: 8) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 14))
                    Text("Paused")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Button {
                        onToggleActive()
                    } label: {
                        Text("Resume")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.rusticOrange)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .foregroundColor(.warmBrown.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.warmBrown.opacity(0.08))
            }

            VStack(spacing: 0) {
                // Header with name and status toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(query.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.coffeeBean)
                            .lineLimit(1)

                        Text(query.areaName)
                            .font(.system(size: 14))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }

                    Spacer()

                    if query.active {
                        Button {
                            onToggleActive()
                        } label: {
                            Text("Pause")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.rusticOrange)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 14)

                divider

                // Criteria rows
                criteriaRow(label: "Budget", value: budgetText)
                divider
                criteriaRow(label: "Bedrooms", value: bedroomsText)
                divider
                criteriaRow(label: "Bathrooms", value: bathroomsText)
                divider
                criteriaRow(label: "Radius", value: radiusText)

                if let furnish = query.furnishType {
                    divider
                    criteriaRow(label: "Furnishing", value: furnish.capitalized)
                }

                divider

                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        onEdit(query)
                    } label: {
                        Text("Edit")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.rusticOrange)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        onDuplicate(query)
                    } label: {
                        Text("Duplicate")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.rusticOrange)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    Button {
                        onDelete(query)
                    } label: {
                        Text("Delete")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 14)
            }
            .padding(.horizontal, 16)
            .opacity(query.active ? 1 : 0.5)
        }
        .background(Color.white)
        .cornerRadius(12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.warmBrown.opacity(0.1))
            .frame(height: 1)
    }

    private func criteriaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.warmBrown.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.coffeeBean)
        }
        .padding(.vertical, 12)
    }

    private var budgetText: String {
        if let minPrice = query.minPrice, let maxPrice = query.maxPrice {
            return "£\(formatPrice(minPrice)) - £\(formatPrice(maxPrice))"
        }
        return "Any"
    }

    private var bedroomsText: String {
        if let minBed = query.minBedrooms, let maxBed = query.maxBedrooms {
            return minBed == maxBed ? "\(minBed)" : "\(minBed) - \(maxBed)"
        }
        return "Any"
    }

    private var bathroomsText: String {
        if let minBath = query.minBathrooms, let maxBath = query.maxBathrooms {
            return minBath == maxBath ? "\(minBath)" : "\(minBath) - \(maxBath)"
        }
        return "Any"
    }

    private var radiusText: String {
        if let radius = query.radius {
            if radius == 0.5 {
                return "½ mile"
            } else if radius == floor(radius) {
                return "\(Int(radius)) \(radius == 1 ? "mile" : "miles")"
            } else {
                return String(format: "%.1f miles", radius)
            }
        }
        return "Any"
    }

    private func formatPrice(_ price: Int) -> String {
        if price >= 1000 {
            let k = Double(price) / 1000.0
            if k == floor(k) {
                return "\(Int(k))k"
            }
            return String(format: "%.1fk", k)
        }
        return "\(price)"
    }
}

#Preview {
    let query = SearchQuery(
        name: "Canary Wharf",
        areaName: "Canary Wharf, London",
        latitude: 51.5054,
        longitude: -0.0235,
        minPrice: 2500,
        maxPrice:
            3500,
        minBedrooms: 2,
        maxBedrooms: 3,
        minBathrooms: 1,
        maxBathrooms: 2,
        radius: 3.0,
        furnishType: "furnished"
    )

    return SearchQueryCard(
        query: query,
        onToggleActive: {},
        onEdit: { _ in },
        onDuplicate: { _ in },
        onDelete: { _ in }
    )
    .padding()
    .background(Color.warmCream)
}
