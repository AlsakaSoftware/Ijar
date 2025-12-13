import SwiftUI

struct OnboardingNotificationsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var notificationService: NotificationService

    @State private var isRequesting = false
    @State private var showContent = false
    @State private var bellBounce = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 28) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stay in the know")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.coffeeBean)

                    Text("We'll send you new listings as we find them.")
                        .font(.system(size: 17))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

                // Bell icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.rusticOrange.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.rusticOrange, .warmRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(bellBounce ? 10 : -10))
                        .animation(
                            .easeInOut(duration: 0.12)
                            .repeatCount(6, autoreverses: true),
                            value: bellBounce
                        )
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                .padding(.vertical, 8)

                // Benefits
                VStack(spacing: 14) {
                    benefitRow(icon: "bolt.fill", text: "Get there before everyone else")
                    benefitRow(icon: "heart.fill", text: "Only homes that match your search")
                    benefitRow(icon: "moon.zzz.fill", text: "A few times a day, max")
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

                Spacer()
            }

            // Buttons
            VStack(spacing: 12) {
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

                Button {
                    viewModel.goToNextStep()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.6))
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.warmCream)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bellBounce = true
            }
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.rusticOrange)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.coffeeBean)

            Spacer()
        }
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
