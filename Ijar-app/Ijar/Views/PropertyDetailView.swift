import SwiftUI
import SwiftData
import Kingfisher

struct PropertyDetailView: View {
    let property: Property
    let isSavedProperty: Bool
    let showLikeButton: Bool
    private let propertyService: PropertyService
    @State private var currentImageIndex = 0
    @State private var showingFullScreenImages = false
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var authService: AuthenticationService

    @State private var showingGuestSignUpPrompt = false

    // Property details state - start with basic property, enrich with details when fetched
    @State private var displayProperty: Property
    @State private var displayImages: [String] = []
    @State private var isLoadingDetails = false
    @StateObject private var searchService = LiveSearchService()

    init(property: Property, isSavedProperty: Bool, showLikeButton: Bool = true, propertyService: PropertyService = PropertyService()) {
        self.property = property
        self.isSavedProperty = isSavedProperty
        self.showLikeButton = showLikeButton
        self.propertyService = propertyService
        _displayProperty = State(initialValue: property)
    }

    // TfL transport data
    private let tflService = TfLService()
    @State private var nearbyStations: [TubeStation] = []
    @State private var nearbyBusStops: [BusStop] = []
    @State private var isLoadingTransport = false
    @State private var transportError: String?

    // Journey times to saved locations
    private let journeyService = TfLJourneyService()
    @StateObject private var locationsManager = SavedLocationsManager()
    @State private var journeys: [SavedLocation: Journey?] = [:]
    @State private var isLoadingJourneys = false

    // Geocoding service for properties without coordinates
    private let geocodingService = GeocodingService()
    @State private var geocodedCoordinates: (latitude: Double, longitude: Double)?

    // SwiftData for property metadata
    @Environment(\.modelContext) private var modelContext
    @Query private var allMetadata: [PropertyMetadata]
    @State private var metadata: PropertyMetadata?

    // Checklist and notes state
    @State private var calledAgent = false
    @State private var setViewing = false
    @State private var putOffer = false
    @State private var notes = ""
    @FocusState private var notesFieldFocused: Bool

    // Floorplan state
    @State private var showingFloorplan = false

    // Like/Save state
    @State private var isLiked: Bool = false
    @State private var isLikeLoading = false
    @State private var showingGroupPicker = false

    private func loadOrCreateMetadata() {
        // Find existing metadata for this property
        if let existing = allMetadata.first(where: { $0.propertyId == property.id }) {
            metadata = existing
            calledAgent = existing.calledAgent
            setViewing = existing.setViewing
            putOffer = existing.putOffer
            notes = existing.notes
        } else {
            // Create new metadata
            let newMetadata = PropertyMetadata(propertyId: property.id)
            modelContext.insert(newMetadata)
            metadata = newMetadata
        }
    }

    private func savePropertyMetadata() {
#if DEBUG
        print("🔥 PropertyDetailView: Saving metadata for property \(property.id)")
        print("   - Called Agent: \(calledAgent)")
        print("   - Set Viewing: \(setViewing)")
        print("   - Put Offer: \(putOffer)")
        print("   - Notes: '\(notes)'")
#endif

        if let metadata = metadata {
            metadata.update(calledAgent: calledAgent, setViewing: setViewing, putOffer: putOffer, notes: notes)
        } else {
            let newMetadata = PropertyMetadata(
                propertyId: property.id,
                calledAgent: calledAgent,
                setViewing: setViewing,
                putOffer: putOffer,
                notes: notes
            )
            modelContext.insert(newMetadata)
            self.metadata = newMetadata
        }

        do {
            try modelContext.save()
#if DEBUG
            print("✅ PropertyDetailView: Metadata saved successfully")
#endif
        } catch {
#if DEBUG
            print("❌ PropertyDetailView: Failed to save metadata: \(error)")
#endif
        }
    }

