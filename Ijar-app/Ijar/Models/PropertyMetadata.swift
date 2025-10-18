import Foundation
import SwiftData

@Model
final class PropertyMetadata {
    @Attribute(.unique) var propertyId: String
    var calledAgent: Bool
    var setViewing: Bool
    var putOffer: Bool
    var notes: String
    var lastUpdated: Date

    init(propertyId: String, calledAgent: Bool = false, setViewing: Bool = false, putOffer: Bool = false, notes: String = "") {
        self.propertyId = propertyId
        self.calledAgent = calledAgent
        self.setViewing = setViewing
        self.putOffer = putOffer
        self.notes = notes
        self.lastUpdated = Date()
    }

    func update(calledAgent: Bool, setViewing: Bool, putOffer: Bool, notes: String) {
        self.calledAgent = calledAgent
        self.setViewing = setViewing
        self.putOffer = putOffer
        self.notes = notes
        self.lastUpdated = Date()
    }
}
