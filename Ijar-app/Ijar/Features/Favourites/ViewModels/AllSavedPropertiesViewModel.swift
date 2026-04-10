import Foundation

@MainActor
class AllSavedPropertiesViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = true

    private let savedPropertyRepository: SavedPropertyRepository

    init(savedPropertyRepository: SavedPropertyRepository = .shared) {
        self.savedPropertyRepository = savedPropertyRepository
    }

    func loadProperties() async {
        properties = (try? await savedPropertyRepository.loadAllSavedProperties()) ?? []
        isLoading = false
    }

    func removeProperty(_ property: Property) {
        properties.removeAll { $0.id == property.id }
    }
}
