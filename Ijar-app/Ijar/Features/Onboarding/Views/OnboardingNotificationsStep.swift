import SwiftUI

struct OnboardingNotificationsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var notificationService: NotificationService

    @State private var isRequesting = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stay in the know")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.coffeeBean)

                    Text("We'll send you new listings as we find them")
                        .font(.system(size: 17))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 25)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

                // Benefits
                VStack(spacing: 14) {
                    benefitRow(text: "Get there before everyone else")
                    benefitRow(text: "Only homes that match your search")
                    benefitRow(text: "A few times a day, max")
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }

            Spacer()

            // Buttons
            VStack(spacing: 8) {
                Button {
                    viewModel.goToNextStep()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.6))
                        .padding(.vertical, 8)
                }
                
                Button {
                    Task {
                        await enableNotifications()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        }
                        Text("Enable Notifications")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.rusticOrange)
                    )
                }
                .disabled(isRequesting)

            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.warmCream)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
    }

    private func benefitRow(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.rusticOrange)

            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.coffeeBean)

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.rusticOrange.opacity(0.08))
        .cornerRadius(12)
    }

    private func enableNotifications() async {
        isRequesting = true
        let granted = await notificationService.requestNotificationPermission()
        isRequesting = false

        if granted {
            if let tokenData = UserDefaults.standard.data(forKey: "deviceToken"),
               let userId = UserDefaults.standard.string(forKey: "currentUserId") {
                await notificationService.saveDeviceToken(tokenData, for: userId)
            }
        }

        viewModel.goToNextStep()
    }
}

#Preview {
    OnboardingNotificationsStep(viewModel: OnboardingViewModel())
        .environmentObject(NotificationService())
        .background(Color.warmCream)
}
