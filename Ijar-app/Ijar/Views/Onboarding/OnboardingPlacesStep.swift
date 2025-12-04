import SwiftUI

struct OnboardingPlacesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var locationsManager: SavedLocationsManager
    @FocusState private var focusedField: Field?
    @State private var placeName = ""
    @State private var postcode = ""
    @State private var isSaving = false
    @State private var error: String?

    private let geocodingService = GeocodingService()

    private enum Field: Hashable {
        case name, postcode
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Places you go often")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.coffeeBean)

                        Text("We'll show commute times from each property")
                            .font(.system(size: 17))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                    .padding(.horizontal, 24)

                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 0) {
                            TextField("e.g., Work, Gym, Partner's", text: $placeName)
                                .font(.system(size: 17))
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .postcode }

                            Spacer()
                        }
                        .padding(.bottom, 12)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(focusedField == .name ? .rusticOrange : .warmBrown.opacity(0.3)),
                            alignment: .bottom
                        )
                    }
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)

                    // Postcode input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 0) {
                            TextField("Postcode", text: $postcode)
                                .font(.system(size: 17))
                                .textInputAutocapitalization(.characters)
                                .focused($focusedField, equals: .postcode)
                                .submitLabel(.done)
                                .onChange(of: postcode) { _, value in
                                    postcode = value.uppercased()
                                }
                                .onSubmit {
                                    Task { await addPlace() }
                                }

                            Spacer()

                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.bottom, 12)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(focusedField == .postcode ? .rusticOrange : .warmBrown.opacity(0.3)),
                            alignment: .bottom
                        )

                        if let error {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.2), value: error)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)

                    // Add Place button
                    Button {
                        Task { await addPlace() }
                    } label: {
                        Text("Add Place")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(canAdd ? .rusticOrange : .warmBrown.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(canAdd ? Color.rusticOrange : Color.warmBrown.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                    .disabled(!canAdd || isSaving)
                    .padding(.horizontal, 24)

                    // Added places
                    if !locationsManager.locations.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(locationsManager.locations.enumerated()), id: \.element.id) { index, location in
                                placeRow(location: location, showDivider: index < locationsManager.locations.count - 1)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                        .frame(height: 120)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Continue button
            continueButton
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }

    private func placeRow(location: SavedLocation, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.coffeeBean)

                    Text(location.postcode)
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.6))
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        locationsManager.deleteLocation(location)
                    }
                } label: {
                    Text("Remove")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.rusticOrange)
                }
            }
            .padding(.vertical, 16)

            if showDivider {
                Rectangle()
                    .fill(Color.warmBrown.opacity(0.15))
                    .frame(height: 1)
            }
        }
    }

    private var continueButton: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.goToNextStep()
            } label: {
                Text(locationsManager.locations.isEmpty ? "Add later" : "Continue")
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
            .padding(.vertical, 16)
            .background(Color.warmCream)
        }
    }

    private var canAdd: Bool {
        !placeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !postcode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @MainActor
    private func addPlace() async {
        let name = placeName.trimmingCharacters(in: .whitespaces)
        let code = postcode.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty, !code.isEmpty else { return }

        isSaving = true
        error = nil

        do {
            let coordinates = try await geocodingService.geocode(code)
            let location = SavedLocation(
                name: name,
                postcode: code.uppercased(),
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            locationsManager.addLocation(location)
            placeName = ""
            postcode = ""
            focusedField = nil
        } catch {
            self.error = "Couldn't find that postcode"
        }

        isSaving = false
    }
}

#Preview {
    OnboardingPlacesStep(
        viewModel: OnboardingViewModel(),
        locationsManager: SavedLocationsManager()
    )
    .background(Color.warmCream)
}
