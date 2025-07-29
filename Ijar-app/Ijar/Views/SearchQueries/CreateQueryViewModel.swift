import SwiftUI
import Supabase

struct SearchQueryRequest: Codable {
    let userId: String
    let name: String
    let locationName: String
    let locationId: String
    let minPrice: Int
    let maxPrice: Int
    let minBedrooms: Int
    let maxBedrooms: Int
    let minBathrooms: Int
    let furnishedType: String
    let propertyType: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case locationName = "location_name"
        case locationId = "location_id"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case minBedrooms = "min_bedrooms"
        case maxBedrooms = "max_bedrooms"
        case minBathrooms = "min_bathrooms"
        case furnishedType = "furnished_type"
        case propertyType = "property_type"
        case isActive = "is_active"
    }
}

class CreateQueryViewModel: ObservableObject {
    @Published var name = ""
    @Published var selectedLocation: Location?
    @Published var customLocationName = ""
    @Published var customLocationId = ""
    @Published var minPrice: Double = 500
    @Published var maxPrice: Double = 3500
    @Published var minBedrooms = 1
    @Published var maxBedrooms = 3
    @Published var minBathrooms = 1
    @Published var furnishedType: FurnishedType = .any
    @Published var propertyType: PropertyType = .any
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showLocationIdHelp = false
    
    var navigationCoordinator: NavigationCoordinator?
    private let supabase = SupabaseManager.shared.client
    private let editingQuery: SearchQuery?
    
    var isEditing: Bool {
        editingQuery != nil
    }
    
    var isValid: Bool {
        !name.isEmpty &&
        (selectedLocation != nil || (!customLocationName.isEmpty && !customLocationId.isEmpty)) &&
        minPrice <= maxPrice &&
        minBedrooms <= maxBedrooms
    }
    
    var locationName: String {
        if selectedLocation?.id == Location.customLocation.id {
            return customLocationName
        }
        return selectedLocation?.name ?? ""
    }
    
    var locationId: String {
        if selectedLocation?.id == Location.customLocation.id {
            return customLocationId
        }
        return selectedLocation?.locationId ?? ""
    }
    
    init(editingQuery: SearchQuery? = nil) {
        self.editingQuery = editingQuery
        
        if let query = editingQuery {
            self.name = query.name
            self.minPrice = Double(query.minPrice ?? 500)
            self.maxPrice = Double(query.maxPrice ?? 3500)
            self.minBedrooms = query.minBedrooms ?? 1
            self.maxBedrooms = query.maxBedrooms ?? 3
            self.minBathrooms = query.minBathrooms ?? 1
            self.furnishedType = query.furnishedType ?? .any
            self.propertyType = query.propertyType ?? .any
            
            // Find matching location or set as custom
            if let preset = Location.presetLocations.first(where: { $0.locationId == query.locationId }) {
                self.selectedLocation = preset
            } else {
                self.selectedLocation = Location.customLocation
                self.customLocationName = query.locationName
                self.customLocationId = query.locationId
            }
        }
    }
    
    func save() {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                let query = SearchQueryRequest(
                    userId: userId.uuidString,
                    name: name,
                    locationName: locationName,
                    locationId: locationId,
                    minPrice: Int(minPrice),
                    maxPrice: Int(maxPrice),
                    minBedrooms: minBedrooms,
                    maxBedrooms: maxBedrooms,
                    minBathrooms: minBathrooms,
                    furnishedType: furnishedType.rawValue,
                    propertyType: propertyType.rawValue,
                    isActive: true
                )
                
                if let editingQuery = editingQuery {
                    try await supabase
                        .from("search_queries")
                        .update(query)
                        .eq("id", value: editingQuery.id)
                        .execute()
                    
                    await MainActor.run {
                        self.isLoading = false
                        self.navigationCoordinator?.pop()
                    }
                } else {
                    try await supabase
                        .from("search_queries")
                        .insert(query)
                        .execute()
                    
                    await MainActor.run {
                        self.isLoading = false
                        self.navigationCoordinator?.pop()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to save search query"
                }
            }
        }
    }
}
