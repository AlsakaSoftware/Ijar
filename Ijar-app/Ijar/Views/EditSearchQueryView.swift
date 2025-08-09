import SwiftUI

struct EditSearchQueryView: View {
    @Environment(\.dismiss) private var dismiss
    let query: SearchQuery
    let onSave: (SearchQuery) -> Void
    
    @State private var name = ""
    @State private var locationName = ""
    @State private var locationId = ""
    @State private var minPrice: Int? = nil
    @State private var maxPrice: Int? = nil
    @State private var minBedrooms: Int? = nil
    @State private var maxBedrooms: Int? = nil
    @State private var minBathrooms: Int? = nil
    @State private var maxBathrooms: Int? = nil
    @State private var radius: Double? = nil
    @State private var furnishType: String? = nil
    
    // Form state
    @State private var minPriceText = ""
    @State private var maxPriceText = ""
    @State private var radiusText = ""
    @State private var selectedFurnishType = "Any"
    
    private let furnishOptions = ["Any", "Furnished", "Unfurnished"]
    private let locationOptions = [
        ("Canary Wharf", "REGION^87490"),
        ("Mile End", "REGION^61166"),
        ("London Bridge", "REGION^61150"),
        ("Canning Town", "REGION^61024"),
        ("Stratford", "REGION^61315")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Search Name", text: $name)
                    
                    Picker("Location", selection: $locationName) {
                        ForEach(locationOptions, id: \.0) { location in
                            Text(location.0).tag(location.0)
                        }
                    }
                    .onChange(of: locationName) { _, newValue in
                        if let selected = locationOptions.first(where: { $0.0 == newValue }) {
                            locationId = selected.1
                        }
                    }
                }
                
                Section("Price Range (£/month)") {
                    HStack {
                        TextField("Min", text: $minPriceText)
                            .keyboardType(.numberPad)
                            .onChange(of: minPriceText) { _, newValue in
                                minPrice = Int(newValue)
                            }
                        
                        Text("to")
                            .foregroundColor(.gray)
                        
                        TextField("Max", text: $maxPriceText)
                            .keyboardType(.numberPad)
                            .onChange(of: maxPriceText) { _, newValue in
                                maxPrice = Int(newValue)
                            }
                    }
                }
                
                Section("Bedrooms") {
                    HStack {
                        Picker("Min", selection: $minBedrooms) {
                            Text("Any").tag(nil as Int?)
                            ForEach(1...5, id: \.self) { num in
                                Text("\(num)").tag(num as Int?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("to")
                            .foregroundColor(.gray)
                        
                        Picker("Max", selection: $maxBedrooms) {
                            Text("Any").tag(nil as Int?)
                            ForEach(1...5, id: \.self) { num in
                                Text("\(num)").tag(num as Int?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Bathrooms") {
                    HStack {
                        Picker("Min", selection: $minBathrooms) {
                            Text("Any").tag(nil as Int?)
                            ForEach(1...4, id: \.self) { num in
                                Text("\(num)").tag(num as Int?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("to")
                            .foregroundColor(.gray)
                        
                        Picker("Max", selection: $maxBathrooms) {
                            Text("Any").tag(nil as Int?)
                            ForEach(1...4, id: \.self) { num in
                                Text("\(num)").tag(num as Int?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Additional Options") {
                    HStack {
                        Text("Search Radius")
                        Spacer()
                        TextField("Miles", text: $radiusText)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: radiusText) { _, newValue in
                                radius = Double(newValue)
                            }
                    }
                    
                    Picker("Furnish Type", selection: $selectedFurnishType) {
                        ForEach(furnishOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .onChange(of: selectedFurnishType) { _, newValue in
                        furnishType = newValue == "Any" ? nil : newValue.lowercased()
                    }
                }
            }
            .navigationTitle("Edit Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveQuery()
                    }
                    .disabled(!isValidForm)
                }
            }
        }
        .onAppear {
            populateFields()
        }
    }
    
    private var isValidForm: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !locationName.isEmpty &&
        !locationId.isEmpty
    }
    
    private func populateFields() {
        name = query.name
        locationName = query.locationName
        locationId = query.locationId
        minPrice = query.minPrice
        maxPrice = query.maxPrice
        minBedrooms = query.minBedrooms
        maxBedrooms = query.maxBedrooms
        minBathrooms = query.minBathrooms
        maxBathrooms = query.maxBathrooms
        radius = query.radius
        furnishType = query.furnishType
        
        // Update text fields
        minPriceText = query.minPrice?.description ?? ""
        maxPriceText = query.maxPrice?.description ?? ""
        radiusText = query.radius?.description ?? ""
        selectedFurnishType = query.furnishType?.capitalized ?? "Any"
    }
    
    private func saveQuery() {
        let updatedQuery = SearchQuery(
            id: query.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            locationId: locationId,
            locationName: locationName,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minBedrooms: minBedrooms,
            maxBedrooms: maxBedrooms,
            minBathrooms: minBathrooms,
            maxBathrooms: maxBathrooms,
            radius: radius,
            furnishType: furnishType,
            active: query.active,
            created: query.created,
            updated: Date()
        )
        
        onSave(updatedQuery)
        dismiss()
    }
}

