import SwiftUI

struct PreferencesOnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var locationsManager = SavedLocationsManager()
    @State private var fetchedProperties: [Property] = []
    let onComplete: ([Property]) -> Void

    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()

            if viewModel.currentStep == .complete {
                OnboardingCompleteStep {
                    onComplete(fetchedProperties)
                }
            } else {
                VStack(spacing: 0) {
                    // Header with back button and progress
                    headerView

                    // Step content
                    TabView(selection: $viewModel.currentStep) {
                        OnboardingLocationStep(viewModel: viewModel)
                            .tag(OnboardingStep.location)

                        OnboardingRoomsStep(viewModel: viewModel)
                            .tag(OnboardingStep.rooms)

                        OnboardingBudgetStep(viewModel: viewModel)
                            .tag(OnboardingStep.budget)

                        OnboardingFurnishingStep(viewModel: viewModel)
                            .tag(OnboardingStep.furnishing)

                        OnboardingPlacesStep(viewModel: viewModel, locationsManager: locationsManager)
                            .tag(OnboardingStep.places)

                        OnboardingSummaryStep(viewModel: viewModel, locationsManager: locationsManager) { properties in
                            fetchedProperties = properties
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentStep = .complete
                            }
                        }
                        .tag(OnboardingStep.summary)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                // Back button
                if !viewModel.isFirstStep {
                    Button {
                        viewModel.goToPreviousStep()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.warmBrown)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Progress indicator
                OnboardingProgressIndicator(currentStep: viewModel.currentStep)

                Spacer()

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }
}

#Preview {
    PreferencesOnboardingView { properties in
        print("Completed with \(properties.count) properties")
    }
}
