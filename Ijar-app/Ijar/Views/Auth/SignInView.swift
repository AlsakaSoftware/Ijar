import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        ZStack {
            Color.warmCream
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "house.lodge.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.sunsetGradient)
                    
                    Text("SupHomey")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.coffeeBean)
                    
                    Text("Find your perfect home")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.8))
                }
                
                Spacer()
                
                // Sign in section
                VStack(spacing: 24) {
                    Text("Welcome to SupHomey")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.coffeeBean)
                    
                    Text("Sign in to save your favorite properties and get personalized recommendations")
                        .font(.system(size: 16))
                        .foregroundColor(.warmBrown)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Apple Sign In Button
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
                    .frame(height: 50)
                    .cornerRadius(25)
                    .padding(.horizontal, 40)
                    
                    if authService.isLoading {
                        ProgressView()
                            .tint(.rusticOrange)
                    }
                }
                
                Spacer()
                
                // Terms and privacy
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(.system(size: 12))
                        .foregroundColor(.warmBrown.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Handle terms tap
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.rusticOrange)
                        
                        Text("and")
                            .font(.system(size: 12))
                            .foregroundColor(.warmBrown.opacity(0.6))
                        
                        Button("Privacy Policy") {
                            // Handle privacy tap
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.rusticOrange)
                    }
                }
                .padding(.bottom, 30)
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
            authService.error = error.localizedDescription
        }
    }
}

#Preview {
    SignInView()
}