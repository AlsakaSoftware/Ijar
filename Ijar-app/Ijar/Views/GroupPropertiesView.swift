import SwiftUI

struct GroupPropertiesView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    @EnvironmentObject var propertyService: PropertyService
    @State private var properties: [Property] = []
    @State private var isLoading = true
    @State private var selectedProperty: Property?

    let group: PropertyGroup

    var body: some View {
        SavedPropertiesListView(
            properties: properties,
            isLoading: isLoading,
            loadingText: "Loading properties...",
            emptyIcon: "folder",
            emptyTitle: "No properties yet",
            emptyMessage: "Add properties to this group\nfrom the property details page",
            onPropertyTap: { property in
                coordinator.navigate(to: .propertyDetail(property: property))
            },
            onSaveToggle: { property in
                selectedProperty = property
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
        .groupPicker(
            propertyService: propertyService,
            selectedProperty: $selectedProperty,
            onUnsave: {
                if let unsavedProperty = selectedProperty {
                    properties.removeAll { $0.id == unsavedProperty.id }
                }
            },
            onDismiss: {
                Task {
                    properties = await propertyService.loadPropertiesForGroup(groupId: group.id)
                }
            }
        )
    }
}
