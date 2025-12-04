import SwiftUI

struct BrowseResultsView: View {
    @EnvironmentObject private var coordinator: BrowseCoordinator
    @StateObject private var searchService = LiveSearchService()
    @StateObject private var propertyService = PropertyService()
    @StateObject private var queryService = SearchQueryService()

    let params: BrowseSearchParams

    // Local filter state (for editing)
    @State private var minPrice: Int?
    @State private var maxPrice: Int?
    @State private var minBedrooms: Int?
    @State private var maxBedrooms: Int?
    @State private var minBathrooms: Int?
    @State private var maxBathrooms: Int?
    @State private var radius: Double?
    @State private var furnishType: String?

    @State private var showFilters = false
    @State private var animateContent = false
    @State private var savedPropertyIds: Set<String> = []
    @State private var isLoading = true
    @State private var showSaveSearchSheet = false
    @State private var hasSavedQuery = false
    @State private var hasSeenFullExplainer = UserDefaults.standard.bool(forKey: "has_seen_save_search_explainer")

    private var activeFiltersCount: Int {
        var count = 0
        if minPrice != nil || maxPrice != nil { count += 1 }
        if minBedrooms != nil || maxBedrooms != nil { count += 1 }
        if minBathrooms != nil || maxBathrooms != nil { count += 1 }
        if radius != nil { count += 1 }
        if furnishType != nil { count += 1 }
        return count
    }

    private var shouldShowSaveButton: Bool {
        // Don't show if user already saved this search
        if hasSavedQuery { return false }

        // Check if a query with these exact coordinates already exists
        let existingQuery = queryService.queries.first { query in
            abs(query.latitude - params.latitude) < 0.001 &&
            abs(query.longitude - params.longitude) < 0.001 &&
            query.minPrice == minPrice &&
            query.maxPrice == maxPrice &&
            query.minBedrooms == minBedrooms &&
            query.maxBedrooms == maxBedrooms &&
            query.minBathrooms == minBathrooms &&
            query.maxBathrooms == maxBathrooms &&
            query.radius == radius &&
            query.furnishType == furnishType
        }

        return existingQuery == nil
    }

    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if searchService.properties.isEmpty && searchService.error == nil {
                emptyView
            } else if let error = searchService.error {
                errorView(error)
            } else {
                resultsListView
            }
        }
        .navigationTitle(params.areaName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.rusticOrange)

                        if activeFiltersCount > 0 {
                            Text("\(activeFiltersCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.rusticOrange)
                                .clipShape(Circle())
                        }
                    }
                }
            }
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
            .onDisappear {
                performSearch()
            }
        }
        .sheet(isPresented: $showSaveSearchSheet) {
            CreateSearchQueryView(
                areaName: params.areaName,
                latitude: params.latitude,
                longitude: params.longitude,
                minPrice: minPrice,
                maxPrice: maxPrice,
                minBedrooms: minBedrooms,
                maxBedrooms: maxBedrooms,
                minBathrooms: minBathrooms,
                maxBathrooms: maxBathrooms,
                radius: radius,
                furnishType: furnishType
            ) { query in
                Task {
                    await queryService.createQuery(query)
                    hasSavedQuery = true
                }
            }
        }
        .task(id: "\(params.latitude),\(params.longitude)") {
            await queryService.loadUserQueries()

            minPrice = params.minPrice
            maxPrice = params.maxPrice
            minBedrooms = params.minBedrooms
            maxBedrooms = params.maxBedrooms
            minBathrooms = params.minBathrooms
            maxBathrooms = params.maxBathrooms
            radius = params.radius
            furnishType = params.furnishType

            performSearch()
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.rusticOrange)

            Text("Searching...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.warmBrown)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.slash")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.warmBrown.opacity(0.4))

            VStack(spacing: 8) {
                Text("No properties found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.coffeeBean)

                Text("Try adjusting your filters or searching a different area")
                    .font(.system(size: 15))
                    .foregroundColor(.warmBrown)
                    .multilineTextAlignment(.center)
            }

            Button {
                showFilters = true
            } label: {
                Text("Adjust Filters")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.rusticOrange)
                    .cornerRadius(10)
            }
        }
        .padding(40)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.coffeeBean)

                Text(error)
                    .font(.system(size: 15))
                    .foregroundColor(.warmBrown)
                    .multilineTextAlignment(.center)
            }

            Button {
                performSearch()
            } label: {
                Text("Try Again")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.rusticOrange)
                    .cornerRadius(10)
            }
        }
        .padding(40)
    }

    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Save search banner (only show if not already saved)
                if shouldShowSaveButton {
                    if hasSeenFullExplainer {
                        // Compact CTA for subsequent visits
                        Button {
                            showSaveSearchSheet = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 16, weight: .medium))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Monitor this for me")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Get new properties sent directly to your 'For You' feed")
                                        .font(.system(size: 13))
                                        .opacity(0.8)
                                }

                                Spacer()

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .opacity(0.6)
                            }
                            .foregroundColor(.white)
                            .padding(14)
                            .background(
                                LinearGradient(
                                    colors: [Color.rusticOrange, Color.warmRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    } else {
                        // Full explainer card for first time
                        SaveSearchExplainerCard {
                            showSaveSearchSheet = true
                            UserDefaults.standard.set(true, forKey: "has_seen_save_search_explainer")
                            hasSeenFullExplainer = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }

                // Results count
                HStack {
                    Text("\(searchService.total) properties")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.warmBrown)

                    Spacer()

                    if searchService.hasMore {
                        Text("Showing \(searchService.properties.count)")
                            .font(.system(size: 13))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Property cards
                ForEach(Array(searchService.properties.enumerated()), id: \.element.id) { index, property in
                    PropertyListCard(
                        property: property,
                        isSaved: savedPropertyIds.contains(property.id),
                        onTap: {
                            coordinator.navigate(to: .propertyDetail(property: property, isSaved: savedPropertyIds.contains(property.id)))
                        },
                        onSaveToggle: {
                            Task {
                                if savedPropertyIds.contains(property.id) {
                                    // Unsave
                                    let success = await propertyService.unsaveLiveSearchProperty(property)
                                    if success {
                                        savedPropertyIds.remove(property.id)
                                    }
                                } else {
                                    // Save
                                    let success = await propertyService.saveLiveSearchProperty(property)
                                    if success {
                                        savedPropertyIds.insert(property.id)
                                    }
                                }
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.3).delay(Double(min(index, 8)) * 0.03),
                        value: animateContent
                    )
                }

                // Load more
                if searchService.hasMore {
                    Button {
                        Task {
                            await searchService.loadMore()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if searchService.isLoadingMore {
                                ProgressView()
                                    .tint(.rusticOrange)
                            } else {
                                Text("Load more")
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.rusticOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rusticOrange.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .disabled(searchService.isLoadingMore)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }

    // MARK: - Actions

    private func performSearch() {
        isLoading = true
        animateContent = false
        Task {
            await searchService.search(
                latitude: params.latitude,
                longitude: params.longitude,
                minPrice: minPrice,
                maxPrice: maxPrice,
                minBedrooms: minBedrooms,
                maxBedrooms: maxBedrooms,
                minBathrooms: minBathrooms,
                maxBathrooms: maxBathrooms,
                radius: radius,
                furnishType: furnishType
            )

            // Check which properties are already saved
            let saved = await propertyService.getSavedPropertyIds(from: searchService.properties)
            savedPropertyIds = saved

            isLoading = false
            withAnimation {
                animateContent = true
            }
        }
    }
}
