import Foundation

struct SearchQuery: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let locationName: String
    let locationId: String
    let minPrice: Int?
    let maxPrice: Int?
    let minBedrooms: Int?
    let maxBedrooms: Int?
    let minBathrooms: Int?
    let furnishedType: FurnishedType?
    let propertyType: PropertyType?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case locationName = "location_name"
        case locationId = "location_id"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case minBedrooms = "min_bedrooms"
        case maxBedrooms = "max_bedrooms"
        case minBathrooms = "min_bathrooms"
        case furnishedType = "furnished_type"
        case propertyType = "property_type"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum FurnishedType: String, Codable, CaseIterable {
    case furnished = "furnished"
    case unfurnished = "unfurnished"
    case partFurnished = "part_furnished"
    case any = "furnished_or_unfurnished"
    
    var displayName: String {
        switch self {
        case .furnished:
            return "Furnished"
        case .unfurnished:
            return "Unfurnished"
        case .partFurnished:
            return "Part Furnished"
        case .any:
            return "Any"
        }
    }
}

enum PropertyType: String, Codable, CaseIterable {
    case flat = "flat"
    case house = "house"
    case any = "any"
    
    var displayName: String {
        switch self {
        case .flat:
            return "Flat"
        case .house:
            return "House"
        case .any:
            return "Any"
        }
    }
}