import SwiftUI

struct SearchQueriesView: View {
    @StateObject private var searchService = SearchQueryService()
    @State private var showingCreateQuery = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.warmCream.opacity(0.3)
                    .ignoresSafeArea()
                
                if searchService.isLoading && searchService.queries.isEmpty {
                    ProgressView()
                        .tint(.rusticOrange)
                } else if searchService.queries.isEmpty {
                    emptyStateView
                } else {
                    queryListView
                }
            }
            .navigationTitle("My Searches")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateQuery = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.rusticOrange)
                    }
                }
            }
            .sheet(isPresented: $showingCreateQuery) {
                CreateSearchQueryView { query in
                    Task {
                        await searchService.createQuery(query)
                    }
                }
            }
            .task {
                await searchService.loadUserQueries()
            }
            .refreshable {
                await searchService.loadUserQueries()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 80))
                .foregroundColor(.warmBrown.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Search Queries")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.coffeeBean)
                
                Text("Create your first search to start finding properties that match your criteria")
                    .font(.system(size: 16))
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                showingCreateQuery = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Search")
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
        List {
            ForEach(searchService.queries) { query in
                SearchQueryRow(
                    query: query,
                    onToggleActive: {
                        Task {
                            var updatedQuery = query
                            updatedQuery = SearchQuery(
                                id: updatedQuery.id,
                                name: updatedQuery.name,
                                locationId: updatedQuery.locationId,
                                locationName: updatedQuery.locationName,
                                minPrice: updatedQuery.minPrice,
                                maxPrice: updatedQuery.maxPrice,
                                minBedrooms: updatedQuery.minBedrooms,
                                maxBedrooms: updatedQuery.maxBedrooms,
                                minBathrooms: updatedQuery.minBathrooms,
                                maxBathrooms: updatedQuery.maxBathrooms,
                                radius: updatedQuery.radius,
                                furnishType: updatedQuery.furnishType,
                                active: !updatedQuery.active,
                                created: updatedQuery.created,
                                updated: Date()
                            )
                            await searchService.updateQuery(updatedQuery)
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
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
}

struct SearchQueryRow: View {
    let query: SearchQuery
    let onToggleActive: () -> Void
    let onDelete: (SearchQuery) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(query.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.coffeeBean)
                    
                    Text(query.locationName)
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: onToggleActive) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(query.active ? Color.rusticOrange : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text(query.active ? "Active" : "Inactive")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(query.active ? .rusticOrange : .gray)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Search criteria summary
            VStack(alignment: .leading, spacing: 6) {
                if let minPrice = query.minPrice, let maxPrice = query.maxPrice {
                    SearchCriteriaChip(
                        icon: "pounds.circle",
                        text: "£\(minPrice) - £\(maxPrice)"
                    )
                }
                
                HStack(spacing: 8) {
                    if let minBed = query.minBedrooms, let maxBed = query.maxBedrooms {
                        if minBed == maxBed {
                            SearchCriteriaChip(
                                icon: "bed.double",
                                text: "\(minBed) bed"
                            )
                        } else {
                            SearchCriteriaChip(
                                icon: "bed.double",
                                text: "\(minBed)-\(maxBed) bed"
                            )
                        }
                    }
                    
                    if let minBath = query.minBathrooms, let maxBath = query.maxBathrooms {
                        if minBath == maxBath {
                            SearchCriteriaChip(
                                icon: "shower",
                                text: "\(minBath) bath"
                            )
                        } else {
                            SearchCriteriaChip(
                                icon: "shower",
                                text: "\(minBath)-\(maxBath) bath"
                            )
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Actions
            HStack {
                Text("Created \(query.created.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12))
                    .foregroundColor(.warmBrown.opacity(0.5))
                
                Spacer()
                
                Button(action: {
                    onDelete(query)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Delete")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.warmRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmCream)
                .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            // Prevent accidental taps - do nothing for general taps
        }
    }
}

struct SearchCriteriaChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.rusticOrange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.rusticOrange.opacity(0.1))
        )
    }
}

#Preview {
    SearchQueriesView()
}