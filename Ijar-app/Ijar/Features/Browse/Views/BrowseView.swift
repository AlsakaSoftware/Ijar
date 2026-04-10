import SwiftUI

// MARK: - Browse Search View (Root)

struct BrowseView: View {
    @EnvironmentObject private var coordinator: BrowseCoordinator
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var viewModel = BrowseViewModel()

    private var isGuestMode: Bool {
        authService.isGuestMode && !authService.isAuthenticated
    }

    @FocusState private var isAreaFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    Text("Find your next home")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.coffeeBean)

                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18))
                                .foregroundColor(.rusticOrange)
                                .frame(width: 24)

                            TextField("Enter area, city or postcode", text: $viewModel.areaName)
                                .font(.system(size: 16))
                                .focused($isAreaFieldFocused)
                                .onChange(of: viewModel.areaName) { _, newValue in
                                    viewModel.geocodeArea(newValue)
                                }

                            if viewModel.isGeocoding {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if viewModel.latitude != nil && viewModel.longitude != nil && viewModel.geocodingError == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .coffeeBean.opacity(0.08), radius: 8, y: 4)

                        if let error = viewModel.geocodingError {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }

                        HStack(spacing: 12) {
                            Button {
                                isAreaFieldFocused = false
                                viewModel.showFilters = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "slider.horizontal.3")
                                    Text("Filters")
                                    if viewModel.filters.activeCount > 0 {
                                        Text("\(viewModel.filters.activeCount)")
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
                                .background(viewModel.canSearch ? Color.rusticOrange : Color.warmBrown.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .disabled(!viewModel.canSearch)
                        }
                    }
                    .padding(.horizontal, 24)

                    if !viewModel.queries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My monitored searches")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.warmBrown)
                                .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.queries) { query in
                                        Button {
                                            viewModel.loadQuery(query)
                                            performSearch()
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
        .sheet(isPresented: $viewModel.showFilters) {
            FilterSheet(
                minPrice: $viewModel.filters.minPrice,
                maxPrice: $viewModel.filters.maxPrice,
                minBedrooms: $viewModel.filters.minBedrooms,
                maxBedrooms: $viewModel.filters.maxBedrooms,
                minBathrooms: $viewModel.filters.minBathrooms,
                maxBathrooms: $viewModel.filters.maxBathrooms,
                radius: $viewModel.filters.radius,
                furnishType: $viewModel.filters.furnishType
            )
            .presentationDragIndicator(.visible)
        }
        .task {
            if !isGuestMode {
                await viewModel.loadQueries()
            }
        }
        .onDisappear {
            isAreaFieldFocused = false
        }
    }

    private func performSearch() {
        guard let params = viewModel.buildSearchParams() else { return }
        coordinator.navigate(to: .searchResults(params: params))
    }
}

// MARK: - Search Parameters

struct BrowseSearchParams: Hashable {
    let areaName: String
    let latitude: Double
    let longitude: Double
    var filters: PropertyFilters
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
