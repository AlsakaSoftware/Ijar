import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase: SupabaseClient
    
    init() {
        // Initialize Supabase client using ConfigManager
        let config = ConfigManager.shared
        
        guard let url = URL(string: config.supabaseURL) else {
            fatalError("Invalid Supabase URL in configuration")
        }
        
        supabase = SupabaseClient(supabaseURL: url, supabaseKey: config.supabaseAnonKey)
        
        #if DEBUG
        config.debugPrint()
        #endif
        
        // Check if user is already signed in
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                self.isAuthenticated = true
                self.user = session.user
            } catch {
                self.isAuthenticated = false
                self.user = nil
            }
        }
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        error = nil
        
        do {
            guard let identityToken = credential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                throw AuthError.invalidCredentials
            }
            
            // Sign in with Supabase using Apple ID token
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )
            
            self.user = session.user
            self.isAuthenticated = true
            
        } catch {
            self.error = error.localizedDescription
            self.isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid Apple ID credentials"
        }
    }
}