import SwiftUI

struct EmojiCatalogPicker: View {
    @Environment(\.dismiss) private var dismiss

    let onPick: (String) -> Void
    let onCancel: () -> Void

    @State private var selectedCategoryIndex: Int = 0

    private var categories: [EmojiCategory] { EmojiCatalog.categories }

    private var currentEmojis: [String] {
        categories[selectedCategoryIndex].emojis
    }

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs (horizontal scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { idx, cat in
                            Button {
                                selectedCategoryIndex = idx
                            } label: {
                                Text(cat.name)
                                    .font(.subheadline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(idx == selectedCategoryIndex ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(currentEmojis, id: \.self) { emoji in
                            Button {
                                dismiss()
                                onPick(String(emoji.prefix(1)))
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Emoji \(emoji)")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Emoji")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                }
            }
        }
    }
}

#Preview {
    EmojiCatalogPicker(onPick: { _ in }, onCancel: {})
}

