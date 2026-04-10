import Foundation

enum TransportMode: String, CaseIterable, Identifiable {
    case rail = "Rail Only"
    case bus = "Bus Only"
    case all = "All Transport"

    var id: String { rawValue }

    var tflModes: String {
        switch self {
        case .rail:
            return "tube,dlr,overground,elizabeth-line,national-rail,walking"
        case .bus:
            return "bus,walking"
        case .all:
            return "tube,dlr,overground,elizabeth-line,national-rail,bus,walking"
        }
    }
}

struct Journey: Codable {
    let duration: Int  // in minutes
    let legs: [JourneyLeg]

    var formattedDuration: String {
        "\(duration) min"
    }

    var summary: String {
        legs.map { $0.summary }.joined(separator: " → ")
    }
}

struct JourneyLeg: Codable {
    let duration: Int  // in minutes
    let instruction: String
    let mode: String  // walk, tube, bus, dlr, etc.
    let lineName: String?  // e.g., "Jubilee", "Central", "277"

    var summary: String {
        if let lineName = lineName, !lineName.isEmpty {
            return "\(duration) min \(lineName)"
        } else {
            return "\(duration) min \(mode)"
        }
    }

    var icon: String {
        switch mode.lowercased() {
        case "walking", "walk":
            return "figure.walk"
        case "bus":
            return "bus.fill"
        case "tube", "underground":
            return "tram.fill"
        case "dlr":
            return "tram.fill"
        case "overground":
            return "tram.fill"
        case "elizabeth-line":
            return "tram.fill"
        default:
            return "arrow.right"
        }
    }
}

// TfL API Response structures
struct TfLJourneyResponse: Codable {
    let journeys: [TfLJourney]?
}

struct TfLJourney: Codable {
    let duration: Int
    let legs: [TfLJourneyLeg]
}

struct TfLJourneyLeg: Codable {
    let duration: Int
    let mode: TfLMode
    let instruction: TfLInstruction?
    let routeOptions: [TfLRouteOption]?

    struct TfLMode: Codable {
        let name: String
    }

    struct TfLInstruction: Codable {
        let summary: String?
        let detailed: String?
    }

    struct TfLRouteOption: Codable {
        let name: String?
    }
}
