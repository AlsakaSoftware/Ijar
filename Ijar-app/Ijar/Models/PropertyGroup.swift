import Foundation

struct PropertyGroup: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let userId: String
    let name: String
    let createdAt: Date
    var propertyCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case createdAt = "created_at"
        case propertyCount = "property_count"
    }

    init(id: String = UUID().uuidString, userId: String, name: String, createdAt: Date = Date(), propertyCount: Int? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.propertyCount = propertyCount
    }
}
