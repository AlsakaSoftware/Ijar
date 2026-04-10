import SwiftUI

struct GroupPropertiesView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    @StateObject private var viewModel = GroupPropertiesViewModel()
    private let propertyGroupService: PropertyGroupService
    private let savedPropertyRepository: SavedPropertyRepository

    let group: PropertyGroup

    init(
        group: PropertyGroup,
        propertyGroupService: PropertyGroupService = PropertyGroupService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) {
        self.group = group
        self.propertyGroupService = propertyGroupService
        self.savedPropertyRepository = savedPropertyRepository
    }

    var body: some View {
        SavedPropertiesListView(
            properties: viewModel.properties,
            isLoading: viewModel.isLoading,
            loadingText: "Loading properties...",
            emptyIcon: "folder",
            emptyTitle: "No properties yet",
            emptyMessage: "Add properties to this group\nfrom the property details page",
            propertyGroupService: propertyGroupService,
            savedPropertyRepository: savedPropertyRepository,
            onPropertyTap: { property in
                coordinator.navigate(to: .propertyDetail(property: property))
            },
            onSaveStateChanged: { property, isSaved in
                if !isSaved {
                    viewModel.removeProperty(property)
                }
            }
        )
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(.rusticOrange)
        .task {
            await viewModel.loadProperties(groupId: group.id, service: propertyGroupService)
        }
    }
}
