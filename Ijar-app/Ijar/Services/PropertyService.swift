import Foundation
import Supabase

@MainActor
class PropertyService: ObservableObject {
    private let supabase: SupabaseClient
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }
    
    func loadPropertiesForUser() async {
        isLoading = true
        error = nil
        
        do {
            // Get current user
            let _ = try await supabase.auth.user()
            
            // Load properties from the property_feed view which shows new recommendations
            let response: [PropertyRow] = try await supabase
                .from("property_feed")
                .select()
                .execute()
                .value
            
            properties = response.map { row in
                Property(
                    id: row.id,
                    images: row.images,
                    price: row.price,
                    bedrooms: row.bedrooms,
                    bathrooms: row.bathrooms,
                    address: row.address,
                    area: row.area ?? ""
                )
            }
            
            print("✅ Loaded \(properties.count) properties from Supabase")
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Error loading properties: \(error)")
            
            // Fallback to mock data if there's an error
            loadMockProperties()
        }
        
        isLoading = false
    }
    
    private func loadMockProperties() {
        properties = [
            Property(
                images: [
                    "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&q=80",
                    "https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800&q=80"
                ],
                price: "£2,500/month",
                bedrooms: 2,
                bathrooms: 1,
                address: "123 Sample Street",
                area: "London E14"
            )
        ]
        print("📝 Using mock data")
    }
    
    // Track user action on property
    func trackPropertyAction(propertyId: String, action: PropertyAction) async -> Bool {
        do {
            let user = try await supabase.auth.user()
            
            let actionData = UserPropertyAction(
                user_id: user.id.uuidString,
                property_id: propertyId,
                action: action.rawValue
            )
            
            try await supabase
                .from("user_property_action")
                .insert(actionData)
                .execute()
            
            // Remove property from local list
            properties.removeAll { $0.id == propertyId }
            
            print("✅ Tracked \(action.rawValue) action for property")
            return true
        } catch {
            print("❌ Error tracking property action: \(error)")
            return false
        }
    }
}

enum PropertyAction: String {
    case saved = "saved"
    case passed = "passed"
}

// Database row structure matching Supabase property_feed view
private struct PropertyRow: Codable {
    let id: String
    let rightmove_id: Int
    let images: [String]
    let price: String
    let bedrooms: Int
    let bathrooms: Int
    let address: String
    let area: String?
    let found_at: String
    let found_by_query: String
}

// Structure for inserting user property actions
private struct UserPropertyAction: Codable {
    let user_id: String
    let property_id: String
    let action: String
}
