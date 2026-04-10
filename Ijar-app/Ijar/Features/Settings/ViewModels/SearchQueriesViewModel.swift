import Foundation

@MainActor
class SearchQueriesViewModel: ObservableObject {
    @Published var queries: [SearchQuery] = []
    @Published var isLoading = true
    @Published var showingCreateQuery = false
    @Published var editingQuery: SearchQuery?
    @Published var showingPaywall = false
    @Published var limitMessage: String?
    @Published var showingSearchStartedAlert = false

    private let searchQueryRepository = SearchQueryRepository()
    private let userRepository = UserRepository()
    private let monitorService = MonitorService()
    private let subscriptionManager = SubscriptionManager.shared

    func loadQueries() async {
        do {
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error loading queries: \(error)")
        }
        isLoading = false
    }

    func createQuery(_ query: SearchQuery) async {
        do {
            try await searchQueryRepository.insertQuery(query)
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error creating query: \(error)")
        }
    }

    func updateQuery(_ query: SearchQuery) async {
        do {
            try await searchQueryRepository.updateQuery(query)
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error updating query: \(error)")
        }
    }

    func deleteQuery(_ query: SearchQuery) async {
        do {
            try await searchQueryRepository.deleteQuery(id: query.id)
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error deleting query: \(error)")
        }
    }

    func duplicateQuery(_ query: SearchQuery) async {
        let duplicated = SearchQuery(
            name: "Copy of \(query.name)",
            areaName: query.areaName,
            latitude: query.latitude,
            longitude: query.longitude,
            minPrice: query.minPrice,
            maxPrice: query.maxPrice,
            minBedrooms: query.minBedrooms,
            maxBedrooms: query.maxBedrooms,
            minBathrooms: query.minBathrooms,
            maxBathrooms: query.maxBathrooms,
            radius: query.radius,
            furnishType: query.furnishType
        )
        do {
            try await searchQueryRepository.insertQuery(duplicated)
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error duplicating query: \(error)")
        }
    }

    func handleCreateQuery() {
        let activeQueryCount = queries.filter { $0.active }.count
        let result = subscriptionManager.canCreateActiveQuery(activeQueryCount: activeQueryCount)

        if result.canCreate {
            showingCreateQuery = true
        } else {
            limitMessage = result.reason
        }
    }

    func handleToggleActive(_ query: SearchQuery) {
        if !query.active {
            let activeQueryCount = queries.filter { $0.active }.count
            let result = subscriptionManager.canActivateQuery(activeQueryCount: activeQueryCount)

            if !result.canActivate {
                limitMessage = result.reason
                return
            }
        }
        Task {
            let updatedQuery = SearchQuery(
                id: query.id,
                name: query.name,
                areaName: query.areaName,
                latitude: query.latitude,
                longitude: query.longitude,
                minPrice: query.minPrice,
                maxPrice: query.maxPrice,
                minBedrooms: query.minBedrooms,
                maxBedrooms: query.maxBedrooms,
                minBathrooms: query.minBathrooms,
                maxBathrooms: query.maxBathrooms,
                radius: query.radius,
                furnishType: query.furnishType,
                active: !query.active,
                created: query.created,
                updated: Date()
            )
            await updateQuery(updatedQuery)
        }
    }

    func triggerSearchForNewQuery() async {
        let hasTriggeredFirstQuerySearch = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
        let isFirstQuery = queries.count == 1

        guard isFirstQuery, !hasTriggeredFirstQuerySearch else { return }

        do {
            guard let user = try await userRepository.fetchCurrentUser() else { return }

            let success = await monitorService.refreshPropertiesForUser(userId: user.id)

            if success {
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
                showingSearchStartedAlert = true
            }
        } catch {
#if DEBUG
            print("SearchQueriesViewModel: Failed to get user for search trigger: \(error)")
#endif
        }
    }
}
