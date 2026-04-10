import Foundation

final class UserRepository {
    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    func fetchCurrentUser() async throws -> UserRow? {
        do {
            let user: UserRow = try await networkService.send(
                endpoint: "/api/user",
                method: .get
            )
            return user
        } catch let error as NetworkError {
            if error.isNotFound { return nil }
            throw error
        }
    }

    func upsertUser() async throws {
        try await networkService.send(
            endpoint: "/api/user",
            method: .put
        )
    }

    func markOnboardingComplete() async throws {
        try await networkService.send(
            endpoint: "/api/user/onboarding",
            method: .patch
        )
    }
}

// MARK: - Row Types

struct UserRow: Codable {
    let id: String
    let hasCompletedOnboarding: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case hasCompletedOnboarding = "has_completed_onboarding"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
