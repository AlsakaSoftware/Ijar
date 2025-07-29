import SwiftUI

struct SearchQueriesListView: View {
    @StateObject private var viewModel = SearchQueriesViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        List {
            if viewModel.searchQueries.isEmpty && !viewModel.isLoading {
                EmptyStateView()
            } else {
                ForEach(viewModel.searchQueries) { query in
                    SearchQueryRow(
                        query: query,
                        onEdit: {
                            viewModel.editQuery(query)
                        },
                        onToggle: {
                            viewModel.toggleQueryStatus(query)
                        }
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteQuery(viewModel.searchQueries[index])
                    }
                }
            }
        }
        .navigationTitle("My Searches")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.createNewQuery) {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .refreshable {
            viewModel.fetchSearchQueries()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.navigationCoordinator = navigationCoordinator
        }
    }
}

struct SearchQueryRow: View {
    let query: SearchQuery
    let onEdit: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(query.name)
                        .font(.headline)
                    
                    Text(query.locationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { query.isActive },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            HStack(spacing: 16) {
                if let maxPrice = query.maxPrice {
                    Label("£\(maxPrice)", systemImage: "sterlingsign.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let bedrooms = query.minBedrooms {
                    Label("\(bedrooms) bed", systemImage: "bed.double")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let bathrooms = query.minBathrooms {
                    Label("\(bathrooms) bath", systemImage: "shower")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No search queries yet")
                .font(.headline)
            
            Text("Create a search to start finding properties")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}