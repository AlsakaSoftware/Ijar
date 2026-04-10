import SwiftUI

protocol NavigationDestination: Hashable {}

protocol Coordinator: AnyObject {
    var navigationPath: NavigationPath { get set }
    func popToRoot()
    func pop()
}

extension Coordinator {
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}