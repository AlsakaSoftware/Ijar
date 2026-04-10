import Foundation

@MainActor
class GroupPropertiesViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = true

    func loadProperties(groupId: String, service: PropertyGroupService) async {
        properties = await service.loadPropertiesForGroup(groupId: groupId)
        isLoading = false
    }

    func removeProperty(_ property: Property) {
        properties.removeAll { $0.id == property.id }
    }
}
