import Foundation

@MainActor
class MonitorService: ObservableObject {
    @Published var isRefreshing = false
    @Published var lastRefreshDate: Date?
    @Published var error: String?

    private let githubToken: String?
    private let repoOwner = "AlsakaSoftware"
    private let repoName = "ijar"

    // Track if user has used their one-time instant search
    private let hasUsedInstantSearchKey = "has_used_instant_search"

    var hasUsedInstantSearch: Bool {
        UserDefaults.standard.bool(forKey: hasUsedInstantSearchKey)
    }

    init() {
        self.githubToken = ConfigManager.shared.githubToken
    }

    private func markInstantSearchAsUsed() {
        UserDefaults.standard.set(true, forKey: hasUsedInstantSearchKey)
    }

    /// Triggers the monitor workflow for a specific user
    func refreshPropertiesForUser(userId: String) async -> Bool {
        guard let token = githubToken, !token.isEmpty else {
            error = "GitHub token not configured. Please add it to Config.plist"
            print("⚠️ GitHub token not found in config")
            return false
        }

        isRefreshing = true
        error = nil

        defer {
            isRefreshing = false
        }

        do {
            let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/dispatches")!
            print("🔍 Triggering workflow at: \(url.absoluteString)")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

            let payload: [String: Any] = [
                "event_type": "monitor-user",
                "client_payload": [
                    "user_id": userId
                ]
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                error = "Invalid response from GitHub"
                return false
            }

            if httpResponse.statusCode == 204 {
                print("✅ Successfully triggered monitor workflow for user: \(userId)")
                lastRefreshDate = Date()
                markInstantSearchAsUsed()
                return true
            } else {
                // Try to get error message from response
                var errorDetails = "Status: \(httpResponse.statusCode)"
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("❌ GitHub API response: \(responseBody)")
                    errorDetails += " - \(responseBody)"
                }
                error = errorDetails
                print("❌ Failed to trigger workflow. \(errorDetails)")
                return false
            }

        } catch {
            self.error = error.localizedDescription
            print("❌ Error triggering monitor workflow: \(error)")
            return false
        }
    }
}
