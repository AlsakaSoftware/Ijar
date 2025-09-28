import SwiftUI

struct SearchQueriesView: View {
    @StateObject private var searchService = SearchQueryService()
    @State private var showingCreateQuery = false
    @State private var editingQuery: SearchQuery? = nil
    
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
                SearchQueryCard(
                    query: query,
                    onToggleActive: {
                        Task {
                            var updatedQuery = query
                            updatedQuery = SearchQuery(
                                id: updatedQuery.id,
                                name: updatedQuery.name,
                                postcode: updatedQuery.postcode,
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
                    onEdit: { queryToEdit in
                        editingQuery = queryToEdit
                    },
                    onDuplicate: { queryToDuplicate in
                        let duplicatedQuery = SearchQuery(
                            name: "Copy of \(queryToDuplicate.name)",
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
                        Text(query.postcode)
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
                        Label("Edit Search", systemImage: "pencil")
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



