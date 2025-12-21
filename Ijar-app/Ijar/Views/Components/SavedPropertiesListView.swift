import SwiftUI

/// Shared component for displaying a sortable list of saved properties
struct SavedPropertiesListView: View {
    let properties: [Property]
    let isLoading: Bool
    let loadingText: String
    let emptyIcon: String
    let emptyTitle: String
    let emptyMessage: String
    let propertyService: PropertyService
    let savedPropertyRepository: SavedPropertyRepository
    let onPropertyTap: (Property) -> Void
    let onSaveStateChanged: (Property, Bool) -> Void

    @State private var animateContent = false
    @State private var selectedSort: SavedSortOption = .newest

    private var sortedProperties: [Property] {
        switch selectedSort {
        case .newest:
            return properties
        case .priceLowToHigh:
            return properties.sorted { extractPrice($0.price) < extractPrice($1.price) }
        case .priceHighToLow:
            return properties.sorted { extractPrice($0.price) > extractPrice($1.price) }
        case .bedroomsLowToHigh:
            return properties.sorted { $0.bedrooms < $1.bedrooms }
        case .bedroomsHighToLow:
            return properties.sorted { $0.bedrooms > $1.bedrooms }
        }
    }

    private func extractPrice(_ priceString: String) -> Int {
        let digitsOnly = priceString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digitsOnly) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if properties.isEmpty {
                emptyStateView
            } else {
                propertiesList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !properties.isEmpty {
                    sortMenu
                }
            }
        }
        .onChange(of: isLoading) { _, newValue in
            if !newValue {
                withAnimation(.easeOut(duration: 0.4)) {
                    animateContent = true
                }
            }
        }
    }

    private var sortMenu: some View {
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
                Text("Sort:")
                    .font(.system(size: 13))
                Text(selectedSort.rawValue)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.rusticOrange)
        }
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

            Text(loadingText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.warmBrown)

            Spacer()
        }
        .onAppear {
            animateContent = true
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

                Image(systemName: emptyIcon)
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
                Text(emptyTitle)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.coffeeBean)

                Text(emptyMessage)
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
                    SaveablePropertyCard(
                        property: property,
                        propertyService: propertyService,
                        savedPropertyRepository: savedPropertyRepository,
                        onTap: {
                            onPropertyTap(property)
                        },
                        onRemove: {
                            onSaveStateChanged(property, false)
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
