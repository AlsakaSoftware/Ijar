import SwiftUI
import Supabase

class SearchQueriesViewModel: ObservableObject {
    @Published var searchQueries: [SearchQuery] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var navigationCoordinator: NavigationCoordinator?
    private let supabase = SupabaseManager.shared.client
    
    init() {
        fetchSearchQueries()
    }
    
    func fetchSearchQueries() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                let queries: [SearchQuery] = try await supabase
                    .from("search_queries")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.searchQueries = queries
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load search queries"
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteQuery(_ query: SearchQuery) {
        Task {
            do {
                try await supabase
                    .from("search_queries")
                    .delete()
                    .eq("id", value: query.id)
                    .execute()
                
                await MainActor.run {
                    self.searchQueries.removeAll { $0.id == query.id }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete search query"
                }
            }
        }
    }
    
    func toggleQueryStatus(_ query: SearchQuery) {
        Task {
            do {
                try await supabase
                    .from("search_queries")
                    .update(["is_active": !query.isActive])
                    .eq("id", value: query.id)
                    .execute()
                
                await MainActor.run {
                    if let index = self.searchQueries.firstIndex(where: { $0.id == query.id }) {
                        self.searchQueries[index] = SearchQuery(
                            id: query.id,
                            userId: query.userId,
                            name: query.name,
                            locationName: query.locationName,
                            locationId: query.locationId,
                            minPrice: query.minPrice,
                            maxPrice: query.maxPrice,
                            minBedrooms: query.minBedrooms,
                            maxBedrooms: query.maxBedrooms,
                            minBathrooms: query.minBathrooms,
                            furnishedType: query.furnishedType,
                            propertyType: query.propertyType,
                            isActive: !query.isActive,
                            createdAt: query.createdAt,
                            updatedAt: Date()
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update search query"
                }
            }
        }
    }
    
    func createNewQuery() {
        navigationCoordinator?.showCreateQuery()
    }
    
    func editQuery(_ query: SearchQuery) {
        navigationCoordinator?.showEditQuery(query)
    }
}