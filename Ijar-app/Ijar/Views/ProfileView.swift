import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: ProfileCoordinator
    @EnvironmentObject var authService: AuthenticationService
    @State private var isTriggering = false
    @State private var triggerMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            // User info section
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.rusticOrange.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.rusticOrange)
                    )
                
                VStack(spacing: 4) {
                    Text(authService.user?.email ?? "User")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.coffeeBean)
                    
                    Text("Ijar Member")
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
            }
            .padding(.top, 20)
            
            // Menu options
            VStack(spacing: 0) {
                ProfileMenuRow(
                    icon: "magnifyingglass.circle.fill",
                    title: "My Searches",
                    action: {
                        coordinator.navigate(to: .searchQueries)
                    }
                )
                
                ProfileMenuRow(
                    icon: "heart.fill",
                    title: "Saved Properties",
                    action: {
                        // Navigate to saved properties
                    }
                )
                
                ProfileMenuRow(
                    icon: "gearshape.fill",
                    title: "Preferences",
                    action: {
                        coordinator.navigate(to: .preferences)
                    }
                )
                
                ProfileMenuRow(
                    icon: "person.fill",
                    title: "Edit Profile",
                    action: {
                        coordinator.navigate(to: .editProfile)
                    }
                )
            }
            .background(Color.warmCream)
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
            
            // TEMPORARY: Manual workflow trigger button
            Button(action: {
                Task {
                    await triggerWorkflowManually()
                }
            }) {
                HStack {
                    if isTriggering {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.blue)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text("Run Property Search (Test)")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            .padding(.bottom, 10)
            .disabled(isTriggering)
            
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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .alert("Workflow Trigger", isPresented: .constant(triggerMessage != nil), presenting: triggerMessage) { _ in
            Button("OK") {
                triggerMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }
    
    // TEMPORARY: Function to manually trigger GitHub workflow
    private func triggerWorkflowManually() async {
        isTriggering = true
        
        // Create the workflow dispatch request
        let url = URL(string: "https://api.github.com/repos/karimalsaka/Ijar/dispatches")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get GitHub token from Config.plist
        guard let githubToken = ConfigManager.shared.githubToken else {
            triggerMessage = "⚠️ GitHub token not configured"
            isTriggering = false
            return
        }
        request.setValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
        
        let payload = [
            "event_type": "manual-test-trigger",
            "client_payload": [
                "triggered_from": "ios_app_test_button"
            ]
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    triggerMessage = "✅ Successfully triggered workflow!"
                } else {
                    triggerMessage = "⚠️ Workflow trigger returned status: \(httpResponse.statusCode)"
                }
            }
        } catch {
            triggerMessage = "❌ Failed to trigger workflow: \(error.localizedDescription)"
        }
        
        isTriggering = false
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.rusticOrange)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.coffeeBean)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.warmBrown.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileCoordinator())
        .environmentObject(AuthenticationService())
}