import SwiftUI

struct SavedPropertiesView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    
    var body: some View {
        VStack {
            Text("Saved Properties")
                .font(.largeTitle)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}