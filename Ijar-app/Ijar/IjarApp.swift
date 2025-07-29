//
//  IjarApp.swift
//  Ijar
//
//  Created by Karim Alsaka on 29/07/2025.
//

import SwiftUI

@main
struct IjarApp: App {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationCoordinator)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            // Root view based on authentication state
            if navigationCoordinator.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .navigationDestination(for: AppDestination.self) { destination in
            destinationView(for: destination)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .signIn:
            SignInView()
        case .signUp:
            SignUpView()
        case .mainTabs:
            MainTabView()
        case .createQuery:
            CreateQueryView(editingQuery: nil)
        case .editQuery(let query):
            CreateQueryView(editingQuery: query)
        }
    }
}
