import Foundation

final class PropertyRepository {
    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    func fetchPropertiesForUser() async throws -> [Property] {
        let rows: [PropertyRow] = try await networkService.send(
            endpoint: "/api/feed",
            method: .get
        )

        return rows.map { row in
            Property(
                id: String(row.rightmove_id),
                images: row.images,
                price: row.price,
                bedrooms: row.bedrooms,
                bathrooms: row.bathrooms,
                address: row.address,
                area: row.area ?? "",
                rightmoveUrl: row.rightmove_url,
                agentPhone: row.agent_phone,
                agentName: row.agent_name,
                branchName: row.branch_name,
                latitude: row.latitude,
                longitude: row.longitude
            )
        }
    }

    @discardableResult
    func trackPropertyAction(propertyId: String, action: PropertyAction) async -> Bool {
        do {
            struct ActionBody: Encodable {
                let action: String
            }

            let _: SuccessResponse = try await networkService.send(
                endpoint: "/api/properties/\(propertyId)/action",
                method: .post,
                body: ActionBody(action: action.rawValue)
            )
            return true
        } catch {
#if DEBUG
            print("PropertyRepository: Failed to track action: \(error)")
#endif
            return false
        }
    }
}

enum PropertyAction: String {
    case saved = "saved"
    case passed = "passed"
}

struct PropertyRow: Codable {
    let id: String
    let rightmove_id: Int
    let images: [String]
    let price: String
    let bedrooms: Int
    let bathrooms: Int
    let address: String
    let area: String?
    let rightmove_url: String?
    let agent_phone: String?
    let agent_name: String?
    let branch_name: String?
    let latitude: Double?
    let longitude: Double?
    let found_at: String?
    let found_by_query: String?
}

private struct SuccessResponse: Decodable {
    let success: Bool
}
