import Foundation

@MainActor
class MonitorService: ObservableObject {
    @Published var isRefreshing = false
    @Published var lastRefreshDate: Date?
    @Published var error: String?

    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    func refreshPropertiesForUser(userId: String) async -> Bool {
        isRefreshing = true
        error = nil

        defer {
            isRefreshing = false
        }

        do {
            struct RefreshResponse: Decodable {
                let success: Bool
            }

            let result: RefreshResponse = try await networkService.send(
                endpoint: "/api/monitor/refresh",
                method: .post
            )

            if result.success {
                lastRefreshDate = Date()
            }
            return result.success
        } catch {
            self.error = error.localizedDescription
#if DEBUG
            print("MonitorService: Failed to trigger refresh: \(error)")
#endif
            return false
        }
    }
}
