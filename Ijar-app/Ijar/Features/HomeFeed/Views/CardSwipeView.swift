import SwiftUI
import Kingfisher

struct CardSwipeView: View {
    @EnvironmentObject var coordinator: HomeFeedCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var initialPropertiesStore: InitialPropertiesStore
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var viewModel = HomeFeedViewModel()

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(UserDefaultsKeys.hasSeenSwipeTutorial) private var hasSeenSwipeTutorial = false


    var body: some View {
        ZStack {
            VStack {
                if viewModel.properties.isEmpty {
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        emptyStateView
                    }
                } else {
                    propertyCounter
                        .padding(.top, 25)
                        .opacity(viewModel.showContent ? 1 : 0)

                    Spacer()

                    cardStackSection
                        .padding(.horizontal, 15)
                        .opacity(viewModel.showContent ? 1 : 0)
                        .scaleEffect(viewModel.showContent ? 1 : 0.95)

                    Spacer()
                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.warmCream)
        .task {
            await viewModel.loadInitialData(
                initialPropertiesStore: initialPropertiesStore,
                authService: authService,
                notificationService: notificationService
            )

            let delay = viewModel.isFirstTimeEntrance ? 0.1 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    viewModel.showContent = true
                }
                viewModel.ambientAnimation = true

                if !hasSeenSwipeTutorial {
                    hasSeenSwipeTutorial = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.showSwipeTutorial = true
                    }
                }
            }
        }
        .refreshable {
            if !authService.isInGuestMode {
                await viewModel.refreshProperties()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase == .background && !authService.isInGuestMode {
                Task {
                    await viewModel.refreshProperties()
                }
            }
        }
        .onChange(of: viewModel.properties.count) { _, _ in
            viewModel.prefetchTopProperties()
        }
        .sheet(isPresented: $viewModel.showingCreateQuery) {
            CreateSearchQueryView { query in
                Task {
                    await viewModel.createQueryAndSearch(query)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAreasSheet) {
            NavigationStack {
                SearchQueriesView()
            }
            .presentationDragIndicator(.visible)
        }
        .alert("Your First Search is Live!", isPresented: $viewModel.showingSearchStartedAlert) {
            Button("Got it!") { }
        } message: {
            Text("We'll send you some properties in a few minutes. We'll keep sending suitable matches for your area as we find them")
        }
        .sheet(isPresented: $viewModel.showingGuestSignUpPrompt) {
            GuestSignUpPromptSheet(
                action: viewModel.guestSignUpAction,
                onDismiss: {
                    viewModel.showingGuestSignUpPrompt = false
                }
            )
            .environmentObject(authService)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - View Components
    private var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.rusticOrange)

                Text("Finding your matches...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.warmBrown)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyStateView: some View {
        let hasQueries = viewModel.hasQueries
        let isGuest = authService.isInGuestMode

        return VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                if isGuest {
                    Text("Ready to find your next home?")
                        .font(.system(size: 32, weight: .bold))

                    Text("Sign up to get tailored homes sent to you.")
                        .font(.system(size: 17))
                    .foregroundColor(.warmBrown.opacity(0.7))
                } else {
                    Text(hasQueries ? "You're all caught up" : "No properties yet")
                        .font(.system(size: 32, weight: .bold))

                    Text(hasQueries ? "We'll notify you when new properties match your searches." : "Add a search area to start receiving property matches.")
                        .font(.system(size: 17))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            .opacity(viewModel.showContent ? 1 : 0)
            .offset(y: viewModel.showContent ? 0 : 15)

            Spacer()

            if isGuest {
                SignInWithAppleButtonView()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(viewModel.showContent ? 1 : 0)
            } else {
                Button {
                    viewModel.showingCreateQuery = true
                } label: {
                    Text(hasQueries ? "Add Another Area" : "Add Search Area")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.rusticOrange)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .opacity(viewModel.showContent ? 1 : 0)
            }
        }
        .animation(.easeOut(duration: 0.35), value: viewModel.showContent)
    }

    private var cardStackSection: some View {
        CardStackView(
            items: viewModel.properties,
            topItem: .constant(0),
            cardContent: { property, isTopCard, dragAmount, saveProgress, passProgress, detailsProgress in
                PropertyCard(
                    property: property,
                    onTap: {
                        coordinator.navigate(to: .propertyDetail(property: property))
                    },
                    dragAmount: dragAmount,
                    saveProgress: saveProgress,
                    passProgress: passProgress,
                    detailsProgress: detailsProgress
                )
            },
            onSwipeLeft: { property in
                if authService.isInGuestMode {
                    viewModel.guestSignUpAction = .pass
                    viewModel.showingGuestSignUpPrompt = true
                    return
                }
                Task {
                    await MainActor.run {
                        withAnimation(.none) {
                            viewModel.removeTopProperty()
                        }
                    }
                    await viewModel.handleSwipeLeft(property: property)
                }
            },
            onSwipeRight: { property in
                if authService.isInGuestMode {
                    viewModel.guestSignUpAction = .save
                    viewModel.showingGuestSignUpPrompt = true
                    return
                }
                Task {
                    await MainActor.run {
                        withAnimation(.none) {
                            viewModel.removeTopProperty()
                        }
                    }
                    await viewModel.handleSwipeRight(property: property)
                }
            },
            onSwipeUp: { property in
                coordinator.navigate(to: .propertyDetail(property: property))
            },
            dragDirection: $viewModel.dragDirection,
            showTutorial: $viewModel.showSwipeTutorial
        )
    }

    private var propertyCounter: some View {
        Button {
            if authService.isInGuestMode {
                viewModel.guestSignUpAction = .areas
                viewModel.showingGuestSignUpPrompt = true
            } else {
                viewModel.showingAreasSheet = true
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.rusticOrange)
                    .frame(width: 8, height: 8)

                Text("\(viewModel.properties.count) to review")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.coffeeBean)

                Text("•")
                    .foregroundColor(.warmBrown.opacity(0.4))

                Text("Edit areas")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.rusticOrange)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.warmCream)
                    .shadow(color: .rusticOrange.opacity(0.15), radius: 4, y: 2)
                    .overlay(
                        Capsule()
                            .stroke(Color.rusticOrange.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(viewModel.ambientAnimation ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: viewModel.ambientAnimation)
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        CardSwipeView()
            .environmentObject(HomeFeedCoordinator())
            .environmentObject(AppCoordinator())
            .environmentObject(InitialPropertiesStore())
            .environmentObject(NotificationService())
    }
}

#Preview("iPhone SE") {
    NavigationStack {
        CardSwipeView()
            .environmentObject(HomeFeedCoordinator())
            .environmentObject(AppCoordinator())
            .environmentObject(InitialPropertiesStore())
            .environmentObject(NotificationService())
    }
}

#Preview("iPhone 15 Pro Max") {
    NavigationStack {
        CardSwipeView()
            .environmentObject(HomeFeedCoordinator())
            .environmentObject(AppCoordinator())
            .environmentObject(InitialPropertiesStore())
            .environmentObject(NotificationService())
    }
}
