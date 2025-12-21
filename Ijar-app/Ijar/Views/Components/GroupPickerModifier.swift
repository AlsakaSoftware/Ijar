import SwiftUI

extension View {
    func groupPickerSheet(
        isPresented: Binding<Bool>,
        property: Property,
        propertyService: PropertyService = PropertyService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) -> some View {
        sheet(isPresented: isPresented) {
            GroupPickerSheet(
                property: property,
                propertyService: propertyService,
                savedPropertyRepository: savedPropertyRepository
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
