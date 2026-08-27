//
//  EmojiPicker.swift
//  ADHD LifeOS
//

import SwiftUI

/// The outcome of validating a typed emoji. Named neutrally now that the control is shared;
/// `LifeAreaEmojiValidation` remains as an alias so the Life Area editor and its tests are
/// untouched by the move.
enum EmojiValidationResult: Equatable {
    case invalidEmpty
    case invalidNotSingleGlyph
    case valid(String)
}

typealias LifeAreaEmojiValidation = EmojiValidationResult

/// One grapheme cluster, or it isn't an emoji we can render in a 44pt cell.
enum EmojiValidation {
    static func validate(_ raw: String) -> EmojiValidationResult {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalidEmpty }
        guard trimmed.count == 1 else { return .invalidNotSingleGlyph }
        return .valid(trimmed)
    }
}

/// The curated palettes. Kept as data rather than inline literals so their invariants — every
/// entry a single grapheme cluster, no duplicates — can actually be tested; a malformed entry
/// would otherwise put an invalid value into the binding the moment it was tapped.
enum EmojiPalette {
    /// Spans the kinds of areas people track.
    static let lifeArea: [String] = [
        "🏠", "💼", "💪", "🧠", "❤️", "👨‍👩‍👧‍👦", "💰", "📚",
        "🎯", "✅", "🎨", "🎵", "🏃", "🧘", "🍎", "🌱",
        "✈️", "🛠️", "📝", "🗂️", "📅", "💡", "🔧", "🎮",
        "🐶", "🌍", "⚽️", "🎬", "🍳", "🛒", "💊", "🚗",
        "✏️", "📱", "💻", "🎓", "🏥", "🧹", "🌿", "⭐️"
    ]

    /// Spans the kinds of PLACES people go — buildings and destinations rather than life themes.
    /// A place palette of "🧠 ❤️ 🎯" would be useless, which is why this is separate.
    static let place: [String] = [
        "🏠", "🏢", "🏋️", "☕️", "🛒", "🏥", "🏫", "🏦",
        "🍽️", "🍺", "🌳", "🏖️", "🚉", "✈️", "⛽️", "🅿️",
        "🎬", "🎭", "📚", "💈", "🐶", "⚽️", "🏊", "🧺",
        "🧘", "🎨", "🛠️", "📦", "👵", "👨‍👩‍👧", "🏛️", "⛪️",
        "🏨", "🚗", "🩺", "💊", "🌆", "🗺️", "📍", "⭐️"
    ]
}

/// Emoji control shared by the Life Area editor and the Places editor: a curated tap-grid (the
/// fast path) plus a free-type field (covers anything not shipped), per §8.
///
/// The grid can only ever produce a valid single-glyph value; the free-type field is validated to
/// exactly one grapheme cluster and shows a readable inline message otherwise — it never pushes an
/// invalid value into the binding.
///
/// Moved out of `LifeAreaEditor` and parameterised when Places needed it (E, 2026-08-27): a place
/// wants a different palette, and its emoji is OPTIONAL, which the Life Area version had no way to
/// express.
struct EmojiPicker: View {
    @Binding var selection: String
    var palette: [String] = EmojiPalette.lifeArea
    /// When true, a "None" cell can clear the selection — for owners whose emoji is optional.
    var allowsClearing = false

    @State private var freeTypeText = ""
    @State private var freeTypeError: String?

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            selectionPreview

            LazyVGrid(columns: columns, spacing: 8) {
                if allowsClearing {
                    clearCell
                }
                ForEach(palette, id: \.self) { emoji in
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
            if selection.isEmpty {
                Text("None")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("No emoji selected")
            } else {
                Text(selection)
                    .font(.largeTitle)
                    .accessibilityLabel("Selected emoji \(selection)")
            }
        }
    }

    private var clearCell: some View {
        Button {
            Haptics.play(.light)
            selection = ""
            freeTypeText = ""
            freeTypeError = nil
        } label: {
            Image(systemName: "slash.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selection.isEmpty ? Color(.secondarySystemFill) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("No emoji")
        .accessibilityAddTraits(selection.isEmpty ? [.isSelected] : [])
        .accessibilityIdentifier("emojiCell_none")
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
        switch EmojiValidation.validate(raw) {
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
                EmojiPicker(selection: $selection)
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
