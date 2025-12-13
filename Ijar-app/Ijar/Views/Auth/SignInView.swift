import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Background
            Color.warmCream
                .ignoresSafeArea()

            // Subtle gradient wash
            LinearGradient(
                colors: [
                    Color.warmCream,
                    Color.rusticOrange.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Logo + Name at top
                HStack(spacing: 0) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)

                    Text("SupHomey")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.coffeeBean)
                }
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Slogan slightly above center
                VStack(spacing: 8) {
                    Text("We fixed Renting.")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.coffeeBean)

                    Text("You're welcome.")
                        .font(.system(size: 34, weight: .regular))
                        .foregroundColor(.warmBrown)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

                Spacer()
                Spacer()

                // Bottom section
                VStack(spacing: 16) {
                    Text("By tapping 'Sign in with Apple', you agree to our Terms of Service and Privacy Policy.")
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    SignInWithAppleButtonView()

                    Button {
                        authService.continueAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.warmBrown)
                    }
                    .padding(.top, 4)

                    if authService.isLoading {
                        ProgressView()
                            .tint(.rusticOrange)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
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
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationService(notificationService: NotificationService()))
}
