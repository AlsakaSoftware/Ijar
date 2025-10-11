import Foundation

enum TfLJourneyError: Error, LocalizedError {
    case invalidCoordinates
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingFailed
    case networkError(Error)
    case noJourneyFound

    var errorDescription: String? {
        switch self {
        case .invalidCoordinates:
            return "Invalid coordinates"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server returned error: \(code)"
        case .decodingFailed:
            return "Failed to parse response"
        case .networkError(let error):
            return "Unable to fetch journey: \(error.localizedDescription)"
        case .noJourneyFound:
            return "No journey found"
        }
    }
}

@MainActor
class TfLJourneyService {
    private let baseURL = "https://api.tfl.gov.uk/Journey/JourneyResults"

    /// Fetch journey details between two locations
    /// - Parameters:
    ///   - fromLat: Starting latitude
    ///   - fromLon: Starting longitude
    ///   - toLat: Destination latitude
    ///   - toLon: Destination longitude
    ///   - mode: Transport mode preference (rail, bus, or all)
    /// - Returns: Journey with legs and duration
    /// - Throws: TfLJourneyError if the request fails
    func fetchJourney(fromLat: Double, fromLon: Double, toLat: Double, toLon: Double, mode: TransportMode = .rail) async throws -> Journey {
        // Format coordinates for TfL API
        let from = "\(fromLat),\(fromLon)"
        let to = "\(toLat),\(toLon)"

        guard let encodedFrom = from.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedTo = to.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw TfLJourneyError.invalidCoordinates
        }

        // Build URL with query parameters
        // Set time to 8 AM to get consistent journey times during normal service hours
        var components = URLComponents(string: "\(baseURL)/\(encodedFrom)/to/\(encodedTo)")!
        components.queryItems = [
            URLQueryItem(name: "mode", value: mode.tflModes),
            URLQueryItem(name: "journeyPreference", value: "leastinterchange"),
            URLQueryItem(name: "time", value: "0800")  // 8 AM
        ]

        guard let url = components.url else {
            throw TfLJourneyError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TfLJourneyError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw TfLJourneyError.serverError(httpResponse.statusCode)
            }

#if DEBUG
            print("🚇 TfLJourneyService: Received response with \(data.count) bytes")
#endif

            let decoder = JSONDecoder()
            let tflResponse = try decoder.decode(TfLJourneyResponse.self, from: data)

            guard let journeys = tflResponse.journeys, !journeys.isEmpty else {
                throw TfLJourneyError.noJourneyFound
            }

#if DEBUG
            print("\n🚇 TfLJourneyService: Found \(journeys.count) journey options:")
            for (index, journey) in journeys.enumerated() {
                let modes = journey.legs.map { leg in
                    let mode = leg.mode.name
                    let route = leg.routeOptions?.first?.name ?? ""
                    return route.isEmpty ? mode : "\(mode)(\(route))"
                }.joined(separator: " → ")
                print("   [\(index + 1)] \(journey.duration) min: \(modes)")
            }
#endif

            // Find the journey with the shortest duration
            guard let fastestJourney = journeys.min(by: { $0.duration < $1.duration }) else {
                throw TfLJourneyError.noJourneyFound
            }

#if DEBUG
            print("   ✅ Selected fastest: \(fastestJourney.duration) min\n")
#endif

            // Convert TfL journey to our Journey model
            let legs = fastestJourney.legs.map { leg -> JourneyLeg in
                let modeName = leg.mode.name.lowercased()
                let routeName = leg.routeOptions?.first?.name ?? ""
                let instruction = leg.instruction?.summary ?? leg.instruction?.detailed ?? ""

                // Extract line name for display
                var lineName: String? = nil
                if modeName != "walking" {
                    lineName = routeName.isEmpty ? nil : routeName
                }

                // Keep the full instruction which includes direction info
                // e.g., "Central line towards Ealing Broadway"
                let legInstruction = instruction

                return JourneyLeg(
                    duration: leg.duration,
                    instruction: legInstruction,
                    mode: modeName == "walking" ? "walk" : modeName,
                    lineName: lineName
                )
            }

            let journey = Journey(
                duration: fastestJourney.duration,
                legs: legs
            )

#if DEBUG
            print("✅ TfLJourneyService: Journey duration: \(journey.duration) min")
            print("   Legs: \(journey.summary)")
#endif

            return journey

        } catch let decodingError as DecodingError {
#if DEBUG
            print("❌ TfLJourneyService: Decoding error: \(decodingError)")
#endif
            throw TfLJourneyError.decodingFailed
        } catch let error as TfLJourneyError {
            throw error
        } catch {
#if DEBUG
            print("❌ TfLJourneyService: Error fetching journey: \(error)")
#endif
            throw TfLJourneyError.networkError(error)
        }
    }
}
