import SwiftUI

struct OnboardingLocationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isAreaFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        Spacer()
                            .frame(height: 60)

                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Where do you want to live?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.coffeeBean)

                            Text("Enter a city, area, or postcode")
                                .font(.system(size: 17))
                                .foregroundColor(.warmBrown.opacity(0.7))
                        }
                        .padding(.horizontal, 24)

                        // Location input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 0) {
                                TextField("e.g., Canary Wharf, London", text: $viewModel.areaName)
                                    .font(.system(size: 17))
                                    .focused($isAreaFieldFocused)
                                    .textContentType(.fullStreetAddress)
                                    .autocapitalization(.words)
                                    .onChange(of: viewModel.areaName) { _, newValue in
                                        viewModel.geocodeArea(newValue)
                                    }

                                Spacer()

                                if viewModel.isGeocoding {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if viewModel.latitude != nil && viewModel.longitude != nil && viewModel.geocodingError == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.bottom, 12)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(isAreaFieldFocused ? .rusticOrange : .warmBrown.opacity(0.3)),
                                alignment: .bottom
                            )

                            if let error = viewModel.geocodingError {
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 24)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.geocodingError)
                        .animation(.easeInOut(duration: 0.2), value: isAreaFieldFocused)

                        // Radius selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Search radius")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.coffeeBean)
                                .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    radiusOption(label: "½ mile", value: 0.5)
                                    radiusOption(label: "1 mile", value: 1.0)
                                    radiusOption(label: "3 miles", value: 3.0)
                                    radiusOption(label: "5 miles", value: 5.0)
                                    radiusOption(label: "10 miles", value: 10.0)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .id("radiusSection")

                        Spacer()
                            .frame(height: 120)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isAreaFieldFocused) { _, focused in
                    if focused {
                        withAnimation {
                            proxy.scrollTo("radiusSection", anchor: .bottom)
                        }
                    }
                }
            }

            // Continue button
            continueButton
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isAreaFieldFocused = false
        }
    }

    private func radiusOption(label: String, value: Double) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.radius = value
            }
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(viewModel.radius == value ? .white : .coffeeBean)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(viewModel.radius == value ? Color.rusticOrange : Color.white)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(viewModel.radius == value ? Color.clear : Color.warmBrown.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var continueButton: some View {
        VStack(spacing: 0) {
            Button {
                isAreaFieldFocused = false
                viewModel.goToNextStep()
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(viewModel.canProceedFromLocation ? Color.rusticOrange : Color.warmBrown.opacity(0.3))
                    )
            }
            .disabled(!viewModel.canProceedFromLocation)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.warmCream)
        }
    }
}

#Preview {
    OnboardingLocationStep(viewModel: OnboardingViewModel())
        .background(Color.warmCream)
}
