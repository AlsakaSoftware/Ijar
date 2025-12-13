import SwiftUI

enum GuestSignUpAction {
    case save
    case pass
    case areas

    var title: String {
        switch self {
        case .save: return "Save this property"
        case .areas: return "Manage your searches"
        case .pass: return "Keep swiping"
        }
    }

    var subtitle: String {
        switch self {
        case .save:
            return "Create a free account to save properties you love and get notified when new matches are found."
        case .areas:
            return "Create a free account to save multiple search areas and get notified of new matches."
        case .pass:
            return "Create a free account to track your preferences and get personalized recommendations."
        }
    }
}

struct GuestSignUpPromptSheet: View {
    @EnvironmentObject var authService: AuthenticationService

    let action: GuestSignUpAction
    let onDismiss: () -> Void

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Title and subtitle
                VStack(alignment: .leading, spacing: 12) {
                    Text(action.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.coffeeBean)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 15)

                    Text(action.subtitle)
                        .font(.system(size: 17))
                        .foregroundColor(.warmBrown.opacity(0.7))
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 15)
                }
                .padding(.horizontal, 24)

                // Benefits
                VStack(alignment: .leading, spacing: 14) {
                    GuestBenefitRow(icon: "heart.fill", text: "Save your favorite properties")
                    GuestBenefitRow(icon: "bell.fill", text: "Get notified of new matches")
                    GuestBenefitRow(icon: "sparkles", text: "Personalized recommendations")
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

                Spacer()
            }

            // Buttons
            VStack(spacing: 12) {
                SignInWithAppleButtonView {
                    onDismiss()
                }
                .padding(.horizontal, 24)

                Button(action: onDismiss) {
                    Text("Keep browsing")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.warmBrown)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .opacity(showContent ? 1 : 0)
        }
        .background(Color.warmCream)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                showContent = true
            }
        }
    }
}

#Preview {
    GuestSignUpPromptSheet(
        action: .save,
        onDismiss: { }
    )
    .environmentObject(AuthenticationService(notificationService: NotificationService()))
}
