//
//  PlaceAppPickerView.swift
//  ADHD LifeOS
//
//  The searchable app directory sheet (F-AppDirectory-1-Directory), replacing the action
//  editor's 10-entry inline Picker. Gated to iOS 17 with the rest of the Places feature — see
//  `PlaceMapPicker` for the §7 note.
//

import SwiftUI

/// Pick one app from the directory, or step out to the custom path. Picking never widens the
/// wire format — the caller saves a plain `.openApp` exactly as the old Picker did.
@available(iOS 17.0, *)
struct PlaceAppPickerView: View {
    let entries: [PlaceAppDirectoryEntry]
    let onPick: (PlaceAppDirectoryEntry) -> Void
    let onCustom: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [PlaceAppDirectoryEntry] {
        PlaceAppDirectorySearch.filter(query, in: entries)
    }

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty {
                    emptySection
                } else {
                    resultsSection
                }
                customSection
            }
            .searchable(text: $query, prompt: "Search apps")
            .navigationTitle("Which app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("appPickerCancelButton")
                }
            }
        }
    }

    private var resultsSection: some View {
        Section {
            ForEach(results) { entry in
                Button {
                    Haptics.play(.selection)
                    onPick(entry)
                    dismiss()
                } label: {
                    Text(entry.name)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .accessibilityIdentifier("appPickerRow-\(entry.scheme)")
            }
        }
    }

    /// The honest miss: the directory is curated, not complete — the custom path underneath is
    /// the answer, not a dead end.
    private var emptySection: some View {
        Section {
            ContentUnavailableView(
                "Not in the list",
                systemImage: "magnifyingglass",
                description: Text("The list only holds apps with a reliable way in. "
                                  + "\u{201C}Something else\u{2026}\u{201D} below works for any app.")
            )
        }
    }

    private var customSection: some View {
        Section {
            Button {
                Haptics.play(.selection)
                onCustom()
                dismiss()
            } label: {
                Label("Something else\u{2026}", systemImage: "square.dashed")
            }
            .contentShape(Rectangle())
            .accessibilityIdentifier("appPickerCustomButton")
        } footer: {
            Text("Any app with a link or URL scheme can open, even if it isn't listed.")
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Picker — Light") {
    PlaceAppPickerView(
        entries: PlaceAppDirectoryBundled.entries, onPick: { _ in }, onCustom: {}
    )
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Picker — Dark") {
    PlaceAppPickerView(
        entries: PlaceAppDirectoryBundled.entries, onPick: { _ in }, onCustom: {}
    )
    .preferredColorScheme(.dark)
}
#endif
