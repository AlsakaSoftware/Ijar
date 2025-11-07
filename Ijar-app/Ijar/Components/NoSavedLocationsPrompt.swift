import SwiftUI

struct NoSavedLocationsPrompt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.rusticOrange)

                Text("Journey Times")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.coffeeBean)
            }

            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("See routes & commute times to places that matter")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.coffeeBean)
                        .multilineTextAlignment(.center)

                    Text("Add yours in Settings → Places that matter")
                        .font(.system(size: 15))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }

                HStack(spacing: 16) {
                    ForEach(Array(zip(["briefcase.fill", "figure.strengthtraining.traditional", "house.fill"], ["Work", "Gym", "Parents"])), id: \.0) { icon, label in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.rusticOrange.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(.rusticOrange)
                                )

                            Text(label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.warmBrown.opacity(0.7))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.warmCream.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.rusticOrange.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
