import Foundation

// MARK: - PropertyService Groups Extension

extension PropertyService {

    func loadGroups() async -> [PropertyGroup] {
        struct GroupRow: Codable {
            let id: String
            let user_id: String
            let name: String
            let created_at: String
        }

        struct MemberRow: Codable {
            let group_id: String
        }

        do {
            let user = try await supabase.auth.user()

            let groupRows: [GroupRow] = try await supabase
                .from("property_group")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            var loadedGroups = groupRows.map { row in
                PropertyGroup(
                    id: row.id,
                    userId: row.user_id,
                    name: row.name,
                    createdAt: dateFormatter.date(from: row.created_at) ?? Date()
                )
            }

            // Load all property counts in a single query (avoids N+1 problem)
            if !loadedGroups.isEmpty {
                let groupIds = loadedGroups.map { $0.id }
                let allMembers: [MemberRow] = try await supabase
                    .from("property_group_member")
                    .select("group_id")
                    .in("group_id", values: groupIds)
                    .execute()
                    .value

                var countsByGroup: [String: Int] = [:]
                for member in allMembers {
                    countsByGroup[member.group_id, default: 0] += 1
                }

                for i in loadedGroups.indices {
                    loadedGroups[i].propertyCount = countsByGroup[loadedGroups[i].id] ?? 0
                }
            }

            return loadedGroups
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to load groups: \(error)")
#endif
            return []
        }
    }

    func createGroup(name: String) async -> PropertyGroup? {
        struct InsertRow: Codable {
            let user_id: String
            let name: String
        }

        struct ResultRow: Codable {
            let id: String
            let user_id: String
            let name: String
            let created_at: String
        }

        do {
            let user = try await supabase.auth.user()

#if DEBUG
            print("🔥 PropertyService: Creating group: \(name)")
#endif

            let created: [ResultRow] = try await supabase
                .from("property_group")
                .insert(InsertRow(user_id: user.id.uuidString, name: name))
                .select()
                .execute()
                .value

            guard let row = created.first else { return nil }

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let group = PropertyGroup(
                id: row.id,
                userId: row.user_id,
                name: row.name,
                createdAt: dateFormatter.date(from: row.created_at) ?? Date(),
                propertyCount: 0
            )

            groups.insert(group, at: 0)

#if DEBUG
            print("✅ PropertyService: Created group: \(group.name)")
#endif

            return group
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to create group: \(error)")
#endif
            return nil
        }
    }

    func deleteGroup(groupId: String) async -> Bool {
        do {
#if DEBUG
            print("🔥 PropertyService: Deleting group: \(groupId)")
#endif

            try await supabase
                .from("property_group_member")
                .delete()
                .eq("group_id", value: groupId)
                .execute()

            try await supabase
                .from("property_group")
                .delete()
                .eq("id", value: groupId)
                .execute()

            groups.removeAll { $0.id == groupId }

#if DEBUG
            print("✅ PropertyService: Deleted group")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to delete group: \(error)")
#endif
            return false
        }
    }

    func renameGroup(groupId: String, newName: String) async -> Bool {
        do {
#if DEBUG
            print("🔥 PropertyService: Renaming group \(groupId) to: \(newName)")
#endif

            try await supabase
                .from("property_group")
                .update(["name": newName])
                .eq("id", value: groupId)
                .execute()

            if let index = groups.firstIndex(where: { $0.id == groupId }) {
                groups[index] = PropertyGroup(
                    id: groups[index].id,
                    userId: groups[index].userId,
                    name: newName,
                    createdAt: groups[index].createdAt,
                    propertyCount: groups[index].propertyCount
                )
            }

#if DEBUG
            print("✅ PropertyService: Renamed group")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to rename group: \(error)")
#endif
            return false
        }
    }

    func addPropertyToGroup(propertyId: String, groupId: String) async -> Bool {
        struct MemberRow: Codable {
            let group_id: String
            let property_id: String
        }

        do {
            guard let dbPropertyId = await lookupPropertyId(rightmoveId: propertyId) else {
#if DEBUG
                print("❌ PropertyService: Property not found for rightmove_id: \(propertyId)")
#endif
                return false
            }

#if DEBUG
            print("🔥 PropertyService: Adding property \(dbPropertyId) to group \(groupId)")
#endif

            try await supabase
                .from("property_group_member")
                .insert(MemberRow(group_id: groupId, property_id: dbPropertyId))
                .execute()

            if let index = groups.firstIndex(where: { $0.id == groupId }) {
                groups[index].propertyCount = (groups[index].propertyCount ?? 0) + 1
            }

#if DEBUG
            print("✅ PropertyService: Added property to group")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to add property to group: \(error)")
#endif
            return false
        }
    }

    func removePropertyFromGroup(propertyId: String, groupId: String) async -> Bool {
        do {
            guard let dbPropertyId = await lookupPropertyId(rightmoveId: propertyId) else {
                return false
            }

#if DEBUG
            print("🔥 PropertyService: Removing property \(dbPropertyId) from group \(groupId)")
#endif

            try await supabase
                .from("property_group_member")
                .delete()
                .eq("group_id", value: groupId)
                .eq("property_id", value: dbPropertyId)
                .execute()

            if let index = groups.firstIndex(where: { $0.id == groupId }) {
                groups[index].propertyCount = max((groups[index].propertyCount ?? 1) - 1, 0)
            }

#if DEBUG
            print("✅ PropertyService: Removed property from group")
#endif

            return true
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to remove property from group: \(error)")
#endif
            return false
        }
    }

    func loadPropertiesForGroup(groupId: String) async -> [Property] {
        struct MemberRow: Codable {
            let property_id: String
        }

        do {
#if DEBUG
            print("🔥 PropertyService: Loading properties for group: \(groupId)")
#endif

            let members: [MemberRow] = try await supabase
                .from("property_group_member")
                .select("property_id")
                .eq("group_id", value: groupId)
                .execute()
                .value

            let propertyIds = members.map { $0.property_id }
            guard !propertyIds.isEmpty else { return [] }

            let properties: [PropertyRow] = try await supabase
                .from("property")
                .select()
                .in("id", values: propertyIds)
                .execute()
                .value

            let result = properties.map { row in
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

#if DEBUG
            print("✅ PropertyService: Loaded \(result.count) properties for group")
#endif

            return result
        } catch {
#if DEBUG
            print("❌ PropertyService: Failed to load properties for group: \(error)")
#endif
            return []
        }
    }

    func getGroupsForProperty(propertyId: String) async -> [String] {
        struct MemberRow: Codable {
            let group_id: String
        }

        do {
            guard let dbPropertyId = await lookupPropertyId(rightmoveId: propertyId) else {
                return []
            }

            let members: [MemberRow] = try await supabase
                .from("property_group_member")
                .select("group_id")
                .eq("property_id", value: dbPropertyId)
                .execute()
                .value

            return members.map { $0.group_id }
        } catch {
            return []
        }
    }

    // MARK: - Private Helpers

    private func lookupPropertyId(rightmoveId: String) async -> String? {
        struct IdRow: Codable {
            let id: String
        }

        do {
            let existing: [IdRow] = try await supabase
                .from("property")
                .select("id")
                .eq("rightmove_id", value: Int(rightmoveId) ?? 0)
                .execute()
                .value

            return existing.first?.id
        } catch {
            return nil
        }
    }
}
