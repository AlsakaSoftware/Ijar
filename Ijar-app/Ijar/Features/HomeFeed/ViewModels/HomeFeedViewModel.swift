import Foundation
import Kingfisher

@MainActor
class HomeFeedViewModel: ObservableObject {
    // MARK: - Published State
    @Published var properties: [Property] = []
    @Published var isLoading = true
    @Published var showContent = false
    @Published var showSwipeTutorial = false
    @Published var showingCreateQuery = false
    @Published var showingSearchStartedAlert = false
    @Published var showingAreasSheet = false
    @Published var showingGuestSignUpPrompt = false
    @Published var guestSignUpAction: GuestSignUpAction = .pass
    @Published var dragDirection: SwipeDirection = .none

    @Published var ambientAnimation = false

    // MARK: - Internal State
    var isFirstTimeEntrance = false
    private var hasUsedInitialProperties = false
    private let searchQueryRepository = SearchQueryRepository()
    private let userRepository = UserRepository()
    private(set) var queries: [SearchQuery] = []

    // MARK: - Dependencies
    private let propertyRepository: PropertyRepository
    private let monitorService = MonitorService()

    init(propertyRepository: PropertyRepository = PropertyRepository()) {
        self.propertyRepository = propertyRepository
    }

    // MARK: - Data Loading

    func loadInitialData(
        initialPropertiesStore: InitialPropertiesStore,
        authService: AuthenticationService,
        notificationService: NotificationService
    ) async {
        await notificationService.checkAndRequestNotificationPermission()

        let comingFromOnboarding = !initialPropertiesStore.properties.isEmpty

        if comingFromOnboarding {
            properties = initialPropertiesStore.properties.reversed()
            initialPropertiesStore.clear()
            hasUsedInitialProperties = true
            isFirstTimeEntrance = true
        } else if authService.isInGuestMode {
            let guestProperties = GuestPreferencesStore.shared.properties
            if !guestProperties.isEmpty && properties.isEmpty {
                properties = guestProperties.reversed()
                isFirstTimeEntrance = !hasUsedInitialProperties
                hasUsedInitialProperties = true
            }
        } else {
            properties = (try? await propertyRepository.fetchPropertiesForUser()) ?? []
        }

        isLoading = false

        if !authService.isInGuestMode {
            await loadQueries()
        }
        prefetchTopProperties()
    }

    func refreshProperties() async {
        properties = (try? await propertyRepository.fetchPropertiesForUser()) ?? []
        prefetchTopProperties()
    }

    private func loadQueries() async {
        do {
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error loading queries: \(error)")
        }
    }

    // MARK: - Card Actions

    func handleSwipeLeft(property: Property) async {
        await propertyRepository.trackPropertyAction(propertyId: property.id, action: .passed)
    }

    func handleSwipeRight(property: Property) async {
        await propertyRepository.trackPropertyAction(propertyId: property.id, action: .saved)
    }

    func removeTopProperty() {
        if !properties.isEmpty {
            properties.removeFirst()
        }
    }

    // MARK: - Search Query Actions

    func createQueryAndSearch(_ query: SearchQuery) async {
        try? await searchQueryRepository.insertQuery(query)
        await loadQueries()
        await triggerSearchForNewQuery()
        properties = (try? await propertyRepository.fetchPropertiesForUser()) ?? []
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
            print("HomeFeedViewModel: Failed to get user for search trigger: \(error)")
#endif
        }
    }

    // MARK: - Prefetching

    func prefetchTopProperties() {
        let propertiesToPrefetch = Array(properties.prefix(3))
        let urls = propertiesToPrefetch.flatMap { property in
            property.images.compactMap { URL(string: $0) }
        }

        guard !urls.isEmpty else { return }

        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()

#if DEBUG
        print("Prefetching \(urls.count) images for \(propertiesToPrefetch.count) properties")
#endif
    }

    var hasQueries: Bool { !queries.isEmpty }
}
