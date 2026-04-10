import Foundation

struct PropertyFilters: Hashable {
    var minPrice: Int?
    var maxPrice: Int?
    var minBedrooms: Int?
    var maxBedrooms: Int?
    var minBathrooms: Int?
    var maxBathrooms: Int?
    var radius: Double?
    var furnishType: String?

    var activeCount: Int {
        var count = 0
        if minPrice != nil || maxPrice != nil { count += 1 }
        if minBedrooms != nil || maxBedrooms != nil { count += 1 }
        if minBathrooms != nil || maxBathrooms != nil { count += 1 }
        if radius != nil { count += 1 }
        if furnishType != nil { count += 1 }
        return count
    }

    static let empty = PropertyFilters()
}
