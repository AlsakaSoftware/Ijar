import SwiftUI

// Wrapper to make Property identifiable for sheet(item:)
struct PropertySheetItem: Identifiable {
    let id: String
    let property: Property

    init(_ property: Property) {
        self.id = property.id
        self.property = property
    }
}

// Modifier for list views where property selection triggers the sheet
struct GroupPickerModifier: ViewModifier {
    let propertyService: PropertyService
    @Binding var selectedProperty: Property?
    var onUnsave: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @State private var selectedGroupIds: [String] = []

    private var sheetItem: Binding<PropertySheetItem?> {
        Binding(
            get: { selectedProperty.map { PropertySheetItem($0) } },
            set: { newValue in
                if newValue == nil {
                    selectedProperty = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: sheetItem) { item in
                GroupPickerSheet(
                    property: item.property,
                    propertyService: propertyService,
                    selectedGroupIds: $selectedGroupIds,
                    onDismiss: {
                        selectedProperty = nil
                        onDismiss?()
                    },
                    onUnsave: {
                        onUnsave?()
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
    }
}

// Modifier for detail views where property is already known
struct GroupPickerPresentedModifier: ViewModifier {
    let property: Property
    let propertyService: PropertyService
    @Binding var isPresented: Bool
    var onUnsave: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @State private var selectedGroupIds: [String] = []

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                GroupPickerSheet(
                    property: property,
                    propertyService: propertyService,
                    selectedGroupIds: $selectedGroupIds,
                    onDismiss: {
                        isPresented = false
                        onDismiss?()
                    },
                    onUnsave: {
                        onUnsave?()
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    /// For list views - pass a selected property binding
    func groupPicker(
        propertyService: PropertyService,
        selectedProperty: Binding<Property?>,
        onUnsave: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(GroupPickerModifier(
            propertyService: propertyService,
            selectedProperty: selectedProperty,
            onUnsave: onUnsave,
            onDismiss: onDismiss
        ))
    }

    /// For detail views - pass a known property and isPresented binding
    func groupPicker(
        property: Property,
        propertyService: PropertyService,
        isPresented: Binding<Bool>,
        onUnsave: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(GroupPickerPresentedModifier(
            property: property,
            propertyService: propertyService,
            isPresented: isPresented,
            onUnsave: onUnsave,
            onDismiss: onDismiss
        ))
    }
}
