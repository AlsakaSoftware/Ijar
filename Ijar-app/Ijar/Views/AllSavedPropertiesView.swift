import SwiftUI

enum SavedSortOption: String, CaseIterable {
    case newest = "Newest"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case bedroomsLowToHigh = "Bedrooms: Low to High"
    case bedroomsHighToLow = "Bedrooms: High to Low"

    var icon: String {
        switch self {
        case .newest: return "clock"
        case .priceLowToHigh: return "arrow.up"
        case .priceHighToLow: return "arrow.down"
        case .bedroomsLowToHigh: return "arrow.up"
        case .bedroomsHighToLow: return "arrow.down"
        }
    }
}

struct AllSavedPropertiesView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    private let propertyService: PropertyService
    private let savedPropertyRepository: SavedPropertyRepository
    @State private var properties: [Property] = []
    @State private var isLoading = true

    init(
        propertyService: PropertyService = PropertyService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) {
        self.propertyService = propertyService
        self.savedPropertyRepository = savedPropertyRepository
    }

    var body: some View {
        SavedPropertiesListView(
            properties: properties,
            isLoading: isLoading,
            loadingText: "Finding your saved homes...",
            emptyIcon: "heart.slash",
            emptyTitle: "No favorites yet",
            emptyMessage: "Heart the homes you love, and\nwe'll keep them here for you",
            propertyService: propertyService,
            savedPropertyRepository: savedPropertyRepository,
            onPropertyTap: { property in
                coordinator.navigate(to: .propertyDetail(property: property))
            },
            onSaveStateChanged: { property, isSaved in
                if !isSaved {
                    properties.removeAll { $0.id == property.id }
                }
            }
        )
        .navigationTitle("All Saved")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(.rusticOrange)
        .task {
            properties = (try? await savedPropertyRepository.loadAllSavedProperties()) ?? []
            isLoading = false
        }
    }
}
