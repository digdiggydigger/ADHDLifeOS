//
//  LifeAreaEmojiPicker.swift
//  ADHD LifeOS
//

import SwiftUI

/// Emoji control shared by the create sheet and the detail screen: a curated tap-grid (the fast
/// path) plus a free-type field (covers anything not shipped), per §8. Binds to the staged emoji
/// string. The grid can only ever produce a valid single-glyph value; the free-type field is
/// validated to exactly one grapheme cluster (`LifeAreaEditorValidation.validateEmoji`) and shows a
/// readable inline message otherwise — it never pushes an invalid value into the binding.
struct LifeAreaEmojiPicker: View {
    @Binding var selection: String

    @State private var freeTypeText = ""
    @State private var freeTypeError: String?

    /// Curated ~40-emoji palette spanning the kinds of areas people track. Every entry is a single
    /// grapheme cluster, so tapping one always yields a valid selection.
    static let curatedEmoji: [String] = [
        "🏠", "💼", "💪", "🧠", "❤️", "👨‍👩‍👧‍👦", "💰", "📚",
        "🎯", "✅", "🎨", "🎵", "🏃", "🧘", "🍎", "🌱",
        "✈️", "🛠️", "📝", "🗂️", "📅", "💡", "🔧", "🎮",
        "🐶", "🌍", "⚽️", "🎬", "🍳", "🛒", "💊", "🚗",
        "✏️", "📱", "💻", "🎓", "🏥", "🧹", "🌿", "⭐️"
    ]

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            selectionPreview

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Self.curatedEmoji, id: \.self) { emoji in
                    emojiCell(emoji)
                }
            }

            freeTypeField
        }
        .padding(.vertical, 8)
    }

    private var selectionPreview: some View {
        HStack(spacing: 8) {
            Text("Selected")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(selection)
                .font(.largeTitle)
                .accessibilityLabel("Selected emoji \(selection)")
        }
    }

    private func emojiCell(_ emoji: String) -> some View {
        Button {
            Haptics.play(.light)
            selection = emoji
            // A grid pick supersedes and clears any free-type attempt.
            freeTypeText = ""
            freeTypeError = nil
        } label: {
            Text(emoji)
                .font(.title2)
                .frame(minWidth: 44, minHeight: 44)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(emoji == selection ? Color(.secondarySystemFill) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Emoji \(emoji)")
        .accessibilityAddTraits(emoji == selection ? [.isSelected] : [])
        .accessibilityIdentifier("emojiCell_\(emoji)")
    }

    private var freeTypeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Or type an emoji", text: $freeTypeText)
                // The value is matched/rendered verbatim; iOS autocapitalisation/autocorrect would
                // mangle a typed glyph exactly as it did tag names (trap e applies here too).
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("emojiFreeTypeField")
                .onChange(of: freeTypeText) { newValue in
                    applyFreeType(newValue)
                }
            if let freeTypeError {
                Text(freeTypeError)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("emojiFreeTypeError")
            }
        }
    }

    private func applyFreeType(_ raw: String) {
        guard !raw.isEmpty else {
            // Cleared field: not an error, just no free-type override in play.
            freeTypeError = nil
            return
        }
        switch LifeAreaEditorValidation.validateEmoji(raw) {
        case .valid(let emoji):
            selection = emoji
            freeTypeError = nil
        case .invalidEmpty:
            freeTypeError = nil
        case .invalidNotSingleGlyph:
            freeTypeError = "Enter a single emoji."
        }
    }
}

#if DEBUG
private struct EmojiPickerPreviewHost: View {
    @State private var selection = "🏠"
    var body: some View {
        Form {
            Section {
                LifeAreaEmojiPicker(selection: $selection)
            } header: {
                Text("Emoji")
            }
        }
    }
}

#Preview("Emoji Picker — Light") {
    EmojiPickerPreviewHost().preferredColorScheme(.light)
}

#Preview("Emoji Picker — Dark") {
    EmojiPickerPreviewHost().preferredColorScheme(.dark)
}
#endif
