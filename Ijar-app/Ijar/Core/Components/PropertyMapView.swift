import SwiftUI
import MapKit

struct PropertyMapView: View {
    let address: String
    let latitude: Double
    let longitude: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Map")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.coffeeBean)

            Map(position: .constant(.region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))) {
                Marker(address, coordinate: CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                ))
                .tint(Color.rusticOrange)
            }
            .allowsHitTesting(false)
            .frame(height: 240)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.coffeeBean.opacity(0.1), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
