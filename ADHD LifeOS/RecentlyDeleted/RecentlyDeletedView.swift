//
//  RecentlyDeletedView.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: the 30-day list, pushed from the one row on Tools.
//
//  **Every word and every row comes from `RecentlyDeletedPresentation`**, and the screen's four
//  states come from `RecentlyDeletedService.Screen` — one `switch`, so "nothing deleted" cannot be
//  drawn over a failed fetch. View bodies here are ~0% covered by design, so anything decided
//  inside one is decided where nothing checks it.
//
//  **No animation, deliberately, and that is a §7.2 decision rather than an omission.** Rows appear
//  and leave with the list's own default. Adding a removal spring would make this a REDUCED site,
//  which would owe a Reduce-Motion branch and (§7.3) an RM-on pass on E's phone — for a list whose
//  whole job is to be legible and unhurried. The buttons' press scale is `MomentumBorderedButtonStyle`'s,
//  already shipped and already §5-compliant.
//

import SwiftUI

struct RecentlyDeletedView: View {
    @StateObject private var service: RecentlyDeletedService
    /// Which row's "Delete forever" is being confirmed. An `item` sheet rather than a `Bool` plus
    /// a stashed id: the confirm names the KIND of thing it is about, so it must hold one.
    @State private var confirmingDeleteForever: RecentlyDeletedItem?

    init(client: RecentlyDeletedClientAdapting = FirebaseRecentlyDeletedClientAdapter()) {
        _service = StateObject(wrappedValue: RecentlyDeletedService(client: client))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                caption
                content
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle(RecentlyDeletedPresentation.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await service.load() }
        // A restore posts `DataChangeSignal` from the write plumbing, and so does a delete made
        // anywhere else in the app while this screen is open.
        .onReceive(DataChangeSignal.changes) { _ in
            Task { await service.load() }
        }
        .confirmationDialog(
            confirmingDeleteForever.map { RecentlyDeletedPresentation.DeleteForever.title(for: $0.kind) } ?? "",
            isPresented: Binding(
                get: { confirmingDeleteForever != nil },
                set: { if !$0 { confirmingDeleteForever = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(RecentlyDeletedPresentation.DeleteForever.confirmTitle, role: .destructive) {
                guard let item = confirmingDeleteForever else { return }
                Haptics.play(.solid)
                Task { await service.deleteForever(item) }
            }
            .accessibilityIdentifier("recentlyDeletedConfirmDeleteForever")
            Button(RecentlyDeletedPresentation.DeleteForever.cancelTitle, role: .cancel) {}
        } message: {
            // The one place in this app where this sentence is TRUE (§2.7). It used to sit under
            // task detail's Delete button, where soft delete made it a lie.
            Text(RecentlyDeletedPresentation.DeleteForever.message)
        }
        // **An `.alert`, not a `confirmationDialog`, and the difference is the message.** The one
        // above asks to confirm an action the user already chose; this one reports a SITUATION
        // they could not have known about — the name was taken while the tag waited — and then
        // offers a choice. `alerts.md`: *"an alert can tell people about a problem"*, and only an
        // alert carries the informative text that has to explain it.
        .alert(
            survivorCopy?.title ?? "",
            isPresented: Binding(
                get: { service.pendingSurvivorChoice != nil },
                set: { if !$0 { service.cancelSurvivorChoice() } }
            ),
            presenting: service.pendingSurvivorChoice
        ) { item in
            let copy = Self.survivorCopy(for: item)
            Button(copy.keepRestoredTitle) {
                Haptics.play(.solid)
                Task { await service.resolveSurvivor(item, keepingRestored: true) }
            }
            .accessibilityIdentifier("recentlyDeletedKeepRestored")
            if let keepLiveTitle = copy.keepLiveTitle {
                Button(keepLiveTitle) {
                    Haptics.play(.solid)
                    Task { await service.resolveSurvivor(item, keepingRestored: false) }
                }
                .accessibilityIdentifier("recentlyDeletedKeepLive")
            }
            // **No `role: .destructive` on either survivor button.** `alerts.md › Buttons`: the
            // style is for "a destructive action people didn't deliberately choose", and both of
            // these carry out the restore the user just asked for.
            Button(copy.cancelTitle, role: .cancel) { service.cancelSurvivorChoice() }
        } message: { item in
            Text(Self.survivorCopy(for: item).message)
        }
        .accessibilityIdentifier("recentlyDeletedView")
    }

    /// The alert's words for whatever row is asking, or `nil` when none is.
    private var survivorCopy: RecentlyDeletedPresentation.SurvivorChoice? {
        service.pendingSurvivorChoice.map(Self.survivorCopy(for:))
    }

    /// **A tag row always has a collision when this is reached** — `restore` only opens the alert
    /// for one. The fallback spells the row's own name rather than an empty string, so a bug that
    /// somehow got here shows a merge of a tag with itself instead of unattributed quotes.
    private static func survivorCopy(
        for item: RecentlyDeletedItem
    ) -> RecentlyDeletedPresentation.SurvivorChoice {
        RecentlyDeletedPresentation.SurvivorChoice.alert(
            restoredName: item.title, liveName: item.collision?.liveName ?? item.title
        )
    }

    private var caption: some View {
        Text(RecentlyDeletedPresentation.sectionCaption)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The four states, in one switch

    @ViewBuilder
    private var content: some View {
        switch service.screen {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityIdentifier("recentlyDeletedLoadingIndicator")
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(Color("StateRisk"))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("recentlyDeletedError")
                .bentoCard()
        case .empty:
            emptyCard
        case .rows(let rows):
            VStack(spacing: 8) {
                ForEach(rows) { row($0) }
            }
            if let errorMessage = service.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(Color("StateRisk"))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("recentlyDeletedMutationError")
            }
        }
    }

    /// Shown rather than hidden — the `ToolsRoutinesSection` rule. A screen that says nothing when
    /// empty can never teach the rule that fills it, and this one's rule is the reassurance.
    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(RecentlyDeletedPresentation.emptyHeadline)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("LabelPrimary"))
                // On the headline, NOT the card: an identifier on the container is inherited by
                // its children and renames them out from under themselves.
                .accessibilityIdentifier("recentlyDeletedEmpty")
            Text(RecentlyDeletedPresentation.emptyBody)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }

    // MARK: - One row

    /// **Restore is a VISIBLE 48pt button, never a swipe** — round 7's rule that anything which
    /// undoes is a key target, and the exact GEST-2 finding this arc is fixing elsewhere. 48 is on
    /// the grid and already has precedent (`PrimaryActionButtonStyle`, `MomentumBorderedButtonStyle`),
    /// so no §2 waiver is needed.
    ///
    /// Delete forever sits beside it, quieter and at the 44pt floor: it is the rarer intent, and
    /// Q10's friction is the confirm rather than a hidden control.
    private func row(_ row: RecentlyDeletedPresentation.Row) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: row.glyph)
                    .font(.title3)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(width: 44, height: 44)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("LabelPrimary"))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        // On the headline, not the card — see `emptyCard`.
                        .accessibilityIdentifier(row.accessibilityIdentifier)
                    Text(row.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                Button(RecentlyDeletedPresentation.restoreTitle) {
                    Haptics.play(.light)
                    Task { await service.restore(row.item) }
                }
                .buttonStyle(MomentumBorderedButtonStyle(minHeight: 48))
                .disabled(service.busyItemID != nil)
                .accessibilityIdentifier("recentlyDeletedRestore-\(row.item.id)")

                // **NOT tinted `StateRisk`, and the reason is measured rather than felt.** Red
                // on `CardSurface` is **4.21:1 in LIGHT** (`#F5102B` on `#FFFFFF`), under the
                // 4.5:1 that `accessibility.md` requires below 18pt — and the palette is E's HELD
                // colour arc, so the fix cannot be the colour. It does not need to be: this
                // button is the DOOR to the destructive moment, not the moment itself.
                // `action-sheets.md › Best practices` puts the prominence on the sheet ("Make
                // destructive choices visually prominent… place these buttons at the top of the
                // action sheet"), which the confirm below does. Quiet here also stops it
                // competing with Restore, which is the action this screen wants people to take.
                Button(RecentlyDeletedPresentation.deleteForeverTitle) {
                    confirmingDeleteForever = row.item
                }
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .disabled(service.busyItemID != nil)
                .accessibilityIdentifier("recentlyDeletedDeleteForever-\(row.item.id)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }
}

#Preview("Recently Deleted — Light") {
    NavigationStack {
        RecentlyDeletedView(client: PreviewRecentlyDeletedClient.populated)
    }
    .preferredColorScheme(.light)
}

