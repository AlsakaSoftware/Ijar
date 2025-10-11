import Foundation

struct TubeStation: Identifiable, Codable {
    let id: String
    let name: String
    let distance: Double // in meters
    let lines: [String]
    let latitude: Double
    let longitude: Double

    var distanceInMiles: String {
        let miles = distance * 0.000621371
        return String(format: "%.1f mi", miles)
    }

    var distanceInMinutes: String {
        // Assume average walking speed of 3.1 mph (5 km/h)
        let miles = distance * 0.000621371
        let minutes = Int(ceil((miles / 3.1) * 60))
        let finalMinutes = max(1, minutes) // Ensure minimum of 1 minute
        return "\(finalMinutes) min walk"
    }

    // Only rail lines (no bus routes for rail stations)
    var railLines: [String] {
        lines.filter { !$0.allSatisfy { $0.isNumber } }
    }
}

struct BusStop: Identifiable, Codable {
    let id: String
    let name: String
    let distance: Double // in meters
    let routes: [String]
    let latitude: Double
    let longitude: Double

    var distanceInMiles: String {
        let miles = distance * 0.000621371
        return String(format: "%.1f mi", miles)
    }

    var distanceInMinutes: String {
        let miles = distance * 0.000621371
        let minutes = Int(ceil((miles / 3.1) * 60))
        let finalMinutes = max(1, minutes) // Ensure minimum of 1 minute
        return "\(finalMinutes) min walk"
    }
}

// Response from TfL API
struct TfLStopPointsResponse: Codable {
    let stopPoints: [TfLStopPoint]
}

struct TfLStopPoint: Codable {
    let id: String
    let commonName: String
    let distance: Double
    let lat: Double
    let lon: Double
    let modes: [String]
    let lines: [TfLLine]?

    func toTubeStation() -> TubeStation? {
        // Include all rail stations: tube, DLR, Overground, Elizabeth Line, and National Rail
        let railModes = ["tube", "dlr", "overground", "elizabeth-line", "national-rail"]
        guard modes.contains(where: { railModes.contains($0) }) else { return nil }

        // Only include non-bus lines for rail stations
        let railLines = lines?.filter { line in
            !line.name.allSatisfy { $0.isNumber }
        }.map { $0.name } ?? []

        return TubeStation(
            id: id,
            name: commonName,
            distance: distance,
            lines: railLines,
            latitude: lat,
            longitude: lon
        )
    }

    func toBusStop() -> BusStop? {
        // Only bus stops
        guard modes.contains("bus") else { return nil }

        // Only include numeric bus routes
        let busRoutes = lines?.filter { line in
            line.name.allSatisfy { $0.isNumber }
        }.map { $0.name } ?? []

        guard !busRoutes.isEmpty else { return nil }

        return BusStop(
            id: id,
            name: commonName,
            distance: distance,
            routes: busRoutes,
            latitude: lat,
            longitude: lon
        )
    }
}

struct TfLLine: Codable {
    let id: String
    let name: String
}
