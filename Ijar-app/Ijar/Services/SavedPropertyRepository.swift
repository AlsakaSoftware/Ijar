import Foundation
import Supabase
import SwiftUI

@MainActor
@Observable
final class SavedPropertyRepository {
    static let shared = SavedPropertyRepository()

    private(set) var savedIds: Set<String> = []
    private let supabase: SupabaseClient
    private var baseURL: String { ConfigManager.shared.liveSearchAPIURL }

    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }

    // MARK: - Auth Helper

    private func getUserId() async -> String? {
        do {
            let user = try await supabase.auth.user()
            return user.id.uuidString
        } catch {
#if DEBUG
            print("❌ SavedPropertyRepository: Failed to get user: \(error)")
#endif
            return nil
        }
    }

    // MARK: - State Queries

    func isSaved(_ propertyId: String) -> Bool {
        savedIds.contains(propertyId)
    }

    var savedCount: Int {
        savedIds.count
    }

    // MARK: - Save Operations

    /// Save a property
    @discardableResult
    func save(_ property: Property) async -> Bool {
        guard let userId = await getUserId() else { return false }

#if DEBUG
        print("🔥 SavedPropertyRepository: Saving property - ID: \(property.id)")
#endif

        guard let url = URL(string: "\(baseURL)/api/properties/save") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Use snake_case keys to match backend
        let body: [String: Any] = [
            "userId": userId,
            "property": [
                "id": property.id,
                "images": property.images,
                "price": property.price,
                "bedrooms": property.bedrooms,
                "bathrooms": property.bathrooms,
                "address": property.address,
                "area": property.area,
                "rightmove_url": property.rightmoveUrl as Any,
                "agent_phone": property.agentPhone as Any,
                "agent_name": property.agentName as Any,
                "branch_name": property.branchName as Any,
                "latitude": property.latitude as Any,
                "longitude": property.longitude as Any
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
#if DEBUG
                print("❌ SavedPropertyRepository: Save failed with status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
#endif
                return false
            }

            struct SaveResponse: Decodable {
                let success: Bool
            }

            let result = try JSONDecoder().decode(SaveResponse.self, from: data)
            if result.success {
                savedIds.insert(property.id)
#if DEBUG
                print("✅ SavedPropertyRepository: Successfully saved property")
#endif
            }
            return result.success

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
        guard let userId = await getUserId() else { return false }

#if DEBUG
        print("🔥 SavedPropertyRepository: Unsaving property - ID: \(property.id)")
#endif

        guard let url = URL(string: "\(baseURL)/api/properties/unsave") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "userId": userId,
            "propertyId": property.id
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            struct UnsaveResponse: Decodable {
                let success: Bool
            }

            let result = try JSONDecoder().decode(UnsaveResponse.self, from: data)
            if result.success {
                savedIds.remove(property.id)
#if DEBUG
                print("✅ SavedPropertyRepository: Successfully unsaved property")
#endif
            }
            return result.success

        } catch {
#if DEBUG
            print("❌ SavedPropertyRepository: Failed to unsave property: \(error)")
#endif
            return false
        }
    }

    // MARK: - Load Operations

    /// Load all saved properties (populates savedIds cache)
    func loadAllSavedProperties() async throws -> [Property] {
        guard let userId = await getUserId() else {
            throw NSError(domain: "SavedPropertyRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

#if DEBUG
        print("🔥 SavedPropertyRepository: Loading saved properties")
#endif

        guard let url = URL(string: "\(baseURL)/api/properties/saved?userId=\(userId)") else {
            throw NSError(domain: "SavedPropertyRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SavedPropertyRepository", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }

        let properties = try JSONDecoder().decode([Property].self, from: data)

        // Update cache
        savedIds = Set(properties.map { $0.id })

#if DEBUG
        print("✅ SavedPropertyRepository: Loaded \(properties.count) saved properties")
#endif

        return properties
    }

    /// Refresh saved IDs cache by loading all saved properties
    func refreshSavedIds() async {
        do {
            _ = try await loadAllSavedProperties()
        } catch {
#if DEBUG
            print("❌ SavedPropertyRepository: Failed to refresh saved IDs: \(error)")
#endif
        }
    }
}
