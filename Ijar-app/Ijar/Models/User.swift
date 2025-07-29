import Foundation

struct User: Codable, Identifiable {
    let id: String
    let userId: String
    let fullName: String?
    let email: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}