#Preview("Recently Deleted — Empty") {
    NavigationStack {
        RecentlyDeletedView(client: PreviewRecentlyDeletedClient.empty)
    }
    .preferredColorScheme(.light)
}

#Preview("Recently Deleted — Dark") {
    NavigationStack {
        RecentlyDeletedView(client: PreviewRecentlyDeletedClient.populated)
    }
    .preferredColorScheme(.dark)
}

/// Preview-only. Renders a task and a capture at opposite ends of the window, plus the empty
/// state — which is the state no journey and no screenshot normally reaches.
private struct PreviewRecentlyDeletedClient: RecentlyDeletedClientAdapting {
    let items: [RecentlyDeletedItem]

    static var populated: PreviewRecentlyDeletedClient {
        PreviewRecentlyDeletedClient(items: [
            RecentlyDeletedItem(
                itemId: UUID(), kind: .task, title: "Ring the dentist about the referral",
                deletedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60)
            ),
            RecentlyDeletedItem(
                itemId: UUID(), kind: .capture, title: "That thing about the bike lock",
                deletedAt: Date().addingTimeInterval(-29.5 * 24 * 60 * 60)
            )
        ])
    }

    static var empty: PreviewRecentlyDeletedClient { PreviewRecentlyDeletedClient(items: []) }

    func fetchDeleted() async throws -> [RecentlyDeletedItem] { items }
    func restore(_ item: RecentlyDeletedItem) async throws {}
    func restore(_ item: RecentlyDeletedItem, keepingRestored: Bool) async throws {}
    func deleteForever(_ item: RecentlyDeletedItem) async throws {}
}
