import SwiftUI

struct PropertyCardView: View {
    let queryProperty: QueryProperty
    
    var property: Property? {
        queryProperty.property
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Property Image
                if let imageUrl = property?.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure(_):
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.2))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.2))
                }
                
                // Property Details Overlay
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(property?.price ?? "Price on request")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Label("\(property?.bedrooms ?? 0)", systemImage: "bed.double")
                            Label("\(property?.bathrooms ?? 0)", systemImage: "shower")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }
                    
                    Text(property?.address ?? "")
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .cornerRadius(20)
            .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 50)
    }
}