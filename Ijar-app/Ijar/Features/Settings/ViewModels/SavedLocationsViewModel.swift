import Foundation

@MainActor
class SavedLocationsViewModel: ObservableObject {
    @Published var showingAddLocation = false
    @Published var showingPaywall = false
    @Published var locationToEdit: SavedLocation?
    @Published var limitMessage: String?

    private let subscriptionManager = SubscriptionManager.shared

    func handleAddLocation(currentLocationCount: Int) {
        let result = subscriptionManager.canAddSavedLocation(currentLocationCount: currentLocationCount)

        if result.canAdd {
            showingAddLocation = true
        } else {
            limitMessage = result.reason
        }
    }
}
