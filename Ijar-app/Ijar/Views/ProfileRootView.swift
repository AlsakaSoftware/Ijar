import SwiftUI

struct ProfileRootView: View {
    @StateObject private var coordinator = ProfileCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ProfileView()
                .environmentObject(coordinator)
                .navigationDestination(for: ProfileDestination.self) { destination in
                    coordinator.build(destination)
                }
        }
    }
}