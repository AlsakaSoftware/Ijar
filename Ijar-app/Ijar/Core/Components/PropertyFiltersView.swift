import SwiftUI

/// Shared property filters component used in FilterSheet, CreateSearchQueryView, and EditSearchQueryView
struct PropertyFiltersView: View {
    @Binding var minPrice: Int?
    @Binding var maxPrice: Int?
    @Binding var minBedrooms: Int?
    @Binding var maxBedrooms: Int?
    @Binding var minBathrooms: Int?
    @Binding var maxBathrooms: Int?
    @Binding var radius: Double?
    @Binding var furnishType: String?

    var body: some View {
        VStack(spacing: 24) {
            // Price
            FilterSection(title: "Price per month") {
                HStack(spacing: 12) {
                    PriceField(title: "Min", value: $minPrice)
                    PriceField(title: "Max", value: $maxPrice)
                }
            }

            // Bedrooms
            FilterSection(title: "Bedrooms") {
                HStack(spacing: 12) {
                    BedroomPicker(title: "Min", selection: $minBedrooms, otherSelection: $maxBedrooms)
                    BedroomPicker(title: "Max", selection: $maxBedrooms, otherSelection: $minBedrooms)
                }
            }

            // Bathrooms
            FilterSection(title: "Bathrooms") {
                HStack(spacing: 12) {
                    BathroomPicker(title: "Min", selection: $minBathrooms)
                    BathroomPicker(title: "Max", selection: $maxBathrooms)
                }
            }

            // Search radius
            FilterSection(title: "Search radius") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterOption(label: "This area", isSelected: radius == nil) {
                            radius = nil
                        }
                        FilterOption(label: "½ mile", isSelected: radius == 0.5) {
                            radius = 0.5
                        }
                        FilterOption(label: "1 mile", isSelected: radius == 1.0) {
                            radius = 1.0
                        }
                        FilterOption(label: "3 miles", isSelected: radius == 3.0) {
                            radius = 3.0
                        }
                        FilterOption(label: "5 miles", isSelected: radius == 5.0) {
                            radius = 5.0
                        }
                        FilterOption(label: "10 miles", isSelected: radius == 10.0) {
                            radius = 10.0
                        }
                    }
                }
            }

            // Furnishing
            FilterSection(title: "Furnishing") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterOption(label: "Any", isSelected: furnishType == nil) {
                            furnishType = nil
                        }
                        FilterOption(label: "Furnished", isSelected: furnishType == "furnished") {
                            furnishType = "furnished"
                        }
                        FilterOption(label: "Part furnished", isSelected: furnishType == "partFurnished") {
                            furnishType = "partFurnished"
                        }
                        FilterOption(label: "Unfurnished", isSelected: furnishType == "unfurnished") {
                            furnishType = "unfurnished"
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Bedroom Picker

struct BedroomPicker: View {
    let title: String
    @Binding var selection: Int?
    @Binding var otherSelection: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.warmBrown)
            Menu {
                Button("Any") {
                    selection = nil
                    // If the other field is also 0 (studio), reset it to nil
                    if otherSelection == 0 {
                        otherSelection = nil
                    }
                }
                Button("Studio") {
                    // For studios, set both min and max to 0
                    selection = 0
                    otherSelection = 0
                }
                ForEach(1...5, id: \.self) { num in
                    Button("\(num)") {
                        selection = num
                        // Clear the other field if it was set to studio (0)
                        if otherSelection == 0 {
                            otherSelection = nil
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection == nil ? "Any" : (selection == 0 ? "Studio" : "\(selection!)"))
                        .foregroundColor(.coffeeBean)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.warmBrown)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Bathroom Picker

struct BathroomPicker: View {
    let title: String
    @Binding var selection: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.warmBrown)
            Menu {
                Button("Any") { selection = nil }
                ForEach(1...4, id: \.self) { num in
                    Button("\(num)") { selection = num }
                }
            } label: {
                HStack {
                    Text(selection == nil ? "Any" : "\(selection!)")
                        .foregroundColor(.coffeeBean)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.warmBrown)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}
