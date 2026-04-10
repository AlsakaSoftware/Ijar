import SwiftUI

class SavedPropertiesCoordinator: ObservableObject, Coordinator {
    @Published var navigationPath = NavigationPath()
    
    func navigate(to destination: SavedPropertiesDestination) {
        navigationPath.append(destination)
    }
    
    @ViewBuilder
    func build(_ destination: SavedPropertiesDestination) -> some View {
        switch destination {
        case .propertyDetail(let property):
            PropertyDetailView(property: property, isSavedProperty: true)
        case .groupProperties(let group):
            GroupPropertiesView(group: group)
        case .allSaved:
            AllSavedPropertiesView()
        }
    }
    
}