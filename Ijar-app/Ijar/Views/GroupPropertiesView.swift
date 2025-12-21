import SwiftUI

struct GroupPropertiesView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    private let propertyService: PropertyService
    private let savedPropertyRepository: SavedPropertyRepository
    @State private var properties: [Property] = []
    @State private var isLoading = true

    let group: PropertyGroup

    init(
        group: PropertyGroup,
        propertyService: PropertyService = PropertyService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) {
        self.group = group
        self.propertyService = propertyService
        self.savedPropertyRepository = savedPropertyRepository
    }

    var body: some View {
        SavedPropertiesListView(
            properties: properties,
            isLoading: isLoading,
            loadingText: "Loading properties...",
            emptyIcon: "folder",
            emptyTitle: "No properties yet",
            emptyMessage: "Add properties to this group\nfrom the property details page",
            propertyService: propertyService,
            savedPropertyRepository: savedPropertyRepository,
            onPropertyTap: { property in
                coordinator.navigate(to: .propertyDetail(property: property))
            },
            onSaveStateChanged: { property, isSaved in
                if !isSaved {
                    properties.removeAll { $0.id == property.id }
                }
            }
        )
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(.rusticOrange)
        .task {
            properties = await propertyService.loadPropertiesForGroup(groupId: group.id)
            isLoading = false
        }
    }
}
