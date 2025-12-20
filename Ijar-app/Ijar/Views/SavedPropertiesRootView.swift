import SwiftUI

struct SavedPropertiesRootView: View {
    @StateObject private var coordinator = SavedPropertiesCoordinator()
    @StateObject private var propertyService = PropertyService()

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            SavedGroupsView()
                .environmentObject(coordinator)
                .environmentObject(propertyService)
                .navigationDestination(for: SavedPropertiesDestination.self) { destination in
                    coordinator.build(destination)
                        .environmentObject(coordinator)
                        .environmentObject(propertyService)
                }
        }
    }
}