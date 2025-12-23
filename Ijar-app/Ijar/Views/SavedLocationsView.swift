import SwiftUI
import RevenueCatUI

struct SavedLocationsView: View {
    @StateObject private var locationsManager = SavedLocationsManager()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddLocation = false
    @State private var showingPaywall = false
    @State private var locationToEdit: SavedLocation?
    @State private var limitMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Places that matter")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.coffeeBean)

                Text("We'll show commute times from each property")
                    .font(.system(size: 15))
                    .foregroundColor(.warmBrown.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)

            if locationsManager.locations.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("No places yet")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.coffeeBean)

                        Text("Add your work, gym, or other places")
                            .font(.system(size: 17))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }

                    Button(action: handleAddLocation) {
                        Text("Add a place")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.rusticOrange)
                            )
                    }
                    .padding(.top, 8)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(locationsManager.locations.enumerated()), id: \.element.id) { index, location in
                            SavedLocationCard(
                                location: location,
                                onEdit: {
                                    locationToEdit = location
                                },
                                onDelete: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        locationsManager.deleteLocation(location)
                                    }
                                }
                            )

                            if index < locationsManager.locations.count - 1 {
                                Rectangle()
                                    .fill(Color.warmBrown.opacity(0.15))
                                    .frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: handleAddLocation) {
                    Image(systemName: "plus")
                        .foregroundColor(.rusticOrange)
                }
            }
        }
        .sheet(isPresented: $showingAddLocation) {
            AddLocationView(locationsManager: locationsManager)
        }
        .sheet(item: $locationToEdit) { location in
            EditLocationView(locationsManager: locationsManager, location: location)
        }
        .upgradePrompt(limitMessage: $limitMessage, showPaywall: $showingPaywall)
    }

    private func handleAddLocation() {
        let result = subscriptionManager.canAddSavedLocation(currentLocationCount: locationsManager.locations.count)

        if result.canAdd {
            showingAddLocation = true
        } else {
            limitMessage = result.reason
        }
    }
}

struct AddLocationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var locationsManager: SavedLocationsManager
    private let geocodingService = GeocodingService()

    @State private var name = ""
    @State private var postcode = ""
    @State private var isGeocoding = false
    @State private var error: String?
    @State private var showNameRequiredError = false
    @State private var showPostcodeRequiredError = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !postcode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    FilterSection(title: "Place Details") {
                        VStack(spacing: 12) {
                            // Name field
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Text("Name")
                                        .font(.system(size: 13))
                                        .foregroundColor(.warmBrown)

                                    Text("*")
                                        .font(.system(size: 13))
                                        .foregroundColor(.rusticOrange)
                                }

                                TextField("e.g., Office", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(showNameRequiredError ? Color.rusticOrange : Color.warmBrown.opacity(0.2), lineWidth: showNameRequiredError ? 2 : 1)
                                    )
                                    .onChange(of: name) { _, _ in
                                        if showNameRequiredError {
                                            showNameRequiredError = false
                                        }
                                    }

                                if showNameRequiredError {
                                    Text("Please enter a name for this place")
                                        .font(.system(size: 12))
                                        .foregroundColor(.rusticOrange)
                                }
                            }

                            // Postcode field
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Text("Postcode")
                                        .font(.system(size: 13))
                                        .foregroundColor(.warmBrown)

                                    Text("*")
                                        .font(.system(size: 13))
                                        .foregroundColor(.rusticOrange)
                                }

                                HStack {
                                    TextField("e.g., E14 5AB", text: $postcode)
                                        .textInputAutocapitalization(.characters)
                                        .onChange(of: postcode) { _, value in
                                            postcode = value.uppercased()
                                            if showPostcodeRequiredError {
                                                showPostcodeRequiredError = false
                                            }
                                        }

                                    if isGeocoding {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            showPostcodeRequiredError ? Color.rusticOrange :
                                            error != nil ? Color.red.opacity(0.5) :
                                            Color.warmBrown.opacity(0.2),
                                            lineWidth: showPostcodeRequiredError ? 2 : 1
                                        )
                                )

                                if showPostcodeRequiredError {
                                    Text("Please enter a postcode")
                                        .font(.system(size: 12))
                                        .foregroundColor(.rusticOrange)
                                } else if let error {
                                    Text(error)
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmCream)
            .navigationTitle("New Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.warmBrown)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.rusticOrange)
                    .disabled(isGeocoding)
                }
            }
        }
    }

    private func saveLocation() {
        // Validate all fields at once
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPostcode = postcode.trimmingCharacters(in: .whitespaces)

        var hasErrors = false

        if trimmedName.isEmpty {
            showNameRequiredError = true
            hasErrors = true
        }

        if trimmedPostcode.isEmpty {
            showPostcodeRequiredError = true
            hasErrors = true
        }

        guard !hasErrors else { return }

        isGeocoding = true
        error = nil

        Task {
            do {
                let coordinates = try await geocodingService.geocode(postcode)
                let location = SavedLocation(
                    name: trimmedName,
                    postcode: postcode.uppercased(),
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )

                locationsManager.addLocation(location)
                dismiss()
            } catch {
                self.error = "Couldn't find that postcode"
            }

            isGeocoding = false
        }
    }
}

struct EditLocationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var locationsManager: SavedLocationsManager
    let location: SavedLocation
    private let geocodingService = GeocodingService()

    @State private var name = ""
    @State private var postcode = ""
    @State private var isGeocoding = false
    @State private var error: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !postcode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    FilterSection(title: "Place Details") {
                        VStack(spacing: 12) {
                            // Name field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)

                                TextField("e.g., Office", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.warmBrown.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            // Postcode field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Postcode")
                                    .font(.system(size: 13))
                                    .foregroundColor(.warmBrown)

                                HStack {
                                    TextField("e.g., E14 5AB", text: $postcode)
                                        .textInputAutocapitalization(.characters)
                                        .onChange(of: postcode) { _, value in
                                            postcode = value.uppercased()
                                        }

                                    if isGeocoding {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(error != nil ? Color.red.opacity(0.5) : Color.warmBrown.opacity(0.2), lineWidth: 1)
                                )

                                if let error {
                                    Text(error)
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmCream)
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.warmBrown)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateLocation()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.rusticOrange)
                    .disabled(!canSave || isGeocoding)
                }
            }
            .onAppear {
                name = location.name
                postcode = location.postcode
            }
        }
    }

    private func updateLocation() {
        isGeocoding = true
        error = nil

        Task {
            do {
                let coordinates = try await geocodingService.geocode(postcode)
                let updatedLocation = SavedLocation(
                    id: location.id,
                    name: name.trimmingCharacters(in: .whitespaces),
                    postcode: postcode.uppercased(),
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )

                locationsManager.updateLocation(updatedLocation)
                dismiss()
            } catch {
                self.error = "Couldn't find that postcode"
            }

            isGeocoding = false
        }
    }
}

#Preview {
    NavigationView {
        SavedLocationsView()
    }
}
