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

    /// Off the same `entries` snapshot the sheet opened with, so the map cannot reshuffle
    /// under a finger mid-browse.
    private var browseSections: [PlaceAppCategoryBrowseSection] {
        PlaceAppPickerPresentation.categoryBrowse(entries)
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
            .navigationDestination(for: PlaceAppCategory.self) { category in
                List {
                    Section {
                        ForEach(entries(in: category)) { entry in
                            directoryRow(for: entry)
                        }
                    }
                }
                .navigationTitle(category.displayName)
                .navigationBarTitleDisplayMode(.inline)
            }
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

    /// Browsing reads as a short "Popular" head then a ten-row category map (E's 2026-09-02
    /// choice over a flat A–Z tail): the whole 152-app directory fits one screen instead of
    /// scrolling 144 rows. A live search collapses to one ranked section — the map only helps
    /// an eye that has nothing to search for.
    @ViewBuilder
    private var resultsSection: some View {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            entrySection(PlaceAppPickerPresentation.popular(results), header: "Popular")
            categoryMapSection
        } else {
            entrySection(results, header: nil)
        }
    }

    /// One row per non-empty category. The count is the point: it tells the eye how much is
    /// behind the chevron before spending a tap on it.
    private var categoryMapSection: some View {
        Section {
            ForEach(browseSections) { section in
                NavigationLink(value: section.category) {
                    LabeledContent {
                        Text("\(section.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } label: {
                        Text(section.category.displayName)
                            .font(.callout)
                            .foregroundStyle(Color("LabelPrimary"))
                    }
                    .frame(minHeight: 44)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(section.category.displayName), \(section.count) apps"
                    )
                }
                .accessibilityIdentifier("appPickerCategoryRow-\(section.category.rawValue)")
            }
        } header: {
            Text("Browse by category").sectionLabel()
        }
    }

    private func entries(in category: PlaceAppCategory) -> [PlaceAppDirectoryEntry] {
        browseSections.first { $0.category == category }?.entries ?? []
    }

    @ViewBuilder
    private func entrySection(_ entries: [PlaceAppDirectoryEntry], header: String?) -> some View {
        if !entries.isEmpty {
            Section {
                ForEach(entries) { entry in
                    directoryRow(for: entry)
                }
            } header: {
                if let header {
                    Text(header).sectionLabel()
                }
            }
        }
    }

    /// Shared by the Popular head, a search result and a category screen, so an app behaves
    /// identically wherever it is met.
    @ViewBuilder
    private func directoryRow(for entry: PlaceAppDirectoryEntry) -> some View {
        if entry.destinations.isEmpty {
            plainRow(for: entry)
        } else {
            // A push, not a pick: the destination step owns the choice — and its first row is
            // the plain open, so the default stays one tap away.
            NavigationLink(value: entry) {
                rowLabel(for: entry)
            }
            .accessibilityIdentifier("appPickerRow-\(entry.scheme)")
        }
    }

    private func plainRow(for entry: PlaceAppDirectoryEntry) -> some View {
        Button {
            Haptics.play(.selection)
            onPick(entry)
            dismiss()
        } label: {
            rowLabel(for: entry)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("appPickerRow-\(entry.scheme)")
    }

    /// POSITIVE-ONLY badge (F-AppDirectory-3): a quiet check for "looks installed", and
    /// nothing otherwise — 150 "doesn't look installed" marks would be noise, and most
    /// entries have no verification slot at all. VoiceOver reads the badge as one element
    /// with the row.
    ///
    /// **Currently switched OFF** at `PlaceAppPickerPresentation.showsInstalledBadge` (E,
    /// 2026-09-02), which short-circuits `checkInstalled` too — no row queries UIKit at all
    /// while the tick is dark.
    private func rowLabel(for entry: PlaceAppDirectoryEntry) -> some View {
        PlaceAppDirectoryRowLabel(
            entry: entry,
            looksInstalled: PlaceAppPickerPresentation.showsInstalledCheck(
                verdict: checkInstalled(entry.scheme)
            )
        )
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
                HStack(spacing: 8) {
                    PlaceAppMonogramDisc(name: "", systemImage: "square.dashed")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Something else\u{2026}")
                            .font(.callout)
                            .foregroundStyle(Color("LabelPrimary"))
                        Text("Paste a link or type a scheme — works for any app.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("appPickerCustomButton")
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
            Text(destination.name).sectionLabel()
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
