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

enum BrowseDestination: NavigationDestination {
    case searchResults(params: BrowseSearchParams)
    case propertyDetail(property: Property, isSaved: Bool)

    static func == (lhs: BrowseDestination, rhs: BrowseDestination) -> Bool {
        switch (lhs, rhs) {
        case let (.searchResults(lhsParams), .searchResults(rhsParams)):
            return lhsParams == rhsParams
        case let (.propertyDetail(lhsProperty, _), .propertyDetail(rhsProperty, _)):
            return lhsProperty.id == rhsProperty.id
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .searchResults(let params):
            hasher.combine("searchResults")
            hasher.combine(params)
        case .propertyDetail(let property, _):
            hasher.combine("propertyDetail")
            hasher.combine(property.id)
        }
    }
}

enum AppDestination: NavigationDestination {
    case homeFeed
    case savedProperties
    case browse
    case profile
}