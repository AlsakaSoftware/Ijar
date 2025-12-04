import SwiftUI

struct OnboardingSummaryStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: ([Property]) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready to find your home?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.coffeeBean)

                        Text("Review your search preferences")
                            .font(.system(size: 16))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                    .padding(.horizontal, 24)

                    // Summary rows
                    VStack(spacing: 0) {
                        summaryRow(
                            title: "Location",
                            value: viewModel.locationSummary,
                            step: .location,
                            showDivider: true
                        )

                        summaryRow(
                            title: "Rooms",
                            value: viewModel.roomsSummary,
                            step: .rooms,
                            showDivider: true
                        )

                        summaryRow(
                            title: "Budget",
                            value: viewModel.budgetSummary,
                            step: .budget,
                            showDivider: true
                        )

                        summaryRow(
                            title: "Furnishing",
                            value: viewModel.furnishingSummary,
                            step: .furnishing,
                            showDivider: false
                        )
                    }
                    .padding(.horizontal, 24)

                    // Info text - condensed
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.rusticOrange)
                        Text("We'll send matching properties to your feed")
                            .font(.system(size: 14))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                    .padding(.horizontal, 24)

                    // Error message
                    if let error = viewModel.submissionError {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    Spacer()
                        .frame(height: 20)
                }
            }

            // Find properties button
            findPropertiesButton
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.submissionError)
    }

    private func infoRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.rusticOrange)
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.warmBrown.opacity(0.7))
        }
    }

    private func summaryRow(title: String, value: String, step: OnboardingStep, showDivider: Bool) -> some View {
        Button {
            viewModel.goToStep(step)
        } label: {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13))
                            .foregroundColor(.warmBrown.opacity(0.6))

                        Text(value)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.coffeeBean)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Text("Edit")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.rusticOrange)
                }
                .padding(.vertical, 16)

                if showDivider {
                    Rectangle()
                        .fill(Color.warmBrown.opacity(0.15))
                        .frame(height: 1)
                }
            }
        }
    }

    private var findPropertiesButton: some View {
        VStack(spacing: 0) {
            if viewModel.isSubmitting {
                Text("Setting up your feed...")
                    .font(.system(size: 14))
                    .foregroundColor(.warmBrown.opacity(0.6))
                    .padding(.bottom, 5)
                    .transition(.opacity)
            }

            Button {
                Task {
                    let properties = await viewModel.completeOnboarding()
                    if viewModel.isComplete {
                        onComplete(properties)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                    }
                    Text(viewModel.isSubmitting ? "Finding properties" : "Find My Properties")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.rusticOrange)
                )
                .opacity(viewModel.isSubmitting ? 0.85 : 1)
            }
            .disabled(viewModel.isSubmitting)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(Color.warmCream)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSubmitting)
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.areaName = "Canary Wharf, London"
    vm.latitude = 51.5054
    vm.longitude = -0.0235
    vm.radius = 3.0
    vm.minBedrooms = 2
    vm.maxBedrooms = 3
    vm.minBathrooms = 1
    vm.minPrice = 2500
    vm.maxPrice = 3500
    vm.furnishType = nil

    return OnboardingSummaryStep(viewModel: vm) { properties in
        print("Completed with \(properties.count) properties")
    }
    .background(Color.warmCream)
}
