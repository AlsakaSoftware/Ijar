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
                            id: String(prop.rightmove_id),  // Use Rightmove ID for consistent PropertyMetadata lookup
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

    /// Save a property from live search results (inserts into Supabase first if needed)
    func saveLiveSearchProperty(_ property: Property) async -> Bool {
        do {
            let user = try await supabase.auth.user()

#if DEBUG
            print("🔥 PropertyService: Saving live search property - ID: \(property.id)")
#endif

            // First, check if property already exists by rightmove_id
            let rightmoveId = Int(property.id) ?? 0

            struct ExistingProperty: Codable {
                let id: String
            }

            let existing: [ExistingProperty] = try await supabase
                .from("property")
                .select("id")
                .eq("rightmove_id", value: rightmoveId)
                .execute()
                .value

            let propertyUUID: String

            if let existingProp = existing.first {
                // Property already exists, use existing UUID
                propertyUUID = existingProp.id
#if DEBUG
                print("🔥 PropertyService: Property already exists with UUID: \(propertyUUID)")
#endif
            } else {
                // Insert new property
                struct NewProperty: Codable {
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
                }

                struct InsertedProperty: Codable {
                    let id: String
                }

                let newProp = NewProperty(
                    rightmove_id: rightmoveId,
                    images: property.images,
                    price: property.price,
                    bedrooms: property.bedrooms,
                    bathrooms: property.bathrooms,
                    address: property.address,
                    area: property.area.isEmpty ? nil : property.area,
                    rightmove_url: property.rightmoveUrl,
                    agent_phone: property.agentPhone,
                    agent_name: property.agentName,
                    branch_name: property.branchName,
                    latitude: property.latitude,
                    longitude: property.longitude
                )

                let inserted: [InsertedProperty] = try await supabase
                    .from("property")
                    .insert(newProp)
                    .select("id")
                    .execute()
                    .value

                guard let insertedProp = inserted.first else {
                    throw NSError(domain: "PropertyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert property"])
                }

                propertyUUID = insertedProp.id
#if DEBUG
                print("🔥 PropertyService: Inserted new property with UUID: \(propertyUUID)")
#endif
            }

            // Check if there's already a saved action for this property
            struct ExistingAction: Codable {
                let action: String
            }

            let existingActions: [ExistingAction] = try await supabase
                .from("user_property_action")
                .select("action")
                .eq("user_id", value: user.id.uuidString)
                .eq("property_id", value: propertyUUID)
                .execute()
                .value

            if let existingAction = existingActions.first {
                if existingAction.action == "saved" {
                    // Already saved, nothing to do
#if DEBUG
                    print("🔥 PropertyService: Property already saved, skipping")
#endif
                    return true
                } else {
                    // Update from "passed" to "saved"
                    try await supabase
                        .from("user_property_action")
                        .update(["action": "saved"])
                        .eq("user_id", value: user.id.uuidString)
                        .eq("property_id", value: propertyUUID)
                        .execute()
#if DEBUG
                    print("✅ PropertyService: Updated action to saved")
#endif
                    return true
                }
            }

            // No existing action, insert new one
            let actionData = UserPropertyAction(
                user_id: user.id.uuidString,
                property_id: propertyUUID,
                action: "saved"
            )

            try await supabase
                .from("user_property_action")
                .insert(actionData)
                .execute()

#if DEBUG
            print("✅ PropertyService: Successfully saved live search property")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to save live search property: \(error)")
#endif
            return false
        }
    }

    /// Unsave a property from live search results
    func unsaveLiveSearchProperty(_ property: Property) async -> Bool {
        do {
            let user = try await supabase.auth.user()

            // Find the property UUID by rightmove_id
            let rightmoveId = Int(property.id) ?? 0

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
                print("⚠️ PropertyService: Property not found in database")
#endif
                return false
            }

            // Update the action to passed
            try await supabase
                .from("user_property_action")
                .update(["action": "passed"])
                .eq("user_id", value: user.id.uuidString)
                .eq("property_id", value: existingProp.id)
                .execute()

#if DEBUG
            print("✅ PropertyService: Successfully unsaved live search property")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to unsave live search property: \(error)")
#endif
            return false
        }
    }

    /// Check which live search properties are saved (batch operation)
    func getSavedPropertyIds(from properties: [Property]) async -> Set<String> {
        do {
            let user = try await supabase.auth.user()

            // Get all rightmove IDs from the properties
            let rightmoveIds = properties.compactMap { Int($0.id) }

#if DEBUG
            print("🔥 getSavedPropertyIds: Checking \(rightmoveIds.count) rightmove IDs")
#endif

            guard !rightmoveIds.isEmpty else { return [] }

            struct PropertyWithRightmoveId: Codable {
                let id: String
                let rightmove_id: Int
            }

            // Find all properties that exist in our database
            let existingProperties: [PropertyWithRightmoveId] = try await supabase
                .from("property")
                .select("id, rightmove_id")
                .in("rightmove_id", values: rightmoveIds)
                .execute()
                .value

#if DEBUG
            print("🔥 getSavedPropertyIds: Found \(existingProperties.count) existing properties in DB")
            for prop in existingProperties {
                print("   - rightmove_id: \(prop.rightmove_id) -> UUID: \(prop.id)")
            }
#endif

            guard !existingProperties.isEmpty else { return [] }

            // Get the UUIDs of existing properties
            let propertyUUIDs = existingProperties.map { $0.id }

            struct SavedAction: Codable {
                let property_id: String
            }

            // Check which ones are saved by this user
            let savedActions: [SavedAction] = try await supabase
                .from("user_property_action")
                .select("property_id")
                .eq("user_id", value: user.id.uuidString)
                .eq("action", value: "saved")
                .in("property_id", values: propertyUUIDs)
                .execute()
                .value

#if DEBUG
            print("🔥 getSavedPropertyIds: Found \(savedActions.count) saved actions")
            for action in savedActions {
                print("   - saved property_id: \(action.property_id)")
            }
#endif

            // Map back from UUID to rightmove_id
            let savedUUIDs = Set(savedActions.map { $0.property_id })
            let savedRightmoveIds = existingProperties
                .filter { savedUUIDs.contains($0.id) }
                .map { String($0.rightmove_id) }

#if DEBUG
            print("🔥 PropertyService: Found \(savedRightmoveIds.count) saved properties out of \(properties.count)")
            print("   Saved rightmove IDs: \(savedRightmoveIds)")
#endif

            return Set(savedRightmoveIds)
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to check saved properties: \(error)")
#endif
            return []
        }
    }

    /// Check if a live search property is saved
    func isLiveSearchPropertySaved(_ property: Property) async -> Bool {
        do {
            let user = try await supabase.auth.user()
            let rightmoveId = Int(property.id) ?? 0

            struct ExistingProperty: Codable {
                let id: String
            }

            // First find the property by rightmove_id
            let existing: [ExistingProperty] = try await supabase
                .from("property")
                .select("id")
                .eq("rightmove_id", value: rightmoveId)
                .execute()
                .value

            guard let existingProp = existing.first else {
                return false
            }

            // Check if there's a saved action for this property
            struct SavedAction: Codable {
                let id: Int
            }

            let savedActions: [SavedAction] = try await supabase
                .from("user_property_action")
                .select("id")
                .eq("user_id", value: user.id.uuidString)
                .eq("property_id", value: existingProp.id)
                .eq("action", value: "saved")
                .execute()
                .value

            return !savedActions.isEmpty
        } catch {
            return false
        }
    }

    func unsaveProperty(_ property: Property) async -> Bool {
        do {
            let user = try await supabase.auth.user()

            // property.id is now Rightmove ID, need to look up database UUID
            let rightmoveId = Int(property.id) ?? 0

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

            // Update the existing saved action to passed using database UUID
            try await supabase
                .from("user_property_action")
                .update(["action": "passed"])
                .eq("user_id", value: user.id.uuidString)
                .eq("property_id", value: existingProp.id)
                .execute()

            // Remove from local array immediately for UI responsiveness
            savedProperties.removeAll { $0.id == property.id }

#if DEBUG
            print("✅ PropertyService: Successfully unsaved property \(property.id)")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to unsave property: \(error)")
#endif
            return false
        }
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
