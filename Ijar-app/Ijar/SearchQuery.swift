import Foundation

struct SearchQuery: Identifiable, Codable {
    let id: UUID
    let name: String
    let postcode: String
    let minPrice: Int?
    let maxPrice: Int?
    let minBedrooms: Int?
    let maxBedrooms: Int?
    let minBathrooms: Int?
    let maxBathrooms: Int?
    let radius: Double?
    let furnishType: String?
    let active: Bool
    let created: Date
    let updated: Date

    init(
        id: UUID = UUID(),
        name: String,
        postcode: String,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        minBedrooms: Int? = nil,
        maxBedrooms: Int? = nil,
        minBathrooms: Int? = nil,
        maxBathrooms: Int? = nil,
        radius: Double? = nil,
        furnishType: String? = nil,
        active: Bool = true,
        created: Date = Date(),
        updated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.postcode = postcode
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.minBedrooms = minBedrooms
        self.maxBedrooms = maxBedrooms
        self.minBathrooms = minBathrooms
        self.maxBathrooms = maxBathrooms
        self.radius = radius
        self.furnishType = furnishType
        self.active = active
        self.created = created
        self.updated = updated
    }
}

