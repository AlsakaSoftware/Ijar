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
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Places that matter")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.coffeeBean)

                Text("We'll show commute times from each property")
                    .font(.system(size: 15))
                    .foregroundColor(.warmBrown.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)

            if locationsManager.locations.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.warmBrown.opacity(0.3))

                    VStack(spacing: 8) {
                        Text("No places yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.coffeeBean)

                        Text("Add your work, gym, or other places")
                            .font(.system(size: 15))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }

                    Button(action: handleAddLocation) {
                        Text("Add a place")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.rusticOrange)
                            )
                    }
                    .padding(.top, 8)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(locationsManager.locations.enumerated()), id: \.element.id) { index, location in
                            SavedLocationCard(
                                location: location,
                                onEdit: {
                                    locationToEdit = location
                                },
                                onDelete: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        locationsManager.deleteLocation(location)
                                    }
                                }
                            )

                            if index < locationsManager.locations.count - 1 {
                                Rectangle()
                                    .fill(Color.warmBrown.opacity(0.15))
                                    .frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
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
