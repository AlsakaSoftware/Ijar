import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var coordinator: ProfileCoordinator
    
    var body: some View {
        VStack {
            Text("Preferences")
                .font(.largeTitle)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}