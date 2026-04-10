import Foundation
import SwiftUI

// MARK: - Request/Response Types

private struct SaveRequest: Encodable {
    let property: PropertyPayload

    struct PropertyPayload: Encodable {
        let id: String
        let images: [String]
        let price: String
        let bedrooms: Int
        let bathrooms: Int
        let address: String
        let area: String
        let rightmove_url: String?
        let agent_phone: String?
        let agent_name: String?
        let branch_name: String?
        let latitude: Double?
        let longitude: Double?
    }
}

private struct UnsaveRequest: Encodable {
    let propertyId: String
}

private struct SuccessResponse: Decodable {
    let success: Bool
}

// MARK: - Repository

@MainActor
@Observable
final class SavedPropertyRepository {
    static let shared = SavedPropertyRepository()

    private(set) var savedIds: Set<String> = []
    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    // MARK: - State Queries

    func isSaved(_ propertyId: String) -> Bool {
        savedIds.contains(propertyId)
    }

    var savedCount: Int {
        savedIds.count
    }

    // MARK: - Save Operations

    @discardableResult
    func save(_ property: Property) async -> Bool {
#if DEBUG
        print("SavedPropertyRepository: Saving property - ID: \(property.id)")
#endif

        let request = SaveRequest(
            property: SaveRequest.PropertyPayload(
                id: property.id,
                images: property.images,
                price: property.price,
                bedrooms: property.bedrooms,
                bathrooms: property.bathrooms,
                address: property.address,
                area: property.area,
                rightmove_url: property.rightmoveUrl,
                agent_phone: property.agentPhone,
                agent_name: property.agentName,
                branch_name: property.branchName,
                latitude: property.latitude,
                longitude: property.longitude
            )
        )

        do {
            let result: SuccessResponse = try await networkService.send(
                endpoint: "/api/properties/save",
                method: .post,
                body: request
            )

            if result.success {
                savedIds.insert(property.id)
            }
            return result.success

        } catch {
#if DEBUG
            print("SavedPropertyRepository: Failed to save property: \(error)")
#endif
            return false
        }
    }

    @discardableResult
    func unsave(_ property: Property) async -> Bool {
#if DEBUG
        print("SavedPropertyRepository: Unsaving property - ID: \(property.id)")
#endif

        let request = UnsaveRequest(propertyId: property.id)

        do {
            let result: SuccessResponse = try await networkService.send(
                endpoint: "/api/properties/unsave",
                method: .post,
                body: request
            )

            if result.success {
                savedIds.remove(property.id)
            }
            return result.success

        } catch let error as NetworkError {
            if error.isNotFound {
                savedIds.remove(property.id)
                return true
            }
#if DEBUG
            print("SavedPropertyRepository: Failed to unsave property: \(error)")
#endif
            return false

        } catch {
#if DEBUG
            print("SavedPropertyRepository: Failed to unsave property: \(error)")
#endif
            return false
        }
    }

    // MARK: - Load Operations

    func loadAllSavedProperties() async throws -> [Property] {
#if DEBUG
        print("SavedPropertyRepository: Loading saved properties")
#endif

        let properties: [Property] = try await networkService.send(
            endpoint: "/api/properties/saved",
            method: .get
        )

        savedIds = Set(properties.map { $0.id })

#if DEBUG
        print("SavedPropertyRepository: Loaded \(properties.count) saved properties")
#endif

        return properties
    }

    func refreshSavedIds() async {
        do {
            _ = try await loadAllSavedProperties()
        } catch {
#if DEBUG
            print("SavedPropertyRepository: Failed to refresh saved IDs: \(error)")
#endif
        }
    }
}
