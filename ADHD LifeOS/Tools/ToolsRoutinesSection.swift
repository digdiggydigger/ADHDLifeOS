//
//  ToolsRoutinesSection.swift
//  ADHD LifeOS
//
//  The Routines section of the Tools page (F-Routines-B-ToolsSection).
//
//  E, 2026-09-05: "the routines section deserves its own Routines section on the Tool list."
//  So it is first-class and named Routines — not folded into Places, not labelled "places that
//  have routines" — while remaining, underneath, exactly what a routine already is: a place's
//  actions for one direction. Every word and every row comes from `ToolsRoutinesCatalog`.
//
//  **Its own file, and its own `PlacesService`.** `ToolsView` receives `placesClient` through the
//  default-param door and hands it on; the section owns the load so `ToolsView` keeps the bare
//  `ToolsView()` call site `AppTabBarCallSiteTests` pins. Two services over one collection is the
//  house arrangement — `PlacesListView` builds its own too, and `DataChangeSignal` keeps them
//  honest with each other.
//
//  Gated to iOS 17 with the rest of Places: the editor a row opens is `@available(iOS 17.0, *)`,
//  so on the 16.0 floor there is nothing to open and the section must not draw.
//

import SwiftUI

@available(iOS 17.0, *)
struct ToolsRoutinesSection: View {
    @StateObject private var service: PlacesService
    /// The routine record (F-RoutineRecord-2): the rows' last-run line. Reconciled on load by
    /// the same reconciler the Journal uses.
    @StateObject private var history: RoutineRunHistoryService
    private let client: PlacesClientAdapting
    /// The place whose editor is open. A routine's editor IS the place's Actions section
    /// (E's settled Option A) — there is no separate routine to edit.
    @State private var editingPlace: Place?
    /// The master switch, re-read wherever the section already refreshes (`.task` on every tab
    /// switch, plus `DataChangeSignal`). Settings' own toggle posts no signal, so a flip made
    /// there reaches this banner on the next tab visit — the house behavior for preference
    /// reads, and Settings sits on another tab so the two are never stale on one screen.
    @State private var arrivalNudgesEnabled = true
    private let preferencesStore: MomentumPreferencesStoring
    /// The empty state's door to Places. `ToolsView` pushes it through its own flag, so the tab
    /// re-tap can pop it (E, 2026-09-08) — a closure link here could not be popped from outside.
    private let onOpenPlaces: () -> Void

    init(
        client: PlacesClientAdapting,
        history: RoutineRunHistoryService? = nil,
        preferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore(),
        onOpenPlaces: @escaping () -> Void = {}
    ) {
        self.client = client
        self.preferencesStore = preferencesStore
        self.onOpenPlaces = onOpenPlaces
        _service = StateObject(wrappedValue: PlacesService(client: client))
        _history = StateObject(wrappedValue: history ?? RoutineRunHistoryService.live())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            content
        }
        // 8 on top of the page's own 16 makes 24 — a §2 macro separation, so the section reads
        // as its own group rather than a third door in the same stack.
        .padding(.top, 8)
        .task {
            arrivalNudgesEnabled = preferencesStore.read().arrivalNudgesEnabled
            await service.load()
            await history.load()
        }
        // The house refresh contract: editing a place's actions anywhere re-derives these rows,
        // because whether a place IS a routine is decided by the actions that edit changes —
        // and a routine finishing anywhere re-derives the last-run line.
        .onReceive(DataChangeSignal.changes) { _ in
            arrivalNudgesEnabled = preferencesStore.read().arrivalNudgesEnabled
            Task {
                await service.load()
                await history.load()
            }
        }
        .sheet(item: $editingPlace) { place in
            PlaceEditorView(existing: place, onSave: save, isSaving: service.isMutating)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ToolsRoutinesCatalog.sectionTitle)
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text(ToolsRoutinesCatalog.sectionCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - States

    @ViewBuilder
    private var content: some View {
        switch service.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityIdentifier("toolsRoutinesLoadingIndicator")
        case .failed(let message):
            // Never the empty state on a failure: "no routines yet" over a failed fetch is a
            // confident lie about the one thing this section exists to report.
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color("StateRisk"))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("toolsRoutinesError")
        case .loaded:
            loaded
        }
    }

    @ViewBuilder
    private var loaded: some View {
        switch ToolsRoutinesCatalog.content(from: service.places, runs: history.runs) {
        case .rows(let rows):
            VStack(spacing: 8) {
                ForEach(rows) { row($0) }
                permissionFooter
            }
        case .empty(let reason):
            emptyCard(reason)
        }
    }

    // MARK: - The permission footer (E's 2026-09-07 ruling)

    /// Only under LISTED routines: the empty card already teaches its own rule, and a warning
    /// about routines that don't exist is noise. Two independent cards, deliberately not one
    /// container — both gates can be down at once, and `LocationPermissionBanner` carries its
    /// own combined accessibility element that a shared wrapper's identifier would rename.
    @ViewBuilder
    private var permissionFooter: some View {
        if ToolsRoutinesCatalog.showsNudgesOffFooter(arrivalNudgesEnabled: arrivalNudgesEnabled) {
            nudgesOffCard
        }
        LocationPermissionBanner(wantsTriggering: true)
            .bentoCard()
    }

    private var nudgesOffCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(ToolsRoutinesCatalog.NudgesOffFooter.headline)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("LabelPrimary"))
                    // On the headline, NOT the card — the emptyCard's inheritance lesson: an
                    // identifier on the container renames the button out from under itself.
                    .accessibilityIdentifier("toolsRoutinesNudgesOffBanner")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color("StateWarn"))
            }
            Text(ToolsRoutinesCatalog.NudgesOffFooter.body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(ToolsRoutinesCatalog.NudgesOffFooter.actionTitle) {
                Haptics.play(.light)
                var preferences = preferencesStore.read()
                preferences.arrivalNudgesEnabled = true
                preferencesStore.write(preferences)
                arrivalNudgesEnabled = true
                // The fences must follow the switch NOW — the Settings toggle's own rule:
                // without this the switch reads on, but nothing is registered until the next
                // app lifecycle event, and this banner's promise is a lie for that window.
                Task { await LocationTriggerService.shared.refreshRegistrations() }
            }
            .buttonStyle(MomentumBorderedButtonStyle(minHeight: 44))
            .accessibilityIdentifier("toolsRoutinesNudgesOnButton")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }

    // MARK: - Rows

    /// One routine. Tapping opens the place's editor, whose Actions section — with its
    /// drag-to-reorder — is the routine editor under E's settled Option A.
    private func row(_ item: ToolsRoutinesCatalog.Row) -> some View {
        Button {
            Haptics.play(.light)
            editingPlace = service.places.first { $0.id == item.placeId }
        } label: {
            HStack(spacing: 8) {
                Text(item.glyph)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("LabelPrimary"))
                    Text(item.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        // Safe on the container here — and only here — because the whole card is ONE button
        // with no separately-addressable control inside it to be renamed by inheritance.
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }

    // MARK: - Nothing to show

    /// Shown rather than hidden, deliberately: a section that disappears when empty can never
    /// teach the rule that fills it, and a brand-new account is in exactly this state.
    private func emptyCard(_ reason: ToolsRoutinesCatalog.EmptyReason) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reason.headline)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("LabelPrimary"))
                // On the headline, NOT the card: an identifier on this container would be
                // inherited by the link below and rename it out from under itself.
                .accessibilityIdentifier(reason.accessibilityIdentifier)
            Text(reason.body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                // `ToolsView` pushes Places inside the Tools stack, under the capture disc, with
                // the same call-site clearance it applies to its own Places card.
                onOpenPlaces()
            } label: {
                HStack(spacing: 4) {
                    Text(reason.actionTitle)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("toolsRoutinesEmptyAction")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }

    private func save(_ place: Place) async -> Bool {
        await service.save(place)
    }
}

