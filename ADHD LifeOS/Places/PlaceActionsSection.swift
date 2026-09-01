//
//  PlaceActionsSection.swift
//  ADHD LifeOS
//
//  The Actions section of the Place editor (F-PlaceActions-2-Editor), split from the add/edit
//  sheet's file when the block-4 automation rows tipped it over the 400-line lint bar. Gated to
//  iOS 17 with the rest of the Places feature — see `PlaceMapPicker` for the §7 note.
//

import SwiftUI

/// What the editor sheet is being opened FOR — `Identifiable` so one `.sheet(item:)` covers
/// both adding and editing without two parallel booleans that could both fire. Identity is
/// minted per presentation (the context is created in a tap handler, never per render).
private struct PlaceActionEditorContext: Identifiable {
    /// The action being edited, or `nil` when adding.
    let editing: PlaceAction?
    let id = UUID()
}

/// What the guide sheet is being opened FOR — the same minted-per-presentation arrangement,
/// holding the already-built guide so the sheet never re-derives it.
private struct PlaceAutomationGuideContext: Identifiable {
    let guide: PlaceAutomationGuide
    let id = UUID()
}

/// The Actions section of `PlaceEditorView`: what this place DOES on a crossing.
@available(iOS 17.0, *)
struct PlaceActionsSection: View {
    @Binding var actions: [PlaceAction]
    /// For the automation guides' location step — the fences don't transfer to Shortcuts, so
    /// the guide can only NAME the place E should pick in Apple's own location picker.
    let placeName: String
    @State private var editorContext: PlaceActionEditorContext?
    @State private var guideContext: PlaceAutomationGuideContext?

    /// The block-4 walkthrough rows: one per action Shortcuts can genuinely automate, keyed
    /// distinctly from the action rows above — one List must never see the same id twice.
    private var automatableGuides: [(rowID: String, guide: PlaceAutomationGuide)] {
        actions.compactMap { action in
            PlaceAutomationGuide.make(for: action, placeName: placeName)
                .map { ("automation-\(action.id.uuidString)", $0) }
        }
    }

    var body: some View {
        Section {
            ForEach(actions) { action in
                row(for: action)
            }
            .onDelete { offsets in
                Haptics.play(.selection)
                actions.remove(atOffsets: offsets)
            }
            // A separate ForEach, NOT rows inside the one above: sharing the deletable
            // ForEach would give every guide row its own swipe-to-delete on the wrong index.
            ForEach(automatableGuides, id: \.rowID) { entry in
                Button {
                    guideContext = PlaceAutomationGuideContext(guide: entry.guide)
                } label: {
                    Label(entry.guide.title, systemImage: "wand.and.stars")
                        .font(.footnote)
                }
                .accessibilityIdentifier("placeEditorAutomationRow-\(entry.rowID)")
            }
            Button {
                editorContext = PlaceActionEditorContext(editing: nil)
            } label: {
                Label("Add an action", systemImage: "plus.circle.fill")
            }
            .accessibilityIdentifier("placeEditorAddActionButton")
            // On the BUTTON, not the Section: a presentation modifier on a `Section` gets
            // applied per-row, and the duplicate presentations dismissed the whole place
            // editor on device (2026-08-31, caught in the block-2 simulator drive). Any single
            // concrete view inside the section can host it; rows share it via `editorContext`.
            .sheet(item: $editorContext) { context in
                PlaceActionEditorSheet(existing: context.editing) { saved in
                    Haptics.play(.solid)
                    if let index = actions.firstIndex(where: { $0.id == saved.id }) {
                        actions[index] = saved
                    } else {
                        actions.append(saved)
                    }
                }
            }
            // Sibling sheets on one view present fine (iOS 14.5+); what they must not do is
            // hang off the Section — the per-row trap above.
            .sheet(item: $guideContext) { context in
                PlaceAutomationGuideView(guide: context.guide)
            }
        } header: {
            Text("Actions")
        } footer: {
            Text("Things this place does when you arrive or leave. An action makes this place "
                 + "watch that crossing (it uses a monitoring slot, like a nudge). Actions that "
                 + "open apps or send texts arrive as a notification — one tap runs them.")
        }
    }

    @ViewBuilder
    private func row(for action: PlaceAction) -> some View {
        if case .unsupported = action.kind {
            // Kept and named, never hidden or editable — this build can only preserve it.
            VStack(alignment: .leading, spacing: 2) {
                Text(PlaceActionRowLabel.title(for: action))
                Text(PlaceActionRowLabel.subtitle(for: action))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(PlaceActionRowLabel.unsupportedExplainer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("placeEditorActionRow-\(action.id)")
        } else {
            Button {
                editorContext = PlaceActionEditorContext(editing: action)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(PlaceActionRowLabel.title(for: action))
                        .foregroundStyle(Color("LabelPrimary"))
                    Text(PlaceActionRowLabel.subtitle(for: action))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("placeEditorActionRow-\(action.id)")
        }
    }
}
