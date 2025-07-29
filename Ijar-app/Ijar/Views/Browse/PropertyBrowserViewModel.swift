import SwiftUI
import Supabase

class PropertyBrowserViewModel: ObservableObject {
    @Published var properties: [QueryProperty] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasNoMoreProperties = false
    
    var navigationCoordinator: NavigationCoordinator?
    private let supabase = SupabaseManager.shared.client
    
    var currentProperty: QueryProperty? {
        guard currentIndex < properties.count else { return nil }
        return properties[currentIndex]
    }
    
    var hasProperties: Bool {
        !properties.isEmpty
    }
    
    init() {
        fetchNewProperties()
    }
    
    func fetchNewProperties() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                // Fetch properties with status 'new' for this user
                let queryProperties: [QueryProperty] = try await supabase
                    .from("query_properties")
                    .select("""
                        *,
                        property:properties(*)
                    """)
                    .eq("user_id", value: userId.uuidString)
                    .eq("status", value: PropertyStatus.new.rawValue)
                    .order("found_at", ascending: false)
                    .limit(20)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.properties = queryProperties
                    self.currentIndex = 0
                    self.hasNoMoreProperties = queryProperties.isEmpty
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load properties"
                    self.isLoading = false
                }
            }
        }
    }
    
    func likeCurrentProperty() {
        guard let property = currentProperty else { return }
        
        Task {
            do {
                // Update status to liked
                try await supabase
                    .from("query_properties")
                    .update(["status": PropertyStatus.liked.rawValue])
                    .eq("id", value: property.id)
                    .execute()
                
                // Also add to favorites
                try await supabase
                    .from("favorites")
                    .insert([
                        "user_id": property.userId,
                        "property_id": property.propertyId,
                        "query_id": property.queryId
                    ])
                    .execute()
                
                await MainActor.run {
                    self.moveToNextProperty()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save property"
                }
            }
        }
    }
    
    func dismissCurrentProperty() {
        guard let property = currentProperty else { return }
        
        Task {
            do {
                // Update status to dismissed
                try await supabase
                    .from("query_properties")
                    .update(["status": PropertyStatus.dismissed.rawValue])
                    .eq("id", value: property.id)
                    .execute()
                
                await MainActor.run {
                    self.moveToNextProperty()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to dismiss property"
                }
            }
        }
    }
    
    private func moveToNextProperty() {
        if currentIndex < properties.count - 1 {
            currentIndex += 1
        } else {
            // No more properties
            properties.removeAll()
            hasNoMoreProperties = true
        }
    }
    
    func openPropertyInBrowser() {
        guard let property = currentProperty?.property else { return }
        if let url = URL(string: "https://www.rightmove.co.uk\(property.propertyUrl)") {
            UIApplication.shared.open(url)
        }
    }
}