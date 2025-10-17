import Foundation
import CoreLocation

enum GeocodingError: Error, LocalizedError {
    case invalidAddress
    case noResults
    case geocodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Invalid address"
        case .noResults:
            return "Could not find coordinates for this location"
        case .geocodingError(let error):
            return "Geocoding error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class GeocodingService {
    private let geocoder = CLGeocoder()

    /// Geocode a UK address or postcode to get coordinates
    /// Uses Apple's CoreLocation which handles both full addresses and postcodes
    /// - Parameter address: The address or postcode to geocode
    /// - Returns: Tuple of (latitude, longitude)
    /// - Throws: GeocodingError if geocoding fails
    func geocode(_ address: String) async throws -> (latitude: Double, longitude: Double) {
        guard !address.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw GeocodingError.invalidAddress
        }

        do {
            // Use CLGeocoder to geocode the addressx
            // This works well for UK addresses, postcodes, and partial addresses
            let placemarks = try await geocoder.geocodeAddressString(address)

            guard let location = placemarks.first?.location else {
                throw GeocodingError.noResults
            }

            return (location.coordinate.latitude, location.coordinate.longitude)

        } catch let error as GeocodingError {
            throw error
        } catch {
            throw GeocodingError.geocodingError(error)
        }
    }
}
