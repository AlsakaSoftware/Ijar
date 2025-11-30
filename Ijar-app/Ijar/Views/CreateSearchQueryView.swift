import SwiftUI
import CoreLocation

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
    @State private var areaName = ""
    @State private var postcode = ""
    @State private var minPrice: Int? = nil
    @State private var maxPrice: Int? = nil
    @State private var minBedrooms: Int? = nil
    @State private var maxBedrooms: Int? = nil
    @State private var minBathrooms: Int? = nil
    @State private var maxBathrooms: Int? = nil
    @State private var radius: Double? = 1.0
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
            .navigationTitle("New Search")
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
    }

    private var isValidForm: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !areaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        geocodingError == nil
    }

    private func saveQuery() {
        let query = SearchQuery(
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
            furnishType: furnishType
        )

        onSave(query)
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