@available(iOS 17.0, *)
#Preview("Routines section — Light") {
    NavigationStack {
        ScrollView {
            ToolsRoutinesSection(client: PreviewToolsRoutinesClient.populated, history: .inert())
                .padding(16)
        }
        .background(Color.pageBackground)
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Routines section — Nudges off") {
    NavigationStack {
        ScrollView {
            ToolsRoutinesSection(
                client: PreviewToolsRoutinesClient.populated,
                history: .inert(),
                preferencesStore: PreviewNudgesOffStore()
            )
            .padding(16)
        }
        .background(Color.pageBackground)
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Routines section — Dark") {
    NavigationStack {
        ScrollView {
            ToolsRoutinesSection(client: PreviewToolsRoutinesClient.empty, history: .inert())
                .padding(16)
        }
        .background(Color.pageBackground)
    }
    .preferredColorScheme(.dark)
}

/// Preview-only. Renders both halves of the section — a real routine, and the first-run empty
/// state — because the empty one is the state no journey and no screenshot normally reaches.
private struct PreviewToolsRoutinesClient: PlacesClientAdapting {
    let places: [Place]

    static var populated: PreviewToolsRoutinesClient {
        let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)
        return PreviewToolsRoutinesClient(places: [
            Place(
                id: UUID(), name: "Home", coordinate: coordinate, radiusMetres: 200,
                emoji: "🏠",
                actions: [
                    PlaceAction(
                        id: UUID(), direction: .arrival,
                        kind: .journalLine(body: "Home")
                    ),
                    PlaceAction(
                        id: UUID(), direction: .arrival,
                        kind: .openApp(scheme: "spotify", displayName: "Spotify")
                    ),
                    PlaceAction(
                        id: UUID(), direction: .arrival,
                        kind: .openApp(scheme: "maps", displayName: "Apple Maps")
                    )
                ]
            )
        ])
    }

    static var empty: PreviewToolsRoutinesClient { PreviewToolsRoutinesClient(places: []) }

    func fetchPlaces() async throws -> [Place] { places }
    func savePlace(_ place: Place) async throws {}
    func deletePlace(id: UUID) async throws {}
}

/// Preview-only: the master switch off, so the permission footer's card renders in the canvas.
private struct PreviewNudgesOffStore: MomentumPreferencesStoring {
    func read() -> MomentumPreferences {
        var preferences = MomentumPreferences.default
        preferences.arrivalNudgesEnabled = false
        return preferences
    }
    func write(_ preferences: MomentumPreferences) {}
}
