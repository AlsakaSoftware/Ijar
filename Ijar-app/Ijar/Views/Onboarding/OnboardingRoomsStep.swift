import SwiftUI

struct OnboardingRoomsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How many rooms do you need?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.coffeeBean)

                        Text("Set your bedroom and bathroom preferences")
                            .font(.system(size: 17))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                    .padding(.horizontal, 24)

                    // Room pickers
                    VStack(spacing: 32) {
                        // Bedrooms
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Bedrooms")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.coffeeBean)

                            HStack(spacing: 16) {
                                OnboardingPickerField(
                                    label: "Min",
                                    value: bedroomLabel(viewModel.minBedrooms),
                                    options: bedroomOptions,
                                    selection: $viewModel.minBedrooms
                                )

                                OnboardingPickerField(
                                    label: "Max",
                                    value: bedroomLabel(viewModel.maxBedrooms),
                                    options: bedroomOptions,
                                    selection: $viewModel.maxBedrooms
                                )
                            }
                        }

                        // Bathrooms
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Bathrooms")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.coffeeBean)

                            HStack(spacing: 16) {
                                OnboardingPickerField(
                                    label: "Min",
                                    value: bathroomLabel(viewModel.minBathrooms),
                                    options: bathroomOptions,
                                    selection: $viewModel.minBathrooms
                                )

                                OnboardingPickerField(
                                    label: "Max",
                                    value: bathroomLabel(viewModel.maxBathrooms),
                                    options: bathroomOptions,
                                    selection: $viewModel.maxBathrooms
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Helper text
                    Text("Leave as 'Any' if you're flexible")
                        .font(.system(size: 15))
                        .foregroundColor(.warmBrown.opacity(0.5))
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 120)
                }
            }

            // Continue button
            continueButton
        }
    }

    private var bedroomOptions: [(String, Int?)] {
        [("Any", nil), ("Studio", 0), ("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5+", 5)]
    }

    private var bathroomOptions: [(String, Int?)] {
        [("Any", nil), ("1", 1), ("2", 2), ("3", 3), ("4+", 4)]
    }

    private func bedroomLabel(_ value: Int?) -> String {
        guard let value = value else { return "Any" }
        return value == 0 ? "Studio" : "\(value)"
    }

    private func bathroomLabel(_ value: Int?) -> String {
        guard let value = value else { return "Any" }
        return "\(value)"
    }

    private var continueButton: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.goToNextStep()
            } label: {
                Text("Continue")
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
}

// MARK: - Picker Field Component

struct OnboardingPickerField<T: Equatable>: View {
    let label: String
    let value: String
    let options: [(String, T?)]
    @Binding var selection: T?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.warmBrown.opacity(0.6))

            Menu {
                ForEach(options.indices, id: \.self) { index in
                    Button(options[index].0) {
                        selection = options[index].1
                    }
                }
            } label: {
                HStack {
                    Text(value)
                        .font(.system(size: 17))
                        .foregroundColor(.coffeeBean)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.5))
                }
                .padding(.bottom, 12)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.warmBrown.opacity(0.3)),
                    alignment: .bottom
                )
            }
        }
    }
}

#Preview {
    OnboardingRoomsStep(viewModel: OnboardingViewModel())
        .background(Color.warmCream)
}
