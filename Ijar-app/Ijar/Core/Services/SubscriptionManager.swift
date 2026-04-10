import Foundation
import RevenueCat
import RevenueCatUI

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

//    Make app free for now
    @Published var isSubscribed = true

    // Free tier limits
    private let freeQueryLimit = 1
    private let freeSavedLocationsLimit = 1

    // Session tracking for paywall
    private let sessionCountKey = "paywall_session_count"
    private let paywallFrequency = 5

    private init() {
        Purchases.logLevel = .debug

        // Configure with user ID if available
        if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
            Purchases.configure(withAPIKey: ConfigManager.shared.revenueCatApiKey, appUserID: userId)
            print("✅ RevenueCat configured with user ID: \(userId)")
        } else {
            Purchases.configure(withAPIKey: ConfigManager.shared.revenueCatApiKey)
            print("✅ RevenueCat configured without user ID (anonymous)")
        }

        Task {
            await checkSubscriptionStatus()
        }

        // Increment session count
        incrementSessionCount()
    }

    // MARK: - Session Tracking

    private func incrementSessionCount() {
        let currentCount = UserDefaults.standard.integer(forKey: sessionCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: sessionCountKey)
    }

    /// Check if we should show the paywall this session
    func shouldShowPaywall() -> Bool {
        guard !isSubscribed else { return false }

        let sessionCount = UserDefaults.standard.integer(forKey: sessionCountKey)
        return sessionCount % paywallFrequency == 0
    }

    /// Reset session count (e.g., after showing paywall)
    func resetSessionCount() {
        UserDefaults.standard.set(1, forKey: sessionCountKey)
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        // App is free for now - skip subscription check
        isSubscribed = true

        // Original RevenueCat check (disabled):
        // do {
        //     let customerInfo = try await Purchases.shared.customerInfo()
        //     isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
        // } catch {
        //     isSubscribed = false
        // }
    }

    /// Update subscription status from existing CustomerInfo (e.g., from purchase completion)
    func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        // App is free for now - always treat as subscribed
        isSubscribed = true

        // Original check (disabled):
        // isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
    }

    // MARK: - Limit Enforcement

    /// Check if user can create a new active query
    /// - Parameter activeQueryCount: Current count of active queries
    /// - Returns: Tuple with (canCreate: Bool, reason: String?)
    func canCreateActiveQuery(activeQueryCount: Int) -> (canCreate: Bool, reason: String?) {
        if isSubscribed {
            return (true, nil)
        }

        if activeQueryCount >= freeQueryLimit {
            return (false, "Free tier allows only \(freeQueryLimit) active query. Upgrade to create more.")
        }

        return (true, nil)
    }

    /// Check if user can activate a query (when they have inactive queries)
    /// - Parameter activeQueryCount: Current count of active queries
    /// - Returns: Tuple with (canActivate: Bool, reason: String?)
    func canActivateQuery(activeQueryCount: Int) -> (canActivate: Bool, reason: String?) {
        if isSubscribed {
            return (true, nil)
        }

        if activeQueryCount >= freeQueryLimit {
            return (false, "Free tier allows only \(freeQueryLimit) active query. Deactivate another query or upgrade.")
        }

        return (true, nil)
    }

    /// Check if user can add a new saved location
    /// - Parameter currentLocationCount: Current total count of saved locations
    /// - Returns: Tuple with (canAdd: Bool, reason: String?)
    func canAddSavedLocation(currentLocationCount: Int) -> (canAdd: Bool, reason: String?) {
        if isSubscribed {
            return (true, nil)
        }

        if currentLocationCount >= freeSavedLocationsLimit {
            return (false, "Free tier allows only \(freeSavedLocationsLimit) saved location. Upgrade to add more.")
        }

        return (true, nil)
    }

    /// Get remaining active query slots
    func getRemainingActiveQueries(activeQueryCount: Int) -> Int {
        if isSubscribed {
            return -1 // -1 indicates unlimited
        }
        return max(0, freeQueryLimit - activeQueryCount)
    }

    /// Get remaining saved location slots
    func getRemainingLocations(currentLocationCount: Int) -> Int {
        if isSubscribed {
            return -1 // -1 indicates unlimited
        }
        return max(0, freeSavedLocationsLimit - currentLocationCount)
    }

    /// Get user-friendly description of current limits
    func getLimitDescription() -> String {
        if isSubscribed {
            return "Premium: Unlimited queries and saved locations"
        }
        return "Free tier: \(freeQueryLimit) active query, \(freeSavedLocationsLimit) saved location"
    }

    /// Determine which queries should be deactivated when downgrading to free tier
    /// - Parameter queries: All user queries sorted by preference (newest first)
    /// - Returns: Array of query IDs that should be deactivated
    func getQueriesToDeactivate(queries: [SearchQuery]) -> [UUID] {
        if isSubscribed {
            return []
        }

        let activeQueries = queries.filter { $0.active }

        // If user has more active queries than allowed, deactivate the excess
        // Keep the oldest ones (created first) and deactivate newer ones
        if activeQueries.count > freeQueryLimit {
            let sortedByDate = activeQueries.sorted { $0.created < $1.created }
            let toDeactivate = sortedByDate.dropFirst(freeQueryLimit)
            return toDeactivate.map { $0.id }
        }

        return []
    }

    /// Determine which saved locations exceed the limit
    /// - Parameter locations: All saved locations
    /// - Returns: Array of location IDs that should be marked as "over limit"
    func getLocationsOverLimit(locations: [SavedLocation]) -> [UUID] {
        if isSubscribed {
            return []
        }

        // If user has more locations than allowed, mark excess as over limit
        // Keep the first N locations, mark rest as over limit
        if locations.count > freeSavedLocationsLimit {
            let overLimit = locations.dropFirst(freeSavedLocationsLimit)
            return overLimit.map { $0.id }
        }

        return []
    }
}
