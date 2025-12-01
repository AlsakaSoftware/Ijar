import Foundation

struct Property: Identifiable {
    let id: String
    let images: [String]
    let price: String
    let bedrooms: Int
    let bathrooms: Int
    let address: String
    let area: String
    let rightmoveUrl: String?
    let agentPhone: String?
    let agentName: String?
    let branchName: String?
    let latitude: Double?
    let longitude: Double?

    // Property details (fetched on-demand)
    var description: String?
    var keyFeatures: [String]?
    var propertyType: String?
    var floorArea: String?
    var epcRating: String?
    var councilTaxBand: String?
    var tenure: String?
    var listingDate: String?
    var availableFrom: String?
    var floorplanImages: [String]?

    /// Returns "Studio" if bedrooms is 0, otherwise returns the number as a string
    var bedroomText: String {
        bedrooms == 0 ? "Studio" : "\(bedrooms)"
    }

    init(id: String = UUID().uuidString, images: [String], price: String, bedrooms: Int, bathrooms: Int, address: String, area: String, rightmoveUrl: String? = nil, agentPhone: String? = nil, agentName: String? = nil, branchName: String? = nil, latitude: Double? = nil, longitude: Double? = nil, description: String? = nil, keyFeatures: [String]? = nil, propertyType: String? = nil, floorArea: String? = nil, epcRating: String? = nil, councilTaxBand: String? = nil, tenure: String? = nil, listingDate: String? = nil, availableFrom: String? = nil, floorplanImages: [String]? = nil) {
        self.id = id
        self.images = images
        self.price = price
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.address = address
        self.area = area
        self.rightmoveUrl = rightmoveUrl
        self.agentPhone = agentPhone
        self.agentName = agentName
        self.branchName = branchName
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.keyFeatures = keyFeatures
        self.propertyType = propertyType
        self.floorArea = floorArea
        self.epcRating = epcRating
        self.councilTaxBand = councilTaxBand
        self.tenure = tenure
        self.listingDate = listingDate
        self.availableFrom = availableFrom
        self.floorplanImages = floorplanImages
    }
}