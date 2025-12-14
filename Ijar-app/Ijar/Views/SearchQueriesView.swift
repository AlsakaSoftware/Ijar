import SwiftUI
import RevenueCatUI

struct SearchQueriesView: View {
    @StateObject private var searchService = SearchQueryService()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var monitorService = MonitorService()
    @State private var showingCreateQuery = false
    @State private var showingPaywall = false
    @State private var editingQuery: SearchQuery? = nil
    @State private var limitMessage: String?
    @State private var showingSearchStartedAlert = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.rusticOrange)
            } else if searchService.queries.isEmpty {
                emptyStateView
            } else {
                queryListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your search areas")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.coffeeBean)

                Text("We scan these areas daily and send matches to your feed")
                    .font(.system(size: 15))
                    .foregroundColor(.warmBrown.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(Color.warmCream)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: handleCreateQuery) {
                    Image(systemName: "plus")
                        .foregroundColor(.rusticOrange)
                }
            }
        }
        .sheet(isPresented: $showingCreateQuery) {
                CreateSearchQueryView { query in
                    Task {
                        await searchService.createQuery(query)
                        await triggerSearchForNewQuery()
                    }
                }
            }
            .sheet(item: $editingQuery) { query in
                EditSearchQueryView(
                    query: query,
                    onSave: { updatedQuery in
                        Task {
                            await searchService.updateQuery(updatedQuery)
                        }
                    }
                )
            }
            .upgradePrompt(limitMessage: $limitMessage, showPaywall: $showingPaywall)
            .alert("Your First Search is Live!", isPresented: $showingSearchStartedAlert) {
                Button("Got it!") { }
            } message: {
                Text("We'll send you some properties in a few minutes. We'll keep sending suitable matches for your area as we find them")
            }
            .task {
                await searchService.loadUserQueries()
                isLoading = false
            }
            .refreshable {
                await searchService.loadUserQueries()
            }
    }

    private func triggerSearchForNewQuery() async {
        // 1. Check if we've already triggered automatic search before
        let hasTriggeredFirstQuerySearch = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)

        // 2. Check if user only has one query (their first one)
        let isFirstQuery = searchService.queries.count == 1

        // Only trigger if: NOT triggered before AND is first query
        if hasTriggeredFirstQuerySearch || !isFirstQuery {
            return
        }

        guard let userId = try? await searchService.getCurrentUserId() else {
            return
        }

        let success = await monitorService.refreshPropertiesForUser(userId: userId)

        if success {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
            showingSearchStartedAlert = true
        }
    }

    private func handleCreateQuery() {
        let activeQueryCount = searchService.queries.filter { $0.active }.count
        let result = subscriptionManager.canCreateActiveQuery(activeQueryCount: activeQueryCount)

        if result.canCreate {
            showingCreateQuery = true
        } else {
            limitMessage = result.reason
        }
    }

    private func handleToggleActive(_ query: SearchQuery) {
        // If turning ON (activating), check limits
        if !query.active {
            let activeQueryCount = searchService.queries.filter { $0.active }.count
            let result = subscriptionManager.canActivateQuery(activeQueryCount: activeQueryCount)

            if !result.canActivate {
                limitMessage = result.reason
                return
            }
        }
        // Proceed with toggle
        Task {
            let updatedQuery = SearchQuery(
                id: query.id,
                name: query.name,
                areaName: query.areaName,
                latitude: query.latitude,
                longitude: query.longitude,
                minPrice: query.minPrice,
                maxPrice: query.maxPrice,
                minBedrooms: query.minBedrooms,
                maxBedrooms: query.maxBedrooms,
                minBathrooms: query.minBathrooms,
                maxBathrooms: query.maxBathrooms,
                radius: query.radius,
                furnishType: query.furnishType,
                active: !query.active,
                created: query.created,
                updated: Date()
            )
            await searchService.updateQuery(updatedQuery)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 80))
                .foregroundColor(.warmBrown.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No searches yet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.coffeeBean)

                Text("Tell us where you'd like to live and what you're looking for")
                    .font(.system(size: 16))
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: handleCreateQuery) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Start Exploring")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.warmCream)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.rusticOrange)
                )
            }
        }
    }
    
    private var queryListView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(searchService.queries) { query in
                SearchQueryCard(
                    query: query,
                    onToggleActive: {
                        handleToggleActive(query)
                    },
                    onEdit: { queryToEdit in
                        editingQuery = queryToEdit
                    },
                    onDuplicate: { queryToDuplicate in
                        let duplicatedQuery = SearchQuery(
                            name: "Copy of \(queryToDuplicate.name)",
                            areaName: queryToDuplicate.areaName,
                            latitude: queryToDuplicate.latitude,
                            longitude: queryToDuplicate.longitude,
                            minPrice: queryToDuplicate.minPrice,
                            maxPrice: queryToDuplicate.maxPrice,
                            minBedrooms: queryToDuplicate.minBedrooms,
                            maxBedrooms: queryToDuplicate.maxBedrooms,
                            minBathrooms: queryToDuplicate.minBathrooms,
                            maxBathrooms: queryToDuplicate.maxBathrooms,
                            radius: queryToDuplicate.radius,
                            furnishType: queryToDuplicate.furnishType
                        )
                        Task {
                            await searchService.createQueryAtBottom(duplicatedQuery)
                        }
                    },
                    onDelete: { queryToDelete in
                        Task {
                            await searchService.deleteQuery(queryToDelete)
                        }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
            }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
    }
}

