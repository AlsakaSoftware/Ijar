import SwiftUI
import AuthenticationServices

/// Reusable Sign In with Apple button that handles authentication
/// Uses the shared AuthenticationService from the environment
struct SignInWithAppleButtonView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var appCoordinator: AppCoordinator

    var style: SignInWithAppleButton.Style = .black
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 28
    var onSuccess: (() -> Void)?

    init(
        style: SignInWithAppleButton.Style = .black,
        height: CGFloat = 56,
        cornerRadius: CGFloat = 28,
        onSuccess: (() -> Void)? = nil
    ) {
        self.style = style
        self.height = height
        self.cornerRadius = cornerRadius
        self.onSuccess = onSuccess
    }

    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                handleResult(result)
            }
        )
        .signInWithAppleButtonStyle(style)
        .frame(height: height)
        .cornerRadius(cornerRadius)
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Check if guest has valid preferences to convert
                let wasGuestWithPreferences = authService.isGuestMode &&
                                              GuestPreferencesStore.shared.hasValidPreferences

                Task {
                    // Sign in first
                    await authService.signInWithApple(credential: credential)

                    // Convert guest data if they had preferences
                    if wasGuestWithPreferences {
                        await authService.convertGuestToAuthenticatedUser()
                    } else if authService.isGuestMode {
                        // Guest without preferences - just exit guest mode
                        authService.exitGuestMode()
                    }

                    await MainActor.run {
                        // Navigate to For You tab after sign-in
                        appCoordinator.selectedTab = .homeFeed
                        onSuccess?()
                    }
                }
            }
        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled, .unknown:
                    // User cancelled, do nothing
                    return
                default:
                    authService.error = error.localizedDescription
                }
            } else {
                authService.error = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignInWithAppleButtonView()
        .padding()
        .environmentObject(AuthenticationService(notificationService: NotificationService()))
        .environmentObject(AppCoordinator())
}
