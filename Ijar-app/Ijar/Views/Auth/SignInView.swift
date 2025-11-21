import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        ZStack {
            // Simple background
            Color.warmCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: 60)

                // Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)

                Spacer()
                    .frame(height: 15)

                // Branding
                VStack(spacing: 5) {
                    Text("SupHomey")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(.coffeeBean)

                    Text("Rightmove went to therapy")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.warmBrown)
                }

                Spacer()
                    .frame(height: 48)

                // Features list
                VStack(alignment: .leading, spacing: 14) {
                        FeatureBullet(text: "Swipe your way to your perfect home")
                        FeatureBullet(text: "See your commute to work, gym, or family at a glance")
                        FeatureBullet(text: "Keep track of where you are with each place")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)

                Spacer()
                    .frame(minHeight: 40)

                // Sign in button
                VStack(spacing: 16) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                await handleSignInWithApple(result: result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .cornerRadius(14)
                    .padding(.horizontal, 40)

                    if authService.isLoading {
                        CircularLoadingView()
                    }
                }

                Spacer()
                    .frame(height: 50)
            }
        }
        .alert("Sign In Error", isPresented: .constant(authService.error != nil)) {
            Button("OK") {
                authService.error = nil
            }
        } message: {
            Text(authService.error ?? "")
        }
    }
    
    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                await authService.signInWithApple(credential: appleIDCredential)
            }
        case .failure(let error):
            // Don't show error if user canceled or dismissed
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled, .unknown:
                    // User canceled or dismissed - do nothing
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

// Feature bullet component
struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.rusticOrange)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.coffeeBean.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationService(notificationService: NotificationService()))
}
