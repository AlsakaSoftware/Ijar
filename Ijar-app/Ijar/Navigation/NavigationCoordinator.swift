import SwiftUI
import Supabase

enum AppDestination: Hashable, Equatable {
    case signIn
    case signUp
    case mainTabs
    case createQuery
    case editQuery(SearchQuery)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .signIn:
            hasher.combine("signIn")
        case .signUp:
            hasher.combine("signUp")
        case .mainTabs:
            hasher.combine("mainTabs")
        case .createQuery:
            hasher.combine("createQuery")
        case .editQuery(let query):
            hasher.combine("editQuery")
            hasher.combine(query.id)
        }
    }
    
    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.signIn, .signIn), (.signUp, .signUp), (.mainTabs, .mainTabs), (.createQuery, .createQuery):
            return true
        case (.editQuery(let lhsQuery), .editQuery(let rhsQuery)):
            return lhsQuery.id == rhsQuery.id
        default:
            return false
        }
    }
}

class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var isAuthenticated = false
    
    private let authService = AuthenticationService.shared
    
    init() {
        // Observe authentication changes
        authService.$isAuthenticated
            .assign(to: &$isAuthenticated)
    }
    
    // MARK: - Navigation Methods
    
    func navigate(to destination: AppDestination) {
        path.append(destination)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func showSignUp() {
        navigate(to: .signUp)
    }
    
    func showMainTabs() {
        popToRoot()
        navigate(to: .mainTabs)
    }
    
    func showCreateQuery() {
        navigate(to: .createQuery)
    }
    
    func showEditQuery(_ query: SearchQuery) {
        navigate(to: .editQuery(query))
    }
    
    func didCompleteAuth() {
        isAuthenticated = true
        showMainTabs()
    }
    
    func didSignOut() {
        isAuthenticated = false
        popToRoot()
    }
}