import Foundation
import Supabase

final class UserRepository {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient? = nil) {
        self.supabase = supabase ?? SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }

    /// Fetches the current user's profile from the `users` table.
    /// Returns nil if no row exists yet.
    func fetchCurrentUser() async throws -> UserRow? {
        let user = try await supabase.auth.user()

        let rows: [UserRow] = try await supabase
            .from("users")
            .select()
            .eq("id", value: user.id)
            .execute()
            .value

        return rows.first
    }

    /// Ensures a row exists in the `users` table for the current auth user.
    /// Uses upsert so it's safe to call multiple times.
    func upsertUser() async throws {
        let user = try await supabase.auth.user()

        let row = UserInsertRow(id: user.id.uuidString)

        try await supabase
            .from("users")
            .upsert(row, onConflict: "id", ignoreDuplicates: true)
            .execute()
    }

    /// Marks onboarding as complete for the current user.
    func markOnboardingComplete() async throws {
        let user = try await supabase.auth.user()

        try await supabase
            .from("users")
            .update(OnboardingUpdateRow(has_completed_onboarding: true))
            .eq("id", value: user.id)
            .execute()
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

private struct UserInsertRow: Codable {
    let id: String
}

private struct OnboardingUpdateRow: Codable {
    let hasCompletedOnboarding: Bool

    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding = "has_completed_onboarding"
    }
}
