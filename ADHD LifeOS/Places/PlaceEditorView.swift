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
    @State private var addressQuery = ""
    /// Owned here so the suggestion list survives the map re-rendering under it.
    @StateObject private var addressSearch = PlaceAddressSearchService(
        completer: MapKitAddressProvider.shared,
        resolver: MapKitAddressProvider.shared
    )

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
            // Two ways in, because they suit different intents: typing is how you enter
            // "14 Bridge Street", tapping is how you pick "that corner of the park" (E's
            // 2026-08-27 critique — the map alone could not do the first).
            addressField
            addressResults
            PlaceMapPicker(coordinate: $coordinate, radiusMetres: radiusMetres)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Where it is")
        } footer: {
            // Said out loud rather than implied: an empty map with no instruction is the single
            // most likely way this screen confuses someone.
            Text(coordinate == nil
                 ? "Search for an address, or tap the map to drop a pin."
                 : "Search again, or tap the map to move the pin.")
        }
    }

    private var addressField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search for an address", text: $addressQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onChange(of: addressQuery) { _, newValue in
                    addressSearch.updateQuery(newValue)
                }
                .accessibilityIdentifier("placeEditorAddressField")
            if !addressQuery.isEmpty {
                Button {
                    addressQuery = ""
                    addressSearch.updateQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear the address search")
                .accessibilityIdentifier("placeEditorAddressClearButton")
            }
        }
    }

    @ViewBuilder
    private var addressResults: some View {
        switch addressSearch.state {
        case .idle:
            EmptyView()
        case .searching:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Searching…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("placeEditorAddressSearching")
        case .noMatches:
            // "No matches" is information; a blank gap here reads as a broken screen.
            Text("No matches for that address.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("placeEditorAddressNoMatches")
        case .failed(let message):
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color("StateRisk"))
                .accessibilityIdentifier("placeEditorAddressError")
        case .results:
            ForEach(addressSearch.suggestions) { suggestion in
                Button {
                    Task { await choose(suggestion) }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.callout)
                            .foregroundStyle(Color("LabelPrimary"))
                        if !suggestion.subtitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text(suggestion.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("placeEditorAddressSuggestion-\(suggestion.id)")
            }
        }
    }

    /// A chosen address drops the pin AND fills the name when E hasn't typed one — naming a place
    /// after the address you just searched for is the overwhelmingly common case.
    private func choose(_ suggestion: AddressSuggestion) async {
        guard let resolved = await addressSearch.resolve(suggestion) else { return }
        Haptics.play(.solid)
        coordinate = resolved
        addressQuery = ""
        if PlaceEditorValidation.normalizedName(name) == nil {
            name = suggestion.title
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
