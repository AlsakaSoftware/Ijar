import SwiftUI
import CoreLocation

struct EditSearchQueryView: View {
    @Environment(\.dismiss) private var dismiss
    let query: SearchQuery
    let onSave: (SearchQuery) -> Void
    
    @State private var name = ""
    @State private var areaName = ""
    @State private var postcode = "" // Hidden - populated via geocoding
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

    // Geocoding state
    @State private var isGeocoding = false
    @State private var geocodingError: String?
    @State private var geocodingTask: Task<Void, Never>?

    private let furnishOptions = ["Any", "Furnished", "Unfurnished"]
    private let geocodingService = GeocodingService()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Search Name", text: $name)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("Area (e.g., Canary Wharf, London)", text: $areaName)
                                .textContentType(.fullStreetAddress)
                                .autocapitalization(.words)
                                .onChange(of: areaName) { _, newValue in
                                    geocodeArea(newValue)
                                }

                            if isGeocoding {
                                CircularLoadingView()
                            } else if !postcode.isEmpty && geocodingError == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }

                        if let error = geocodingError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
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
        !areaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        geocodingError == nil
    }

    private func populateFields() {
        name = query.name
        areaName = query.areaName // Pre-populate with existing area name
        postcode = query.postcode
        minPrice = query.minPrice
        maxPrice = query.maxPrice
        minBedrooms = query.minBedrooms
        maxBedrooms = query.maxBedrooms
        minBathrooms = query.minBathrooms
        maxBathrooms = query.maxBathrooms
        radius = query.radius
        furnishType = query.furnishType

        // Update text fields and pickers
        minPriceText = query.minPrice?.description ?? ""
        maxPriceText = query.maxPrice?.description ?? ""
        selectedFurnishType = query.furnishType?.capitalized ?? "Any"

        // Set radius option based on the stored radius value
        if let radiusValue = query.radius,
           let radiusEnum = SearchRadius(rawValue: radiusValue) {
            selectedRadius = radiusEnum
        } else {
            selectedRadius = .oneMile
        }
    }

    private func saveQuery() {
        let updatedQuery = SearchQuery(
            id: query.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            areaName: areaName.trimmingCharacters(in: .whitespacesAndNewlines),
            postcode: postcode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            minPrice: minPrice,
            maxPrice: maxPrice,
            minBedrooms: minBedrooms,
            maxBedrooms: maxBedrooms,
            minBathrooms: minBathrooms,
            maxBathrooms: maxBathrooms,
            radius: selectedRadius.rawValue,
            furnishType: furnishType,
            active: query.active,
            created: query.created,
            updated: Date()
        )

        onSave(updatedQuery)
        dismiss()
    }

    private func geocodeArea(_ area: String) {
        // Cancel previous geocoding task
        geocodingTask?.cancel()

        // Clear previous results
        postcode = ""
        geocodingError = nil

        // Don't geocode empty strings
        let trimmedArea = area.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedArea.isEmpty else {
            return
        }

        // Debounce: wait 0.5 seconds before geocoding
        geocodingTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    isGeocoding = true
                }

                // Use the geocoding service
                let result = try await geocodingService.geocodeAreaToPostcode(trimmedArea)

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    isGeocoding = false
                    postcode = result.postcode
                    geocodingError = nil
                }
            } catch let error as GeocodingError {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    isGeocoding = false
                    postcode = ""
                    geocodingError = error.localizedDescription
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    isGeocoding = false
                    postcode = ""
                    geocodingError = "We couldn't find this area. Please check the spelling."
                }
            }
        }
    }
}

