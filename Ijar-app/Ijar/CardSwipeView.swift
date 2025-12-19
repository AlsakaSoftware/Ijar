import SwiftUI
import Kingfisher

struct CardSwipeView: View {
    @EnvironmentObject var coordinator: HomeFeedCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var initialPropertiesStore: InitialPropertiesStore
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var propertyService = PropertyService()
    @StateObject private var searchService = SearchQueryService()
    @StateObject private var monitorService = MonitorService()
    @Environment(\.scenePhase) private var scenePhase
    @State private var dragDirection: SwipeDirection = .none
    @State private var buttonPressed: SwipeDirection = .none
    @State private var ambientAnimation = false
    @State private var showingCreateQuery = false
    @State private var showingSearchStartedAlert = false
    @State private var showingAreasSheet = false
    @State private var hasUsedInitialProperties = false
    @State private var showingGuestSignUpPrompt = false 
    @State private var guestSignUpAction: GuestSignUpAction = .pass

    // Entrance animation states
    @State private var showContent = false
    @State private var isFirstTimeEntrance = false
    @State private var showSwipeTutorial = false
    @AppStorage(UserDefaultsKeys.hasSeenSwipeTutorial) private var hasSeenSwipeTutorial = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    
    
    var body: some View {
        ZStack {
            VStack {
                if propertyService.properties.isEmpty {
                    if propertyService.isLoading {
                        loadingView
                    } else {
                        emptyStateView
                    }
                } else {
                    propertyCounter
                        .padding(.top, 25)
                        .opacity(showContent ? 1 : 0)

                    Spacer()

                    cardStackSection
                        .padding(.horizontal, 15)
                        .padding(.bottom, 40)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.95)

                    Spacer()

                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .background(Color.warmCream)
        .task {
            // Request notification permission if not determined
            await notificationService.checkAndRequestNotificationPermission()

            // Check if coming from onboarding (have initial properties)
            let comingFromOnboarding = !initialPropertiesStore.properties.isEmpty

            // Use initial properties from onboarding if available
            if comingFromOnboarding {
                propertyService.setProperties(initialPropertiesStore.properties)
                initialPropertiesStore.clear()
                hasUsedInitialProperties = true
                isFirstTimeEntrance = true
            } else if authService.isInGuestMode {
                // Guest mode: Use properties from GuestPreferencesStore
                let guestProperties = GuestPreferencesStore.shared.properties
                if !guestProperties.isEmpty && propertyService.properties.isEmpty {
                    propertyService.setProperties(guestProperties)
                    isFirstTimeEntrance = !hasUsedInitialProperties
                    hasUsedInitialProperties = true
                }
                // Don't load from database for guests
            } else {
                await propertyService.loadPropertiesForUser()
            }

            if !authService.isInGuestMode {
                await searchService.loadUserQueries()
            }
            prefetchTopProperties()

            let delay = isFirstTimeEntrance ? 0.1 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showContent = true
                }
                ambientAnimation = true

                // Show tutorial only once ever
                if !hasSeenSwipeTutorial {
                    hasSeenSwipeTutorial = true // Set immediately to prevent race conditions
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSwipeTutorial = true
                    }
                }
            }
        }
        .refreshable {
            if !authService.isInGuestMode {
                await propertyService.loadPropertiesForUser()
                prefetchTopProperties()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase == .background && !authService.isInGuestMode {
                Task {
                    await propertyService.loadPropertiesForUser()
                    prefetchTopProperties()
                }
            }
        }
        .onChange(of: propertyService.properties.count) { _, _ in
            prefetchTopProperties()
        }
        .sheet(isPresented: $showingCreateQuery) {
            CreateSearchQueryView { query in
                Task {
                    await searchService.createQuery(query)
                    // Automatically trigger search for the user's first query only
                    await triggerSearchForNewQuery()
                    // Reload properties after creating a new search query
                    await propertyService.loadPropertiesForUser()
                }
            }
        }
        .sheet(isPresented: $showingAreasSheet) {
            NavigationStack {
                SearchQueriesView()
            }
            .presentationDragIndicator(.visible)
        }
        .alert("Your First Search is Live!", isPresented: $showingSearchStartedAlert) {
            Button("Got it!") { }
        } message: {
            Text("We'll send you some properties in a few minutes. We'll keep sending suitable matches for your area as we find them")
        }
        .sheet(isPresented: $showingGuestSignUpPrompt) {
            GuestSignUpPromptSheet(
                action: guestSignUpAction,
                onDismiss: {
                    showingGuestSignUpPrompt = false
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
        let hasQueries = !searchService.queries.isEmpty
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
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)

            Spacer()

            if isGuest {
                SignInWithAppleButtonView()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(showContent ? 1 : 0)
            } else {
                Button {
                    showingCreateQuery = true
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
                .opacity(showContent ? 1 : 0)
            }
            
        }
        .animation(.easeOut(duration: 0.35), value: showContent)
    }
    
    private var cardStackSection: some View {
        CardStackView(
            items: propertyService.properties,
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
                    guestSignUpAction = .pass
                    showingGuestSignUpPrompt = true
                    return
                }
                Task {
                    await MainActor.run {
                        withAnimation(.none) {
                            propertyService.removeTopProperty()
                        }
                    }
                    await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
                }
            },
            onSwipeRight: { property in
                if authService.isInGuestMode {
                    guestSignUpAction = .save
                    showingGuestSignUpPrompt = true
                    return
                }
                Task {
                    await MainActor.run {
                        withAnimation(.none) {
                            propertyService.removeTopProperty()
                        }
                    }
                    let success = await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
                    #if DEBUG
                    if success {
                        print("✅ CardSwipeView: Successfully saved property \(property.id)")
                    } else {
                        print("❌ CardSwipeView: Failed to save property \(property.id)")
                    }
                    #endif
                }
            },
            onSwipeUp: { property in
                coordinator.navigate(to: .propertyDetail(property: property))
            },
            dragDirection: $dragDirection,
            showTutorial: $showSwipeTutorial
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 60) {
            dismissButton
            saveButton
        }
    }
    
