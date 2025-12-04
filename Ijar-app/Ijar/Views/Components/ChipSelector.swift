import SwiftUI

struct ChipSelector: View {
    let options: [String]
    @Binding var selection: String?
    var onSelect: ((String) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    chip(option)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func chip(_ label: String) -> some View {
        let isSelected = selection == label

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = label
            }
            onSelect?(label)
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
}

// Version with typed values (like Double for radius)
struct ChipSelectorTyped<T: Equatable>: View {
    let options: [(label: String, value: T)]
    @Binding var selection: T
    var onSelect: ((T) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { index in
                    chip(options[index])
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func chip(_ option: (label: String, value: T)) -> some View {
        let isSelected = selection == option.value

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = option.value
            }
            onSelect?(option.value)
        } label: {
            Text(option.label)
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
}

#Preview {
    VStack(spacing: 32) {
        ChipSelector(
            options: ["Work", "Gym", "Partner's", "Family"],
            selection: .constant("Work")
        )

        ChipSelectorTyped(
            options: [("½ mile", 0.5), ("1 mile", 1.0), ("3 miles", 3.0), ("5 miles", 5.0)],
            selection: .constant(1.0)
        )
    }
    .padding(.vertical, 20)
    .background(Color.warmCream)
}
