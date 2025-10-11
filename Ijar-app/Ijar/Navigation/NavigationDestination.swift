import Foundation

enum HomeFeedDestination: NavigationDestination {
    case propertyDetail(property: Property)
    
    static func == (lhs: HomeFeedDestination, rhs: HomeFeedDestination) -> Bool {
        switch (lhs, rhs) {
        case let (.propertyDetail(lhsProperty), .propertyDetail(rhsProperty)):
            return lhsProperty.id == rhsProperty.id
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .propertyDetail(let property):
            hasher.combine("propertyDetail")
            hasher.combine(property.id)
        }
    }
}

enum SavedPropertiesDestination: NavigationDestination {
    case propertyDetail(property: Property)
    
    static func == (lhs: SavedPropertiesDestination, rhs: SavedPropertiesDestination) -> Bool {
        switch (lhs, rhs) {
        case let (.propertyDetail(lhsProperty), .propertyDetail(rhsProperty)):
            return lhsProperty.id == rhsProperty.id
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .propertyDetail(let property):
            hasher.combine("propertyDetail")
            hasher.combine(property.id)
        }
    }
}

enum ProfileDestination: NavigationDestination {
    case editProfile
    case preferences
    case searchQueries
    case savedLocations
}

enum AppDestination: NavigationDestination {
    case homeFeed
    case savedProperties
    case profile
}