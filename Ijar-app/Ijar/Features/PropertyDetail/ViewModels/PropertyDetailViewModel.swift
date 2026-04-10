import Foundation

@MainActor
class PropertyDetailViewModel: ObservableObject {
    // MARK: - Property Details State
    @Published var displayProperty: Property
    @Published var displayImages: [String] = []
    @Published var isLoadingDetails = false

    // MARK: - Transport State
    @Published var nearbyStations: [TubeStation] = []
    @Published var nearbyBusStops: [BusStop] = []
    @Published var isLoadingTransport = false
    @Published var transportError: String?

    // MARK: - Journey State
    @Published var journeys: [SavedLocation: Journey?] = [:]
    @Published var isLoadingJourneys = false

    // MARK: - Geocoding State
    @Published var geocodedCoordinates: (latitude: Double, longitude: Double)?

    // MARK: - UI State
    @Published var showingFullScreenImages = false
    @Published var showingFloorplan = false
    @Published var showingGroupPicker = false
    @Published var showingGuestSignUpPrompt = false
    @Published var currentImageIndex = 0

    // MARK: - Dependencies
    private let searchService = LiveSearchService()
    private let tflService = TfLService()
    private let journeyService = TfLJourneyService()
    private let geocodingService = GeocodingService()

    let property: Property

    var propertyCoordinates: (latitude: Double, longitude: Double)? {
        if let lat = property.latitude, let lon = property.longitude {
            return (lat, lon)
        }
        return geocodedCoordinates
    }

    init(property: Property) {
        self.property = property
        self.displayProperty = property
    }

    // MARK: - Data Loading

    func loadPropertyDetails() async {
        isLoadingDetails = true
        if let enrichedProperty = await searchService.fetchPropertyDetails(for: property) {
            displayProperty = enrichedProperty
            displayImages = enrichedProperty.images
        }
        isLoadingDetails = false

        if displayImages.isEmpty {
            displayImages = property.images
        }
    }

    func ensureSavedIdsLoaded() async {
        let savedPropertyRepository = SavedPropertyRepository.shared
        if savedPropertyRepository.savedIds.isEmpty {
            await savedPropertyRepository.refreshSavedIds()
        }
    }

    private var hasLoadedTransport = false

    func geocodeAndLoadTransport() async {
        guard !hasLoadedTransport else { return }

        if property.latitude == nil || property.longitude == nil {
            do {
                let address = property.area.isEmpty ? property.address : "\(property.address), \(property.area)"
                let coordinates = try await geocodingService.geocode(address)
                geocodedCoordinates = coordinates
            } catch {
                transportError = "Could not determine location coordinates"
                return
            }
        }

        guard let coordinates = propertyCoordinates else { return }
        let lat = coordinates.latitude
        let lon = coordinates.longitude

        isLoadingTransport = true
        transportError = nil

        do {
            let result = try await tflService.fetchNearbyStations(latitude: lat, longitude: lon)
            nearbyStations = result.stations
            nearbyBusStops = result.busStops
        } catch {
            transportError = error.localizedDescription
        }

        isLoadingTransport = false
        hasLoadedTransport = true
    }

    private var hasLoadedJourneys = false

    func fetchJourneys(locations: [SavedLocation]) async {
        guard !hasLoadedJourneys else { return }
        guard let coordinates = propertyCoordinates else { return }
        guard !locations.isEmpty else { return }

        let lat = coordinates.latitude
        let lon = coordinates.longitude

        isLoadingJourneys = true

        await withTaskGroup(of: (SavedLocation, Journey?).self) { group in
            for location in locations {
                guard let toLat = location.latitude, let toLon = location.longitude else {
                    journeys[location] = nil
                    continue
                }

                group.addTask {
                    do {
                        let journey = try await self.journeyService.fetchJourney(
                            fromLat: lat,
                            fromLon: lon,
                            toLat: toLat,
                            toLon: toLon,
                            mode: .all
                        )
                        return (location, journey)
                    } catch {
                        return (location, nil)
                    }
                }
            }

            for await (location, journey) in group {
                journeys[location] = journey
            }
        }

        isLoadingJourneys = false
        hasLoadedJourneys = true
    }
}
