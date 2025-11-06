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
    
    var body: some View {
        Group {
            if searchService.isLoading && searchService.queries.isEmpty {
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
        .navigationTitle("Areas I'm Exploring")
        .navigationBarTitleDisplayMode(.large)
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
                Text("We'll send you some properties in a few minutes. We'll keep sending suitable matches for your area as we find them.")
            }
            .task {
                await searchService.loadUserQueries()
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
                postcode: query.postcode,
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
                            postcode: queryToDuplicate.postcode,
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
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
    }
}

struct SearchQueryCard: View {
    let query: SearchQuery
    let onToggleActive: () -> Void
    let onEdit: (SearchQuery) -> Void
    let onDuplicate: (SearchQuery) -> Void
    let onDelete: (SearchQuery) -> Void
    
    @State private var showingOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with name, location and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(query.name)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.coffeeBean)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.warmBrown.opacity(0.6))
                        Text(query.areaName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.warmBrown.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Status toggle
                Button(action: onToggleActive) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(query.active ? Color.green : Color.gray.opacity(0.4))
                            .frame(width: 10, height: 10)
                        Text(query.active ? "Active" : "Paused")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(query.active ? .green : .gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(query.active ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Attractive criteria pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let minPrice = query.minPrice, let maxPrice = query.maxPrice {
                        CriteriaPill(
                            icon: "pounds.circle",
                            text: "£\(formatPrice(minPrice)) - £\(formatPrice(maxPrice))"
                        )
                    }
                    
                    if let minBed = query.minBedrooms, let maxBed = query.maxBedrooms {
                        let bedText = minBed == maxBed ? "\(minBed) bed" : "\(minBed)-\(maxBed) beds"
                        CriteriaPill(
                            icon: "bed.double",
                            text: bedText
                        )
                    }
                    
                    if let minBath = query.minBathrooms, let maxBath = query.maxBathrooms {
                        let bathText = minBath == maxBath ? "\(minBath) bath" : "\(minBath)-\(maxBath) baths"
                        CriteriaPill(
                            icon: "shower",
                            text: bathText
                        )
                    }
                    
                    if let radius = query.radius {
                        CriteriaPill(
                            icon: "location.circle",
                            text: "\(String(format: "%.1f", radius)) mi"
                        )
                    }
                    
                    if let furnish = query.furnishType {
                        CriteriaPill(
                            icon: "sofa",
                            text: furnish.capitalized
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
            
            // Footer with options menu
            HStack {
                Text("Created \(query.created.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.warmBrown.opacity(0.5))
                
                Spacer()
                
                // Options menu button
                Menu {
                    Button(action: { onEdit(query) }) {
                        Label("Edit This Search", systemImage: "pencil")
                    }
                    
                    Button(action: { onDuplicate(query) }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { onDelete(query) }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Text("Options")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.warmBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.warmBrown.opacity(0.4), lineWidth: 1.2)
                                .background(Color.warmCream.opacity(0.3))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .coffeeBean.opacity(0.08), radius: 8, y: 4)
        )
    }
    
    private func formatPrice(_ price: Int) -> String {
        if price >= 1000 {
            return String(format: "%.1fk", Double(price) / 1000.0)
        }
        return "\(price)"
    }
}

struct CriteriaPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.rusticOrange)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.coffeeBean)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.warmCream)
                .overlay(
                    Capsule()
                        .stroke(Color.rusticOrange.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}



