import SwiftUI

struct SavedLocationsView: View {
    @StateObject private var locationsManager = SavedLocationsManager()
    @State private var showingAddLocation = false

    var body: some View {
        List {
            if locationsManager.locations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.warmBrown.opacity(0.5))

                    Text("No saved locations")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.coffeeBean)

                    Text("Add important places to see journey times from properties")
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(locationsManager.locations) { location in
                    LocationRow(location: location)
                }
                .onDelete(perform: locationsManager.deleteLocations)
            }
        }
        .navigationTitle("My Locations")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddLocation = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.rusticOrange)
                }
            }
        }
        .sheet(isPresented: $showingAddLocation) {
            AddLocationView(locationsManager: locationsManager)
        }
    }
}

struct LocationRow: View {
    let location: SavedLocation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: locationIcon)
                .font(.system(size: 20))
                .foregroundColor(.rusticOrange)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.rusticOrange.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.coffeeBean)

                Text(location.postcode)
                    .font(.system(size: 14))
                    .foregroundColor(.warmBrown.opacity(0.7))
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var locationIcon: String {
        let lowercasedName = location.name.lowercased()

        if lowercasedName.contains("work") || lowercasedName.contains("office") {
            return "briefcase.fill"
        } else if lowercasedName.contains("gym") || lowercasedName.contains("fitness") {
            return "figure.strengthtraining.traditional"
        } else if lowercasedName.contains("school") {
            return "building.2.fill"
        } else if lowercasedName.contains("home") || lowercasedName.contains("house") {
            return "house.fill"
        } else if lowercasedName.contains("friend") {
            return "person.2.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}

struct AddLocationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var locationsManager: SavedLocationsManager

    @State private var name = ""
    @State private var postcode = ""
    @State private var isGeocoding = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name (e.g., Work, Gym)", text: $name)
                        .autocapitalization(.words)

                    TextField("Postcode", text: $postcode)
                        .autocapitalization(.allCharacters)
                        .textInputAutocapitalization(.characters)
                } header: {
                    Text("Location Details")
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                }

                Section {
                    Text("Journey times from properties to this location will be calculated using TfL's Journey Planner.")
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isGeocoding {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveLocation()
                        }
                        .disabled(name.isEmpty || postcode.isEmpty)
                    }
                }
            }
        }
    }

    private func saveLocation() {
        isGeocoding = true
        error = nil

        // Geocode the postcode to get coordinates
        Task {
            do {
                let coordinates = try await geocodePostcode(postcode)
                let location = SavedLocation(
                    name: name,
                    postcode: postcode.uppercased(),
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )

                locationsManager.addLocation(location)
                dismiss()
            } catch {
                self.error = "Could not find coordinates for this postcode. Please check and try again."
            }

            isGeocoding = false
        }
    }

    private func geocodePostcode(_ postcode: String) async throws -> (latitude: Double, longitude: Double) {
        // Use UK postcode geocoding API
        let cleanedPostcode = postcode.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "https://api.postcodes.io/postcodes/\(cleanedPostcode)") else {
            throw NSError(domain: "InvalidURL", code: 0)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PostcodeResponse.self, from: data)

        guard let result = response.result else {
            throw NSError(domain: "NoResult", code: 0)
        }

        return (result.latitude, result.longitude)
    }
}

struct PostcodeResponse: Codable {
    let result: PostcodeResult?

    struct PostcodeResult: Codable {
        let latitude: Double
        let longitude: Double
    }
}

#Preview {
    NavigationView {
        SavedLocationsView()
    }
}
