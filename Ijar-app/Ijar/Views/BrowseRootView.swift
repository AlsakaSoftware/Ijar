import SwiftUI

struct BrowseRootView: View {
    @StateObject private var coordinator = BrowseCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            BrowseView()
                .environmentObject(coordinator)
                .navigationDestination(for: BrowseDestination.self) { destination in
                    coordinator.build(destination)
                }
        }
    }
}
