//
//  PlaceAppPickerView.swift
//  ADHD LifeOS
//
//  The searchable app directory sheet (F-AppDirectory-1-Directory), replacing the action
//  editor's 10-entry inline Picker; the destination step (F-AppDirectory-2-Links) hangs off
//  entries that offer one. Gated to iOS 17 with the rest of the Places feature — see
//  `PlaceMapPicker` for the §7 note.
//

import SwiftUI

/// Pick one app from the directory — or one of its deep destinations — or step out to the
/// custom path. A plain pick saves `.openApp` exactly as the old Picker did; only a
/// destination pick produces a link.
@available(iOS 17.0, *)
struct PlaceAppPickerView: View {
    let entries: [PlaceAppDirectoryEntry]
    /// For the destination step's one-tap "Directions to <place>" row — the free synergy of
    /// already being inside a place's editor.
    let placeName: String
    let placeCoordinate: PlaceCoordinate?
    let onPick: (PlaceAppDirectoryEntry) -> Void
    let onPickLink: (PlaceActionDraftLinkPick) -> Void
    let onCustom: () -> Void
    /// Injected so previews don't consult UIKit; the default is the real check.
    var checkInstalled: (String?) -> PlaceAppInstallVerdict = { scheme in
        PlaceAppInstallVerdict.verdict(scheme: scheme) {
            UIApplicationSchemeInstallChecker().canOpen($0)
        }
    }

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
            .navigationDestination(for: PlaceAppDirectoryEntry.self) { entry in
                PlaceAppDestinationStep(
                    entry: entry,
                    placeName: placeName,
                    placeCoordinate: placeCoordinate,
                    onJustOpen: {
                        onPick(entry)
                        dismiss()
                    },
                    onPickLink: { pick in
                        onPickLink(pick)
                        dismiss()
                    }
                )
            }
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
                if entry.destinations.isEmpty {
                    plainRow(for: entry)
                } else {
                    // A push, not a pick: the destination step owns the choice — and its
                    // first row is the plain open, so the default stays one tap away.
                    NavigationLink(value: entry) {
                        rowLabel(for: entry)
                    }
                    .accessibilityIdentifier("appPickerRow-\(entry.scheme)")
                }
            }
        }
    }

    private func plainRow(for entry: PlaceAppDirectoryEntry) -> some View {
        Button {
            Haptics.play(.selection)
            onPick(entry)
            dismiss()
        } label: {
            rowLabel(for: entry)
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier("appPickerRow-\(entry.scheme)")
    }

    /// POSITIVE-ONLY badge (F-AppDirectory-3): a quiet check for "looks installed", and
    /// nothing otherwise — 150 "doesn't look installed" marks would be noise, and most
    /// entries have no verification slot at all. VoiceOver reads the badge as one element
    /// with the row.
    private func rowLabel(for entry: PlaceAppDirectoryEntry) -> some View {
        HStack(spacing: 8) {
            Text(entry.name)
            if checkInstalled(entry.scheme) == .looksInstalled {
                Image(systemName: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Installed on this iPhone")
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

/// One app's destinations: the plain open first (the ADHD-friendly default — skippable in one
/// tap means the DEFAULT is one tap), then the place-prefilled rows, then the type-a-value
/// forms.
@available(iOS 17.0, *)
private struct PlaceAppDestinationStep: View {
    let entry: PlaceAppDirectoryEntry
    let placeName: String
    let placeCoordinate: PlaceCoordinate?
    let onJustOpen: () -> Void
    let onPickLink: (PlaceActionDraftLinkPick) -> Void

    @State private var values: [String: String] = [:]

    var body: some View {
        Form {
            Section {
                Button {
                    Haptics.play(.selection)
                    onJustOpen()
                } label: {
                    Label("Just open \(entry.name)", systemImage: "arrow.up.forward.app")
                }
                .contentShape(Rectangle())
                .accessibilityIdentifier("destinationJustOpenButton")
            }
            if placeCoordinate != nil {
                directionsSection
            }
            ForEach(entry.destinations, id: \.self) { destination in
                destinationSection(for: destination)
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The free synergy: this editor already knows where the place IS.
    @ViewBuilder
    private var directionsSection: some View {
        let prefillable = entry.destinations.filter(\.placeCoordinatePrefill)
        if let destination = prefillable.first, let placeCoordinate {
            Section {
                Button {
                    Haptics.play(.selection)
                    let value = PlaceAppDestinationPick.coordinateValue(placeCoordinate)
                    guard let link = destination.resolved(with: value) else { return }
                    onPickLink(
                        PlaceActionDraftLinkPick(
                            displayName: PlaceAppDestinationPick.directionsDisplayName(
                                entry: entry, placeName: placeName
                            ),
                            link: link,
                            scheme: entry.scheme
                        )
                    )
                } label: {
                    Label("Directions to \(placeName)", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
                .contentShape(Rectangle())
                .accessibilityIdentifier("destinationDirectionsButton")
            } footer: {
                Text("Uses this place's own location — nothing to type.")
            }
        }
    }

    private func destinationSection(for destination: PlaceAppDestinationTemplate) -> some View {
        Section {
            TextField(
                destination.isPassThrough ? "Paste the share link" : "Paste or type it here",
                text: binding(for: destination)
            )
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .accessibilityIdentifier("destinationValueField-\(destination.name)")
            Button {
                Haptics.play(.selection)
                guard let pick = pick(for: destination) else { return }
                onPickLink(pick)
            } label: {
                Text("Add \u{201C}\(destination.name)\u{201D}")
            }
            .disabled(pick(for: destination) == nil)
            .accessibilityIdentifier("destinationAddButton-\(destination.name)")
        } header: {
            Text(destination.name)
        }
    }

    private func binding(for destination: PlaceAppDestinationTemplate) -> Binding<String> {
        Binding(
            get: { values[destination.name] ?? "" },
            set: { values[destination.name] = $0 }
        )
    }

    private func pick(for destination: PlaceAppDestinationTemplate) -> PlaceActionDraftLinkPick? {
        guard let link = destination.resolved(with: values[destination.name] ?? ""),
              URL(string: link) != nil else { return nil }
        return PlaceActionDraftLinkPick(
            displayName: PlaceAppDestinationPick.displayName(entry: entry, destination: destination),
            link: link,
            scheme: entry.scheme
        )
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Picker — Light") {
    PlaceAppPickerView(
        entries: PlaceAppDirectoryBundled.entries,
        placeName: "Gym",
        placeCoordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
        onPick: { _ in }, onPickLink: { _ in }, onCustom: {}
    )
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Picker — Dark") {
    PlaceAppPickerView(
        entries: PlaceAppDirectoryBundled.entries,
        placeName: "Gym",
        placeCoordinate: nil,
        onPick: { _ in }, onPickLink: { _ in }, onCustom: {}
    )
    .preferredColorScheme(.dark)
}
#endif
