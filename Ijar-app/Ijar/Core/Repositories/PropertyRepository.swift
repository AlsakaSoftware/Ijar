import Foundation
import Supabase

final class PropertyRepository {
    private let supabase: SupabaseClient

    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }

    func fetchPropertiesForUser() async throws -> [Property] {
#if DEBUG
        print("PropertyRepository: Querying property_feed...")
#endif
        let _ = try await supabase.auth.user()

        let response: [PropertyRow] = try await supabase
            .from("property_feed")
            .select()
            .execute()
            .value

#if DEBUG
        print("PropertyRepository: Got \(response.count) properties from Supabase")
#endif

        return response.map { row in
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
            let user = try await supabase.auth.user()
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
                print("PropertyRepository: Property not found for rightmove_id: \(rightmoveId)")
#endif
                return false
            }

            let actionData = UserPropertyAction(
                user_id: user.id.uuidString,
                property_id: existingProp.id,
                action: action.rawValue
            )

            try await supabase
                .from("user_property_action")
                .insert(actionData)
                .execute()

#if DEBUG
            print("PropertyRepository: Tracked \(action.rawValue) for property \(propertyId)")
#endif
            return true
        } catch {
#if DEBUG
            print("PropertyRepository: Failed to track action: \(error)")
#endif
            return false
        }
    }

    func getCurrentUserId() async throws -> String {
        let user = try await supabase.auth.user()
        return user.id.uuidString
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

private struct UserPropertyAction: Codable {
    let user_id: String
    let property_id: String
    let action: String
}
