import SwiftUI

#if os(iOS)

public struct EmojiCatalogPicker: View {
    @Environment(\.dismiss) private var dismiss

    public let onPick: (String) -> Void
    public let onCancel: () -> Void

    @State private var selectedCategoryIndex: Int = 0
    @State private var searchText: String = ""

    private var categories: [EmojiCategory] { EmojiCatalog.categories }

    private var currentEmojis: [String] {
        categories[selectedCategoryIndex].emojis
    }

    // Minimal, extensible keyword index. Expand as needed.
    // Key: emoji glyph; Value: list of keywords
    private let emojiKeywords: [String: [String]] = [
        // Smileys
        "😀": ["grin", "smile", "happy", "face"],
        "😁": ["beaming", "smile", "grin", "happy"],
        "😂": ["joy", "tears", "lol", "laugh", "funny"],
        "🤣": ["rofl", "rolling", "laugh", "funny"],
        "😊": ["smile", "blush", "happy", "warm"],
        "😉": ["wink", "flirt", "hint"],
        "😍": ["love", "hearts", "in love", "heart eyes"],
        "😘": ["kiss", "love"],
        "😎": ["cool", "sunglasses"],
        "🙂": ["slight", "smile", "okay"],
        "😢": ["cry", "sad", "tear"],
        "😭": ["cry", "sob", "tears", "sad"],
        "😡": ["angry", "mad", "rage"],
        "🤔": ["think", "thinking", "hmm", "question"],
        "🙃": ["upside down", "sarcasm", "irony"],
        "🫠": ["melting", "awkward", "embarrassed"],
        "🤯": ["mind blown", "shock", "wow"],
        "🤗": ["hug", "hugs", "embrace"],

        // People/gestures
        "👍": ["thumbs up", "like", "approve", "yes"],
        "👎": ["thumbs down", "dislike", "no"],
        "🙏": ["pray", "please", "thanks", "high five"],
        "👏": ["clap", "applause", "bravo"],
        "🙌": ["raised hands", "hooray", "celebrate"],
        "💪": ["muscle", "strong", "workout", "gym", "exercise"],
        "👋": ["wave", "hello", "hi"],
        "✌️": ["victory", "peace", "two"],

        // Animals
        "🐶": ["dog", "puppy"],
        "🐱": ["cat", "kitty"],
        "🐭": ["mouse"],
        "🐰": ["rabbit", "bunny"],
        "🦊": ["fox"],
        "🐻": ["bear"],
        "🐼": ["panda"],
        "🐨": ["koala"],
        "🐯": ["tiger"],
        "🦁": ["lion"],
        "🐷": ["pig"],
        "🐸": ["frog"],
        "🐵": ["monkey"],
        "🐔": ["chicken"],
        "🐧": ["penguin"],
        "🐦": ["bird"],
        "🐝": ["bee"],
        "🦋": ["butterfly"],
        "🐢": ["turtle"],
        "🐍": ["snake"],
        "🦈": ["shark"],
        "🐬": ["dolphin"],
        "🐳": ["whale"],

        // Food & drink
        "🍎": ["apple", "fruit"],
        "🍌": ["banana", "fruit"],
        "🍇": ["grapes", "fruit"],
        "🍓": ["strawberry", "fruit"],
        "🍉": ["watermelon", "fruit"],
        "🍔": ["burger", "hamburger"],
        "🍟": ["fries"],
        "🍕": ["pizza"],
        "🍣": ["sushi"],
        "🍜": ["noodles", "ramen"],
        "🍞": ["bread"],
        "🍳": ["egg", "breakfast", "cook"],
        "🥗": ["salad", "healthy"],
        "🍫": ["chocolate"],
        "☕": ["coffee", "tea", "drink"],

        // Activities/sports
        "⚽": ["soccer", "football"],
        "🏀": ["basketball"],
        "🏈": ["american football"],
        "🎾": ["tennis"],
        "🏓": ["ping pong", "table tennis"],
        "🏆": ["trophy", "win", "award"],
        "🎮": ["game", "gaming", "controller"],

        // Travel/transport
        "✈️": ["airplane", "flight", "travel"],
        "🚗": ["car", "auto", "drive"],
        "🚲": ["bike", "bicycle", "cycle"],
        "🚀": ["rocket", "space"],

        // Objects
        "⌚": ["watch", "time"],
        "📱": ["phone", "mobile", "smartphone"],
        "💻": ["laptop", "computer"],
        "📷": ["camera", "photo"],
        "📚": ["books", "reading", "study", "library"],
        "📝": ["memo", "note", "write"],
        "🔑": ["key", "unlock"],
        "🔨": ["hammer", "tool"],
        "⚙️": ["gear", "settings"],

        // Symbols
        "❤️": ["heart", "love", "red"],
        "🧡": ["heart", "love", "orange"],
        "💛": ["heart", "love", "yellow"],
        "💚": ["heart", "love", "green"],
        "💙": ["heart", "love", "blue"],
        "💜": ["heart", "love", "purple"],
        "🖤": ["heart", "love", "black"],
        "🤍": ["heart", "love", "white"],
        "🤎": ["heart", "love", "brown"],
        "💔": ["broken heart", "heartbreak", "sad"],
        "❣️": ["heart exclamation", "love"],
        "💕": ["two hearts", "love"],
        "💤": ["sleep", "zzz", "tired"],
        "✅": ["check", "checkmark", "done", "complete", "yes"],
        "❌": ["x", "cross", "no", "wrong"],
        "⭕": ["circle", "record"],
        "🔴": ["red circle"],
        "🟢": ["green circle"],
        "🔵": ["blue circle"],

        // Flags (limited)
        "🇺🇸": ["flag", "usa", "america", "united states"],
        "🇬🇧": ["flag", "uk", "britain", "united kingdom"],
        "🇨🇦": ["flag", "canada"],
        "🇫🇷": ["flag", "france"],
        "🇩🇪": ["flag", "germany"],
        "🇯🇵": ["flag", "japan"],
        "🇮🇳": ["flag", "india"],
        "🇧🇷": ["flag", "brazil"]
    ]

    // Filter with keyword support
    private var filteredEmojis: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return currentEmojis
        }

        // Search across all categories and deduplicate while preserving order
        var seen = Set<String>()
        var results: [String] = []

        func matches(_ emoji: String) -> Bool {
            // 1) Direct glyph match (in case user pasted/typed emoji)
            if emoji.localizedCaseInsensitiveContains(query) { return true }
            // 2) Keyword match
            if let kws = emojiKeywords[emoji] {
                if kws.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
                    return true
                }
            }
            return false
        }

        for category in categories {
            for emoji in category.emojis {
                if matches(emoji), !seen.contains(emoji) {
                    seen.insert(emoji)
                    results.append(emoji)
                }
            }
        }
        return results
    }

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    public init(onPick: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onPick = onPick
        self.onCancel = onCancel
    }

    public var body: some View {
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
                    if filteredEmojis.isEmpty {
                        VStack(spacing: 8) {
                            Text("No results")
                                .font(.headline)
                            if !searchText.isEmpty {
                                Text("No emojis match “\(searchText)”")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredEmojis, id: \.self) { emoji in
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
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search emojis")
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
        }
    }
}

#endif
