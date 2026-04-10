import Foundation

final class PropertyGroupService {
    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    func loadGroups() async -> [PropertyGroup] {
        do {
            return try await networkService.send(
                endpoint: "/api/groups",
                method: .get
            )
        } catch {
#if DEBUG
            print("PropertyGroupService: Failed to load groups: \(error)")
#endif
            return []
        }
    }

    func createGroup(name: String) async -> PropertyGroup? {
        struct CreateBody: Encodable {
            let name: String
        }
        struct CreateResponse: Decodable {
            let group: PropertyGroup?
        }

        do {
            let result: CreateResponse = try await networkService.send(
                endpoint: "/api/groups",
                method: .post,
                body: CreateBody(name: name)
            )
            return result.group
        } catch {
#if DEBUG
            print("PropertyGroupService: Failed to create group: \(error)")
#endif
            return nil
        }
    }

    func deleteGroup(groupId: String) async -> Bool {
        struct DeleteResponse: Decodable {
            let success: Bool
        }

        do {
            let result: DeleteResponse = try await networkService.send(
                endpoint: "/api/groups/\(groupId)",
                method: .delete
            )
            return result.success
        } catch {
#if DEBUG
            print("PropertyGroupService: Failed to delete group: \(error)")
#endif
            return false
        }
    }

    func renameGroup(groupId: String, newName: String) async -> Bool {
        struct RenameBody: Encodable {
            let name: String
        }
        struct RenameResponse: Decodable {
            let success: Bool
        }

        do {
            let result: RenameResponse = try await networkService.send(
                endpoint: "/api/groups/\(groupId)",
                method: .patch,
                body: RenameBody(name: newName)
            )
            return result.success
        } catch {
#if DEBUG
            print("PropertyGroupService: Failed to rename group: \(error)")
#endif
            return false
        }
    }

    func addPropertyToGroup(propertyId: String, groupId: String) async -> Bool {
        struct AddBody: Encodable {
            let propertyId: String
        }
        struct AddResponse: Decodable {
            let success: Bool
        }

        do {
            let result: AddResponse = try await networkService.send(
                endpoint: "/api/groups/\(groupId)/properties",
                method: .post,
                body: AddBody(propertyId: propertyId)
            )
            return result.success
        } catch {
#if DEBUG
            print("PropertyGroupService: Failed to add property to group: \(error)")
#endif
            return false
        }
    }

    func removePropertyFromGroup(propertyId: String, groupId: String) async -> Bool {
        struct RemoveResponse: Decodable {
            let success: Bool
        }

        do {
            let result: RemoveResponse = try await networkService.send(
                endpoint: "/api/groups/\(groupId)/properties/\(propertyId)",
                method: .delete
            )
            return result.success
        } catch {
#if DEBUG
            print("PropertyGroupService: Failed to remove property from group: \(error)")
#endif
            return false
        }
    }

    func loadPropertiesForGroup(groupId: String) async -> [Property] {
        do {
            return try await networkService.send(
                endpoint: "/api/groups/\(groupId)/properties",
                method: .get
            )
        } catch {
#if DEBUG
            print("PropertyGroupService: Failed to load properties for group: \(error)")
#endif
            return []
        }
    }

    func getGroupsForProperty(propertyId: String) async -> [String] {
        do {
            return try await networkService.send(
                endpoint: "/api/properties/\(propertyId)/groups",
                method: .get
            )
        } catch {
            return []
        }
    }
}
