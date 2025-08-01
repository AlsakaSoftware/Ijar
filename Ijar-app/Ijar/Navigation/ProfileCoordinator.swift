import SwiftUI

class ProfileCoordinator: ObservableObject, Coordinator {
    @Published var navigationPath = NavigationPath()
    
    func navigate(to destination: ProfileDestination) {
        navigationPath.append(destination)
    }
    
    @ViewBuilder
    func build(_ destination: ProfileDestination) -> some View {
        switch destination {
        case .editProfile:
            EditProfileView()
                .environmentObject(self)
        case .preferences:
            PreferencesView()
                .environmentObject(self)
        case .searchQueries:
            SearchQueriesView()
                .environmentObject(self)
        }
    }
    
}