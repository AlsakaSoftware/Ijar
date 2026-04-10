import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var showingDeleteConfirmation = false
    @Published var showingPaywall = false

    func signOut(authService: AuthenticationService) async {
        await authService.signOut()
    }

    func deleteAccount(authService: AuthenticationService) async {
        do {
            try await authService.deleteAccount()
        } catch {
            // Error is already set in authService
        }
    }

    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
    }

    func resetGuestMode() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCompletedPreferencesOnboarding)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isGuestMode)
    }
}
