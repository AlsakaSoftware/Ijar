import SwiftUI

// MARK: - Browse Search View (Root)

struct BrowseView: View {
    @EnvironmentObject private var coordinator: BrowseCoordinator
    @StateObject private var queryService = SearchQueryService()

    @State private var areaName = ""
    @State private var postcode = ""
    @State private var isGeocoding = false
    @State private var geocodingError: String?
    @State private var geocodingTask: Task<Void, Never>?

    @State private var minPrice: Int?
    @State private var maxPrice: Int?
    @State private var minBedrooms: Int?
    @State private var maxBedrooms: Int?
    @State private var minBathrooms: Int?
    @State private var maxBathrooms: Int?
    @State private var radius: Double?
    @State private var furnishType: String?

    @State private var showFilters = false
    @FocusState private var isAreaFieldFocused: Bool

    private let geocodingService = GeocodingService()

    private var canSearch: Bool {
        !postcode.isEmpty && geocodingError == nil && !isGeocoding
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
                            } else if !postcode.isEmpty && geocodingError == nil {
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
                            Text("Recent searches")
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
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
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
        postcode = query.postcode
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
        let searchParams = BrowseSearchParams(
            areaName: areaName,
            postcode: postcode,
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
                    geocodingError = "Couldn't find this area"
                }
            }
        }
    }
}

// MARK: - Search Parameters

struct BrowseSearchParams: Hashable {
    let areaName: String
    let postcode: String
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
                VStack(spacing: 24) {
                    // Price
                    FilterSection(title: "Price per month") {
                        HStack(spacing: 12) {
                            PriceField(title: "Min", value: $minPrice)
                            PriceField(title: "Max", value: $maxPrice)
                        }
                    }

                    // Bedrooms
                    FilterSection(title: "Bedrooms") {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Min")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)
                                Menu {
                                    Button("Any") { minBedrooms = nil }
                                    Button("Studio") { minBedrooms = 0 }
                                    ForEach(1...5, id: \.self) { num in
                                        Button("\(num)") { minBedrooms = num }
                                    }
                                } label: {
                                    HStack {
                                        Text(minBedrooms == nil ? "Any" : (minBedrooms == 0 ? "Studio" : "\(minBedrooms!)"))
                                            .foregroundColor(.coffeeBean)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.warmBrown)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Max")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)
                                Menu {
                                    Button("Any") { maxBedrooms = nil }
                                    Button("Studio") { maxBedrooms = 0 }
                                    ForEach(1...5, id: \.self) { num in
                                        Button("\(num)") { maxBedrooms = num }
                                    }
                                } label: {
                                    HStack {
                                        Text(maxBedrooms == nil ? "Any" : (maxBedrooms == 0 ? "Studio" : "\(maxBedrooms!)"))
                                            .foregroundColor(.coffeeBean)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.warmBrown)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    FilterSection(title: "Bathrooms") {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Min")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)
                                Menu {
                                    Button("Any") { minBathrooms = nil }
                                    ForEach(1...4, id: \.self) { num in
                                        Button("\(num)") { minBathrooms = num }
                                    }
                                } label: {
                                    HStack {
                                        Text(minBathrooms == nil ? "Any" : "\(minBathrooms!)")
                                            .foregroundColor(.coffeeBean)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.warmBrown)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Max")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)
                                Menu {
                                    Button("Any") { maxBathrooms = nil }
                                    ForEach(1...4, id: \.self) { num in
                                        Button("\(num)") { maxBathrooms = num }
                                    }
                                } label: {
                                    HStack {
                                        Text(maxBathrooms == nil ? "Any" : "\(maxBathrooms!)")
                                            .foregroundColor(.coffeeBean)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.warmBrown)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    FilterSection(title: "Search radius") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterOption(label: "This area", isSelected: radius == nil) {
                                    radius = nil
                                }
                                FilterOption(label: "½ mile", isSelected: radius == 0.5) {
                                    radius = 0.5
                                }
                                FilterOption(label: "1 mile", isSelected: radius == 1.0) {
                                    radius = 1.0
                                }
                                FilterOption(label: "3 miles", isSelected: radius == 3.0) {
                                    radius = 3.0
                                }
                                FilterOption(label: "5 miles", isSelected: radius == 5.0) {
                                    radius = 5.0
                                }
                                FilterOption(label: "10 miles", isSelected: radius == 10.0) {
                                    radius = 10.0
                                }
                            }
                        }
                    }

                    FilterSection(title: "Furnishing") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterOption(label: "Any", isSelected: furnishType == nil) {
                                    furnishType = nil
                                }
                                FilterOption(label: "Furnished", isSelected: furnishType == "furnished") {
                                    furnishType = "furnished"
                                }
                                FilterOption(label: "Part furnished", isSelected: furnishType == "partFurnished") {
                                    furnishType = "partFurnished"
                                }
                                FilterOption(label: "Unfurnished", isSelected: furnishType == "unfurnished") {
                                    furnishType = "unfurnished"
                                }
                            }
                        }
                    }
                }
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
    }
}
