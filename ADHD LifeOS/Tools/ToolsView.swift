//
//  ToolsView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The sixth tab (E's 2026-09-02 call), and the reason the app now draws its own tab bar.
///
/// **Bento cards, not Settings rows** — E's explicit choice when the page was designed. The tab
/// is a destination in its own right, and a grouped `Form` would have read as a second Settings
/// screen rather than the workshop drawer it is meant to be. So it wears Today's and Areas'
/// language: an eyebrow, a large title, and `.bentoCard()` doors.
///
/// **Two cards and one section.** The page was left sparse so Routines — the declared next arc —
/// had an obvious place to land, and as of F-Routines-B it has landed: E's call was "its own
/// Routines section on the Tool list", so it is a headed section below the doors rather than a
/// third card. `ToolsCatalog` still pins the CARD count, so a third door has to be a decision.
///
/// **The Settings split this completes is ASYMMETRIC, deliberately.** Places left Settings
/// entirely and is reachable only from here. Life Areas gained a door here and **kept** its
/// Settings row, because it is genuinely both a setting and a tool. That is knowingly the
/// opposite of the de-duplication the Captures rethink spent two blocks on, and it is not to be
/// tidied — `ToolsPageCallSiteTests` holds both halves.
///
/// **The clients arrive through the default-param door**, the way `SettingsView` takes the same
/// two. `RootView` holds neither of them — they were constructed inside `SettingsView` — so
/// threading them through `RootView` and `ADHD_LifeOSApp` would add two properties to two files
/// to duplicate what the house pattern already does, and would break the `ToolsView()` call site
/// `AppTabBarCallSiteTests` pins. Tests and previews inject through the same door.
struct ToolsView: View {
    private let placesClient: PlacesClientAdapting
    private let lifeAreaEditorClient: LifeAreaEditorClientAdapting
    private let recentlyDeletedClient: RecentlyDeletedClientAdapting
    /// `F-E3-OneCardToday`: the Nudges screen's door moved here from Today (E, 2026-09-24), so
    /// Tools owns a service for it — shared by the row's count and the pushed screen, as
    /// `NudgesView` expects of its host.
    @StateObject private var nudgesService: NudgesService
    /// Wired into `nudgesService` in `.task`: an `@Environment` value cannot be read in `init`,
    /// where the service is built. Home does the same for `recordAction`.
    @Environment(\.celebrate) private var celebrate
    @Environment(\.recordAction) private var recordAction

    init(
        placesClient: PlacesClientAdapting? = nil,
        lifeAreaEditorClient: LifeAreaEditorClientAdapting? = nil,
        recentlyDeletedClient: RecentlyDeletedClientAdapting? = nil,
        nudgesClient: NudgesClientAdapting? = nil,
        nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting? = nil
    ) {
        self.placesClient = placesClient ?? FirebasePlacesClientAdapter()
        self.lifeAreaEditorClient = lifeAreaEditorClient ?? FirebaseLifeAreaEditorClientAdapter()
        self.recentlyDeletedClient = recentlyDeletedClient ?? FirebaseRecentlyDeletedClientAdapter()
        _nudgesService = StateObject(wrappedValue: NudgesService(
            client: nudgesClient ?? FirebaseNudgesClientAdapter(),
            notificationSchedulingClient: nudgeNotificationSchedulingClient ?? NotificationCenterNudgeAdapter()
        ))
    }

    /// Everything this page can push: the catalog's two CARDS plus the Recently Deleted and
    /// Nudges SECTIONS' one row each.
    ///
    /// **A local superset rather than a third `ToolsCatalog.Destination`**, because
    /// `ToolsCatalogTests.testEveryDestinationHasAnEntry` holds the catalog's case list and its
    /// entry list equal — a destination there without an entry is a card, and E chose a row. The
    /// case NAMES match the catalog's so `pushedDestination = .places` still reads the same at
    /// every site, and `init(_:)` below switches exhaustively, so a new catalog destination fails
    /// the build here rather than silently having nowhere to go.
    enum Push: Hashable {
        case places
        case lifeAreas
        case recentlyDeleted
        case nudges

        init(_ destination: ToolsCatalog.Destination) {
            switch destination {
            case .places: self = .places
            case .lifeAreas: self = .lifeAreas
            }
        }
    }

