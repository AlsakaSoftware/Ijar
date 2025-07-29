import SwiftUI
import AuthenticationServices

class SignInViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthenticationService.shared
    var navigationCoordinator: NavigationCoordinator?
    
    func handleSignInWithApple(credential: ASAuthorizationAppleIDCredential) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signInWithApple(credential: credential)
                
                await MainActor.run {
                    self.isLoading = false
                    self.navigationCoordinator?.didCompleteAuth()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Sign in failed. Please try again."
                }
            }
        }
    }
    
    func signInWithAppleErrored(_ error: Error) {
        errorMessage = "Sign in failed. Please try again."
    }
    
    func showSignUp() {
        navigationCoordinator?.showSignUp()
    }
}