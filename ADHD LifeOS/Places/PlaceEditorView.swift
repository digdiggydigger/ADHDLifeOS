//
//  PlaceEditorView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Create or edit one place: name, identity emoji, where it is, and how big it is.
///
/// Gated to iOS 17 with the rest of the Places feature — see `PlaceMapPicker` for the §7 note.
@available(iOS 17.0, *)
struct PlaceEditorView: View {
    /// `nil` when creating.
    let existing: Place?
    let onSave: (Place) async -> Bool
    var isSaving: Bool = false

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var coordinate: PlaceCoordinate?
    @State private var radiusMetres: Double = 200
    @State private var hasSeeded = false

    private var canSave: Bool {
        PlaceEditorValidation.canSave(name: name, coordinate: coordinate) && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                locationSection
                radiusSection
            }
            .navigationTitle(existing == nil ? "New place" : "Edit place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("placeEditorCancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(!canSave)
                        .accessibilityIdentifier("placeEditorSaveButton")
                }
            }
            .task { seedOnce() }
        }
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section {
            TextField("Name", text: $name)
                .accessibilityIdentifier("placeEditorNameField")
            TextField("Emoji (optional)", text: $emoji)
                .accessibilityIdentifier("placeEditorEmojiField")
        } header: {
            Text("What is it")
        }
    }

    private var locationSection: some View {
        Section {
            PlaceMapPicker(coordinate: $coordinate, radiusMetres: radiusMetres)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Where it is")
        } footer: {
            // Said out loud rather than implied: an empty map with no instruction is the single
            // most likely way this screen confuses someone.
            Text(coordinate == nil
                 ? "Tap the map to drop a pin."
                 : "Tap again anywhere to move the pin.")
        }
    }

    private var radiusSection: some View {
        Section {
            Stepper(
                value: $radiusMetres,
                in: Place.minimumRadiusMetres...Place.maximumRadiusMetres,
                step: 50,
                onEditingChanged: { editing in
                    // Once, on release — the house stepper rule (E, 2026-08-27).
                    if !editing { Haptics.play(.selection) }
                },
                label: {
                    LabeledContent("Radius", value: "\(Int(radiusMetres)) m")
                }
            )
            .accessibilityIdentifier("placeEditorRadiusStepper")
        } header: {
            Text("How close counts as here")
        } footer: {
            Text("Arriving anywhere inside the circle counts as arriving. "
                 + "Below about 100m, arrival detection gets unreliable.")
        }
    }

    // MARK: - Behaviour

    /// Seeds the fields once. Guarded because `.task` can re-run, and re-seeding mid-edit would
    /// silently throw away what E had typed.
    private func seedOnce() {
        guard !hasSeeded else { return }
        hasSeeded = true
        guard let existing else { return }
        name = existing.name
        emoji = existing.emoji ?? ""
        coordinate = existing.coordinate
        radiusMetres = existing.radiusMetres
    }

    private func save() async {
        guard let place = PlaceEditorValidation.makePlace(
            id: existing?.id ?? UUID(),
            name: name,
            coordinate: coordinate,
            radiusMetres: radiusMetres,
            emoji: emoji,
            // Preserved on edit so a save cannot orphan records already tagged with this place.
            createdAt: existing?.createdAt ?? .now
        ) else { return }

        if await onSave(place) {
            dismiss()
        }
    }
}
