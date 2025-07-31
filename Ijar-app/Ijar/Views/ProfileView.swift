import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            Text("Profile")
                .font(.largeTitle)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}