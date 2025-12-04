import Foundation

@MainActor
class LiveSearchService: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = false
    @Published var total = 0
    @Published var error: String?

    private var currentPage = 1
    private var currentParams: SearchParams?

    struct SearchParams: Encodable {
        let latitude: Double
        let longitude: Double
        var minPrice: Int?
        var maxPrice: Int?
        var minBedrooms: Int?
        var maxBedrooms: Int?
        var minBathrooms: Int?
        var maxBathrooms: Int?
        var radius: Double?
        var furnishType: String?
        var page: Int = 1
    }

    // Rightmove API response types
    private struct APIResponse: Decodable {
        let properties: [RightmoveProperty]
        let total: Int
        let hasMore: Bool
        let page: Int
    }

    private struct RightmoveProperty: Decodable {
        let identifier: Int
        let bedrooms: Int
        let address: String
        let propertyType: String?
        let photoCount: Int
        let monthlyRent: Int
        let displayPrices: [DisplayPrice]?
        let thumbnailPhotos: [ThumbnailPhoto]?
        let photoLargeThumbnailUrl: String?
        let summary: String?
        let latitude: Double?
        let longitude: Double?
        let branch: Branch?
        let listingUpdateReason: String?
    }

    private struct DisplayPrice: Decodable {
        let displayPrice: String
        let displayPriceQualifier: String?
    }

    private struct ThumbnailPhoto: Decodable {
        let url: String
    }

    private struct Branch: Decodable {
        let brandName: String?
        let name: String?
        let contactTelephoneNumber: String?
    }

    func search(
        latitude: Double,
        longitude: Double,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        minBedrooms: Int? = nil,
        maxBedrooms: Int? = nil,
        minBathrooms: Int? = nil,
        maxBathrooms: Int? = nil,
        radius: Double? = nil,
        furnishType: String? = nil
    ) async {
        let params = SearchParams(
            latitude: latitude,
            longitude: longitude,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minBedrooms: minBedrooms,
            maxBedrooms: maxBedrooms,
            minBathrooms: minBathrooms,
            maxBathrooms: maxBathrooms,
            radius: radius,
            furnishType: furnishType,
            page: 1
        )

        currentParams = params
        currentPage = 1
        isLoading = true
        error = nil
        properties = []

        await performSearch(params: params)
        isLoading = false
    }

    func searchFromQuery(_ query: SearchQuery) async {
        await search(
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
    }

    // MARK: - Onboarding Search (saves to Supabase)

    struct OnboardingSearchParams: Encodable {
        let queryId: String
        let latitude: Double
        let longitude: Double
        var minPrice: Int?
        var maxPrice: Int?
        var minBedrooms: Int?
        var maxBedrooms: Int?
        var minBathrooms: Int?
        var maxBathrooms: Int?
        var radius: Double?
        var furnishType: String?
    }

    private struct OnboardingAPIResponse: Decodable {
        let properties: [OnboardingProperty]
        let total: Int
        let saved: Int
    }

    private struct OnboardingProperty: Decodable {
        let id: String
        let images: [String]
        let price: String
        let bedrooms: Int
        let bathrooms: Int
        let address: String
        let area: String
        let rightmoveUrl: String
        let agentPhone: String?
        let agentName: String?
        let branchName: String?
        let latitude: Double?
        let longitude: Double?
    }

    /// Perform onboarding search - fetches properties, gets HD images, saves to Supabase
    func onboardingSearch(queryId: String, query: SearchQuery) async {
        let params = OnboardingSearchParams(
            queryId: queryId,
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

        isLoading = true
        error = nil
        properties = []

        let baseURL = ConfigManager.shared.liveSearchAPIURL
        guard let url = URL(string: "\(baseURL)/api/onboarding-search") else {
            error = "Invalid API URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Longer timeout for HD image fetching

        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(params)

#if DEBUG
            print("🔍 OnboardingSearch: Fetching properties for query \(queryId)")
#endif

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                error = "Invalid response"
                isLoading = false
                return
            }

            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    error = errorMessage
                } else {
                    error = "Server error (\(httpResponse.statusCode))"
                }
                isLoading = false
                return
            }

            let apiResponse = try JSONDecoder().decode(OnboardingAPIResponse.self, from: data)

            properties = apiResponse.properties.map { prop in
                Property(
                    id: prop.id,
                    images: prop.images,
                    price: prop.price,
                    bedrooms: prop.bedrooms,
                    bathrooms: prop.bathrooms,
                    address: prop.address,
                    area: prop.area,
                    rightmoveUrl: prop.rightmoveUrl,
                    agentPhone: prop.agentPhone,
                    agentName: prop.agentName,
                    branchName: prop.branchName,
                    latitude: prop.latitude,
                    longitude: prop.longitude
                )
            }

            total = apiResponse.total
            hasMore = false // Onboarding only returns first batch

#if DEBUG
            print("✅ OnboardingSearch: Got \(properties.count) properties, \(apiResponse.saved) saved to DB")
#endif

        } catch {
            self.error = "Search failed: \(error.localizedDescription)"
#if DEBUG
            print("❌ OnboardingSearch: Error - \(error)")
#endif
        }

        isLoading = false
    }

    func loadMore() async {
        guard hasMore, var params = currentParams else { return }

        isLoadingMore = true
        currentPage += 1
        params.page = currentPage

        await performSearch(params: params, append: true)
        isLoadingMore = false
    }

    private func performSearch(params: SearchParams, append: Bool = false) async {
        let baseURL = ConfigManager.shared.liveSearchAPIURL
        guard let url = URL(string: "\(baseURL)/api/search") else {
            error = "Invalid API URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(params)

#if DEBUG
            print("🔍 LiveSearch: Searching at (\(params.latitude), \(params.longitude)) page \(params.page)")
#endif

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                error = "Invalid response"
                return
            }

            if httpResponse.statusCode != 200 {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    error = errorMessage
                } else {
                    error = "Server error (\(httpResponse.statusCode))"
                }
                return
            }

            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)

            let newProperties = apiResponse.properties.map { prop -> Property in
                // Get price display
                let price = prop.displayPrices?.first?.displayPrice ?? "£\(prop.monthlyRent) pcm"

                // Get images - use original URLs
                let images = prop.thumbnailPhotos?.map { $0.url } ?? []

                // Extract area from address
                let addressParts = prop.address.split(separator: ",")
                let area = addressParts.count > 1 ? String(addressParts.last!).trimmingCharacters(in: .whitespaces) : ""

                return Property(
                    id: String(prop.identifier),
                    images: images,
                    price: price,
                    bedrooms: prop.bedrooms,
                    bathrooms: 0, // Will get from details
                    address: prop.address.trimmingCharacters(in: .whitespaces),
                    area: area,
                    rightmoveUrl: "https://www.rightmove.co.uk/properties/\(prop.identifier)",
                    agentPhone: prop.branch?.contactTelephoneNumber,
                    agentName: prop.branch?.brandName,
                    branchName: prop.branch?.name,
                    latitude: prop.latitude,
                    longitude: prop.longitude,
                    propertyType: prop.propertyType
                )
            }

            if append {
                properties.append(contentsOf: newProperties)
            } else {
                properties = newProperties
            }

            total = apiResponse.total
            hasMore = apiResponse.hasMore