    // Computed property to get coordinates (from property or geocoded fallback)
    private var propertyCoordinates: (latitude: Double, longitude: Double)? {
        if let lat = property.latitude, let lon = property.longitude {
            return (lat, lon)
        }
        return geocodedCoordinates
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image section
                heroImageSection

                // Property details content
                VStack(spacing: 20) {
                    // Floorplan button
                    if let floorplans = displayProperty.floorplanImages, !floorplans.isEmpty {
                        floorplanButton
                    }

                    // Price and basic info
                    propertyHeaderSection

                    // Property Details section (combines features with listing details)
                    propertyDetailsSection

                    // Location section
                    locationSection

                    // Nearby tube stations section
                    if propertyCoordinates != nil {
                        nearbyStationsSection
                    }

                    // Journey times to saved locations
                    if propertyCoordinates != nil {
                        if !locationsManager.locations.isEmpty {
                            journeyTimesSection
                        } else {
                            NoSavedLocationsPrompt {
                                appCoordinator.navigate(to: .profile(.savedLocations))
                            }
                        }
                    }

                    // Map section
                    if let coordinates = propertyCoordinates {
                        PropertyMapView(
                            address: property.address,
                            latitude: coordinates.latitude,
                            longitude: coordinates.longitude
                        )
                    }

                    // Progress section (checklist + notes combined) - only for saved properties
                    if isSavedProperty {
                        progressSection
                    }

                    // Agent contact section
                    agentContactSection

                    // Additional details could go here
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(action: {
                    notesFieldFocused = false
                    savePropertyMetadata()
                }) {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.rusticOrange)
                }
            }
        }
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                if notesFieldFocused {
                    savePropertyMetadata()
                    notesFieldFocused = false
                }
            }
        )
        .onChange(of: notesFieldFocused) { _, newValue in
            // Save when keyboard dismisses and there's content
            if !newValue && isSavedProperty {
                savePropertyMetadata()
            }
        }
        .fullScreenCover(isPresented: $showingFullScreenImages) {
            FullScreenImageGallery(
                images: displayImages,
                currentIndex: $currentImageIndex,
                isPresented: $showingFullScreenImages
            )
        }
        .sheet(isPresented: $showingFloorplan) {
            FloorplanViewer(
                floorplans: displayProperty.floorplanImages ?? [],
                isPresented: $showingFloorplan
            )
        }
        .sheet(isPresented: $showingGuestSignUpPrompt) {
            GuestSignUpPromptSheet(
                action: .save,
                onDismiss: {
                    showingGuestSignUpPrompt = false
                }
            )
            .environmentObject(authService)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .groupPicker(
            property: property,
            propertyService: propertyService,
            isPresented: $showingGroupPicker,
            onUnsave: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLiked = false
                }
            }
        )
        .onceTask {
            // Fetch full property details from Rightmove API (via our server)
            // This gets HD images, description, floorplans, etc.
            isLoadingDetails = true
            if let enrichedProperty = await searchService.fetchPropertyDetails(for: property) {
                displayProperty = enrichedProperty
                displayImages = enrichedProperty.images
#if DEBUG
                print("📋 Property details loaded: \(enrichedProperty.images.count) HD images, description: \(enrichedProperty.description != nil)")
#endif
            }
            isLoadingDetails = false

            // Check saved status from DB (runs once on first appear)
            if isSavedProperty {
                isLiked = true
                loadOrCreateMetadata()
            } else {
                let isSaved = await propertyService.isLiveSearchPropertySaved(property)
                isLiked = isSaved
            }

            // Show existing images immediately while loading details
            if displayImages.isEmpty {
                displayImages = property.images
            }
        }
        .onAppear {
            // Reload locations in case new ones were added
            locationsManager.loadLocations()

            // Fetch journeys if we have both coordinates and locations
            if propertyCoordinates != nil && !locationsManager.locations.isEmpty {
                Task {
                    await fetchJourneys()
                }
            }
        }
        .task {
            // Geocode address if property doesn't have coordinates
            if property.latitude == nil || property.longitude == nil {
                do {
                    // Try to geocode the address
                    let address = property.area.isEmpty ? property.address : "\(property.address), \(property.area)"
#if DEBUG
                    print("🗺️ Geocoding address: \(address)")
#endif
                    let coordinates = try await geocodingService.geocode(address)
                    geocodedCoordinates = coordinates
#if DEBUG
                    print("✅ Geocoded to: \(coordinates.latitude), \(coordinates.longitude)")
#endif
                } catch {
                    // If geocoding fails, we just won't show transport info
#if DEBUG
                    print("❌ Geocoding failed: \(error)")
#endif
                    transportError = "Could not determine location coordinates"
                    return
                }
            }

            // Get coordinates (either from property or geocoded)
            guard let coordinates = propertyCoordinates else { return }
            let lat = coordinates.latitude
            let lon = coordinates.longitude

#if DEBUG
            print("📍 Using coordinates: \(lat), \(lon)")
#endif

            // Fetch nearby transport
            isLoadingTransport = true
            transportError = nil

            do {
                let result = try await tflService.fetchNearbyStations(latitude: lat, longitude: lon)
                nearbyStations = result.stations
                nearbyBusStops = result.busStops
#if DEBUG
                print("✅ Found \(result.stations.count) stations, \(result.busStops.count) bus stops")
#endif
            } catch {
                transportError = error.localizedDescription
#if DEBUG
                print("❌ TfL API error: \(error)")
#endif
            }

            isLoadingTransport = false

            // Fetch journey times to saved locations
            guard !locationsManager.locations.isEmpty else { return }

            isLoadingJourneys = true

            await withTaskGroup(of: (SavedLocation, Journey?).self) { group in
                for location in locationsManager.locations {
                    guard let toLat = location.latitude, let toLon = location.longitude else {
                        journeys[location] = nil
                        continue
                    }

                    group.addTask {
                        do {
                            let journey = try await self.journeyService.fetchJourney(
                                fromLat: lat,
                                fromLon: lon,
                                toLat: toLat,
                                toLon: toLon,
                                mode: .all  // Always use all transport modes
                            )
                            return (location, journey)
                        } catch {
#if DEBUG
                            print("❌ Failed to fetch journey to \(location.name): \(error)")
#endif
                            return (location, nil)
                        }
                    }
                }

                for await (location, journey) in group {
                    journeys[location] = journey
                }
            }

            isLoadingJourneys = false
        }
    }

    private func fetchJourneys() async {
        guard let coordinates = propertyCoordinates else { return }
        guard !locationsManager.locations.isEmpty else { return }

        let lat = coordinates.latitude
        let lon = coordinates.longitude

        isLoadingJourneys = true
        journeys.removeAll()

        await withTaskGroup(of: (SavedLocation, Journey?).self) { group in
            for location in locationsManager.locations {
                guard let toLat = location.latitude, let toLon = location.longitude else {
                    journeys[location] = nil
                    continue
                }

                group.addTask {
                    do {
                        let journey = try await self.journeyService.fetchJourney(
                            fromLat: lat,
                            fromLon: lon,
                            toLat: toLat,
                            toLon: toLon,
                            mode: .all
                        )
                        return (location, journey)
                    } catch {
#if DEBUG
                        print("❌ Failed to fetch journey to \(location.name): \(error)")
#endif
                        return (location, nil)
                    }
                }
            }

            for await (location, journey) in group {
                journeys[location] = journey
            }
        }
        isLoadingJourneys = false
    }

    private var heroImageSection: some View {
        ZStack(alignment: .bottom) {
            if isLoadingDetails {
                // Loading state - show nice block color with loading indicator
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.warmCream, Color.warmCream.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 400)
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(.rusticOrange)

                            Text("Loading images...")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.warmBrown.opacity(0.7))
                        }
                    }
            } else {
                // Main image carousel
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(displayImages.enumerated()), id: \.offset) { index, imageURL in
                        KFImage(URL(string: imageURL))
                            .placeholder {
                                Rectangle()
                                    .fill(Color.warmBrown.opacity(0.1))
                                    .frame(height: 400)
                                    .overlay {
                                        ProgressView()
                                            .tint(.warmBrown)
                                    }
                            }
                            .onFailure { _ in }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 400)
                            .clipped()
                            .onTapGesture {
                                showingFullScreenImages = true
                            }
                            .tag(index)
                    }
                }
                .frame(height: 400)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }

            // Image indicators and expand button (only show when not loading)
            if !isLoadingDetails {
                VStack(spacing: 16) {
                    Spacer()

                    HStack {
                        // Image indicators - show count if more than 10 images
                        if displayImages.count > 10 {
                            Text("\(currentImageIndex + 1) / \(displayImages.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.4))
                                )
                        } else {
                            HStack(spacing: 6) {
                                ForEach(0..<displayImages.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: index == currentImageIndex ? 8 : 6, height: index == currentImageIndex ? 8 : 6)
                                        .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.4))
                            )
                        }

                        Spacer()

                        // Expand button
                        Button(action: { showingFullScreenImages = true }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.4))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Top gradient for better navigation visibility
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)

                Spacer()
            }
            .allowsHitTesting(false)

        }
    }

    private var likeButton: some View {
        LikeButton(isLiked: isLiked, isLoading: isLikeLoading, action: handleLikeToggle)
    }

    private func handleLikeToggle() {
        // Guest mode: show sign-up prompt instead of saving
        if authService.isInGuestMode {
            showingGuestSignUpPrompt = true
            return
        }

        if isLiked {
            // Already saved - show group picker to manage groups or unsave
            showingGroupPicker = true
        } else {
            // Save to All Saved first, then show group picker
            Task {
                isLikeLoading = true
                let success = await propertyService.saveLiveSearchProperty(property)
                if success {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked = true
                    }
                }
                isLikeLoading = false
                showingGroupPicker = true
            }
        }
    }

    private var propertyHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Price with like button (if shown)
            HStack(alignment: .center) {
                Text(property.price)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.coffeeBean)

                Spacer()

                if showLikeButton {
                    likeButton
                }
            }

            // Address
            VStack(alignment: .leading, spacing: 4) {
                Text(property.address)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.warmBrown)

                if !property.area.isEmpty {
                    Text(property.area)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var propertyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Property Details")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.coffeeBean)

            // First row: Bedrooms and Bathrooms (larger)
            HStack(spacing: 24) {
                // Bedrooms
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.rusticOrange)

                    Text(property.bedrooms == 0 ? "1" : "\(property.bedrooms)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.coffeeBean)

                    Text(property.bedrooms == 0 ? "Studio" : "Bedroom\(property.bedrooms == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.warmCream)
                        .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
                )

                // Bathrooms
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "shower.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.rusticOrange)

                    if isLoadingDetails {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(height: 24)
                    } else if displayProperty.bathrooms > 0 {
                        Text("\(displayProperty.bathrooms)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.coffeeBean)
                    } else {
                        Text("—")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.warmBrown.opacity(0.5))
                    }

                    Text("Bathroom\(displayProperty.bathrooms == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.warmCream)
                        .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
                )
            }

            // Additional details grid (smaller cards)
            if shouldShowListingDetails {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    if let propertyType = displayProperty.propertyType {
                        smallDetailCard(icon: "house.fill", label: "Type", value: propertyType)
                    }

                    if let floorArea = displayProperty.floorArea {
                        smallDetailCard(icon: "square.fill", label: "Size", value: floorArea)
                    }

                    if let epcRating = displayProperty.epcRating {
                        smallDetailCard(icon: "leaf.fill", label: "EPC", value: epcRating)
                    }

                    if let councilTaxBand = displayProperty.councilTaxBand {
                        smallDetailCard(icon: "banknote.fill", label: "Council Tax", value: "Band \(councilTaxBand)")
                    }

                    if let tenure = displayProperty.tenure {
                        smallDetailCard(icon: "doc.text.fill", label: "Tenure", value: tenure)
                    }

                    if let availableFrom = displayProperty.availableFrom {
                        smallDetailCard(icon: "calendar.fill", label: "Available", value: availableFrom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func smallDetailCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.rusticOrange)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .textCase(.uppercase)
            }

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.coffeeBean)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.warmCream)
        )
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.coffeeBean)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.rusticOrange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(property.address)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.coffeeBean)
                        
                        if !property.area.isEmpty {
                            Text(property.area)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.warmBrown.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.warmCream)
                        .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Property Details Sections

    private var floorplanButton: some View {
        Button(action: {
            showingFloorplan = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.system(size: 16))
                    .foregroundColor(.rusticOrange)

                Text("View Floorplan")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.coffeeBean)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.warmBrown.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.warmCream)
                    .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func keyFeaturesSection(features: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Features")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.coffeeBean)

            // Compact chip-style layout - 2 columns
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.rusticOrange)

                        Text(feature)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.coffeeBean)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.warmCream)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shouldShowListingDetails: Bool {
        displayProperty.propertyType != nil ||
        displayProperty.floorArea != nil ||
        displayProperty.epcRating != nil ||
        displayProperty.councilTaxBand != nil ||
        displayProperty.tenure != nil ||
        displayProperty.availableFrom != nil
    }


    private var nearbyStationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Rail Stations Section
            railStationsSection

            // Bus Stops Section
            if !nearbyBusStops.isEmpty {
                busStopsSection
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var railStationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.rusticOrange)

                Text("Rail Stations")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.coffeeBean)
            }

            if isLoadingTransport {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.rusticOrange)
                    Text("Finding stations...")
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
                .padding(.vertical, 8)
            } else if let error = transportError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.rusticOrange)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown)
                }
                .padding(.vertical, 8)
            } else if nearbyStations.isEmpty && !isLoadingTransport {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.rusticOrange)
                    Text("No stations nearby")
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown)
                }
                .padding(.vertical, 8)
            } else if !nearbyStations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(nearbyStations) { station in
                            HStack(spacing: 8) {
                                Image(systemName: "tram.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.rusticOrange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(station.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.coffeeBean)
                                        .lineLimit(1)

                                    Text(station.distanceInMinutes)
                                        .font(.system(size: 12))
                                        .foregroundColor(.warmBrown.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.warmCream)
                            )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var busStopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.rusticOrange)

                Text("Buses")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.coffeeBean)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(nearbyBusStops) { busStop in
                        HStack(spacing: 8) {
                            Image(systemName: "bus.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.rusticOrange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(busStop.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.coffeeBean)
                                    .lineLimit(1)

                                Text(busStop.distanceInMinutes)
                                    .font(.system(size: 12))
                                    .foregroundColor(.warmBrown.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.warmCream)
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var journeyTimesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.rusticOrange)

                Text("Journey Times")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.coffeeBean)
            }

            if isLoadingJourneys {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.rusticOrange)
                    Text("Calculating journeys...")
                        .font(.system(size: 13))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(locationsManager.locations) { location in
                        if let journey = journeys[location] {
                            if let actualJourney = journey {
                                JourneyRow(location: location, journey: actualJourney)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.coffeeBean)

            VStack(spacing: 8) {
                ChecklistItem(
                    title: "Called agent",
                    isChecked: calledAgent
                ) {
                    calledAgent.toggle()
                    savePropertyMetadata()
                }

                ChecklistItem(
                    title: "Viewed Property",
                    isChecked: setViewing
                ) {
                    setViewing.toggle()
                    savePropertyMetadata()
                }

                ChecklistItem(
                    title: "Put offer",
                    isChecked: putOffer
                ) {
                    putOffer.toggle()
                    savePropertyMetadata()
                }
            }

            // Notes field integrated into progress section
            ZStack(alignment: .topLeading) {
                if notes.isEmpty && !notesFieldFocused {
                    Text("Add your thoughts...")
                        .font(.system(size: 15))
                        .foregroundColor(.warmBrown.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }

                TextEditor(text: $notes)
                    .font(.system(size: 15))
                    .foregroundColor(.coffeeBean)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 80)
                    .padding(6)
                    .focused($notesFieldFocused)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.warmCream)
                    .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var agentContactSection: some View {
        let hasAgentInfo = (property.agentName != nil && !property.agentName!.isEmpty) ||
        (property.agentPhone != nil && !property.agentPhone!.isEmpty) ||
        (property.rightmoveUrl != nil && !property.rightmoveUrl!.isEmpty)
        
        if hasAgentInfo {
            VStack(alignment: .leading, spacing: 16) {
                Text("Contact Agent")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.coffeeBean)
                
                VStack(spacing: 12) {
                    // Agent information
                    if let agentName = property.agentName, !agentName.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.rusticOrange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(agentName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.coffeeBean)
                                
                                if let branchName = property.branchName, !branchName.isEmpty {
                                    Text(branchName)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.warmBrown.opacity(0.7))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.warmCream)
                                .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
                        )
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Call agent button
                        if let agentPhone = property.agentPhone, !agentPhone.isEmpty {
                            Button(action: {
                                if let phoneURL = URL(string: "tel:\(agentPhone)") {
                                    UIApplication.shared.open(phoneURL)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Text("Call Agent")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.rusticOrange)
                                )
                            }
                        }
                        
                        // View on Rightmove button
                        if let rightmoveUrl = property.rightmoveUrl, !rightmoveUrl.isEmpty {
                            Button(action: {
                                if let url = URL(string: rightmoveUrl) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "safari.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Text("View on Rightmove")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.coffeeBean)
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct FullScreenImageGallery: View {
    let images: [String]
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                    KFImage(URL(string: imageURL))
                        .placeholder {
                            ProgressView()
                                .tint(.white)
                        }
                        .onFailure { _ in }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    withAnimation(.spring()) {
                                        if scale < 1 {
                                            scale = 1
                                            offset = .zero
                                        } else if scale > 4 {
                                            scale = 4
                                        }
                                        lastScale = scale
                                    }
                                }
                        )
                        .gesture(
                            scale > 1 ? DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                                .onEnded { _ in
                                    withAnimation(.spring()) {
                                        let maxOffset: CGFloat = 100
                                        if abs(offset.width) > maxOffset || abs(offset.height) > maxOffset {
                                            offset = .zero
                                        }
                                    }
                                } : nil
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale == 1 {
                                    scale = 2
                                    lastScale = 2
                                } else {
                                    scale = 1
                                    lastScale = 1
                                    offset = .zero
                                }
                            }
                        }
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Controls overlay
            VStack {
                // Top controls
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.5))
                            )
                    }
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) of \(images.count)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.5))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Bottom indicators - only show dots if 10 or fewer images
                if images.count > 1 && images.count <= 10 {
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .statusBarHidden()
        .onAppear {
            resetZoom()
        }
        .onChange(of: currentIndex) { _,_ in
            resetZoom()
        }
    }
    
    private func resetZoom() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
        }
    }
}

