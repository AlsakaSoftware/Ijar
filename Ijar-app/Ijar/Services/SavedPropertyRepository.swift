import Foundation
import Supabase
import SwiftUI

@Observable
final class SavedPropertyRepository {
    static let shared = SavedPropertyRepository()

    private(set) var savedIds: Set<String> = []
    private let supabase: SupabaseClient

    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }

    // MARK: - State Queries

    func isSaved(_ propertyId: String) -> Bool {
        savedIds.contains(propertyId)
    }

    // MARK: - Save Operations

    /// Save a property from live search results (inserts into Supabase first if needed)
    @discardableResult
    func save(_ property: Property) async -> Bool {
        do {
            let user = try await supabase.auth.user()

#if DEBUG
            print("🔥 SavedPropertyRepository: Saving property - ID: \(property.id)")
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
                print("🔥 SavedPropertyRepository: Property already exists with UUID: \(propertyUUID)")
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
                    throw NSError(domain: "SavedPropertyRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert property"])
                }

                propertyUUID = insertedProp.id
#if DEBUG
                print("🔥 SavedPropertyRepository: Inserted new property with UUID: \(propertyUUID)")
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
                    // Already saved, just update cache
#if DEBUG
                    print("🔥 SavedPropertyRepository: Property already saved, updating cache")
#endif
                    savedIds.insert(property.id)
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
                    print("✅ SavedPropertyRepository: Updated action to saved")
#endif
                    savedIds.insert(property.id)
                    return true
                }
            }

            // No existing action, insert new one
            struct UserPropertyAction: Codable {
                let user_id: String
                let property_id: String
                let action: String
            }

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
            print("✅ SavedPropertyRepository: Successfully saved property")
#endif

            savedIds.insert(property.id)
            return true
        } catch {
#if DEBUG
            print("❌ SavedPropertyRepository: Failed to save property: \(error)")
#endif
            return false
        }
    }

    /// Unsave a property
    @discardableResult
    func unsave(_ property: Property) async -> Bool {
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
                print("⚠️ SavedPropertyRepository: Property not found in database")
#endif
                savedIds.remove(property.id)
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
            print("✅ SavedPropertyRepository: Successfully unsaved property")
#endif

            savedIds.remove(property.id)
            return true
        } catch {
#if DEBUG
            print("❌ SavedPropertyRepository: Failed to unsave property: \(error)")
#endif
            return false
        }
    }

    // MARK: - Batch Operations

    /// Load saved IDs for a list of properties (used by BrowseResultsView)
    func loadSavedIds(for properties: [Property]) async {
        do {
            let user = try await supabase.auth.user()

            // Get all rightmove IDs from the properties
            let rightmoveIds = properties.compactMap { Int($0.id) }

#if DEBUG
            print("🔥 SavedPropertyRepository: Checking \(rightmoveIds.count) rightmove IDs")
#endif

            guard !rightmoveIds.isEmpty else {
                savedIds = []
                return
            }

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
            print("🔥 SavedPropertyRepository: Found \(existingProperties.count) existing properties in DB")
#endif

            guard !existingProperties.isEmpty else {
                savedIds = []
                return
            }

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
            print("🔥 SavedPropertyRepository: Found \(savedActions.count) saved actions")
#endif

            // Map back from UUID to rightmove_id
            let savedUUIDs = Set(savedActions.map { $0.property_id })
            let savedRightmoveIds = existingProperties
                .filter { savedUUIDs.contains($0.id) }
                .map { String($0.rightmove_id) }

#if DEBUG
            print("🔥 SavedPropertyRepository: Found \(savedRightmoveIds.count) saved properties out of \(properties.count)")
#endif

            savedIds = Set(savedRightmoveIds)
        } catch {
#if DEBUG
            print("❌ SavedPropertyRepository: Failed to load saved IDs: \(error)")
#endif
            savedIds = []
        }
    }

    /// Load all saved properties (used by AllSavedPropertiesView)
    func loadAllSavedProperties() async throws -> [Property] {
        let user = try await supabase.auth.user()

#if DEBUG
        print("🔥 SavedPropertyRepository: Loading saved properties for user: \(user.id)")
#endif

        // Try using the saved_properties view first
        do {
            let savedPropertyRows: [PropertyRow] = try await supabase
                .from("saved_properties")
                .select()
                .execute()
                .value

            let fetchedProperties = savedPropertyRows.map { row in
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

            // Update cache with all saved property IDs
            savedIds = Set(fetchedProperties.map { $0.id })

#if DEBUG
            print("✅ SavedPropertyRepository: Loaded \(fetchedProperties.count) saved properties from view")
#endif

            return fetchedProperties
        } catch {
#if DEBUG
            print("⚠️ SavedPropertyRepository: View failed, falling back to manual query: \(error)")
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
            print("🔥 SavedPropertyRepository: Found \(propertyIds.count) saved property IDs")
#endif

            if !propertyIds.isEmpty {
                let properties: [PropertyRow] = try await supabase
                    .from("property")
                    .select()
                    .in("id", values: propertyIds)
                    .execute()
                    .value

                var propertyDict: [String: Property] = [:]
                for prop in properties {
                    propertyDict[prop.id] = Property(
                        id: String(prop.rightmove_id),
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

                let fetchedProperties = propertyIds.compactMap { propertyDict[$0] }

                // Update cache
                savedIds = Set(fetchedProperties.map { $0.id })

#if DEBUG
                print("✅ SavedPropertyRepository: Loaded \(fetchedProperties.count) saved properties via manual query")
#endif

                return fetchedProperties
            } else {
                savedIds = []
                return []
            }
        }
    }

    /// Get the count of saved properties
    func getSavedCount() async throws -> Int {
        let user = try await supabase.auth.user()

        struct CountResult: Codable {
            let count: Int
        }

        let result: [CountResult] = try await supabase
            .from("user_property_action")
            .select("count", head: false)
            .eq("user_id", value: user.id.uuidString)
            .eq("action", value: "saved")
            .execute()
            .value

#if DEBUG
        print("🔥 SavedPropertyRepository: Saved properties count: \(result.first?.count ?? 0)")
#endif

        return result.first?.count ?? 0
    }

    /// Check if a specific property is saved (with API fallback if not in cache)
    func checkIfSaved(_ property: Property) async -> Bool {
        // First check cache
        if savedIds.contains(property.id) {
            return true
        }

        // If not in cache, check API
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

            let isSaved = !savedActions.isEmpty
            if isSaved {
                savedIds.insert(property.id)
            }
            return isSaved
        } catch {
            return false
        }
    }
}
