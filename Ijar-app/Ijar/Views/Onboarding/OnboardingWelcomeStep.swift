import SwiftUI

struct OnboardingWelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title and subtitle - left aligned like other steps
            VStack(alignment: .leading, spacing: 15) {
                Text("Welcome to SupHomey")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.coffeeBean)

                VStack(spacing: 0) {
                    
                    HStack {
                        Text("Let's find your next home…")
                            .font(.system(size: 18))
                            .lineSpacing(1)
                            .foregroundColor(.warmBrown.opacity(0.8))
                        Spacer()
                    }
                                        
                    HStack {
                        Spacer()
                        Text("without pulling out your hair")
                            .font(.system(size: 18))
                            .lineSpacing(1)
                            .foregroundColor(.warmBrown.opacity(0.8))
                    }
                }
//                Text("Let's find your next home \n          …without pulling out your hair")
//                    .font(.system(size: 18))
//                    .lineSpacing(1)
//                    .foregroundColor(.warmBrown.opacity(0.7))

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)

            Spacer()

            // Get Started button
            Button {
                viewModel.goToNextStep()
            } label: {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.rusticOrange)
                    )
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                showContent = true
            }
        }
    }
}

#Preview {
    OnboardingWelcomeStep(viewModel: OnboardingViewModel())
        .background(Color.warmCream)
}
