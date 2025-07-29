import Foundation
import AuthenticationServices
import Supabase

enum AuthError: Error {
    case invalidCredentials
    case networkError
    case unknown
    case signInWithAppleFailed
}

final class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        checkCurrentSession()
    }
    
    // MARK: - Session Management
    
    func checkCurrentSession() {
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    self.isAuthenticated = true
                    Task {
                        await fetchCurrentUser()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Sign In with Apple
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.signInWithAppleFailed
        }
        
        let fullName = PersonNameComponentsFormatter.localizedString(
            from: credential.fullName ?? PersonNameComponents(),
            style: .default
        )
        
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )
            
            // Update user profile if needed
            let userId = session.user.id
            try await updateUserProfile(userId: userId, fullName: fullName)
            
            await MainActor.run {
                self.isAuthenticated = true
            }
            
            await fetchCurrentUser()
        } catch {
            throw AuthError.signInWithAppleFailed
        }
    }
    
    // MARK: - User Profile
    
    private func fetchCurrentUser() async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            let response: User = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = response
            }
        } catch {
            print("Error fetching user profile: \(error)")
        }
    }
    
    private func updateUserProfile(userId: UUID, fullName: String?) async throws {
        let profile = UserProfile(
            userId: userId.uuidString,
            fullName: fullName,
            updatedAt: Date()
        )
        
        try await supabase
            .from("profiles")
            .upsert(profile)
            .execute()
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable {
    let userId: String
    let fullName: String?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fullName = "full_name"
        case updatedAt = "updated_at"
    }
}
