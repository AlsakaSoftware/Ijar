import SwiftUI

struct OnboardingBudgetStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: BudgetField?

    enum BudgetField {
        case minPrice
        case maxPrice
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        Spacer()
                            .frame(height: 60)

                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's your monthly budget?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.coffeeBean)

                            Text("Set your price range per month")
                                .font(.system(size: 17))
                                .foregroundColor(.warmBrown.opacity(0.7))
                        }
                        .padding(.horizontal, 24)

                        // Price inputs
                        HStack(spacing: 16) {
                            OnboardingPriceInputField(
                                label: "Min",
                                value: $viewModel.minPrice,
                                isFocused: focusedField == .minPrice
                            )
                            .focused($focusedField, equals: .minPrice)

                            OnboardingPriceInputField(
                                label: "Max",
                                value: $viewModel.maxPrice,
                                isFocused: focusedField == .maxPrice
                            )
                            .focused($focusedField, equals: .maxPrice)
                        }
                        .padding(.horizontal, 24)

                        // Quick select buttons
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick select")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.coffeeBean)
                                .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    quickSelectButton(label: "£1.5-2.5k", min: 1500, max: 2500)
                                    quickSelectButton(label: "£2.5-3.5k", min: 2500, max: 3500)
                                    quickSelectButton(label: "£3.5-4.5k", min: 3500, max: 4500)
                                    quickSelectButton(label: "£4-5k", min: 4000, max: 5000)
                                    quickSelectButton(label: "£5k+", min: 5000, max: nil)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .id("quickSelect")

                        // Helper text
                        Text("Leave empty if you're flexible on budget")
                            .font(.system(size: 15))
                            .foregroundColor(.warmBrown.opacity(0.5))
                            .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 120)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { _, focused in
                    if focused != nil {
                        withAnimation {
                            proxy.scrollTo("quickSelect", anchor: .bottom)
                        }
                    }
                }
            }

            // Continue button
            continueButton
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }

    private func quickSelectButton(label: String, min: Int?, max: Int?) -> some View {
        let isSelected = viewModel.minPrice == min && viewModel.maxPrice == max

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.minPrice = min
                viewModel.maxPrice = max
                focusedField = nil
            }
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .white : .coffeeBean)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.rusticOrange : Color.white)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color.clear : Color.warmBrown.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var continueButton: some View {
        VStack(spacing: 0) {
            Button {
                focusedField = nil
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

// MARK: - Price Input Field

struct OnboardingPriceInputField: View {
    let label: String
    @Binding var value: Int?
    var isFocused: Bool = false
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.warmBrown.opacity(0.6))

            HStack(spacing: 4) {
                Text("£")
                    .font(.system(size: 17))
                    .foregroundColor(.coffeeBean)

                TextField("Any", text: $text)
                    .font(.system(size: 17))
                    .keyboardType(.numberPad)
                    .onChange(of: text) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            text = filtered
                        }
                        value = Int(filtered)
                    }
            }
            .padding(.bottom, 12)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(isFocused ? .rusticOrange : .warmBrown.opacity(0.3)),
                alignment: .bottom
            )
        }
        .onAppear {
            if let value = value {
                text = "\(value)"
            }
        }
        .onChange(of: value) { _, newValue in
            if let newValue = newValue {
                if text != "\(newValue)" {
                    text = "\(newValue)"
                }
            } else {
                text = ""
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    OnboardingBudgetStep(viewModel: OnboardingViewModel())
        .background(Color.warmCream)
}
