//
//  ToolsNudgesSection.swift
//  ADHD LifeOS
//
//  The Nudges row on the Tools page (`F-E3-OneCardToday`).
//
//  **Why it is here.** `NudgesView` had exactly one production door — Today's nudges card — and
//  Structure C (*"Today shows ONE card, then a short 'then' list, and nothing else"*) removes it.
//  E's Step 0 answer, 2026-09-24: *"the Nudges manager door moves to Tools, beside Routines."*
//  Due nudges themselves stay on Today, at the top of the "then" list; this is the manager —
//  creating, editing, pausing, the history.
//
//  **A headed SECTION with ONE row**, the `ToolsRecentlyDeletedSection` shape, so `ToolsCatalog`
//  still pins exactly two CARDS.
//

import SwiftUI

struct ToolsNudgesSection: View {
    /// Tools' own service, shared with the screen this row pushes (`NudgesView`'s contract).
    @ObservedObject var service: NudgesService
    /// The push is `ToolsView`'s, through its one flag, so a tab re-tap can pop it.
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            row
        }
        // 8 on top of the page's own 16 makes 24 — §2's macro separation, the siblings' spacing.
        .padding(.top, 8)
        .task { await service.load() }
        // A nudge created, dismissed or paused anywhere changes this count.
        .onReceive(DataChangeSignal.changes) { _ in
            Task { await service.load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Nudges")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text("Recurring reminders you set for yourself.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// **Drawn in every state, including empty and failed** — this is the only way to the Nudges
    /// screen, so it can never be missing. The subtitle is the only thing that changes.
    private var row: some View {
        Button {
            Haptics.play(.light)
            onOpen()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(width: 44, height: 44)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nudges")
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
        // Safe on the container: the whole card is ONE button, with nothing inside it to rename.
        .accessibilityIdentifier("toolsNudgesRow")
    }

    /// **A failed count says nothing rather than "No nudges yet"** — the Recently Deleted row's
    /// rule: claiming an empty schedule because the fetch failed is a lie with less room to explain.
    private var subtitle: String {
        guard case .loaded(let nudges) = service.state else { return "Opens your nudge schedule" }
        let due = nudges.filter { NudgeDueness.isNudgeDue(nudge: $0, now: Date()) }
        return HomeNudgesSection.countLine(
            dueCount: due.count,
            scheduledCount: HomeNudgesSection.scheduledCount(all: nudges, due: due)
        )
    }
}

#if DEBUG
private enum ToolsNudgesSectionPreview {
    @MainActor static func service() -> NudgesService {
        NudgesService(client: PreviewNudgesClient(), notificationSchedulingClient: PreviewNudgeScheduling())
    }
}

private struct PreviewNudgesClient: NudgesClientAdapting {
    func fetchNudges() async throws -> [Nudge] {
        [Nudge(
            id: UUID(), label: "Stretch", schedule: "0 9 * * *", active: true,
            completionDates: nil, createdAt: Date(), updatedAt: Date()
        )]
    }
    func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge {
        throw NudgesServiceError.notFound
    }
    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
        throw NudgesServiceError.notFound
    }
    func markFired(id: UUID, existingCompletionDates: [Date]) async throws -> Nudge {
        throw NudgesServiceError.notFound
    }
    func unmarkFired(
        id: UUID, previousLastFiredAt: Date?, previousCompletionDates: [Date]
    ) async throws -> Nudge {
        throw NudgesServiceError.notFound
    }
}

private struct PreviewNudgeScheduling: NudgeNotificationSchedulingAdapting {
    func requestAuthorizationIfNeeded() async -> Bool { false }
    func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async {}
    func cancelNotifications(nudgeId: UUID) async {}
    func hasScheduledNotifications(nudgeId: UUID) async -> Bool { false }
}

#Preview("Tools · Nudges — Light") {
    ScrollView {
        ToolsNudgesSection(service: ToolsNudgesSectionPreview.service()) {}
            .padding(16)
    }
    .background(Color.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Tools · Nudges — Dark") {
    ScrollView {
        ToolsNudgesSection(service: ToolsNudgesSectionPreview.service()) {}
            .padding(16)
    }
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}
#endif
