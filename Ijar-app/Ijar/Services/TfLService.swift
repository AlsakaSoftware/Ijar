import Foundation

struct NearbyTransportResult {
    let stations: [TubeStation]
    let busStops: [BusStop]
}

enum TfLServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server returned error: \(code)"
        case .decodingFailed:
            return "Failed to parse response"
        case .networkError(let error):
            return "Unable to fetch stations: \(error.localizedDescription)"
        }
    }
}

@MainActor
class TfLService {
    // TfL API endpoint for nearby stop points
    private let baseURL = "https://api.tfl.gov.uk/StopPoint"

    /// Fetch nearby tube/DLR stations and bus stops for a given location
    /// - Parameters:
    ///   - latitude: Property latitude
    ///   - longitude: Property longitude
    ///   - radiusMeters: Search radius in meters (default: 1200m, about 0.75 miles)
    /// - Returns: NearbyTransportResult containing stations and bus stops
    /// - Throws: TfLServiceError if the request fails
    func fetchNearbyStations(latitude: Double, longitude: Double, radiusMeters: Int = 1200) async throws -> NearbyTransportResult {
        // Build URL with query parameters - fetch both rail and bus
        var components = URLComponents(string: "\(baseURL)")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "stopTypes", value: "NaptanMetroStation,NaptanRailStation,NaptanBusCoachStation"), // Tube, DLR, and Bus
            URLQueryItem(name: "radius", value: String(radiusMeters)),
            URLQueryItem(name: "modes", value: "tube,dlr,bus")
        ]

        guard let url = components.url else {
            throw TfLServiceError.invalidURL
        }

#if DEBUG
        print("🚇 TfLService: Fetching nearby stations from: \(url.absoluteString)")
#endif

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TfLServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw TfLServiceError.serverError(httpResponse.statusCode)
            }

#if DEBUG
            print("🚇 TfLService: Received response with \(data.count) bytes")
#endif

            let decoder = JSONDecoder()
            let tflResponse = try decoder.decode(TfLStopPointsResponse.self, from: data)

#if DEBUG
            print("🚇 TfLService: Found \(tflResponse.stopPoints.count) stop points")
#endif

            // Separate rail stations from bus stops
            let stations = tflResponse.stopPoints
                .compactMap { $0.toTubeStation() }
                .sorted { $0.distance < $1.distance }
                .prefix(3)

            let busStops = tflResponse.stopPoints
                .compactMap { $0.toBusStop() }
                .sorted { $0.distance < $1.distance }
                .prefix(3)

            let result = NearbyTransportResult(
                stations: Array(stations),
                busStops: Array(busStops)
            )

#if DEBUG
            print("✅ TfLService: Loaded \(result.stations.count) rail stations, \(result.busStops.count) bus stops")
            for station in result.stations {
                print("   🚇 \(station.name): \(station.distanceInMiles)")
            }
            for stop in result.busStops {
                print("   🚌 \(stop.name): \(stop.distanceInMiles)")
            }
#endif

            return result

        } catch let decodingError as DecodingError {
#if DEBUG
            print("❌ TfLService: Decoding error: \(decodingError)")
#endif
            throw TfLServiceError.decodingFailed
        } catch let error as TfLServiceError {
            throw error
        } catch {
#if DEBUG
            print("❌ TfLService: Error fetching stations: \(error)")
#endif
            throw TfLServiceError.networkError(error)
        }
    }
}