struct JourneyRow: View {
    let location: SavedLocation
    let journey: Journey
    @State private var showingDetail = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Location icon - centered vertically
            Image(systemName: locationIcon)
                .font(.system(size: 16))
                .foregroundColor(.rusticOrange)
                .frame(width: 24)

            // Content column
            VStack(alignment: .leading, spacing: 8) {
                // Location name
                Text(location.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.coffeeBean)

                // Journey legs summary (first 3 with times, or just icons if more)
                HStack(spacing: 5) {
                    ForEach(Array(journey.legs.prefix(3).enumerated()), id: \.offset) { index, leg in
                        HStack(spacing: 3) {
                            Image(systemName: leg.icon)
                                .font(.system(size: 13))
                                .foregroundColor(.warmBrown.opacity(0.7))

                            Text("\(leg.duration)")
                                .font(.system(size: 13))
                                .foregroundColor(.warmBrown.opacity(0.6))
                                .fixedSize()
                        }

                        if index < min(2, journey.legs.count - 1) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9))
                                .foregroundColor(.warmBrown.opacity(0.4))
                        }
                    }

                    if journey.legs.count > 3 {
                        Text("+\(journey.legs.count - 3)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.warmBrown.opacity(0.6))
                            .fixedSize()
                    }
                }
                .padding(.trailing, 8)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(journey.formattedDuration)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.rusticOrange)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.warmBrown.opacity(0.4))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmCream)
                .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
        )
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            JourneyDetailView(location: location, journey: journey)
        }
    }

    private var locationIcon: String {
        let lowercasedName = location.name.lowercased()

        if lowercasedName.contains("work") || lowercasedName.contains("office") {
            return "briefcase.fill"
        } else if lowercasedName.contains("gym") || lowercasedName.contains("fitness") {
            return "figure.strengthtraining.traditional"
        } else if lowercasedName.contains("school") {
            return "building.2.fill"
        } else if lowercasedName.contains("home") || lowercasedName.contains("house") {
            return "house.fill"
        } else if lowercasedName.contains("friend") {
            return "person.2.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}

struct JourneyDetailView: View {
    @Environment(\.dismiss) var dismiss
    let location: SavedLocation
    let journey: Journey

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with total time
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: locationIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.rusticOrange)

                            Text(location.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.coffeeBean)
                        }

                        Text("Total journey time: \(journey.formattedDuration)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.warmBrown)
                    }
                    .padding(.top, 20)

                    // Journey legs
                    VStack(spacing: 16) {
                        ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    // Step number
                                    ZStack {
                                        Circle()
                                            .fill(Color.rusticOrange)
                                            .frame(width: 32, height: 32)

                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: leg.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(.rusticOrange)

                                            if let lineName = leg.lineName {
                                                Text(lineName)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.coffeeBean)
                                            } else {
                                                Text(leg.mode.capitalized)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.coffeeBean)
                                            }
                                        }

                                        Text("\(leg.duration) min")
                                            .font(.system(size: 14))
                                            .foregroundColor(.warmBrown.opacity(0.7))
                                    }
                                }

                                // Instruction text
                                if !leg.instruction.isEmpty {
                                    Text(leg.instruction)
                                        .font(.system(size: 14))
                                        .foregroundColor(.warmBrown)
                                        .padding(.leading, 44)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.warmCream)
                                    .shadow(color: .coffeeBean.opacity(0.05), radius: 4, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Journey Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.rusticOrange)
                }
            }
        }
    }

    private var locationIcon: String {
        let lowercasedName = location.name.lowercased()

        if lowercasedName.contains("work") || lowercasedName.contains("office") {
            return "briefcase.fill"
        } else if lowercasedName.contains("gym") || lowercasedName.contains("fitness") {
            return "figure.strengthtraining.traditional"
        } else if lowercasedName.contains("school") {
            return "building.2.fill"
        } else if lowercasedName.contains("home") || lowercasedName.contains("house") {
            return "house.fill"
        } else if lowercasedName.contains("friend") {
            return "person.2.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}

struct FloorplanViewer: View {
    let floorplans: [String]
    @Binding var isPresented: Bool
    @State private var currentIndex = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                // Floorplan content with safe padding
                VStack {
                    Spacer()
                        .frame(height: 80) // Space for top controls

                    TabView(selection: $currentIndex) {
                        ForEach(Array(floorplans.enumerated()), id: \.offset) { index, floorplanURL in
                            AsyncImage(url: URL(string: floorplanURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .background(Color.white)
                                case .empty:
                                    ProgressView()
                                        .tint(.white)
                                case .failure:
                                    VStack(spacing: 16) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("Floorplan unavailable")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())

                    if floorplans.count > 1 {
                        Spacer()
                            .frame(height: 60) // Space for bottom indicators
                    } else {
                        Spacer()
                            .frame(height: 20)
                    }
                }

                // Top controls
                VStack {
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                )
                        }

                        Spacer()

                        if floorplans.count > 1 {
                            Text("\(currentIndex + 1) of \(floorplans.count)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.5))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()

                    // Bottom indicators
                    if floorplans.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<floorplans.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Floorplan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    PropertyDetailView(
        property: Property(
            images: [
                "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&q=80",
                "https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800&q=80",
                "https://images.unsplash.com/photo-1560185009-5bf9f2849dbe?w=800&q=80"
            ],
            price: "£2,500/month",
            bedrooms: 3,
            bathrooms: 2,
            address: "123 Canary Wharf",
            area: "London E14"
        ),
        isSavedProperty: true
    )
}
