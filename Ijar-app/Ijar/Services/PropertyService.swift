import Foundation
import Supabase

final class PropertyService {
    let supabase: SupabaseClient

    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }

    func fetchPropertiesForUser() async throws -> [Property] {
#if DEBUG
        print("🔥 PropertyService: fetchPropertiesForUser called")
#endif

#if DEBUG
        print("🔥 PropertyService: Getting user for property load...")
#endif
        // Get current user
        let _ = try await supabase.auth.user()

#if DEBUG
        print("🔥 PropertyService: Querying property_feed...")
#endif
        // Load properties from the property_feed view which shows new recommendations
        let response: [PropertyRow] = try await supabase
            .from("property_feed")
            .select()
            .execute()
            .value

#if DEBUG
        print("🔥 PropertyService: Got \(response.count) properties from Supabase")
        print("🔥 PropertyService: Property IDs from DB: \(response.map { $0.id })")
#endif

        let fetchedProperties = response.map { row in
            Property(
                id: String(row.rightmove_id),  // Use Rightmove ID for consistent PropertyMetadata lookup
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

#if DEBUG
        print("✅ PropertyService: Loaded \(fetchedProperties.count) properties from Supabase")
        print("🔥 PropertyService: Final property IDs: \(fetchedProperties.map { $0.id })")
#endif

        return fetchedProperties
    }

    @discardableResult
    func trackPropertyAction(propertyId: String, action: PropertyAction) async -> Bool {
        do {
            let user = try await supabase.auth.user()

            // propertyId is now Rightmove ID, need to look up database UUID
            let rightmoveId = Int(propertyId) ?? 0

            struct ExistingProperty: Codable {
                let id: String
            }

            let existing: [ExistingProperty] = try await supabase
                .from("property")
                .select("id")
                .eq("rightmove_id", value: rightmoveId)
                .execute()
                .value

            guard let existingProp = existing.first else {
#if DEBUG
                print("❌ PropertyService: Property not found for rightmove_id: \(rightmoveId)")
#endif
                return false
            }

            let actionData = UserPropertyAction(
                user_id: user.id.uuidString,
                property_id: existingProp.id,  // Use database UUID
                action: action.rawValue
            )

#if DEBUG
            print("🔥 PropertyService: Tracking action - User: \(user.id.uuidString), Property UUID: \(existingProp.id), Rightmove ID: \(propertyId), Action: \(action.rawValue)")
#endif

            try await supabase
                .from("user_property_action")
                .insert(actionData)
                .execute()

#if DEBUG
            print("✅ PropertyService: Successfully tracked \(action.rawValue) action for property \(propertyId)")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to track action: \(error)")
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
    let found_at: String?  // Optional: only in property_feed view
    let found_by_query: String?  // Optional: only in property_feed view
}

private struct UserPropertyAction: Codable {
    let user_id: String
    let property_id: String
    let action: String
}
