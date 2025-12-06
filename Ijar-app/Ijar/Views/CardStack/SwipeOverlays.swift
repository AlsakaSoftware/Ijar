import SwiftUI

/// Overlay shown when swiping right (Save) - icon on LEFT (visible side)
struct SaveOverlay: View {
    var body: some View {
        Color.black.opacity(0.35)
            .blur(radius: 0.5)
            .overlay(alignment: .topLeading) {
                HStack(spacing: 8) {
                    Text("❤️")
                        .font(.system(size: 36))

                    Text("Love it!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
                .padding(.leading, 24)
                .padding(.top, 30)
            }
    }
}

/// Overlay shown when swiping left (Pass) - icon on RIGHT (visible side)
struct PassOverlay: View {
    var body: some View {
        Color.black.opacity(0.35)
            .blur(radius: 0.5)
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Text("Nope")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                    Text("👎")
                        .font(.system(size: 36))
                }
                .padding(.trailing, 24)
                .padding(.top, 30)
            }
    }
}

#Preview("Save Overlay") {
    SaveOverlay()
        .frame(width: 300, height: 450)
}

#Preview("Pass Overlay") {
    PassOverlay()
        .frame(width: 300, height: 450)
}
