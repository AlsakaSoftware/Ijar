import SwiftUI

struct ChecklistItem: View {
    let title: String
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isChecked ? Color.rusticOrange : Color.warmBrown.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isChecked ? Color.rusticOrange.opacity(0.1) : Color.clear)
                        )

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.rusticOrange)
                    }
                }

                // Title
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isChecked ? .warmBrown.opacity(0.7) : .coffeeBean)
                    .strikethrough(isChecked, color: .warmBrown.opacity(0.5))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.warmCream)
                    .shadow(color: .coffeeBean.opacity(0.03), radius: 2, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
