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
    @StateObject private var viewModel = AllSavedPropertiesViewModel()
    private let propertyGroupService: PropertyGroupService
    private let savedPropertyRepository: SavedPropertyRepository

    init(
        propertyGroupService: PropertyGroupService = PropertyGroupService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) {
        self.propertyGroupService = propertyGroupService
        self.savedPropertyRepository = savedPropertyRepository
    }

    var body: some View {
        SavedPropertiesListView(
            properties: viewModel.properties,
            isLoading: viewModel.isLoading,
            loadingText: "Finding your saved homes...",
            emptyIcon: "heart.slash",
            emptyTitle: "No favorites yet",
            emptyMessage: "Heart the homes you love, and\nwe'll keep them here for you",
            propertyGroupService: propertyGroupService,
            savedPropertyRepository: savedPropertyRepository,
            onPropertyTap: { property in
                coordinator.navigate(to: .propertyDetail(property: property))
            },
            onSaveStateChanged: { property, isSaved in
                if !isSaved {
                    viewModel.removeProperty(property)
                }
            }
        )
        .navigationTitle("All Saved")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(.rusticOrange)
        .task {
            await viewModel.loadProperties()
        }
    }
}
