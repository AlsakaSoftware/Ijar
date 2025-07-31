import SwiftUI

struct PropertyDetailView: View {
    let property: Property
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Property Details")
                    .font(.largeTitle)
                Text(property.address)
                Text(property.price)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}