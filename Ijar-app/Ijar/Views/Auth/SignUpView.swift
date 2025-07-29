import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Header
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start finding your dream home")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sign Up Section
            VStack(spacing: 20) {
                SignInWithAppleButton(
                    .signUp,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                viewModel.handleSignUpWithApple(credential: appleIDCredential)
                            }
                        case .failure(let error):
                            viewModel.signUpWithAppleErrored(error)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal)
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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.navigationCoordinator = navigationCoordinator
        }
    }
}