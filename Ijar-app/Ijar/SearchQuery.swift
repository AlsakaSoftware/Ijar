import Foundation

struct SearchQuery: Identifiable, Codable {
    let id: UUID
    let name: String
    let locationId: String
    let locationName: String
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
        locationId: String,
        locationName: String,
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
        self.locationId = locationId
        self.locationName = locationName
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

// Mock data for testing
extension SearchQuery {
    static let mockQueries = [
        SearchQuery(
            name: "Canary Wharf 3-bed",
            locationId: "REGION^87490",
            locationName: "Canary Wharf",
            minPrice: 2500,
            maxPrice: 4000,
            minBedrooms: 3,
            maxBedrooms: 3
        ),
        SearchQuery(
            name: "Mile End Budget",
            locationId: "REGION^61166",
            locationName: "Mile End",
            minPrice: 1800,
            maxPrice: 2500,
            minBedrooms: 2,
            maxBedrooms: 4
        )
    ]
}