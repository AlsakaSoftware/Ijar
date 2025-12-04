import Foundation
import Supabase

@MainActor
class SearchQueryService: ObservableObject {
    private let supabase: SupabaseClient
    @Published var queries: [SearchQuery] = []
    @Published var error: String?

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

    func loadUserQueries() async {
        error = nil

        do {
            // Get current user
            let user = try await supabase.auth.user()

            let response: [QueryRow] = try await supabase
                .from("query")
                .select()
                .eq("user_id", value: user.id)
                .order("created", ascending: false)
                .execute()
                .value

            queries = response.map { row in
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
        } catch {
            self.error = error.localizedDescription
            print("Error loading queries: \(error)")
        }
    }

    @discardableResult
    func createQuery(_ query: SearchQuery) async -> Bool {
        error = nil

        do {
            // Get current user
            let user = try await supabase.auth.user()

            // Check if this is the user's first query
            let isFirstQuery = queries.isEmpty

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

            // If this is the first query, trigger GitHub workflow
            if isFirstQuery {
                await triggerGitHubWorkflow()
            }

            await loadUserQueries() // Refresh the list
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error creating query: \(error)")
            return false
        }
    }

    // Special method for duplicating queries that adds them at the bottom
    func createQueryAtBottom(_ query: SearchQuery) async -> Bool {
        error = nil

        do {
            // Get current user
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

            // Add to bottom of local list instead of reloading
            queries.append(query)
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error creating query: \(error)")
            return false
        }
    }

    private func triggerGitHubWorkflow() async {
        // For production, you'd want to call your backend API that has the GitHub token
        // For now, we'll just log that we would trigger the workflow
        print("🚀 Would trigger GitHub workflow for first query")
    }

    @discardableResult
    func updateQuery(_ query: SearchQuery) async -> Bool {
        error = nil

        do {
            // Use QueryUpdateRow which excludes 'created' field
            // This prevents overwriting the original created timestamp
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

            await loadUserQueries()
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error updating query: \(error)")
            return false
        }
    }

    func deleteQuery(_ query: SearchQuery) async -> Bool {
        error = nil

        do {
            try await supabase
                .from("query")
                .delete()
                .eq("id", value: query.id.uuidString)
                .execute()

            await loadUserQueries() // Refresh the list
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error deleting query: \(error)")
            return false
        }
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
