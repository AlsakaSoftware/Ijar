import Foundation
import CoreLocation

enum GeocodingError: Error, LocalizedError {
    case invalidAddress
    case noResults
    case networkError
    case notInUK
    case geocodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Invalid address"
        case .noResults:
            return "We couldn't find this area. Please check the spelling."
        case .networkError:
            return "Network error. Please check your connection."
        case .notInUK:
            return "Only UK locations are supported"
        case .geocodingError(let error):
            return "Geocoding error: \(error.localizedDescription)"
        }
    }
}

struct GeocodingResult {
    let postcode: String
    let latitude: Double
    let longitude: Double
    let formattedAddress: String
}

@MainActor
class GeocodingService {
    private let geocoder = CLGeocoder()

    /// Build a formatted address string from placemark components
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        // Add locality (neighborhood/area) if available
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }

        // Add city
        if let locality = placemark.locality {
            // Avoid duplicates
            if !components.contains(locality) {
                components.append(locality)
            }
        }

        // Always add UK at the end
        components.append("UK")

        return components.joined(separator: ", ")
    }

    /// Geocode an area name to get UK postcode
    /// Uses two-step approach: forward geocode, then reverse geocode if needed
    /// - Parameter areaName: The area name (e.g., "Canary Wharf, London")
    /// - Returns: GeocodingResult with postcode and coordinates
    /// - Throws: GeocodingError if geocoding fails
    func geocodeAreaToPostcode(_ areaName: String) async throws -> GeocodingResult {
        let trimmedArea = areaName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedArea.isEmpty else {
            throw GeocodingError.invalidAddress
        }

        // Append UK to improve geocoding accuracy if not already present
        let searchString = trimmedArea.contains(",") ? trimmedArea : "\(trimmedArea), UK"

        do {
            // Step 1: Forward geocode the area name
            let placemarks = try await geocoder.geocodeAddressString(searchString)

            #if DEBUG
            print("🗺️ Geocoding '\(searchString)' returned \(placemarks.count) placemarks")
            for (index, placemark) in placemarks.enumerated() {
                print("  [\(index)] Country: \(placemark.isoCountryCode ?? "nil"), Postcode: \(placemark.postalCode ?? "nil"), Locality: \(placemark.locality ?? "nil")")
            }
            #endif

            // Find first UK placemark
            guard let ukPlacemark = placemarks.first(where: { $0.isoCountryCode == "GB" }) else {
                throw GeocodingError.notInUK
            }

            // If placemark has a postcode, use it directly
            if let geocodedPostcode = ukPlacemark.postalCode,
               let location = ukPlacemark.location {
                let formatted = formatAddress(from: ukPlacemark)
                #if DEBUG
                print("✅ Geocoded to postcode: \(geocodedPostcode), formatted: \(formatted)")
                #endif

                return GeocodingResult(
                    postcode: geocodedPostcode,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    formattedAddress: formatted
                )
            }

            // Step 2: No postcode found, try reverse geocoding from coordinates
            #if DEBUG
            print("📍 No postcode in placemark, trying reverse geocode from coordinates")
            #endif

            guard let location = ukPlacemark.location else {
                throw GeocodingError.noResults
            }

            let reverseGeocodedPlacemarks = try await geocoder.reverseGeocodeLocation(location)

            #if DEBUG
            print("🔄 Reverse geocoding returned \(reverseGeocodedPlacemarks.count) placemarks")
            for (index, placemark) in reverseGeocodedPlacemarks.enumerated() {
                print("  [\(index)] Country: \(placemark.isoCountryCode ?? "nil"), Postcode: \(placemark.postalCode ?? "nil")")
            }
            #endif

            if let reversePlacemark = reverseGeocodedPlacemarks.first,
               let reverseGeocodedPostcode = reversePlacemark.postalCode {
                let formatted = formatAddress(from: reversePlacemark)
                #if DEBUG
                print("✅ Reverse geocoded to postcode: \(reverseGeocodedPostcode), formatted: \(formatted)")
                #endif

                return GeocodingResult(
                    postcode: reverseGeocodedPostcode,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    formattedAddress: formatted
                )
            }

            // If all else fails, throw error
            throw GeocodingError.noResults

        } catch let error as GeocodingError {
            throw error
        } catch {
            let nsError = error as NSError
            if nsError.code == 2 {
                throw GeocodingError.networkError
            }
            throw GeocodingError.geocodingError(error)
        }
    }

    /// Geocode a UK address or postcode to get coordinates (legacy method)
    /// - Parameter address: The address or postcode to geocode
    /// - Returns: Tuple of (latitude, longitude)
    /// - Throws: GeocodingError if geocoding fails
    func geocode(_ address: String) async throws -> (latitude: Double, longitude: Double) {
        guard !address.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw GeocodingError.invalidAddress
        }

        do {
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
