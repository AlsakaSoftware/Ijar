import SwiftUI
import CoreLocation

struct EditSearchQueryView: View {
    @Environment(\.dismiss) private var dismiss
    let query: SearchQuery
    let onSave: (SearchQuery) -> Void

    @State private var name = ""
    @State private var areaName = ""
    @State private var postcode = ""
    @State private var minPrice: Int? = nil
    @State private var maxPrice: Int? = nil
    @State private var minBedrooms: Int? = nil
    @State private var maxBedrooms: Int? = nil
    @State private var minBathrooms: Int? = nil
    @State private var maxBathrooms: Int? = nil
    @State private var radius: Double? = nil
    @State private var furnishType: String? = nil

    // Geocoding state
    @State private var isGeocoding = false
    @State private var geocodingError: String?
    @State private var geocodingTask: Task<Void, Never>?

    private let geocodingService = GeocodingService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Name & Location section
                    FilterSection(title: "Name & Location") {
                        VStack(spacing: 12) {
                            // Name field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Search name")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)
                                TextField("e.g., Canary Wharf 2-bed", text: $name)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            // Area field with geocoding
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Area")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)
                                HStack {
                                    TextField("e.g., Canary Wharf, London", text: $areaName)
                                        .textContentType(.fullStreetAddress)
                                        .autocapitalization(.words)
                                        .onChange(of: areaName) { _, newValue in
                                            geocodeArea(newValue)
                                        }

                                    if isGeocoding {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else if !postcode.isEmpty && geocodingError == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(geocodingError != nil ? Color.red.opacity(0.5) : Color.warmBrown.opacity(0.2), lineWidth: 1)
                                )

                                if let error = geocodingError {
                                    Text(error)
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // Reuse PropertyFiltersView for filters
                    PropertyFiltersView(
                        minPrice: $minPrice,
                        maxPrice: $maxPrice,
                        minBedrooms: $minBedrooms,
                        maxBedrooms: $maxBedrooms,
                        minBathrooms: $minBathrooms,
                        maxBathrooms: $maxBathrooms,
                        radius: $radius,
                        furnishType: $furnishType
                    )
                }
                .padding(20)
            }
            .background(Color.warmCream)
            .navigationTitle("Edit Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.warmBrown)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveQuery()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.rusticOrange)
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
        areaName = query.areaName
        postcode = query.postcode
        minPrice = query.minPrice
        maxPrice = query.maxPrice
        minBedrooms = query.minBedrooms
        maxBedrooms = query.maxBedrooms
        minBathrooms = query.minBathrooms
        maxBathrooms = query.maxBathrooms
        radius = query.radius
        furnishType = query.furnishType
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
            radius: radius,
            furnishType: furnishType,
            active: query.active,
            created: query.created,
            updated: Date()
        )

        onSave(updatedQuery)
        dismiss()
    }

    private func geocodeArea(_ area: String) {
        geocodingTask?.cancel()
        postcode = ""
        geocodingError = nil

        let trimmedArea = area.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedArea.isEmpty else { return }

        geocodingTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }

                await MainActor.run { isGeocoding = true }

                let result = try await geocodingService.geocodeAreaToPostcode(trimmedArea)
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
