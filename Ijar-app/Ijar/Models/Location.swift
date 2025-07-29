import Foundation

struct Location: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let locationId: String
    
    var displayName: String {
        return name
    }
}

// Predefined locations for MVP
extension Location {
    static let presetLocations: [Location] = [
        Location(id: "1", name: "Canary Wharf", locationId: "STATION%5E1724"),
        Location(id: "2", name: "London Bridge", locationId: "STATION%5E5792"),
        Location(id: "3", name: "Canning Town", locationId: "REGION%5E70412"),
        Location(id: "4", name: "Mile End", locationId: "REGION%5E85206"),
        Location(id: "5", name: "Stratford", locationId: "REGION%5E85313"),
        Location(id: "6", name: "Liverpool Street", locationId: "STATION%5E5664"),
        Location(id: "7", name: "Shoreditch", locationId: "REGION%5E87515"),
        Location(id: "8", name: "Hackney", locationId: "REGION%5E5294"),
        Location(id: "9", name: "Bethnal Green", locationId: "REGION%5E66749"),
        Location(id: "10", name: "Whitechapel", locationId: "REGION%5E87543")
    ]
    
    static let customLocation = Location(id: "custom", name: "Other...", locationId: "")
}