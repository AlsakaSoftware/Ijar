import SwiftUI

extension View {
    func groupPickerSheet(
        isPresented: Binding<Bool>,
        property: Property,
        propertyGroupService: PropertyGroupService = PropertyGroupService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) -> some View {
        sheet(isPresented: isPresented) {
            GroupPickerSheet(
                property: property,
                propertyGroupService: propertyGroupService,
                savedPropertyRepository: savedPropertyRepository
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
