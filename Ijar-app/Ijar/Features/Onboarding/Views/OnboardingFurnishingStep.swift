import SwiftUI

struct OnboardingFurnishingStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let options: [(id: String?, label: String, description: String)] = [
        (nil, "Any", "I'm flexible on furnishing"),
        ("furnished", "Furnished", "Ready to move in with furniture"),
        ("partFurnished", "Part Furnished", "Some furniture included"),
        ("unfurnished", "Unfurnished", "Empty, bring your own")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Furnishing preference?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.coffeeBean)

                        Text("Choose your preferred furnishing level")
                            .font(.system(size: 17))
                            .foregroundColor(.warmBrown.opacity(0.7))
                    }
                    .padding(.horizontal, 24)

                    // Furnishing options
                    VStack(spacing: 0) {
                        ForEach(options.indices, id: \.self) { index in
                            let option = options[index]
                            furnishingRow(
                                id: option.id,
                                label: option.label,
                                description: option.description,
                                showDivider: index < options.count - 1
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 120)
                }
            }

            // Continue button
            continueButton
        }
    }

    private func furnishingRow(id: String?, label: String, description: String, showDivider: Bool) -> some View {
        let isSelected = viewModel.furnishType == id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.furnishType = id
            }
        } label: {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(label)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.coffeeBean)

                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.warmBrown.opacity(0.6))
                    }

                    Spacer()

                    // Radio button style
                    Circle()
                        .strokeBorder(isSelected ? Color.rusticOrange : Color.warmBrown.opacity(0.3), lineWidth: isSelected ? 6 : 1.5)
                        .frame(width: 22, height: 22)
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

#Preview {
    OnboardingFurnishingStep(viewModel: OnboardingViewModel())
        .background(Color.warmCream)
}
