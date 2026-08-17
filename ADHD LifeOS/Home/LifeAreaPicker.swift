//
//  LifeAreaPicker.swift
//  ADHD LifeOS
//

import SwiftUI

/// The one shared life-area picker used by all five sites (Task Create, Task Detail, Capture
/// triage, Journal filter, Log composer).
///
/// Built on `Menu` + `Button`, **not** `Picker`: `.disabled(true)` on a row inside a `Picker`
/// (menu or inline style) does nothing, so "archived — greyed and unselectable" (§8) is simply not
/// available from `Picker`. On a `Button` inside a `Menu` it genuinely greys the row and refuses
/// the tap. Archived-ness is also carried in TEXT (an "Archived" suffix), so it is never conveyed
/// by colour alone (§4) — and VoiceOver reads each row as one `Label`.
struct LifeAreaPicker: View {
    let title: String
    /// The leading option, tagged `nil`. Preserved verbatim per site: "None" (Task Create / Detail /
    /// Capture triage), "All" (Journal filter), "No life area" (Log composer).
    let noSelectionLabel: String
    let lifeAreas: [LifeArea]
    @Binding var selection: UUID?
    let accessibilityID: String

    /// An archived row is disabled EXCEPT when it is the current selection. Without that exception a
    /// task or log that already holds an archived area would render blank — which is exactly the
    /// failure §8 chose greying-over-hiding to avoid. Pure so the rule is unit-tested directly.
    static func isRowDisabled(area: LifeArea, isSelected: Bool) -> Bool {
        area.archived && !isSelected
    }

    /// Active areas first (by sortOrder), then archived (by sortOrder) — matching the Settings
    /// editor's "archived in their own section at the bottom" precedent.
    private var orderedAreas: [LifeArea] {
        let active = lifeAreas.filter { !$0.archived }.sorted { $0.sortOrder < $1.sortOrder }
        let archived = lifeAreas.filter { $0.archived }.sorted { $0.sortOrder < $1.sortOrder }
        return active + archived
    }

    private var selectedLabel: String {
        guard let selection, let area = lifeAreas.first(where: { $0.id == selection }) else {
            return noSelectionLabel
        }
        return area.name
    }

    var body: some View {
        Menu {
            Button { selection = nil } label: {
                rowLabel(text: noSelectionLabel, isSelected: selection == nil, isDisabled: false)
            }
            ForEach(orderedAreas) { area in
                let isSelected = selection == area.id
                let isDisabled = Self.isRowDisabled(area: area, isSelected: isSelected)
                Button { selection = area.id } label: {
                    rowLabel(
                        text: area.archived ? "\(area.name) (Archived)" : area.name,
                        isSelected: isSelected,
                        isDisabled: isDisabled
                    )
                }
                .disabled(isDisabled)
            }
        } label: {
            // In a Form this renders as a tappable row with the value trailing — matching the
            // Picker it replaces. `LabeledContent` reflows at accessibility Dynamic Type sizes
            // instead of clipping into narrow columns (§7 house pattern).
            LabeledContent(title, value: selectedLabel)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier(accessibilityID)
    }

    @ViewBuilder
    private func rowLabel(text: String, isSelected: Bool, isDisabled: Bool) -> some View {
        Group {
            if isSelected {
                Label(text, systemImage: "checkmark")
            } else {
                Text(text)
            }
        }
        // Greyed via a semantic hierarchical style, never `.opacity` (§4). The disabled state also
        // greys the row on its own; this reinforces it where the system menu honours the style.
        .foregroundStyle(isDisabled ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
    }
}

#if DEBUG
private struct LifeAreaPickerPreviewHost: View {
    @State private var selection: UUID?
    let areas: [LifeArea]
    let initialSelection: UUID?

    init(areas: [LifeArea], initialSelection: UUID? = nil) {
        self.areas = areas
        self.initialSelection = initialSelection
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        Form {
            LifeAreaPicker(
                title: "Life Area",
                noSelectionLabel: "None",
                lifeAreas: areas,
                selection: $selection,
                accessibilityID: "previewLifeAreaPicker"
            )
        }
    }
}

private let previewActive = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
private let previewArchived = LifeArea(id: UUID(), name: "Old Side Project", colour: "🗂️", sortOrder: 1, archived: true)

#Preview("Archived present — Light") {
    LifeAreaPickerPreviewHost(areas: [previewActive, previewArchived])
        .preferredColorScheme(.light)
}

#Preview("Archived present — Dark") {
    LifeAreaPickerPreviewHost(areas: [previewActive, previewArchived])
        .preferredColorScheme(.dark)
}

#Preview("Archived IS the selection") {
    // The exception: an archived area held as the current selection stays selectable and shown.
    LifeAreaPickerPreviewHost(areas: [previewActive, previewArchived], initialSelection: previewArchived.id)
}
#endif
