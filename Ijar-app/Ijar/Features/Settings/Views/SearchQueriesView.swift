import SwiftUI
import RevenueCatUI

struct SearchQueriesView: View {
    @StateObject private var viewModel = SearchQueriesViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.rusticOrange)
            } else if viewModel.queries.isEmpty {
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
                Button(action: { viewModel.handleCreateQuery() }) {
                    Image(systemName: "plus")
                        .foregroundColor(.rusticOrange)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingCreateQuery) {
            CreateSearchQueryView { query in
                Task {
                    await viewModel.createQuery(query)
                    await viewModel.triggerSearchForNewQuery()
                }
            }
        }
        .sheet(item: $viewModel.editingQuery) { query in
            EditSearchQueryView(
                query: query,
                onSave: { updatedQuery in
                    Task {
                        await viewModel.updateQuery(updatedQuery)
                    }
                }
            )
        }
        .upgradePrompt(limitMessage: $viewModel.limitMessage, showPaywall: $viewModel.showingPaywall)
        .alert("Your First Search is Live!", isPresented: $viewModel.showingSearchStartedAlert) {
            Button("Got it!") { }
        } message: {
            Text("We'll send you some properties in a few minutes. We'll keep sending suitable matches for your area as we find them")
        }
        .task {
            await viewModel.loadQueries()
        }
        .refreshable {
            await viewModel.loadQueries()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("No searches yet")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.coffeeBean)

                Text("Tell us where you'd like to live and what you're looking for")
                    .font(.system(size: 17))
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: { viewModel.handleCreateQuery() }) {
                Text("Start Exploring")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
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
                ForEach(viewModel.queries) { query in
                    SearchQueryCard(
                        query: query,
                        onToggleActive: {
                            viewModel.handleToggleActive(query)
                        },
                        onEdit: { queryToEdit in
                            viewModel.editingQuery = queryToEdit
                        },
                        onDuplicate: { queryToDuplicate in
                            Task {
                                await viewModel.duplicateQuery(queryToDuplicate)
                            }
                        },
                        onDelete: { queryToDelete in
                            Task {
                                await viewModel.deleteQuery(queryToDelete)
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
