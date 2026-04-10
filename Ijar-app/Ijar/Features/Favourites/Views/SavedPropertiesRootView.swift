import SwiftUI

struct SavedPropertiesRootView: View {
    @StateObject private var coordinator = SavedPropertiesCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            SavedGroupsView()
                .environmentObject(coordinator)
                .navigationDestination(for: SavedPropertiesDestination.self) { destination in
                    coordinator.build(destination)
                        .environmentObject(coordinator)
                }
        }
    }
}
