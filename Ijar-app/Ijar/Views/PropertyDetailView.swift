import SwiftUI

struct PropertyDetailView: View {
    let property: Property
    @State private var currentImageIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Test content to see if modal is working
                Text("Property Details")
                    .font(.largeTitle)
                    .foregroundColor(.coffeeBean)
                
                Text(property.price)
                    .font(.title)
                    .foregroundColor(.rusticOrange)
                
                Text(property.address)
                    .font(.title2)
                    .foregroundColor(.warmBrown)
                
                Text(property.area)
                    .font(.body)
                    .foregroundColor(.warmBrown)
                
                Text("Bedrooms: \(property.bedrooms)")
                Text("Bathrooms: \(property.bathrooms)")
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.warmCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}