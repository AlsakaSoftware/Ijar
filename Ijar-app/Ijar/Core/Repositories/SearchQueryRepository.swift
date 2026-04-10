import Foundation

final class SearchQueryRepository {
    private let networkService: NetworkService

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    func fetchQueries() async throws -> [SearchQuery] {
        let response: [QueryRow] = try await networkService.send(
            endpoint: "/api/queries",
            method: .get
        )

        return response.map { row in
            SearchQuery(
                id: UUID(uuidString: row.id) ?? UUID(),
                name: row.name,
                areaName: row.area_name,
                latitude: row.latitude,
                longitude: row.longitude,
                minPrice: row.min_price,
                maxPrice: row.max_price,
                minBedrooms: row.min_bedrooms,
                maxBedrooms: row.max_bedrooms,
                minBathrooms: row.min_bathrooms,
                maxBathrooms: row.max_bathrooms,
                radius: row.radius,
                furnishType: row.furnish_type,
                active: row.active ?? true,
                created: dateFormatter.date(from: row.created) ?? Date(),
                updated: dateFormatter.date(from: row.updated) ?? Date()
            )
        }.sorted { $0.created > $1.created }
    }

    func insertQuery(_ query: SearchQuery) async throws {
        let body = QueryRow(
            id: query.id.uuidString,
            user_id: nil,
            name: query.name,
            area_name: query.areaName,
            latitude: query.latitude,
            longitude: query.longitude,
            min_price: query.minPrice,
            max_price: query.maxPrice,
            min_bedrooms: query.minBedrooms,
            max_bedrooms: query.maxBedrooms,
            min_bathrooms: query.minBathrooms,
            max_bathrooms: query.maxBathrooms,
            radius: query.radius,
            furnish_type: query.furnishType,
            active: query.active,
            created: dateFormatter.string(from: query.created),
            updated: dateFormatter.string(from: query.updated)
        )

        try await networkService.send(
            endpoint: "/api/queries",
            method: .post,
            body: body
        )
    }

    func updateQuery(_ query: SearchQuery) async throws {
        let body = QueryUpdateRow(
            name: query.name,
            area_name: query.areaName,
            latitude: query.latitude,
            longitude: query.longitude,
            min_price: query.minPrice,
            max_price: query.maxPrice,
            min_bedrooms: query.minBedrooms,
            max_bedrooms: query.maxBedrooms,
            min_bathrooms: query.minBathrooms,
            max_bathrooms: query.maxBathrooms,
            radius: query.radius,
            furnish_type: query.furnishType,
            active: query.active,
            updated: dateFormatter.string(from: Date())
        )

        try await networkService.send(
            endpoint: "/api/queries/\(query.id.uuidString)",
            method: .put,
            body: body
        )
    }

    func deleteQuery(id: UUID) async throws {
        try await networkService.send(
            endpoint: "/api/queries/\(id.uuidString)",
            method: .delete
        )
    }

}

// Database row structure matching API response
private struct QueryRow: Codable {
    let id: String
    let user_id: String?
    let name: String
    let area_name: String
    let latitude: Double
    let longitude: Double
    let min_price: Int?
    let max_price: Int?
    let min_bedrooms: Int?
    let max_bedrooms: Int?
    let min_bathrooms: Int?
    let max_bathrooms: Int?
    let radius: Double?
    let furnish_type: String?
    let active: Bool?
    let created: String
    let updated: String
}

private struct QueryUpdateRow: Codable {
    let name: String
    let area_name: String
    let latitude: Double
    let longitude: Double
    let min_price: Int?
    let max_price: Int?
    let min_bedrooms: Int?
    let max_bedrooms: Int?
    let min_bathrooms: Int?
    let max_bathrooms: Int?
    let radius: Double?
    let furnish_type: String?
    let active: Bool?
    let updated: String
}
