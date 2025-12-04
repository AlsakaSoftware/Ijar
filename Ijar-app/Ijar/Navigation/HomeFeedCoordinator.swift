import SwiftUI

class HomeFeedCoordinator: ObservableObject, Coordinator {
    @Published var navigationPath = NavigationPath()
    
    func navigate(to destination: HomeFeedDestination) {
        navigationPath.append(destination)
    }
    
    @ViewBuilder
    func build(_ destination: HomeFeedDestination) -> some View {
        switch destination {
        case .propertyDetail(let property):
            PropertyDetailView(property: property, isSavedProperty: false, showLikeButton: false)
        }
    }
    
}