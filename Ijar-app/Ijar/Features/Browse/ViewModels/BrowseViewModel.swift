import Foundation

@MainActor
class BrowseViewModel: ObservableObject {
    // MARK: - Published State
    @Published var areaName = ""
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var isGeocoding = false
    @Published var geocodingError: String?
    @Published var filters = PropertyFilters(radius: 1.0)
    @Published var showFilters = false
    @Published var queries: [SearchQuery] = []

    // MARK: - Dependencies
    private let geocodingService = GeocodingService()
    private let searchQueryRepository = SearchQueryRepository()
    private var geocodingTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var canSearch: Bool {
        latitude != nil && longitude != nil && geocodingError == nil && !isGeocoding
    }

    // MARK: - Actions

    func loadQueries() async {
        do {
            queries = try await searchQueryRepository.fetchQueries()
        } catch {
            print("Error loading queries: \(error)")
        }
    }

    func loadQuery(_ query: SearchQuery) {
        areaName = query.areaName
        latitude = query.latitude
        longitude = query.longitude
        filters = PropertyFilters(
            minPrice: query.minPrice,
            maxPrice: query.maxPrice,
            minBedrooms: query.minBedrooms,
            maxBedrooms: query.maxBedrooms,
            minBathrooms: query.minBathrooms,
            maxBathrooms: query.maxBathrooms,
            radius: query.radius,
            furnishType: query.furnishType
        )
        geocodingError = nil
    }

    func buildSearchParams() -> BrowseSearchParams? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return BrowseSearchParams(
            areaName: areaName,
            latitude: lat,
            longitude: lng,
            filters: filters
        )
    }

    func geocodeArea(_ area: String) {
        geocodingTask?.cancel()
        latitude = nil
        longitude = nil
        geocodingError = nil

        let trimmedArea = area.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedArea.isEmpty else { return }

        geocodingTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }

                isGeocoding = true

                let result = try await geocodingService.geocodeAreaToPostcode(trimmedArea)
                guard !Task.isCancelled else { return }

                isGeocoding = false
                latitude = result.latitude
                longitude = result.longitude
                geocodingError = nil
            } catch let error as GeocodingError {
                guard !Task.isCancelled else { return }
                isGeocoding = false
                latitude = nil
                longitude = nil
                geocodingError = error.localizedDescription
            } catch {
                guard !Task.isCancelled else { return }
                isGeocoding = false
                latitude = nil
                longitude = nil
                geocodingError = "Couldn't find this area"
            }
        }
    }
}
