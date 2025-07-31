import SwiftUI

extension Color {
    // Warm rustic color palette
    static let warmCream = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let rusticOrange = Color(red: 0.92, green: 0.55, blue: 0.32)
    static let warmRed = Color(red: 0.85, green: 0.36, blue: 0.31)
    static let goldenYellow = Color(red: 0.96, green: 0.76, blue: 0.42)
    static let deepOrange = Color(red: 0.82, green: 0.42, blue: 0.25)
    static let burntSienna = Color(red: 0.71, green: 0.31, blue: 0.22)
    static let warmBrown = Color(red: 0.47, green: 0.33, blue: 0.28)
    static let coffeeBean = Color(red: 0.24, green: 0.16, blue: 0.12)
    
    // Gradient combinations
    static let warmGradient = LinearGradient(
        colors: [rusticOrange, warmRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sunsetGradient = LinearGradient(
        colors: [goldenYellow, rusticOrange, warmRed],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let autumnGradient = LinearGradient(
        colors: [deepOrange, burntSienna],
        startPoint: .leading,
        endPoint: .trailing
    )
}