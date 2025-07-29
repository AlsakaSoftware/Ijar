import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PropertyBrowserView()
                .tabItem {
                    Image(systemName: "square.stack")
                    Text("Browse")
                }
                .tag(0)
            
            SearchQueriesListView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Searches")
                }
                .tag(1)
            
            FavoritesListView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
    }
}