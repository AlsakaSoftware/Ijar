import SwiftUI

enum SearchRadius: Double, CaseIterable, Identifiable {
    case halfMile = 0.5
    case oneMile = 1.0
    case threeMiles = 3.0
    case fiveMiles = 5.0
    case tenMiles = 10.0
    case fifteenMiles = 15.0
    case twentyMiles = 20.0
    case thirtyMiles = 30.0
    case fortyMiles = 40.0

    var id: Double { rawValue }

    var displayText: String {
        switch self {
        case .halfMile: return "Within 1/2 mile"
        case .oneMile: return "Within 1 mile"
        case .threeMiles: return "Within 3 miles"
        case .fiveMiles: return "Within 5 miles"
        case .tenMiles: return "Within 10 miles"
        case .fifteenMiles: return "Within 15 miles"
        case .twentyMiles: return "Within 20 miles"
        case .thirtyMiles: return "Within 30 miles"
        case .fortyMiles: return "Within 40 miles"
        }
    }
}

struct CreateSearchQueryView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (SearchQuery) -> Void
    
    @State private var name = ""
    @State private var postcode = ""
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
    @State private var selectedRadius: SearchRadius = .oneMile
    @State private var selectedFurnishType = "Any"

    private let furnishOptions = ["Any", "Furnished", "Unfurnished"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Name & Location") {
                    TextField("e.g., Canary Wharf 2-bed", text: $name)

                    TextField("Postcode (e.g., E14 6FT)", text: $postcode)
                        .textContentType(.postalCode)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
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
                    Picker("Search Radius", selection: $selectedRadius) {
                        ForEach(SearchRadius.allCases) { radiusOption in
                            Text(radiusOption.displayText).tag(radiusOption)
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
            .navigationTitle("New Search")
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
            // No need to set default values for postcode
        }
    }
    
    private var isValidForm: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveQuery() {
        let query = SearchQuery(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            postcode: postcode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            minPrice: minPrice,
            maxPrice: maxPrice,
            minBedrooms: minBedrooms,
            maxBedrooms: maxBedrooms,
            minBathrooms: minBathrooms,
            maxBathrooms: maxBathrooms,
            radius: selectedRadius.rawValue,
            furnishType: furnishType
        )

        onSave(query)
        dismiss()
    }
}


