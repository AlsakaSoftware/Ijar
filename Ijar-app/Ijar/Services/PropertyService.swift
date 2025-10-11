import Foundation
import Supabase

@MainActor
class PropertyService: ObservableObject {
    private let supabase: SupabaseClient
    @Published var properties: [Property] = []
    @Published var savedProperties: [Property] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }
    
    func loadPropertiesForUser() async {
#if DEBUG
        print("🔥 PropertyService: loadPropertiesForUser called")
#endif
        isLoading = true
        error = nil
        
        do {
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
            
            properties = response.map { row in
                Property(
                    id: row.id,
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
            print("✅ PropertyService: Loaded \(properties.count) properties from Supabase")
            print("🔥 PropertyService: Final property IDs: \(properties.map { $0.id })")
#endif
            
        } catch {
            self.error = "Unable to load properties. Please check your connection and try again."
#if DEBUG
            print("❌ PropertyService: Error loading properties: \(error)")
            print("❌ PropertyService: Error details: \(error.localizedDescription)")
#endif

            properties = []
        }
        
        isLoading = false
#if DEBUG
        print("🔥 PropertyService: loadPropertiesForUser completed")
#endif
    }

    @discardableResult
    func trackPropertyAction(propertyId: String, action: PropertyAction) async -> Bool {
        do {
            let user = try await supabase.auth.user()
            
            let actionData = UserPropertyAction(
                user_id: user.id.uuidString,
                property_id: propertyId,
                action: action.rawValue
            )
            
#if DEBUG
            print("🔥 PropertyService: Tracking action - User: \(user.id.uuidString), Property: \(propertyId), Action: \(action.rawValue)")
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
    
    func removeTopProperty() {
        if !properties.isEmpty {
            properties.removeFirst()
        }
    }
    
    func loadSavedProperties() async {
        isLoading = true
        error = nil
        
        do {
            let user = try await supabase.auth.user()
            
#if DEBUG
            print("🔥 PropertyService: Loading saved properties for user: \(user.id)")
#endif
            
            // Try using the saved_properties view first
            do {
                let savedPropertyRows: [PropertyRow] = try await supabase
                    .from("saved_properties")
                    .select()
                    .execute()
                    .value
                
                savedProperties = savedPropertyRows.map { row in
                    Property(
                        id: row.id,
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
                print("✅ PropertyService: Loaded \(savedProperties.count) saved properties from view")
#endif
            } catch {
#if DEBUG
                print("⚠️ PropertyService: View failed, falling back to manual query: \(error)")
#endif
                // Fallback to manual query if view doesn't work
                struct SavedAction: Codable {
                    let property_id: String
                    let created: String
                }

                let savedActions: [SavedAction] = try await supabase
                    .from("user_property_action")
                    .select("property_id, created")
                    .eq("user_id", value: user.id.uuidString)
                    .eq("action", value: "saved")
                    .order("created", ascending: false)
                    .execute()
                    .value

                let propertyIds = savedActions.map { $0.property_id }

#if DEBUG
                print("🔥 PropertyService: Found \(propertyIds.count) saved property IDs: \(propertyIds)")
#endif

                if !propertyIds.isEmpty {
                    // Use PropertyRow to ensure consistency with property_feed
                    let properties: [PropertyRow] = try await supabase
                        .from("property")
                        .select()
                        .in("id", values: propertyIds)
                        .execute()
                        .value

                    var propertyDict: [String: Property] = [:]
                    for prop in properties {
                        propertyDict[prop.id] = Property(
                            id: prop.id,
                            images: prop.images,
                            price: prop.price,
                            bedrooms: prop.bedrooms,
                            bathrooms: prop.bathrooms,
                            address: prop.address,
                            area: prop.area ?? "",
                            rightmoveUrl: prop.rightmove_url,
                            agentPhone: prop.agent_phone,
                            agentName: prop.agent_name,
                            branchName: prop.branch_name,
                            latitude: prop.latitude,
                            longitude: prop.longitude
                        )
                    }

                    savedProperties = propertyIds.compactMap { propertyDict[$0] }

#if DEBUG
                    print("✅ PropertyService: Loaded \(savedProperties.count) saved properties via manual query")
#endif
                } else {
                    savedProperties = []
                }
            }
            
        } catch {
            self.error = "Unable to load saved properties."
            savedProperties = []
#if DEBUG
            print("❌ PropertyService: Error loading saved properties: \(error)")
#endif
        }
        
        isLoading = false
    }
}

enum PropertyAction: String {
    case saved = "saved"
    case passed = "passed"
}

private struct PropertyRow: Codable {
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
