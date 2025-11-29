import Foundation

@MainActor
class LiveSearchService: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = false
    @Published var total = 0
    @Published var error: String?

    private var currentIndex = 0
    private var currentParams: SearchParams?

    struct SearchParams: Encodable {
        let postcode: String
        var minPrice: Int?
        var maxPrice: Int?
        var minBedrooms: Int?
        var maxBedrooms: Int?
        var minBathrooms: Int?
        var maxBathrooms: Int?
        var radius: Double?
        var furnishType: String?
        var index: Int = 0
    }

    private struct APIResponse: Decodable {
        let properties: [APIProperty]
        let total: Int
        let hasMore: Bool
        let nextIndex: Int?
    }

    private struct APIProperty: Decodable {
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

    func search(
        postcode: String,
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
            postcode: postcode,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minBedrooms: minBedrooms,
            maxBedrooms: maxBedrooms,
            minBathrooms: minBathrooms,
            maxBathrooms: maxBathrooms,
            radius: radius,
            furnishType: furnishType,
            index: 0
        )

        currentParams = params
        currentIndex = 0
        isLoading = true
        error = nil
        properties = []

        await performSearch(params: params)
        isLoading = false
    }

    func searchFromQuery(_ query: SearchQuery) async {
        await search(
            postcode: query.postcode,
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

    func loadMore() async {
        guard hasMore, var params = currentParams else { return }

        isLoadingMore = true
        currentIndex += 24
        params.index = currentIndex

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
            print("🔍 LiveSearch: Searching for \(params.postcode) at index \(params.index)")
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

            let newProperties = apiResponse.properties.map { apiProp in
                Property(
                    id: apiProp.id,
                    images: apiProp.images,
                    price: apiProp.price,
                    bedrooms: apiProp.bedrooms,
                    bathrooms: apiProp.bathrooms,
                    address: apiProp.address,
                    area: apiProp.area,
                    rightmoveUrl: apiProp.rightmoveUrl,
                    agentPhone: apiProp.agentPhone,
                    agentName: apiProp.agentName,
                    branchName: apiProp.branchName,
                    latitude: apiProp.latitude,
                    longitude: apiProp.longitude
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
        currentIndex = 0
        currentParams = nil
        error = nil
    }
}
