import SwiftUI
import EmojiKit

#if os(iOS)

public struct EmojiCatalogPicker: View {
    @Environment(\.dismiss) private var dismiss

    public let onPick: (String) -> Void
    public let onCancel: () -> Void

    @State private var selectedCategoryIndex: Int = 0
    @State private var searchText: String = ""

    private static let standardCategories: [EmojiCategory] = [
        .smileysAndPeople,
        .animalsAndNature,
        .foodAndDrink,
        .activity,
        .travelAndPlaces,
        .objects,
        .symbols,
        .flags
    ]

    private var categories: [EmojiCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return Self.standardCategories
        }
        return [EmojiCategory.search(query: query)].filter { !$0.emojis.isEmpty }
    }

    private var displayCategories: [EmojiCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return Self.standardCategories
        }
        let searchCategory = EmojiCategory.search(query: query)
        return searchCategory.emojis.isEmpty ? [] : [searchCategory]
    }

    private var currentCategory: EmojiCategory? {
        let cats = displayCategories
        guard selectedCategoryIndex >= 0, selectedCategoryIndex < cats.count else {
            return cats.first
        }
        return cats[selectedCategoryIndex]
    }

    private var currentEmojis: [Emoji] {
        currentCategory?.emojis ?? []
    }

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    public init(onPick: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onPick = onPick
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !displayCategories.isEmpty && displayCategories.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(displayCategories.enumerated()), id: \.element.id) { idx, cat in
                                Button {
                                    selectedCategoryIndex = idx
                                } label: {
                                    Text(cat.localizedName)
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
                }

                ScrollView {
                    if currentEmojis.isEmpty {
                        VStack(spacing: 8) {
                            Text("No results")
                                .font(.headline)
                            if !searchText.isEmpty {
                                Text("No emojis match \"\(searchText)\"")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(currentEmojis) { emoji in
                                Button {
                                    onPick(emoji.char)
                                    dismiss()
                                } label: {
                                    Text(emoji.char)
                                        .font(.system(size: 28))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.secondary.opacity(0.08))
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(emoji.localizedName)
                            }
                        }
                        .padding()
                    }
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
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search emojis"
            )
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .onChange(of: searchText) { _, _ in
                selectedCategoryIndex = 0
            }
        }
    }
}

#endif
