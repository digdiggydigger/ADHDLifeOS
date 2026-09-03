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

    private var isBrowsing: Bool {
        query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // `ScrollView` + `LazyVStack` per CLAUDE.md §2, and here it earns its keep
                // three times over: E asked for STICKY headers (a `List`'s inset-grouped style
                // will not pin), the row needs TWO independent hit areas which a `List` row's
                // single tap target fights, and the dense metrics need row padding a `List`
                // does not hand over.
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                    if results.isEmpty {
                        emptyState
                    } else if isBrowsing {
                        Section {
                            rowsCard(PlaceAppPickerPresentation.popular(results))
                        } header: {
                            pinnedHeader("Popular")
                        }
                        Section {
                            categoryCard
                        } header: {
                            pinnedHeader("Browse by category")
                        }
                    } else {
                        // One ranked list, no header: searching already says what the list is,
                        // and a lone pinned header would just eat a row of height.
                        rowsCard(results)
                    }
                    customCard
                }
                .padding(16)
            }
            .background(Color.pageBackground)
            .searchable(text: $query, prompt: "Search apps")
            .navigationTitle("Which app")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PlaceAppCategory.self) { category in
                categoryScreen(category)
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

    /// Opaque on purpose: a pinned header sits ON TOP of the rows sliding under it, and a
    /// transparent one lets app names show through its letters.
    ///
    /// **That was the requirement all along and `.bar` did not meet it** — it is a material, so
    /// it blurred the rows rather than hiding them, and this comment asserted the opposite while
    /// nothing checked. F-Tools-4-Headers moved both pinned headers onto the shared
    /// `pinnedSectionHeader()`, whose surface is the PAGE: opaque for the first time, and no
    /// longer a square strip laid over rounded cards. See `Theme.swift` for the measurement.
    private func pinnedHeader(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(.secondary)
            .pinnedSectionHeader()
    }

    /// One bordered card holding a run of rows with inset dividers — the house treatment from
    /// the Tasks board, so the picker and the rest of v3 stay in lockstep.
    private func rowsCard(_ entries: [PlaceAppDirectoryEntry]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                directoryRow(for: entry)
                if index != entries.indices.last {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .cardEdges()
    }

    /// The row TAP picks the app — every row, alike. Deep destinations moved OFF the row and
    /// onto their own control (E's 2026-09-02 call): a chevron that swallowed the whole row
    /// made Apple Maps behave unlike Apple Music for no reason a user could see, and charged
    /// an extra tap to do the ordinary thing.
    private func directoryRow(for entry: PlaceAppDirectoryEntry) -> some View {
        HStack(spacing: 8) {
            Button {
                Haptics.play(.selection)
                onPick(entry)
                dismiss()
            } label: {
                rowLabel(for: entry)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("appPickerRow-\(entry.scheme)")

            if PlaceAppPickerPresentation.showsDestinationControl(for: entry) {
                destinationControl(for: entry)
            }
        }
        .padding(.horizontal, 16)
    }

    /// "More ways in", not a bare chevron: the row itself no longer pushes, so an arrow here
    /// would promise navigation the row does not perform. 44×44 per §3, and its own
    /// accessibility element so VoiceOver offers picking and exploring as separate actions.
    private func destinationControl(for entry: PlaceAppDirectoryEntry) -> some View {
        NavigationLink(value: entry) {
            Image(systemName: "ellipsis.circle")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More ways to open \(entry.name)")
        .accessibilityIdentifier("appPickerDestinations-\(entry.scheme)")
    }

    /// The ten-row map. The count is the point — it says how much sits behind the chevron
    /// before a tap is spent finding out.
    private var categoryCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(browseSections.enumerated()), id: \.element.id) { index, section in
                NavigationLink(value: section.category) {
                    categoryRow(section)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("appPickerCategoryRow-\(section.category.rawValue)")
                if index != browseSections.indices.last {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .cardEdges()
    }

    private func categoryRow(_ section: PlaceAppCategoryBrowseSection) -> some View {
        HStack(spacing: 8) {
            // LabeledContent, not a hand-rolled HStack + Spacer: it reflows into two lines at
            // accessibility sizes instead of crushing the name into a narrow column (§7).
            LabeledContent {
                Text("\(section.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } label: {
                Text(section.category.displayName)
                    .font(.callout)
                    .foregroundStyle(Color("LabelPrimary"))
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, PlaceAppPickerPresentation.RowMetrics.verticalPadding)
        .frame(minHeight: PlaceAppPickerPresentation.RowMetrics.minimumHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.category.displayName), \(section.count) apps")
    }

    private func categoryScreen(_ category: PlaceAppCategory) -> some View {
        ScrollView {
            rowsCard(entries(in: category))
                .padding(16)
        }
        .background(Color.pageBackground)
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func entries(in category: PlaceAppCategory) -> [PlaceAppDirectoryEntry] {
        browseSections.first { $0.category == category }?.entries ?? []
    }

    /// The installed tick — positive-only by design (F-AppDirectory-3), and **currently
    /// switched OFF** at `PlaceAppPickerPresentation.showsInstalledBadge` (E, 2026-09-02),
    /// which short-circuits `checkInstalled` too: no row queries UIKit while the tick is dark.
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
    private var emptyState: some View {
        ContentUnavailableView(
            "Not in the list",
            systemImage: "magnifyingglass",
            description: Text("The list only holds apps with a reliable way in. "
                              + "\u{201C}Something else\u{2026}\u{201D} below works for any app.")
        )
        .padding(.vertical, 24)
    }

    private var customCard: some View {
        Button {
            Haptics.play(.selection)
            onCustom()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                PlaceAppMonogramDisc(
                    name: "", systemImage: "square.dashed",
                    size: PlaceAppPickerPresentation.RowMetrics.discSize
                )
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
            .frame(minHeight: PlaceAppPickerPresentation.RowMetrics.minimumHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityIdentifier("appPickerCustomButton")
    }
}

/// The rows-card edges: clip FIRST so a row's own background cannot bleed past the corner,
/// then the surface and its 1pt border. Matches the Tasks board's bucket card; no shadow,
/// because these cards butt against a pinned header rather than float.
@available(iOS 17.0, *)
private extension View {
    func cardEdges() -> some View {
        clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background(
                Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
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
