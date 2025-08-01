import SwiftUI

struct TimeBasedGreeting: View {
    @State private var ambientAnimation = false
    
    private var greetingData: (text: String, colors: [Color]) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return (
                "Find your perfect morning retreat",
                [Color.goldenYellow, Color.rusticOrange.opacity(0.8)]
            )
        case 12..<17:
            return (
                "Discover your afternoon sanctuary", 
                [Color.rusticOrange, Color.warmRed.opacity(0.9)]
            )
        case 17..<22:
            return (
                "Unwind in your evening haven",
                [Color.warmRed, Color.burntSienna]
            )
        default:
            return (
                "Dream of your cozy hideaway",
                [Color.warmBrown, Color.coffeeBean.opacity(0.8)]
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Dynamic background gradient based on time
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            greetingData.colors[0].opacity(0.15),
                            greetingData.colors[1].opacity(0.08),
                            greetingData.colors[0].opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: greetingData.colors[0].opacity(0.15), radius: 12, y: 4)
            
            // Clean background elements (clipped to bounds)
            GeometryReader { geometry in
                ZStack {
                    // Simple floating circles with time-based colors - kept more centered and visible
                    Circle()
                        .fill(greetingData.colors[0].opacity(0.15))
                        .frame(width: 25, height: 25)
                        .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.35)
                        .scaleEffect(ambientAnimation ? 1.3 : 0.8)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: ambientAnimation)
                    
                    Circle()
                        .fill(greetingData.colors[1].opacity(0.12))
                        .frame(width: 16, height: 16)
                        .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.65)
                        .scaleEffect(ambientAnimation ? 0.7 : 1.2)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: ambientAnimation)
                    
                    // Simple decorative dots with time-based colors
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(greetingData.colors[0].opacity(0.2))
                                .frame(width: 3, height: 3)
                        }
                    }
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.25)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            // Main content
            VStack(spacing: 12) {
                // Clean greeting text
                Text(greetingData.text)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(.coffeeBean)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Simple elegant accent with time-based colors
                HStack(spacing: 6) {
                    Circle()
                        .fill(greetingData.colors[0])
                        .frame(width: 5, height: 5)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    greetingData.colors[0].opacity(0.6),
                                    greetingData.colors[1].opacity(0.3),
                                    greetingData.colors[0].opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 2)
                        .cornerRadius(1)
                    
                    Circle()
                        .fill(greetingData.colors[0])
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.vertical, 18)
        }
        .frame(height: 100)
        .onAppear {
            ambientAnimation = true
        }
    }
}

#Preview {
    TimeBasedGreeting()
        .padding(.horizontal, 20)
        .background(Color.warmCream)
}