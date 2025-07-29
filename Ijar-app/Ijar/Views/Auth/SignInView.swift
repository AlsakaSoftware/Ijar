import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo and App Name
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Ijar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Find your perfect home")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sign In Section
            VStack(spacing: 20) {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                viewModel.handleSignInWithApple(credential: appleIDCredential)
                            }
                        case .failure(let error):
                            viewModel.signInWithAppleErrored(error)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal)
                
                Button(action: {
                    viewModel.showSignUp()
                }) {
                    Text("Don't have an account? Sign up")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.navigationCoordinator = navigationCoordinator
        }
    }
}