    /// Which destination is pushed, if any. A flag push rather than the closure-based
    /// `NavigationLink` this screen used until 2026-09-08: a simulator probe showed a closure
    /// push is invisible to the stack's path and survives a reset, so a tab re-tap could never
    /// pop it. Clearing this pops it, and the closure links deeper in the stack (the Life Areas
    /// editor's rows) collapse with it — the same probe. The closure links there stay: the probe
    /// also showed a flag push and closure links coexist in one stack, which value links do not.
    @State private var pushedDestination: Push?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Text("The screens you set up once and come back to rarely.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(ToolsCatalog.entries) { entry in
                        card(entry)
                    }
                    // Routines is a SECTION, not a card (E's 2026-09-05 call) — so it is here
                    // rather than in `ToolsCatalog`, and the catalog still pins two cards. It sat
                    // behind `if #available(iOS 17.0, *)` until `F-Floor18`, with the rest of Places.
                    ToolsRoutinesSection(client: placesClient) { pushedDestination = .places }
                    // Beside Routines, E's Step 0 answer (2026-09-24): Today's one card left the
                    // Nudges screen no door, and this is its only one now.
                    ToolsNudgesSection(service: nudgesService) { pushedDestination = .nudges }
                    // A SECTION with one row, E's own word (round 2: "One row in Tools"), so the
                    // catalog still pins two cards.
                    ToolsRecentlyDeletedSection(client: recentlyDeletedClient) {
                        pushedDestination = .recentlyDeleted
                    }
                }
                .padding(16)
                .tabRootScrollAnchor()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground.ignoresSafeArea())
            // This page scrolls INSIDE the tab bar, so its last card would otherwise sit under
            // the capture disc. The bar's own inset is separate and already applied by RootView.
            .captureDiscClearance()
            // The house pattern for a tab root that draws its own title (Today, Areas — and the
            // Journal until 2026-09-18, when E kept its system nav bar and large title instead,
            // `F-JournalPencilDisc`).
            // Pushed screens are unaffected — they bring their own bar.
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: Binding(
                get: { pushedDestination != nil },
                set: { if !$0 { pushedDestination = nil } }
            )) {
                if let pushedDestination {
                    destination(for: pushedDestination)
                }
            }
            .tabRoot(.tools, isAtRoot: pushedDestination == nil, onPopToRoot: { pushedDestination = nil })
            .task {
                // Before anything can be dismissed: the seven-day streak and the undo capsule.
                nudgesService.celebrate = celebrate
                nudgesService.recordAction = recordAction
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Workshop")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text("Tools")
                .font(.largeTitle.bold())
                .tracking(-0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Cards

    /// A button that sets the flag the stack's one `navigationDestination(isPresented:)` reads.
    /// Not a value link: mixing closure and value links in one `NavigationStack` silently breaks
    /// the push (trap b, confirmed on device in the Tag Editor block and restated in
    /// `LifeAreaEditorListView`), and the editor pushed from here still uses closure links.
    private func card(_ entry: ToolsCatalog.Entry) -> some View {
        Button {
            pushedDestination = Push(entry.destination)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: entry.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(width: 44, height: 44)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("LabelPrimary"))
                    Text(entry.caption)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
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
        .accessibilityIdentifier(entry.accessibilityIdentifier)
    }

    /// Both destinations are PUSHED, so both stay under the capture disc and both ask for the
    /// room — the same call-site clearance `AreasView` applies to its own copy of the Life Areas
    /// editor. (Settings' copy needs none: a sheet covers the disc entirely.)
    @ViewBuilder
    private func destination(for destination: Push) -> some View {
        switch destination {
        case .places:
            PlacesListView(client: placesClient)
                .captureDiscClearance()
        case .lifeAreas:
            LifeAreaEditorListView(client: lifeAreaEditorClient)
                .captureDiscClearance()
        case .recentlyDeleted:
            RecentlyDeletedView(client: recentlyDeletedClient)
                .captureDiscClearance()
        case .nudges:
            NudgesView(service: nudgesService)
                .captureDiscClearance()
        }
    }
}

#Preview("Tools — Light") {
    ToolsView()
        .preferredColorScheme(.light)
}

#Preview("Tools — Dark") {
    ToolsView()
        .preferredColorScheme(.dark)
}
