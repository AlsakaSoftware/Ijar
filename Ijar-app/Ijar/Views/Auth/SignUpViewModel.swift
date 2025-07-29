import SwiftUI
import AuthenticationServices

class SignUpViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthenticationService.shared
    var navigationCoordinator: NavigationCoordinator?
    
    func handleSignUpWithApple(credential: ASAuthorizationAppleIDCredential) {
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
                    self.errorMessage = "Sign up failed. Please try again."
                }
            }
        }
    }
    
    func signUpWithAppleErrored(_ error: Error) {
        errorMessage = "Sign up failed. Please try again."
    }
}