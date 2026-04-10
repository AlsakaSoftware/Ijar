import SwiftUI

// MARK: - Shared Progress Ring Component

private struct ProgressRing: View {
    let progress: CGFloat
    let size: CGFloat
    let lineWidth: CGFloat
    let icon: String
    let iconSize: CGFloat
    let iconWeight: Font.Weight

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            Image(systemName: icon)
                .font(.system(size: iconSize, weight: iconWeight))
                .foregroundColor(.white)
                .scaleEffect(0.8 + (0.2 * progress))
        }
    }
}

// MARK: - Overlay Components

/// Slack-style overlay shown when swiping right (Save) - positioned top-left
struct SaveOverlay: View {
    var progress: CGFloat = 1.0

    private let accentColor = CardConstants.saveColor

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Progressive color fill
            accentColor
                .opacity(0.95 * progress)

            // Content - top left corner
            VStack(alignment: .leading, spacing: 10) {
                ProgressRing(
                    progress: progress,
                    size: CardConstants.ringSize,
                    lineWidth: CardConstants.ringLineWidth,
                    icon: "heart.fill",
                    iconSize: CardConstants.ringIconSize,
                    iconWeight: .medium
                )

                Text("Love it")
                    .font(.system(size: CardConstants.overlayTextSize, weight: CardConstants.overlayTextWeight, design: CardConstants.overlayTextDesign))
                    .foregroundColor(.white)
            }
            .padding(.leading, 24)
            .padding(.top, 28)
            .opacity(progress > 0.1 ? 1 : 0)
            .scaleEffect(0.9 + (0.1 * progress), anchor: .topLeading)
        }
        .animation(.easeOut(duration: 0.15), value: progress)
    }
}

/// Slack-style overlay shown when swiping left (Pass) - positioned top-right
struct PassOverlay: View {
    var progress: CGFloat = 1.0

    private let accentColor = CardConstants.passColor

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Progressive color fill
            accentColor
                .opacity(0.95 * progress)

            // Content - top right corner
            VStack(alignment: .trailing, spacing: 10) {
                ProgressRing(
                    progress: progress,
                    size: CardConstants.ringSize,
                    lineWidth: CardConstants.ringLineWidth,
                    icon: "xmark",
                    iconSize: CardConstants.ringIconSize,
                    iconWeight: .semibold
                )

                Text("Nope")
                    .font(.system(size: CardConstants.overlayTextSize, weight: CardConstants.overlayTextWeight, design: CardConstants.overlayTextDesign))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 24)
            .padding(.top, 28)
            .opacity(progress > 0.1 ? 1 : 0)
            .scaleEffect(0.9 + (0.1 * progress), anchor: .topTrailing)
        }
        .animation(.easeOut(duration: 0.15), value: progress)
    }
}

/// Slack-style overlay shown when swiping up (Details) - positioned bottom center
struct DetailsOverlay: View {
    var progress: CGFloat = 1.0

    private let accentColor = CardConstants.detailsColor

    var body: some View {
        ZStack(alignment: .bottom) {
            // Progressive color fill
            accentColor
                .opacity(0.95 * progress)

            // Content - bottom center
            VStack(spacing: 8) {
                ProgressRing(
                    progress: progress,
                    size: CardConstants.ringSizeSmall,
                    lineWidth: CardConstants.ringLineWidthSmall,
                    icon: "eye.fill",
                    iconSize: CardConstants.ringIconSizeSmall,
                    iconWeight: .medium
                )

                Text("Details")
                    .font(.system(size: CardConstants.overlayTextSize, weight: CardConstants.overlayTextWeight, design: CardConstants.overlayTextDesign))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 80)
            .opacity(progress > 0.1 ? 1 : 0)
            .scaleEffect(0.9 + (0.1 * progress), anchor: .bottom)
        }
        .animation(.easeOut(duration: 0.15), value: progress)
    }
}

// Mock card background for previews
private struct MockCardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.gray.opacity(0.3), .gray.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("£2,500/month")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    Text("123 Example Street")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.9))
                    Text("London E14")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview("Save - Full") {
    ZStack {
        MockCardBackground()
        SaveOverlay(progress: 1.0)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}

#Preview("Save - 75%") {
    ZStack {
        MockCardBackground()
        SaveOverlay(progress: 0.75)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}

#Preview("Save - 50%") {
    ZStack {
        MockCardBackground()
        SaveOverlay(progress: 0.5)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}

#Preview("Pass - Full") {
    ZStack {
        MockCardBackground()
        PassOverlay(progress: 1.0)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}

#Preview("Pass - 75%") {
    ZStack {
        MockCardBackground()
        PassOverlay(progress: 0.75)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}

#Preview("Pass - 50%") {
    ZStack {
        MockCardBackground()
        PassOverlay(progress: 0.5)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}

#Preview("Details - Full") {
    ZStack {
        MockCardBackground()
        DetailsOverlay(progress: 1.0)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}

#Preview("Details - 75%") {
    ZStack {
        MockCardBackground()
        DetailsOverlay(progress: 0.75)
    }
    .frame(width: 320, height: 480)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(Color.black.opacity(0.1))
}
