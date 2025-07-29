import Foundation

struct Property: Codable, Identifiable {
    let id: String
    let rightmoveId: String
    let address: String
    let price: String
    let bedrooms: Int
    let bathrooms: Int
    let propertyUrl: String
    let imageUrl: String?
    let description: String?
    let firstSeenDate: Date
    let lastSeenDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case rightmoveId = "rightmove_id"
        case address
        case price
        case bedrooms
        case bathrooms
        case propertyUrl = "property_url"
        case imageUrl = "image_url"
        case description
        case firstSeenDate = "first_seen_date"
        case lastSeenDate = "last_seen_date"
    }
}

struct QueryProperty: Codable, Identifiable {
    let id: String
    let queryId: String
    let propertyId: String
    let userId: String
    let status: PropertyStatus
    let foundAt: Date
    let property: Property?
    
    enum CodingKeys: String, CodingKey {
        case id
        case queryId = "query_id"
        case propertyId = "property_id"
        case userId = "user_id"
        case status
        case foundAt = "found_at"
        case property
    }
}

enum PropertyStatus: String, Codable {
    case new = "new"
    case viewed = "viewed"
    case liked = "liked"
    case dismissed = "dismissed"
}