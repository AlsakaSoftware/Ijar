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
        print("🔥 PropertyService: loadPropertiesForUser called")
        isLoading = true
        error = nil
        
        do {
            print("🔥 PropertyService: Getting user for property load...")
            // Get current user
            let _ = try await supabase.auth.user()
            
            print("🔥 PropertyService: Querying property_feed...")
            // Load properties from the property_feed view which shows new recommendations
            let response: [PropertyRow] = try await supabase
                .from("property_feed")
                .select()
                .execute()
                .value
            
            print("🔥 PropertyService: Got \(response.count) properties from Supabase")
            print("🔥 PropertyService: Property IDs from DB: \(response.map { $0.id })")
            
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
            
            print("✅ PropertyService: Loaded \(properties.count) properties from Supabase")
            print("🔥 PropertyService: Final property IDs: \(properties.map { $0.id })")
            
        } catch {
            self.error = error.localizedDescription
            print("❌ PropertyService: Error loading properties: \(error)")
            print("❌ PropertyService: Error details: \(error.localizedDescription)")
            
            // Fallback to mock data if there's an error
            loadMockProperties()
        }
        
        isLoading = false
        print("🔥 PropertyService: loadPropertiesForUser completed")
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
    
    // Track user action on property and remove it from the list
    func trackPropertyAction(propertyId: String, action: PropertyAction) async -> Bool {
        print("🔥 PropertyService: trackPropertyAction called for \(propertyId) with action \(action.rawValue)")
        print("🔥 PropertyService: Current properties count: \(properties.count)")
        print("🔥 PropertyService: Property IDs: \(properties.map { $0.id })")
        
        // Remove property from local list immediately for UI responsiveness - ON MAIN THREAD
        await MainActor.run {
            let removedProperty = properties.first { $0.id == propertyId }
            let beforeCount = properties.count
            properties.removeAll { $0.id == propertyId }
            let afterCount = properties.count
            
            print("🔥 PropertyService: Removed property \(propertyId) from local list ON MAIN THREAD")
            print("🔥 PropertyService: Properties count: \(beforeCount) -> \(afterCount)")
            print("🔥 PropertyService: Remaining property IDs: \(properties.map { $0.id })")
            
            if removedProperty == nil {
                print("⚠️ PropertyService: WARNING - Property \(propertyId) was not found in local list!")
            }
        }
        
        do {
            print("🔥 PropertyService: Getting user...")
            let user = try await supabase.auth.user()
            print("🔥 PropertyService: User ID: \(user.id.uuidString)")
            
            let actionData = UserPropertyAction(
                user_id: user.id.uuidString,
                property_id: propertyId,
                action: action.rawValue
            )
            
            print("🔥 PropertyService: Inserting action data to Supabase...")
            try await supabase
                .from("user_property_action")
                .insert(actionData)
                .execute()
            
            print("✅ PropertyService: Successfully tracked \(action.rawValue) action for property \(propertyId)")
            return true
        } catch {
            print("❌ PropertyService: Error tracking property action: \(error)")
            print("❌ PropertyService: Error details: \(error.localizedDescription)")
            if let supabaseError = error as? Error {
                print("❌ PropertyService: Supabase error: \(supabaseError)")
            }
            // If API call fails, we could optionally re-add the property back
            // but for now we'll keep it removed to prevent it from returning
            return false
        }
    }
    
    // Remove the top property without tracking (for UI animations)
    func removeTopProperty() {
        if !properties.isEmpty {
            properties.removeFirst()
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
