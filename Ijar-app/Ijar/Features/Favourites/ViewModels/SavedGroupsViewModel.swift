import Foundation

@MainActor
class SavedGroupsViewModel: ObservableObject {
    @Published var groups: [PropertyGroup] = []
    @Published var savedPropertiesCount = 0
    @Published var isLoading = true
    @Published var animateContent = false
    @Published var showCreateGroupSheet = false
    @Published var newGroupName = ""

    private let propertyGroupService: PropertyGroupService
    private let savedPropertyRepository: SavedPropertyRepository

    init(
        propertyGroupService: PropertyGroupService = PropertyGroupService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) {
        self.propertyGroupService = propertyGroupService
        self.savedPropertyRepository = savedPropertyRepository
    }

    func loadData() async {
        async let refreshTask: () = savedPropertyRepository.refreshSavedIds()
        async let groupsTask = propertyGroupService.loadGroups()
        await refreshTask
        groups = await groupsTask
        savedPropertiesCount = savedPropertyRepository.savedCount
        isLoading = false
    }

    func refreshData() async {
        async let refreshTask: () = savedPropertyRepository.refreshSavedIds()
        async let groupsTask = propertyGroupService.loadGroups()
        await refreshTask
        groups = await groupsTask
        savedPropertiesCount = savedPropertyRepository.savedCount
    }

    func createGroup() async {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let newGroup = await propertyGroupService.createGroup(name: name) {
            groups.insert(newGroup, at: 0)
        }
        newGroupName = ""
        showCreateGroupSheet = false
    }

    func deleteGroup(_ group: PropertyGroup) async {
        _ = await propertyGroupService.deleteGroup(groupId: group.id)
        groups = await propertyGroupService.loadGroups()
    }
}
