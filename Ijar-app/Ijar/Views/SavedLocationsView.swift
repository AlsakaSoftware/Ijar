import SwiftUI
import RevenueCatUI

struct SavedLocationsView: View {
    @StateObject private var locationsManager = SavedLocationsManager()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddLocation = false
    @State private var showingPaywall = false
    @State private var locationToEdit: SavedLocation?
    @State private var limitMessage: String?

    var body: some View {
        ZStack {
            Color.warmCream
                .ignoresSafeArea()

            List {
                if locationsManager.locations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.warmBrown.opacity(0.5))

                        Text("No places yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.coffeeBean)

                        Text("Add your work, gym, or anywhere you visit regularly. We'll show journey times from every property.")
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
                        LocationRow(location: location, onEdit: {
                            locationToEdit = location
                        }, onDelete: {
                            locationsManager.deleteLocation(location)
                        })
                    }
                    .onDelete(perform: locationsManager.deleteLocations)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Places That Matter")
        .navigationBarTitleDisplayMode(.large)
        .tint(.rusticOrange)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: handleAddLocation) {
                    Image(systemName: "plus")
                        .foregroundColor(.rusticOrange)
                }
            }
        }
        .sheet(isPresented: $showingAddLocation) {
            AddLocationView(locationsManager: locationsManager)
        }
        .sheet(item: $locationToEdit) { location in
            EditLocationView(locationsManager: locationsManager, location: location)
        }
        .upgradePrompt(limitMessage: $limitMessage, showPaywall: $showingPaywall)
    }

    private func handleAddLocation() {
        let result = subscriptionManager.canAddSavedLocation(currentLocationCount: locationsManager.locations.count)

        if result.canAdd {
            showingAddLocation = true
        } else {
            limitMessage = result.reason
        }
    }
}

struct LocationRow: View {
    let location: SavedLocation
    let onEdit: () -> Void
    let onDelete: () -> Void

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

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.rusticOrange)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.rusticOrange.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
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
    private let geocodingService = GeocodingService()

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
                    Text("We'll calculate journey times from properties to this place using TfL's Journey Planner.")
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
            }
            .navigationTitle("Add Place")
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

        // Geocode the postcode/address to get coordinates using CoreLocation
        Task {
            do {
                let coordinates = try await geocodingService.geocode(postcode)
                let location = SavedLocation(
                    name: name,
                    postcode: postcode.uppercased(),
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )

                locationsManager.addLocation(location)
                dismiss()
            } catch {
                self.error = "Could not find coordinates for this location. Please check and try again."
            }

            isGeocoding = false
        }
    }
}

struct EditLocationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var locationsManager: SavedLocationsManager
    let location: SavedLocation
    private let geocodingService = GeocodingService()

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
                    Text("We'll calculate journey times from properties to this place using TfL's Journey Planner.")
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
            }
            .navigationTitle("Edit Place")
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
                            updateLocation()
                        }
                        .disabled(name.isEmpty || postcode.isEmpty)
                    }
                }
            }
            .onAppear {
                name = location.name
                postcode = location.postcode
            }
        }
    }

    private func updateLocation() {
        isGeocoding = true
        error = nil

        // Geocode the postcode/address to get coordinates using CoreLocation
        Task {
            do {
                let coordinates = try await geocodingService.geocode(postcode)
                let updatedLocation = SavedLocation(
                    id: location.id,
                    name: name,
                    postcode: postcode.uppercased(),
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )

                locationsManager.updateLocation(updatedLocation)
                dismiss()
            } catch {
                self.error = "Could not find coordinates for this location. Please check and try again."
            }

            isGeocoding = false
        }
    }
}

#Preview {
    NavigationView {
        SavedLocationsView()
    }
}
