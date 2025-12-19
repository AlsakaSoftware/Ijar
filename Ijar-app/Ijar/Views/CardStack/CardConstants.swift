import SwiftUI

/// Shared constants for the card stack UI
enum CardConstants {
    // MARK: - Card Appearance
    static let cornerRadius: CGFloat = 12
    static let aspectRatio: CGFloat = 0.65

    // MARK: - Swipe Thresholds
    static let horizontalActionThreshold: CGFloat = 140
    static let horizontalProgressStart: CGFloat = 30
    static let verticalActionThreshold: CGFloat = 150
    static let verticalProgressStart: CGFloat = 50
    static let pureVerticalMaxWidth: CGFloat = 80

    // MARK: - Overlay Appearance
    static let overlayMaxOpacity: CGFloat = 0.95
    static let overlayProgressThreshold: CGFloat = 0.1

    // MARK: - Overlay Progress Ring
    static let ringSize: CGFloat = 72
    static let ringLineWidth: CGFloat = 4
    static let ringIconSize: CGFloat = 24
    static let ringSizeSmall: CGFloat = 60
    static let ringLineWidthSmall: CGFloat = 3
    static let ringIconSizeSmall: CGFloat = 24

    // MARK: - Overlay Text
    static let overlayTextSize: CGFloat = 30
    static let overlayTextWeight: Font.Weight = .bold
    static let overlayTextDesign: Font.Design = .rounded

    // MARK: - Animation
    static let cardRotationMax: Double = 15
    static let cardScaleMin: CGFloat = 0.92

    // MARK: - Overlay Colors
    static let saveColor = Color(red: 0.36, green: 0.62, blue: 0.45)
    static let passColor = Color(red: 0.72, green: 0.52, blue: 0.45)
    static let detailsColor = Color(red: 0.35, green: 0.45, blue: 0.55)
}
