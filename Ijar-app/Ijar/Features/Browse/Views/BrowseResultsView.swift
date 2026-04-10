import SwiftUI

struct BrowseResultsView: View {
    @EnvironmentObject private var coordinator: BrowseCoordinator
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var viewModel = BrowseResultsViewModel()
    private let propertyGroupService: PropertyGroupService
    private let savedPropertyRepository: SavedPropertyRepository

    let params: BrowseSearchParams

    init(
        params: BrowseSearchParams,
        propertyGroupService: PropertyGroupService = PropertyGroupService(),
        savedPropertyRepository: SavedPropertyRepository = .shared
    ) {
        self.params = params
        self.propertyGroupService = propertyGroupService
        self.savedPropertyRepository = savedPropertyRepository
    }

    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if viewModel.properties.isEmpty && viewModel.searchError == nil {
                emptyView
            } else if let error = viewModel.searchError {
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
                    viewModel.showFilters = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.rusticOrange)

                        if viewModel.filters.activeCount > 0 {
                            Text("\(viewModel.filters.activeCount)")
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
            .onDisappear {
                Task {
                    await viewModel.performSearch(params: params)
                }
            }
        }
        .sheet(isPresented: $viewModel.showSaveSearchSheet) {
            CreateSearchQueryView(
                areaName: params.areaName,
                latitude: params.latitude,
                longitude: params.longitude,
                minPrice: viewModel.filters.minPrice,
                maxPrice: viewModel.filters.maxPrice,
                minBedrooms: viewModel.filters.minBedrooms,
                maxBedrooms: viewModel.filters.maxBedrooms,
                minBathrooms: viewModel.filters.minBathrooms,
                maxBathrooms: viewModel.filters.maxBathrooms,
                radius: viewModel.filters.radius,
                furnishType: viewModel.filters.furnishType
            ) { query in
                Task {
                    await viewModel.createQuery(query)
                }
            }
        }
        .sheet(isPresented: $viewModel.showGuestSignUpSheet) {
            GuestSignUpPromptSheet(action: .monitor) {
                viewModel.showGuestSignUpSheet = false
            }
            .presentationDetents([.medium])
        }
        .onceTask {
            await viewModel.loadInitialData(params: params)
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
                viewModel.showFilters = true
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
                Task {
                    await viewModel.performSearch(params: params)
                }
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
                if viewModel.shouldShowSaveButton(params: params) {
                    if viewModel.hasSeenFullExplainer {
                        Button {
                            if authService.isInGuestMode {
                                viewModel.showGuestSignUpSheet = true
                            } else {
                                viewModel.showSaveSearchSheet = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 16, weight: .medium))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Monitor this for me")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Get new properties sent directly to your 'For You' feed")
                                        .multilineTextAlignment(.leading)
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
                        SaveSearchExplainerCard {
                            viewModel.markExplainerSeen()
                            if authService.isInGuestMode {
                                viewModel.showGuestSignUpSheet = true
                            } else {
                                viewModel.showSaveSearchSheet = true
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }

                HStack {
                    Text("\(viewModel.total) properties")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.warmBrown)

                    Spacer()

                    if viewModel.hasMore {
                        Text("Showing \(viewModel.properties.count)")
                            .font(.system(size: 13))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ForEach(Array(viewModel.properties.enumerated()), id: \.element.id) { index, property in
                    SaveablePropertyCard(
                        property: property,
                        propertyGroupService: propertyGroupService,
                        savedPropertyRepository: savedPropertyRepository,
                        onTap: {
                            coordinator.navigate(to: .propertyDetail(property: property, isSaved: savedPropertyRepository.isSaved(property.id)))
                        }
                    )
                    .padding(.horizontal, 20)
                    .opacity(viewModel.animateContent ? 1 : 0)
                    .offset(y: viewModel.animateContent ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.3).delay(Double(min(index, 8)) * 0.03),
                        value: viewModel.animateContent
                    )
                }

                if viewModel.hasMore {
                    Button {
                        Task {
                            await viewModel.loadMore()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoadingMore {
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
                    .disabled(viewModel.isLoadingMore)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }
}
