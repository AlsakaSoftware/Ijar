import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var coordinator: ProfileCoordinator
    
    var body: some View {
        VStack {
            Text("Edit Profile")
                .font(.largeTitle)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}