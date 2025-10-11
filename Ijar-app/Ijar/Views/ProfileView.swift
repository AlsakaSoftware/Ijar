import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: ProfileCoordinator
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        VStack(spacing: 30) {
            // Main actions
            VStack(spacing: 0) {
                ProfileMenuRow(
                    icon: "magnifyingglass.circle.fill",
                    title: "Areas I'm Exploring",
                    subtitle: "Manage the neighborhoods you're searching",
                    action: {
                        coordinator.navigate(to: .searchQueries)
                    }
                )

                Divider()
                    .padding(.leading, 60)

                ProfileMenuRow(
                    icon: "mappin.circle.fill",
                    title: "Places That Matter",
                    subtitle: "Your work, gym, and other important spots",
                    action: {
                        coordinator.navigate(to: .savedLocations)
                    }
                )
            }
            .background(Color.warmCream)
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()

            // Sign out button
            Button(action: {
                Task {
                    await authService.signOut()
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.warmRed)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color.warmRed, lineWidth: 1)
                )
            }
            .padding(.bottom, 30)

            if authService.isLoading {
                ProgressView()
                    .tint(.rusticOrange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream.opacity(0.3))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.rusticOrange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.coffeeBean)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.warmBrown.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.warmBrown.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    let notificationService = NotificationService()
    return ProfileView()
        .environmentObject(ProfileCoordinator())
        .environmentObject(AuthenticationService(notificationService: notificationService))
        .environmentObject(notificationService)
}
