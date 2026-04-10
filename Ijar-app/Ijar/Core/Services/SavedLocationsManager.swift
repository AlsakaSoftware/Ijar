import Foundation

@MainActor
class SavedLocationsManager: ObservableObject {
    @Published private(set) var locations: [SavedLocation] = []

    private let userDefaultsKey = "saved_locations"

    init() {
        loadLocations()
    }

    /// Load saved locations from UserDefaults
    func loadLocations() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
#if DEBUG
            print("📍 SavedLocationsManager: No saved locations found")
#endif
            locations = []
            return
        }

        locations = decoded
#if DEBUG
        print("📍 SavedLocationsManager: Loaded \(locations.count) locations")
#endif
    }

    /// Save locations to UserDefaults
    private func saveLocations() {
        guard let encoded = try? JSONEncoder().encode(locations) else {
#if DEBUG
            print("❌ SavedLocationsManager: Failed to encode locations")
#endif
            return
        }

        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
#if DEBUG
        print("✅ SavedLocationsManager: Saved \(locations.count) locations")
#endif
    }

    /// Add a new location
    func addLocation(_ location: SavedLocation) {
        locations.append(location)
        saveLocations()
    }

    /// Update an existing location
    func updateLocation(_ location: SavedLocation) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
            saveLocations()
        }
    }

    /// Delete a location
    func deleteLocation(_ location: SavedLocation) {
        locations.removeAll { $0.id == location.id }
        saveLocations()
    }

    /// Delete locations at specific indices
    func deleteLocations(at offsets: IndexSet) {
        locations.remove(atOffsets: offsets)
        saveLocations()
    }
}
