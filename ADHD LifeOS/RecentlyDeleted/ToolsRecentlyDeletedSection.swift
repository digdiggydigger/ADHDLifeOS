//
//  ToolsRecentlyDeletedSection.swift
//  ADHD LifeOS
//
//  The Recently Deleted row on the Tools page (`F-C3-RecentlyDeleted`).
//
//  **A headed SECTION with ONE row, which is E's own word for it** — round 2: *"Where Recently
//  Deleted lives → 'One row in Tools'"*. `ToolsRoutinesSection` is the precedent for a section
//  rather than a third bento card, so `ToolsCatalog` still pins exactly two CARDS and a third
//  door stays a decision rather than a drift.
//
//  **Deliberately NOT gated `@available(iOS 17.0, *)`, unlike `ToolsRoutinesSection`.** That gate
//  exists because the Places editor a routine row opens is 17+; Recently Deleted has no such
//  dependency and must stay reachable on the 16.0 floor (§7.1). Copying the shape without the
//  gate is the point.
//

import SwiftUI

struct ToolsRecentlyDeletedSection: View {
    @StateObject private var service: RecentlyDeletedService
    /// The push is `ToolsView`'s, through its one flag, so a tab re-tap can pop it (E, 2026-09-08)
    /// — a closure link here could not be popped from outside.
    private let onOpen: () -> Void

    init(client: RecentlyDeletedClientAdapting = FirebaseRecentlyDeletedClientAdapter(), onOpen: @escaping () -> Void) {
        _service = StateObject(wrappedValue: RecentlyDeletedService(client: client))
        self.onOpen = onOpen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            row
        }
        // 8 on top of the page's own 16 makes 24 — §2's macro separation, matching
        // `ToolsRoutinesSection`, so this reads as its own group rather than a third door.
        .padding(.top, 8)
        .task { await service.load() }
        // Any delete or restore anywhere in the app changes this count.
        .onReceive(DataChangeSignal.changes) { _ in
            Task { await service.load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(RecentlyDeletedPresentation.sectionTitle)
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text(RecentlyDeletedPresentation.sectionCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// **Drawn in every state, including empty and failed**, so the door is never missing when
    /// someone goes looking for it — which is exactly the moment they have just deleted something
    /// by mistake. The subtitle is the only thing that changes.
    private var row: some View {
        Button {
            Haptics.play(.light)
            onOpen()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(width: 44, height: 44)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(RecentlyDeletedPresentation.sectionTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("LabelPrimary"))
                    Text(subtitle)
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
        // Safe on the container here — and only here — because the whole card is ONE button with
        // no separately-addressable control inside it to be renamed by inheritance.
        .accessibilityIdentifier("toolsRecentlyDeletedRow")
    }

    /// **A failed count says nothing rather than "Nothing waiting".** Claiming the list is empty
    /// because the fetch failed is the same lie the screen itself refuses to tell, one level up
    /// and with less room to explain — so the row falls back to its own caption's promise.
    private var subtitle: String {
        switch service.screen {
        case .loading, .failed:
            return RecentlyDeletedPresentation.toolsRowLoadingSubtitle
        case .empty, .rows:
            return RecentlyDeletedPresentation.toolsRowSubtitle(for: service.items)
        }
    }
}

#Preview("Tools · Recently Deleted — Light") {
    ScrollView {
        ToolsRecentlyDeletedSection(client: PreviewToolsRecentlyDeletedClient.populated) {}
            .padding(16)
    }
    .background(Color.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Tools · Recently Deleted — Empty, Dark") {
    ScrollView {
        ToolsRecentlyDeletedSection(client: PreviewToolsRecentlyDeletedClient.empty) {}
            .padding(16)
    }
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}

private struct PreviewToolsRecentlyDeletedClient: RecentlyDeletedClientAdapting {
    let items: [RecentlyDeletedItem]

    static var populated: PreviewToolsRecentlyDeletedClient {
        PreviewToolsRecentlyDeletedClient(items: [
            RecentlyDeletedItem(
                itemId: UUID(), kind: .task, title: "Ring the dentist",
                deletedAt: Date().addingTimeInterval(-29.5 * 24 * 60 * 60)
            ),
            RecentlyDeletedItem(
                itemId: UUID(), kind: .capture, title: "Bike lock",
                deletedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60)
            )
        ])
    }

    static var empty: PreviewToolsRecentlyDeletedClient { PreviewToolsRecentlyDeletedClient(items: []) }

    func fetchDeleted() async throws -> [RecentlyDeletedItem] { items }
    func restore(_ item: RecentlyDeletedItem) async throws {}
    func restore(_ item: RecentlyDeletedItem, keepingRestored: Bool) async throws {}
    func deleteForever(_ item: RecentlyDeletedItem) async throws {}
}
