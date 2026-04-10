import Foundation

struct SavedLocation: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String          // e.g., "Work", "Gym", "Kids School"
    var postcode: String
    var latitude: Double?
    var longitude: Double?

    init(id: UUID = UUID(), name: String, postcode: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.postcode = postcode
        self.latitude = latitude
        self.longitude = longitude
    }
}
