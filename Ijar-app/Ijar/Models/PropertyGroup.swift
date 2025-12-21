import Foundation

struct PropertyGroup: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let userId: String
    let name: String
    let createdAt: Date
    var propertyCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case createdAt = "created_at"
        case propertyCount = "property_count"
    }

    init(id: String = UUID().uuidString, userId: String, name: String, createdAt: Date = Date(), propertyCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.propertyCount = propertyCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        propertyCount = try container.decodeIfPresent(Int.self, forKey: .propertyCount) ?? 0

        // Parse ISO8601 date string
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            createdAt = formatter.date(from: dateString) ?? Date()
        }
    }
}