    private var dismissButton: some View {
        Button(action: {
            impactFeedback.impactOccurred()
            buttonPressed = .left
            dismissCard()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                buttonPressed = .none
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.warmBrown)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(Color.warmCream)
                        .shadow(color: .warmBrown.opacity((dragDirection == .left || buttonPressed == .left) ? 0.4 : 0.1), radius: (dragDirection == .left || buttonPressed == .left) ? 16 : 8, y: 2)
                )
                .scaleEffect((dragDirection == .left || buttonPressed == .left) ? 1.1 : 1.0)
                .overlay(
                    Circle()
                        .stroke(Color.warmBrown.opacity((dragDirection == .left || buttonPressed == .left) ? 0.3 : 0), lineWidth: 2)
                        .scaleEffect((dragDirection == .left || buttonPressed == .left) ? 1.2 : 1.0)
                        .opacity((dragDirection == .left || buttonPressed == .left) ? 0.6 : 0)
                )
        }
        .disabled(propertyService.properties.isEmpty)
        .animation(.easeOut(duration: 0.15), value: dragDirection)
        .animation(.easeOut(duration: 0.15), value: buttonPressed)
    }
    
    private var saveButton: some View {
        Button(action: {
            selectionFeedback.selectionChanged()
            buttonPressed = .right
            saveCard()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                buttonPressed = .none
            }
        }) {
            Image(systemName: "heart.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.rusticOrange)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(Color.warmCream)
                        .shadow(color: .rusticOrange.opacity((dragDirection == .right || buttonPressed == .right) ? 0.4 : 0.15), radius: (dragDirection == .right || buttonPressed == .right) ? 16 : 8, y: 2)
                )
                .scaleEffect((dragDirection == .right || buttonPressed == .right) ? 1.1 : 1.0)
                .overlay(
                    Circle()
                        .stroke(Color.rusticOrange.opacity((dragDirection == .right || buttonPressed == .right) ? 0.3 : 0), lineWidth: 2)
                        .scaleEffect((dragDirection == .right || buttonPressed == .right) ? 1.2 : 1.0)
                        .opacity((dragDirection == .right || buttonPressed == .right) ? 0.6 : 0)
                )
        }
        .disabled(propertyService.properties.isEmpty)
        .animation(.easeOut(duration: 0.15), value: dragDirection)
        .animation(.easeOut(duration: 0.15), value: buttonPressed)
    }
    
    private var propertyCounter: some View {
        Button {
            if authService.isInGuestMode {
                guestSignUpAction = .areas
                showingGuestSignUpPrompt = true
            } else {
                showingAreasSheet = true
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.rusticOrange)
                    .frame(width: 8, height: 8)

                Text("\(propertyService.properties.count) to review")
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
        .scaleEffect(ambientAnimation ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: ambientAnimation)
    }
    
    private func saveCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
            Task {
                await propertyService.trackPropertyAction(propertyId: property.id, action: .saved)
                await MainActor.run {
                    propertyService.removeTopProperty()
                }
            }
        }
    }
    
    private func dismissCard() {
        if !propertyService.properties.isEmpty {
            let property = propertyService.properties[0]
            Task {
                await propertyService.trackPropertyAction(propertyId: property.id, action: .passed)
                await MainActor.run {
                    propertyService.removeTopProperty()
                }
            }
        }
    }

    private func triggerSearchForNewQuery() async {
        let hasTriggeredFirstQuerySearch = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)

        let isFirstQuery = searchService.queries.count == 1

        guard isFirstQuery, !hasTriggeredFirstQuerySearch else { return }

        guard let userId = try? await searchService.getCurrentUserId() else {
            return
        }

        let success = await monitorService.refreshPropertiesForUser(userId: userId)

        if success {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasTriggeredFirstQuerySearch)
            showingSearchStartedAlert = true
        }
    }

    private func prefetchTopProperties() {
        // Prefetch images for the top 3 properties
        let propertiesToPrefetch = Array(propertyService.properties.prefix(3))

        // Get all images from each property
        let urls = propertiesToPrefetch.flatMap { property in
            property.images.compactMap { URL(string: $0) }
        }

        guard !urls.isEmpty else { return }

        // Start prefetching with Kingfisher
        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()

        #if DEBUG
        print("🔄 Prefetching \(urls.count) images for \(propertiesToPrefetch.count) properties")
        #endif
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

