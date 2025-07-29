import SwiftUI

struct FavoritesListView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        List {
            if viewModel.favorites.isEmpty && !viewModel.isLoading {
                EmptyFavoritesView()
            } else {
                ForEach(viewModel.favorites) { favorite in
                    if let property = favorite.property {
                        FavoritePropertyRow(
                            property: property,
                            queryName: favorite.query?.name ?? "Unknown Search"
                        )
                        .onTapGesture {
                            viewModel.openProperty(property)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeFavorite(viewModel.favorites[index])
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .refreshable {
            viewModel.fetchFavorites()
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

struct FavoritePropertyRow: View {
    let property: Property
    let queryName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Property Image
            if let imageUrl = property.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Property Details
            VStack(alignment: .leading, spacing: 4) {
                Text(property.price)
                    .font(.headline)
                
                Text(property.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(property.bedrooms) bed", systemImage: "bed.double")
                    Label("\(property.bathrooms) bath", systemImage: "shower")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text(queryName)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No favorites yet")
                .font(.headline)
            
            Text("Swipe right on properties you like\nto save them here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}