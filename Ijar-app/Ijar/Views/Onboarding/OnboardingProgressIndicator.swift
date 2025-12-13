import SwiftUI

struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingStep
    let totalSteps = OnboardingStep.allCases.count

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep.rawValue ? Color.rusticOrange : Color.warmBrown.opacity(0.25))
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressIndicator(currentStep: .location)
        OnboardingProgressIndicator(currentStep: .rooms)
        OnboardingProgressIndicator(currentStep: .budget)
        OnboardingProgressIndicator(currentStep: .furnishing)
        OnboardingProgressIndicator(currentStep: .summary)
        OnboardingProgressIndicator(currentStep: .notifications)
    }
    .padding()
    .background(Color.warmCream)
}
