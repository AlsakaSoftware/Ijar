import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var navigationCoordinator: NavigationCoordinator?
    private let authService = AuthenticationService.shared
    
    init() {
        user = authService.currentUser
    }
    
    func logout() {
        isLoading = true
        
        Task {
            do {
                try await authService.signOut()
                
                await MainActor.run {
                    self.isLoading = false
                    self.navigationCoordinator?.didSignOut()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to sign out"
                }
            }
        }
    }
}