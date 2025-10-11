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

    init(id: String = UUID().uuidString, images: [String], price: String, bedrooms: Int, bathrooms: Int, address: String, area: String, rightmoveUrl: String? = nil, agentPhone: String? = nil, agentName: String? = nil, branchName: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
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
    }
}