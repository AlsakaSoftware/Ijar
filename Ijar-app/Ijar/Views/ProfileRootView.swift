import SwiftUI

struct ProfileRootView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $appCoordinator.profilePath) {
            ProfileView()
                .navigationDestination(for: ProfileDestination.self) { destination in
                    buildDestination(destination)
                }
        }
    }

    @ViewBuilder
    private func buildDestination(_ destination: ProfileDestination) -> some View {
        switch destination {
        case .editProfile:
            EditProfileView()
        case .preferences:
            PreferencesView()
        case .searchQueries:
            SearchQueriesView()
        case .savedLocations:
            SavedLocationsView()
        }
    }
}