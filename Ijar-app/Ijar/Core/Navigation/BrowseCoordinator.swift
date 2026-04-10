import SwiftUI

class BrowseCoordinator: ObservableObject, Coordinator {
    @Published var navigationPath = NavigationPath()

    func navigate(to destination: BrowseDestination) {
        navigationPath.append(destination)
    }

    @ViewBuilder
    func build(_ destination: BrowseDestination) -> some View {
        switch destination {
        case .searchResults(let params):
            BrowseResultsView(params: params)
                .environmentObject(self)
        case .propertyDetail(let property, let isSaved):
            PropertyDetailView(property: property, isSavedProperty: isSaved)
        }
    }
}
