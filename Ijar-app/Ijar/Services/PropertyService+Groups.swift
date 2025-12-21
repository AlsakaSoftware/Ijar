import Foundation
import Supabase

// MARK: - PropertyService Groups Extension

extension PropertyService {

    private var baseURL: String { ConfigManager.shared.liveSearchAPIURL }

    private func getUserId() async -> String? {
        do {
            let user = try await supabase.auth.user()
            return user.id.uuidString
        } catch {
            return nil
        }
    }

    func loadGroups() async -> [PropertyGroup] {
        guard let userId = await getUserId() else { return [] }

        guard let url = URL(string: "\(baseURL)/api/groups?userId=\(userId)") else { return [] }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }

            return try JSONDecoder().decode([PropertyGroup].self, from: data)

        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to load groups: \(error)")
#endif
            return []
        }
    }

    func createGroup(name: String) async -> PropertyGroup? {
        guard let userId = await getUserId() else { return nil }

        guard let url = URL(string: "\(baseURL)/api/groups") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            let body: [String: Any] = [
                "userId": userId,
                "name": name
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                return nil
            }

            struct CreateGroupResponse: Decodable {
                let group: PropertyGroup?
            }

            let result = try JSONDecoder().decode(CreateGroupResponse.self, from: data)
            return result.group

        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to create group: \(error)")
#endif
            return nil
        }
    }

    func deleteGroup(groupId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/groups/\(groupId)") else { return false }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            struct DeleteResponse: Decodable {
                let success: Bool
            }

            let result = try JSONDecoder().decode(DeleteResponse.self, from: data)
            return result.success

        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to delete group: \(error)")
#endif
            return false
        }
    }

    func renameGroup(groupId: String, newName: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/groups/\(groupId)") else { return false }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            let body = ["name": newName]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            struct RenameResponse: Decodable {
                let success: Bool
            }

            let result = try JSONDecoder().decode(RenameResponse.self, from: data)
            return result.success

        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to rename group: \(error)")
#endif
            return false
        }
    }

    func addPropertyToGroup(propertyId: String, groupId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/groups/\(groupId)/properties") else { return false }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            let body = ["propertyId": propertyId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            struct AddResponse: Decodable {
                let success: Bool
            }

            let result = try JSONDecoder().decode(AddResponse.self, from: data)
            return result.success

        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to add property to group: \(error)")
#endif
            return false
        }
    }

    func removePropertyFromGroup(propertyId: String, groupId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/groups/\(groupId)/properties/\(propertyId)") else { return false }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            struct RemoveResponse: Decodable {
                let success: Bool
            }

            let result = try JSONDecoder().decode(RemoveResponse.self, from: data)
            return result.success

        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to remove property from group: \(error)")
#endif
            return false
        }
    }

    func loadPropertiesForGroup(groupId: String) async -> [Property] {
        guard let url = URL(string: "\(baseURL)/api/groups/\(groupId)/properties") else { return [] }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }

            return try JSONDecoder().decode([Property].self, from: data)

        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to load properties for group: \(error)")
#endif
            return []
        }
    }

    func getGroupsForProperty(propertyId: String) async -> [String] {
        guard let userId = await getUserId() else { return [] }

        guard let url = URL(string: "\(baseURL)/api/properties/\(propertyId)/groups?userId=\(userId)") else { return [] }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }

            return try JSONDecoder().decode([String].self, from: data)

        } catch {
            return []
        }
    }
}
