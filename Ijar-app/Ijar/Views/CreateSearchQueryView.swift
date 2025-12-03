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
    @StateObject private var searchQueryService = SearchQueryService()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    let onSave: (SearchQuery) -> Void

    // Optional pre-filled values (from browse results)
    let prefillAreaName: String?
    let prefillLatitude: Double?
    let prefillLongitude: Double?
    let prefillMinPrice: Int?
    let prefillMaxPrice: Int?
    let prefillMinBedrooms: Int?
    let prefillMaxBedrooms: Int?
    let prefillMinBathrooms: Int?
    let prefillMaxBathrooms: Int?
    let prefillRadius: Double?
    let prefillFurnishType: String?

    @State private var name = ""
    @State private var areaName = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var minPrice: Int? = nil
    @State private var maxPrice: Int? = nil
    @State private var minBedrooms: Int? = nil
    @State private var maxBedrooms: Int? = nil
    @State private var minBathrooms: Int? = nil
    @State private var maxBathrooms: Int? = nil
    @State private var radius: Double? = 1.0
    @State private var furnishType: String? = nil

    @State private var showPaywall = false
    @State private var limitMessage: String?
    @State private var showNameRequiredError = false
    @State private var showAreaRequiredError = false

    // Geocoding state
    @State private var isGeocoding = false
    @State private var geocodingError: String?
    @State private var geocodingTask: Task<Void, Never>?

    private let geocodingService = GeocodingService()

    // Default initializer (no prefill)
    init(onSave: @escaping (SearchQuery) -> Void) {
        self.onSave = onSave
        self.prefillAreaName = nil
        self.prefillLatitude = nil
        self.prefillLongitude = nil
        self.prefillMinPrice = nil
        self.prefillMaxPrice = nil
        self.prefillMinBedrooms = nil
        self.prefillMaxBedrooms = nil
        self.prefillMinBathrooms = nil
        self.prefillMaxBathrooms = nil
        self.prefillRadius = nil
        self.prefillFurnishType = nil
    }

    // Prefilled initializer (from browse results)
    init(
        areaName: String,
        latitude: Double,
        longitude: Double,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        minBedrooms: Int? = nil,
        maxBedrooms: Int? = nil,
        minBathrooms: Int? = nil,
        maxBathrooms: Int? = nil,
        radius: Double? = nil,
        furnishType: String? = nil,
        onSave: @escaping (SearchQuery) -> Void
    ) {
        self.onSave = onSave
        self.prefillAreaName = areaName
        self.prefillLatitude = latitude
        self.prefillLongitude = longitude
        self.prefillMinPrice = minPrice
        self.prefillMaxPrice = maxPrice
        self.prefillMinBedrooms = minBedrooms
        self.prefillMaxBedrooms = maxBedrooms
        self.prefillMinBathrooms = minBathrooms
        self.prefillMaxBathrooms = maxBathrooms
        self.prefillRadius = radius
        self.prefillFurnishType = furnishType
    }

    var body: some View {
        NavigationStack {
            contentView
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
                    }
                }
                .upgradePrompt(limitMessage: $limitMessage, showPaywall: $showPaywall)
                .task {
                    await searchQueryService.loadUserQueries()
                }
                .onAppear {
                    prefillFormIfNeeded()
                }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                nameAndLocationSection

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
    }

    private var nameAndLocationSection: some View {
        FilterSection(title: "Name & Location") {
            VStack(spacing: 12) {
                nameField
                areaField
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Search name")
                    .font(.system(size: 13))
                    .foregroundColor(.warmBrown)

                Text("*")
                    .font(.system(size: 13))
                    .foregroundColor(.rusticOrange)
            }

            TextField("e.g., Canary Wharf 2-bed", text: $name)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(showNameRequiredError ? Color.rusticOrange : Color.warmBrown.opacity(0.2), lineWidth: showNameRequiredError ? 2 : 1)
                )
                .onChange(of: name) { _, _ in
                    // Hide error when user starts typing
                    if showNameRequiredError {
                        showNameRequiredError = false
                    }
                }

            if showNameRequiredError {
                Text("Please enter a name for this search")
                    .font(.system(size: 12))
                    .foregroundColor(.rusticOrange)
            }
        }
    }

    private var areaField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Area")
                    .font(.system(size: 13))
                    .foregroundColor(.warmBrown)

                Text("*")
                    .font(.system(size: 13))
                    .foregroundColor(.rusticOrange)
            }

            HStack {
                TextField("e.g., Canary Wharf, London", text: $areaName)
                    .textContentType(.fullStreetAddress)
                    .autocapitalization(.words)
                    .onChange(of: areaName) { _, newValue in
                        geocodeArea(newValue)
                        // Hide error when user starts typing
                        if showAreaRequiredError {
                            showAreaRequiredError = false
                        }
                    }

                if isGeocoding {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if latitude != nil && longitude != nil && geocodingError == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        showAreaRequiredError ? Color.rusticOrange :
                        geocodingError != nil ? Color.red.opacity(0.5) :
                        Color.warmBrown.opacity(0.2),
                        lineWidth: showAreaRequiredError ? 2 : 1
                    )
            )

            if showAreaRequiredError {
                Text("Please enter an area to search")
                    .font(.system(size: 12))
                    .foregroundColor(.rusticOrange)
            } else if let error = geocodingError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }

    private func prefillFormIfNeeded() {
        if let prefillAreaName = prefillAreaName {
            areaName = prefillAreaName
        }
        if let prefillLatitude = prefillLatitude {
            latitude = prefillLatitude
        }
        if let prefillLongitude = prefillLongitude {
            longitude = prefillLongitude
        }
        if let prefillMinPrice = prefillMinPrice {
            minPrice = prefillMinPrice
        }
        if let prefillMaxPrice = prefillMaxPrice {
            maxPrice = prefillMaxPrice
        }
        if let prefillMinBedrooms = prefillMinBedrooms {
            minBedrooms = prefillMinBedrooms
        }
        if let prefillMaxBedrooms = prefillMaxBedrooms {
            maxBedrooms = prefillMaxBedrooms
        }
        if let prefillMinBathrooms = prefillMinBathrooms {
            minBathrooms = prefillMinBathrooms
        }
        if let prefillMaxBathrooms = prefillMaxBathrooms {
            maxBathrooms = prefillMaxBathrooms
        }
        if let prefillRadius = prefillRadius {
            radius = prefillRadius
        }
        if let prefillFurnishType = prefillFurnishType {
            furnishType = prefillFurnishType
        }
    }

    private var isValidForm: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !areaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude != nil && longitude != nil &&
        geocodingError == nil
    }

    private func saveQuery() {
        // Validate all fields at once
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedArea = areaName.trimmingCharacters(in: .whitespacesAndNewlines)

        var hasErrors = false

        // Check name
        if trimmedName.isEmpty {
            showNameRequiredError = true
            hasErrors = true
        }

        // Check area and coordinates
        if trimmedArea.isEmpty || latitude == nil || longitude == nil {
            showAreaRequiredError = true
            hasErrors = true
        }

        // If any errors, return early
        guard !hasErrors else {
            return
        }

        // Check subscription limit BEFORE saving
        let activeQueryCount = searchQueryService.queries.filter { $0.active }.count
        let canCreate = subscriptionManager.canCreateActiveQuery(activeQueryCount: activeQueryCount)

        guard canCreate.canCreate else {
            limitMessage = canCreate.reason ?? "You've reached your query limit. Upgrade to Premium for unlimited searches!"
            return
        }

        let query = SearchQuery(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            areaName: areaName.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude!,
            longitude: longitude!,
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
        latitude = nil
        longitude = nil
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
                    latitude = result.latitude
                    longitude = result.longitude
                    geocodingError = nil
                }
            } catch let error as GeocodingError {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isGeocoding = false
                    latitude = nil
                    longitude = nil
                    geocodingError = error.localizedDescription
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isGeocoding = false
                    latitude = nil
                    longitude = nil
                    geocodingError = "We couldn't find this area. Please check the spelling."
                }
            }
        }
    }
}
