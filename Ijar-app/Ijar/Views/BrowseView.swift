import SwiftUI

// MARK: - Browse Search View (Root)

struct BrowseView: View {
    @EnvironmentObject private var coordinator: BrowseCoordinator
    @StateObject private var queryService = SearchQueryService()

    @State private var areaName = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var isGeocoding = false
    @State private var geocodingError: String?
    @State private var geocodingTask: Task<Void, Never>?

    @State private var minPrice: Int?
    @State private var maxPrice: Int?
    @State private var minBedrooms: Int?
    @State private var maxBedrooms: Int?
    @State private var minBathrooms: Int?
    @State private var maxBathrooms: Int?
    @State private var radius: Double? = 1.0
    @State private var furnishType: String?

    @State private var showFilters = false
    @FocusState private var isAreaFieldFocused: Bool

    private let geocodingService = GeocodingService()

    private var canSearch: Bool {
        latitude != nil && longitude != nil && geocodingError == nil && !isGeocoding
    }

    private var activeFiltersCount: Int {
        var count = 0
        if minPrice != nil || maxPrice != nil { count += 1 }
        if minBedrooms != nil || maxBedrooms != nil { count += 1 }
        if minBathrooms != nil || maxBathrooms != nil { count += 1 }
        if radius != nil { count += 1 }
        if furnishType != nil { count += 1 }
        return count
    }

    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.rusticOrange)

                        Text("Find your next home")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.coffeeBean)
                    }

                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18))
                                .foregroundColor(.rusticOrange)
                                .frame(width: 24)

                            TextField("Enter area, city or postcode", text: $areaName)
                                .font(.system(size: 16))
                                .focused($isAreaFieldFocused)
                                .onChange(of: areaName) { _, newValue in
                                    geocodeArea(newValue)
                                }

                            if isGeocoding {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if latitude != nil && longitude != nil && geocodingError == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .coffeeBean.opacity(0.08), radius: 8, y: 4)

                        if let error = geocodingError {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }

                        HStack(spacing: 12) {
                            Button {
                                isAreaFieldFocused = false
                                showFilters = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "slider.horizontal.3")
                                    Text("Filters")
                                    if activeFiltersCount > 0 {
                                        Text("\(activeFiltersCount)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.rusticOrange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.rusticOrange.opacity(0.15))
                                            .cornerRadius(10)
                                    }
                                }
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.coffeeBean)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .coffeeBean.opacity(0.06), radius: 4, y: 2)
                            }

                            Button {
                                isAreaFieldFocused = false
                                performSearch()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(canSearch ? Color.rusticOrange : Color.warmBrown.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .disabled(!canSearch)
                        }
                    }
                    .padding(.horizontal, 24)

                    if !queryService.queries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My monitored searches")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.warmBrown)
                                .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(queryService.queries) { query in
                                        Button {
                                            loadQuery(query)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "clock.arrow.circlepath")
                                                    .font(.system(size: 12))
                                                Text(query.areaName)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(.coffeeBean)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                            .shadow(color: .coffeeBean.opacity(0.06), radius: 4, y: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .onTapGesture {
            isAreaFieldFocused = false
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(
                minPrice: $minPrice,
                maxPrice: $maxPrice,
                minBedrooms: $minBedrooms,
                maxBedrooms: $maxBedrooms,
                minBathrooms: $minBathrooms,
                maxBathrooms: $maxBathrooms,
                radius: $radius,
                furnishType: $furnishType
            )
            .presentationDragIndicator(.visible)
        }
        .task {
            await queryService.loadUserQueries()
        }
        .onDisappear {
            isAreaFieldFocused = false
        }
    }

    private func loadQuery(_ query: SearchQuery) {
        areaName = query.areaName
        latitude = query.latitude
        longitude = query.longitude
        minPrice = query.minPrice
        maxPrice = query.maxPrice
        minBedrooms = query.minBedrooms
        maxBedrooms = query.maxBedrooms
        minBathrooms = query.minBathrooms
        maxBathrooms = query.maxBathrooms
        radius = query.radius
        furnishType = query.furnishType
        geocodingError = nil

        performSearch()
    }

    private func performSearch() {
        guard let lat = latitude, let lng = longitude else { return }
        let searchParams = BrowseSearchParams(
            areaName: areaName,
            latitude: lat,
            longitude: lng,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minBedrooms: minBedrooms,
            maxBedrooms: maxBedrooms,
            minBathrooms: minBathrooms,
            maxBathrooms: maxBathrooms,
            radius: radius,
            furnishType: furnishType
        )
        coordinator.navigate(to: .searchResults(params: searchParams))
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
                    geocodingError = "Couldn't find this area"
                }
            }
        }
    }
}

// MARK: - Search Parameters

struct BrowseSearchParams: Hashable {
    let areaName: String
    let latitude: Double
    let longitude: Double
    var minPrice: Int?
    var maxPrice: Int?
    var minBedrooms: Int?
    var maxBedrooms: Int?
    var minBathrooms: Int?
    var maxBathrooms: Int?
    var radius: Double?
    var furnishType: String?
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var minPrice: Int?
    @Binding var maxPrice: Int?
    @Binding var minBedrooms: Int?
    @Binding var maxBedrooms: Int?
    @Binding var minBathrooms: Int?
    @Binding var maxBathrooms: Int?
    @Binding var radius: Double?
    @Binding var furnishType: String?

    var body: some View {
        NavigationStack {
            ScrollView {
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
                .padding(20)
            }
            .background(Color.warmCream)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        minPrice = nil
                        maxPrice = nil
                        minBedrooms = nil
                        maxBedrooms = nil
                        minBathrooms = nil
                        maxBathrooms = nil
                        radius = nil
                        furnishType = nil
                    }
                    .foregroundColor(.warmBrown)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.rusticOrange)
                }
            }
        }
    }
}

// MARK: - Filter Components

struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.coffeeBean)
            content
        }
    }
}

struct FilterOption: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .coffeeBean)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.rusticOrange : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.warmBrown.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct PriceField: View {
    let title: String
    @Binding var value: Int?
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.warmBrown)

            HStack {
                Text("£")
                    .foregroundColor(.warmBrown)
                TextField("Any", text: $text)
                    .keyboardType(.numberPad)
                    .onChange(of: text) { _, newValue in
                        value = Int(newValue)
                    }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            if let value = value {
                text = "\(value)"
            }
        }
        .onChange(of: value) { _, newValue in
            if let newValue = newValue {
                text = "\(newValue)"
            } else {
                text = ""
            }
        }
    }
}
