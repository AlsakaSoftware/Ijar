import SwiftUI

@MainActor
class BrowseResultsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var filters = PropertyFilters()
    @Published var showFilters = false
    @Published var animateContent = false
    @Published var isLoading = true
    @Published var showSaveSearchSheet = false
    @Published var showGuestSignUpSheet = false
    @Published var hasSavedQuery = false
    @Published var hasSeenFullExplainer = UserDefaults.standard.bool(forKey: "has_seen_save_search_explainer")

    // MARK: - Published State (search results)
    @Published var properties: [Property] = []
    @Published var searchError: String?
    @Published var total = 0
    @Published var hasMore = false
    @Published var isLoadingMore = false

    // MARK: - Dependencies
    private let searchService = LiveSearchService()
    private let searchQueryRepository = SearchQueryRepository()
    private(set) var queries: [SearchQuery] = []

    // MARK: - Computed Properties

    func shouldShowSaveButton(params: BrowseSearchParams) -> Bool {
        if hasSavedQuery { return false }

        let existingQuery = queries.first { query in
            abs(query.latitude - params.latitude) < 0.001 &&
            abs(query.longitude - params.longitude) < 0.001 &&
            query.minPrice == filters.minPrice &&
            query.maxPrice == filters.maxPrice &&
            query.minBedrooms == filters.minBedrooms &&
            query.maxBedrooms == filters.maxBedrooms &&
            query.minBathrooms == filters.minBathrooms &&
            query.maxBathrooms == filters.maxBathrooms &&
            query.radius == filters.radius &&
            query.furnishType == filters.furnishType
        }

        return existingQuery == nil
    }

    // MARK: - Actions

    func loadInitialData(params: BrowseSearchParams) async {
        do {
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error loading queries: \(error)")
        }

        filters = params.filters
        await performSearch(params: params)
    }

    func performSearch(params: BrowseSearchParams) async {
        isLoading = true
        animateContent = false

        await searchService.search(
            latitude: params.latitude,
            longitude: params.longitude,
            minPrice: filters.minPrice,
            maxPrice: filters.maxPrice,
            minBedrooms: filters.minBedrooms,
            maxBedrooms: filters.maxBedrooms,
            minBathrooms: filters.minBathrooms,
            maxBathrooms: filters.maxBathrooms,
            radius: filters.radius,
            furnishType: filters.furnishType
        )

        syncFromSearchService()
        await SavedPropertyRepository.shared.refreshSavedIds()

        isLoading = false
        withAnimation {
            self.animateContent = true
        }
    }

    func loadMore() async {
        isLoadingMore = true
        await searchService.loadMore()
        syncFromSearchService()
        isLoadingMore = false
    }

    func createQuery(_ query: SearchQuery) async {
        try? await searchQueryRepository.insertQuery(query)
        hasSavedQuery = true
    }

    func markExplainerSeen() {
        UserDefaults.standard.set(true, forKey: "has_seen_save_search_explainer")
        hasSeenFullExplainer = true
    }

    // MARK: - Private

    private func syncFromSearchService() {
        properties = searchService.properties
        searchError = searchService.error
        total = searchService.total
        hasMore = searchService.hasMore
    }
}
