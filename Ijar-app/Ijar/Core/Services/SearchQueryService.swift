import Foundation

/// Temporary wrapper around SearchQueryRepository that maintains ObservableObject conformance.
/// Will be removed as ViewModels are introduced for each feature.
@MainActor
class SearchQueryService: ObservableObject {
    private let repository = SearchQueryRepository()
    @Published var queries: [SearchQuery] = []
    @Published var error: String?

    func loadUserQueries() async {
        error = nil
        do {
            queries = try await repository.fetchQueries()
        } catch {
            self.error = error.localizedDescription
            print("Error loading queries: \(error)")
        }
    }

    @discardableResult
    func createQuery(_ query: SearchQuery) async -> Bool {
        error = nil
        do {
            try await repository.insertQuery(query)
            await loadUserQueries()
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error creating query: \(error)")
            return false
        }
    }

    func createQueryAtBottom(_ query: SearchQuery) async -> Bool {
        error = nil
        do {
            try await repository.insertQuery(query)
            queries.append(query)
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error creating query: \(error)")
            return false
        }
    }

    @discardableResult
    func updateQuery(_ query: SearchQuery) async -> Bool {
        error = nil
        do {
            try await repository.updateQuery(query)
            await loadUserQueries()
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error updating query: \(error)")
            return false
        }
    }

    func deleteQuery(_ query: SearchQuery) async -> Bool {
        error = nil
        do {
            try await repository.deleteQuery(id: query.id)
            await loadUserQueries()
            return true
        } catch {
            self.error = error.localizedDescription
            print("Error deleting query: \(error)")
            return false
        }
    }

    func getCurrentUserId() async throws -> String {
        try await repository.getCurrentUserId()
    }
}
