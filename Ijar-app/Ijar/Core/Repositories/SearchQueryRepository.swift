import Foundation
import Supabase

final class SearchQueryRepository {
    private let supabase: SupabaseClient

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }

    func fetchQueries() async throws -> [SearchQuery] {
        let user = try await supabase.auth.user()

        let response: [QueryRow] = try await supabase
            .from("query")
            .select()
            .eq("user_id", value: user.id)
            .order("created", ascending: false)
            .execute()
            .value

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
        let user = try await supabase.auth.user()

        let queryRow = QueryRow(
            id: query.id.uuidString,
            user_id: user.id.uuidString,
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

        try await supabase
            .from("query")
            .insert(queryRow)
            .execute()
    }

    func updateQuery(_ query: SearchQuery) async throws {
        let updateRow = QueryUpdateRow(
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

        try await supabase
            .from("query")
            .update(updateRow)
            .eq("id", value: query.id.uuidString)
            .execute()
    }

    func deleteQuery(id: UUID) async throws {
        try await supabase
            .from("query")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func getCurrentUserId() async throws -> String {
        let user = try await supabase.auth.user()
        return user.id.uuidString
    }
}

// Database row structure matching Supabase schema
private struct QueryRow: Codable {
    let id: String
    let user_id: String
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

// Update row - excludes created field so it doesn't get modified
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
