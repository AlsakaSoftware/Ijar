import Foundation
import Supabase

@MainActor
class SearchQueryService: ObservableObject {
    private let supabase: SupabaseClient
    @Published var queries: [SearchQuery] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }
    
    func loadUserQueries() async {
        isLoading = true
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
                    locationId: row.location_id,
                    locationName: row.location_name,
                    minPrice: row.min_price,
                    maxPrice: row.max_price,
                    minBedrooms: row.min_bedrooms,
                    maxBedrooms: row.max_bedrooms,
                    minBathrooms: row.min_bathrooms,
                    maxBathrooms: row.max_bathrooms,
                    radius: row.radius,
                    furnishType: row.furnish_type,
                    active: row.active ?? true,
                    created: ISO8601DateFormatter().date(from: row.created) ?? Date(),
                    updated: ISO8601DateFormatter().date(from: row.updated) ?? Date()
                )
            }
        } catch {
            self.error = error.localizedDescription
            print("Error loading queries: \(error)")
        }
        
        isLoading = false
    }
    
    func createQuery(_ query: SearchQuery) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Get current user
            let user = try await supabase.auth.user()
            
            let queryRow = QueryRow(
                id: query.id.uuidString,
                user_id: user.id.uuidString,
                name: query.name,
                location_id: query.locationId,
                location_name: query.locationName,
                min_price: query.minPrice,
                max_price: query.maxPrice,
                min_bedrooms: query.minBedrooms,
                max_bedrooms: query.maxBedrooms,
                min_bathrooms: query.minBathrooms,
                max_bathrooms: query.maxBathrooms,
                radius: query.radius,
                furnish_type: query.furnishType,
                active: query.active,
                created: ISO8601DateFormatter().string(from: query.created),
                updated: ISO8601DateFormatter().string(from: query.updated)
            )
            
            try await supabase
                .from("query")
                .insert(queryRow)
                .execute()
            
            await loadUserQueries() // Refresh the list
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error creating query: \(error)")
            isLoading = false
            return false
        }
    }
    
    @discardableResult
    func updateQuery(_ query: SearchQuery) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // Get current user
            let user = try await supabase.auth.user()
            
            let queryRow = QueryRow(
                id: query.id.uuidString,
                user_id: user.id.uuidString,
                name: query.name,
                location_id: query.locationId,
                location_name: query.locationName,
                min_price: query.minPrice,
                max_price: query.maxPrice,
                min_bedrooms: query.minBedrooms,
                max_bedrooms: query.maxBedrooms,
                min_bathrooms: query.minBathrooms,
                max_bathrooms: query.maxBathrooms,
                radius: query.radius,
                furnish_type: query.furnishType,
                active: query.active,
                created: ISO8601DateFormatter().string(from: query.created),
                updated: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("query")
                .update(queryRow)
                .eq("id", value: query.id.uuidString)
                .execute()
            
            await loadUserQueries() // Refresh the list
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error updating query: \(error)")
            isLoading = false
            return false
        }
    }
    
    func deleteQuery(_ query: SearchQuery) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await supabase
                .from("query")
                .delete()
                .eq("id", value: query.id.uuidString)
                .execute()
            
            await loadUserQueries() // Refresh the list
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error deleting query: \(error)")
            isLoading = false
            return false
        }
    }
}

// Database row structure matching Supabase schema
private struct QueryRow: Codable {
    let id: String
    let user_id: String
    let name: String
    let location_id: String
    let location_name: String
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
