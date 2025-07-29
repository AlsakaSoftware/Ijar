import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(viewModel.user?.fullName ?? "User")
                            .font(.headline)
                        
                        Text(viewModel.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Section("Settings") {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.blue)
                    Text("Notifications")
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)
                    Text("Help & Support")
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("About") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundColor(.blue)
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: viewModel.logout) {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.navigationCoordinator = navigationCoordinator
        }
    }
}