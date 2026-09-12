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
    @State private var nudgeOnArrival = false
    @State private var nudgeOnDeparture = false
    @State private var arrivalMessage = ""
    @State private var departureMessage = ""
    /// Staged like every other field and applied on Save — including `.unsupported` actions
    /// from a newer build, which ride through untouched.
    @State private var actions: [PlaceAction] = []
    @State private var hasSeeded = false
    @State private var addressQuery = ""
    /// The last address E chose, held as a FALLBACK name only. E's 2026-08-27 rule: it must not
    /// write into the name field — it applies at save time, and only if the field is still empty.
    @State private var chosenAddressTitle: String?
    /// Owned here so the suggestion list survives the map re-rendering under it.
    @StateObject private var addressSearch = PlaceAddressSearchService(
        completer: MapKitAddressProvider.shared,
        resolver: MapKitAddressProvider.shared
    )

    private var canSave: Bool {
        PlaceEditorValidation.canSave(
            name: name,
            coordinate: coordinate,
            addressFallback: chosenAddressTitle
        ) && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                locationSection
                radiusSection
                nudgesSection
                PlaceActionsSection(actions: $actions, placeName: name, placeCoordinate: coordinate)
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
            // The shared grid, not a bare TextField (E's 2026-08-27 note): a text field opened the
            // alphabetic keyboard, accepted "hello", and gave no sense of what a good pick was.
            // `allowsClearing` because a place's emoji is genuinely optional — the row falls back
            // to 📍 — which the Life Area version had no way to express.
            EmojiPicker(selection: $emoji, palette: EmojiPalette.place, allowsClearing: true)
                .accessibilityIdentifier("placeEditorEmojiPicker")
        } header: {
            Text("What is it")
        } footer: {
            if PlaceEditorValidation.normalizedName(name) == nil, let chosenAddressTitle {
                Text("Leave the name blank and this will be saved as \"\(chosenAddressTitle)\".")
            }
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

    /// Drops the pin and REMEMBERS the address — it deliberately does not touch the name field
    /// (E's 2026-08-27 bug report: it was filling the field the instant an address was chosen).
    private func choose(_ suggestion: AddressSuggestion) async {
        guard let resolved = await addressSearch.resolve(suggestion) else { return }
        Haptics.play(.solid)
        coordinate = resolved
        addressQuery = ""
        chosenAddressTitle = suggestion.title
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

    /// The per-place nudge toggles (block 4b) — staged like every other field here, applied on
    /// Save. The Always escalation banner appears the moment a toggle goes on: that first flip
    /// is when the feature finally means something, which is the honest moment to ask.
    private var nudgesSection: some View {
        Section {
            Toggle("Nudge on arrival", isOn: $nudgeOnArrival)
                .accessibilityIdentifier("placeEditorArrivalToggle")
            if nudgeOnArrival {
                TextField("Say this when I arrive (optional)", text: $arrivalMessage, axis: .vertical)
                    .accessibilityIdentifier("placeEditorArrivalMessageField")
            }
            Toggle("Nudge when leaving", isOn: $nudgeOnDeparture)
                .accessibilityIdentifier("placeEditorDepartureToggle")
            if nudgeOnDeparture {
                TextField("Say this when I leave (optional)", text: $departureMessage, axis: .vertical)
                    .accessibilityIdentifier("placeEditorDepartureMessageField")
            }
            if nudgeOnArrival || nudgeOnDeparture {
                LocationPermissionBanner(wantsTriggering: true)
            }
        } header: {
            Text("Nudges")
        } footer: {
            Text("Off by default. A nudging place uses one of the "
                 + "\(PlaceMonitoringCapacity.limit) monitoring slots iOS gives the whole app. "
                 + "With a message set, that crossing always says it; with none, a nudge only "
                 + "fires when this place has open At-Place tasks.")
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
        nudgeOnArrival = existing.nudgeOnArrival
        nudgeOnDeparture = existing.nudgeOnDeparture
        arrivalMessage = existing.arrivalMessage ?? ""
        departureMessage = existing.departureMessage ?? ""
        actions = existing.actions
    }

    private func save() async {
        guard let place = PlaceEditorValidation.makePlace(
            id: existing?.id ?? UUID(),
            name: name,
            coordinate: coordinate,
            radiusMetres: radiusMetres,
            emoji: emoji,
            // Preserved on edit so a save cannot orphan records already tagged with this place.
            createdAt: existing?.createdAt ?? .now,
            addressFallback: chosenAddressTitle,
            nudgeOnArrival: nudgeOnArrival,
            nudgeOnDeparture: nudgeOnDeparture,
            arrivalMessage: arrivalMessage,
            departureMessage: departureMessage,
            actions: actions
        ) else { return }

        if await onSave(place) {
            // AFTER the write lands, never before: `onSave` returns false when it failed,
            // and a buzz on the way in would report a save that never happened.
            Haptics.play(.solid)
            dismiss()
        }
    }
}