#if DEBUG
            print("✅ LiveSearch: Got \(newProperties.count) properties (total: \(total), hasMore: \(hasMore))")
#endif

        } catch {
            self.error = "Search failed: \(error.localizedDescription)"
#if DEBUG
            print("❌ LiveSearch: Error - \(error)")
#endif
        }
    }

    func clearResults() {
        properties = []
        total = 0
        hasMore = false
        currentPage = 1
        currentParams = nil
        error = nil
    }

    // MARK: - Property Details

    // Clean property details response from server
    private struct PropertyDetailsResponse: Decodable {
        let id: Int
        let bedrooms: Int
        let bathrooms: Int
        let address: String
        let price: String
        let description: String?
        let propertyType: String?
        let furnishType: String?
        let availableFrom: String?
        let latitude: Double?
        let longitude: Double?
        let photos: [String]
        let floorplans: [String]
        let features: [String]
        let stations: [Station]
        let agent: Agent
    }

    private struct Station: Decodable {
        let name: String
        let distance: Double
    }

    private struct Agent: Decodable {
        let name: String?
        let branch: String?
        let phone: String?
        let address: String?
    }

    /// Fetch full property details including HD images and listing information
    func fetchPropertyDetails(for property: Property) async -> Property? {
        let baseURL = ConfigManager.shared.liveSearchAPIURL
        guard let url = URL(string: "\(baseURL)/api/property/\(property.id)/details") else {
            return nil
        }

        do {
#if DEBUG
            print("📋 Fetching property details for \(property.id)")
#endif
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let details = try JSONDecoder().decode(PropertyDetailsResponse.self, from: data)

#if DEBUG
            print("✅ Got property details: \(details.photos.count) HD images, \(details.features.count) features, \(details.bathrooms) bathrooms")
#endif

            // Create updated property with details
            return Property(
                id: property.id,
                images: details.photos.isEmpty ? property.images : details.photos,
                price: details.price,
                bedrooms: details.bedrooms,
                bathrooms: details.bathrooms,
                address: details.address,
                area: property.area,
                rightmoveUrl: property.rightmoveUrl,
                agentPhone: details.agent.phone ?? property.agentPhone,
                agentName: details.agent.name ?? property.agentName,
                branchName: details.agent.branch ?? property.branchName,
                latitude: details.latitude ?? property.latitude,
                longitude: details.longitude ?? property.longitude,
                description: details.description,
                keyFeatures: details.features.isEmpty ? nil : details.features,
                propertyType: details.propertyType,
                availableFrom: details.availableFrom,
                floorplanImages: details.floorplans.isEmpty ? nil : details.floorplans
            )

        } catch {
#if DEBUG
            print("❌ Failed to fetch property details: \(error)")
#endif
            return nil
        }
    }
}
