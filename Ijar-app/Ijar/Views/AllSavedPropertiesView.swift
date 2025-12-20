import SwiftUI

enum SavedSortOption: String, CaseIterable {
    case newest = "Newest"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case bedroomsLowToHigh = "Bedrooms: Low to High"
    case bedroomsHighToLow = "Bedrooms: High to Low"

    var icon: String {
        switch self {
        case .newest: return "clock"
        case .priceLowToHigh: return "arrow.up"
        case .priceHighToLow: return "arrow.down"
        case .bedroomsLowToHigh: return "arrow.up"
        case .bedroomsHighToLow: return "arrow.down"
        }
    }
}

struct AllSavedPropertiesView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    @EnvironmentObject var propertyService: PropertyService
    @State private var animateContent = false
    @State private var selectedSort: SavedSortOption = .newest
    @State private var selectedProperty: Property?

    private var sortedProperties: [Property] {
        switch selectedSort {
        case .newest:
            return propertyService.savedProperties
        case .priceLowToHigh:
            return propertyService.savedProperties.sorted { extractPrice($0.price) < extractPrice($1.price) }
        case .priceHighToLow:
            return propertyService.savedProperties.sorted { extractPrice($0.price) > extractPrice($1.price) }
        case .bedroomsLowToHigh:
            return propertyService.savedProperties.sorted { $0.bedrooms < $1.bedrooms }
        case .bedroomsHighToLow:
            return propertyService.savedProperties.sorted { $0.bedrooms > $1.bedrooms }
        }
    }

    private func extractPrice(_ priceString: String) -> Int {
        let digitsOnly = priceString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digitsOnly) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            if propertyService.isLoading && propertyService.savedProperties.isEmpty {
                loadingView
            } else if propertyService.savedProperties.isEmpty {
                emptyStateView
            } else {
                propertiesList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .navigationTitle("All Saved")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(.rusticOrange)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !propertyService.savedProperties.isEmpty {
                    Menu {
                        ForEach(SavedSortOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSort = option
                                }
                            } label: {
                                Label(option.rawValue, systemImage: selectedSort == option ? "checkmark" : option.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 12))
                            Text("Sort")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(.rusticOrange)
                    }
                }
            }
        }
        .onAppear {
            // Data already loaded by SavedGroupsView - just animate
            withAnimation(.easeOut(duration: 0.4)) {
                animateContent = true
            }
        }
        .groupPicker(
            propertyService: propertyService,
            selectedProperty: $selectedProperty
        )
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.rusticOrange.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .offset(x: CGFloat(index - 1) * 30)
                        .scaleEffect(animateContent ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animateContent
                        )
                }
            }

            Text("Finding your saved homes...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.warmBrown)

            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.rusticOrange.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateContent)

                Image(systemName: "heart.slash")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.rusticOrange, Color.warmRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animateContent ? 0 : -10))
                    .animation(.spring(response: 0.8, dampingFraction: 0.5), value: animateContent)
            }

            VStack(spacing: 12) {
                Text("No favorites yet")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.coffeeBean)

                Text("Heart the homes you love, and\nwe'll keep them here for you")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.warmBrown.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var propertiesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(sortedProperties.enumerated()), id: \.element.id) { index, property in
                    PropertyListCard(
                        property: property,
                        isSaved: true,
                        onTap: {
                            coordinator.navigate(to: .propertyDetail(property: property))
                        },
                        onSaveToggle: {
                            selectedProperty = property
                        }
                    )
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 50)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(min(index, 5)) * 0.1),
                        value: animateContent
                    )
                }
            }
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
    }
}
