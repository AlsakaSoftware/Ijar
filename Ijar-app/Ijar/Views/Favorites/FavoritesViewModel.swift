import SwiftUI
import Supabase

class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Favorite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var navigationCoordinator: NavigationCoordinator?
    private let supabase = SupabaseManager.shared.client
    
    init() {
        fetchFavorites()
    }
    
    func fetchFavorites() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                let favorites: [Favorite] = try await supabase
                    .from("favorites")
                    .select("""
                        *,
                        property:properties(*),
                        query:search_queries(name)
                    """)
                    .eq("user_id", value: userId.uuidString)
                    .order("saved_at", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.favorites = favorites
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load favorites"
                    self.isLoading = false
                }
            }
        }
    }
    
    func removeFavorite(_ favorite: Favorite) {
        Task {
            do {
                try await supabase
                    .from("favorites")
                    .delete()
                    .eq("id", value: favorite.id)
                    .execute()
                
                await MainActor.run {
                    self.favorites.removeAll { $0.id == favorite.id }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to remove favorite"
                }
            }
        }
    }
    
    func openProperty(_ property: Property) {
        if let url = URL(string: "https://www.rightmove.co.uk\(property.propertyUrl)") {
            UIApplication.shared.open(url)
        }
    }
}

struct Favorite: Codable, Identifiable {
    let id: String
    let userId: String
    let propertyId: String
    let queryId: String
    let savedAt: Date
    let property: Property?
    let query: SearchQueryInfo?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case propertyId = "property_id"
        case queryId = "query_id"
        case savedAt = "saved_at"
        case property
        case query
    }
}

struct SearchQueryInfo: Codable {
    let name: String
}