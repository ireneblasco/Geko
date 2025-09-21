import SwiftUI

public struct ColorPickerGrid: View {
    @Binding var selection: HabitColor

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    public init(selection: Binding<HabitColor>) {
        self._selection = selection
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HabitColor.allCases) { item in
                Button {
                    selection = item
                } label: {
                    ZStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 36, height: 36)
                        if selection == item {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(6)
                    .background(
                        Circle()
                            .fill(item == selection ? item.color.opacity(0.25) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.rawValue.capitalized)
            }
        }
    }
}
