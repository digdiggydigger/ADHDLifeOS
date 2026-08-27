//
//  HomeAccessoryStrips.swift
//  ADHD LifeOS
//
//  Home's reorder list and the v3 Today header, both here for `HomeView.swift`'s length
//  budget. The due-nudges dismiss strip that used to live here was replaced by the v3
//  "Nudges waiting" row (F-V3-Today) — dismissal now happens on the Nudges tab.
//

import SwiftUI

extension HomeView {
    var reorderList: some View {
        List {
            ForEach(arrangeAreas) { area in
                HStack(spacing: 8) {
                    Text(area.colour)
                    Text(area.name)
                        .font(.body)
                }
                .accessibilityIdentifier("homeReorderRow-\(area.id.uuidString)")
            }
            .onMove(perform: moveArrangeAreas)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    /// Today's inbox module, per the Claude Design Today frame — the 📥 avatar row,
    /// "Unprocessed inbox items"-style header with the count, and the "Clear the deck" CTA —
    /// widened after E's follow-up: the first cut was too small to interact with and said too
    /// little. Each peek row is now its own 44pt door straight into that capture, the CTA opens
    /// triage, and the handled line names the day's throughput.
    var inboxPeekCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Haptics.play(.light)
                onOpenCaptures?()
            } label: {
                HStack(spacing: 8) {
                    Text("📥")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(
                            Color.accentColor.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Capture inbox")
                            .font(.headline)
                        Text(
                            inboxCount > 0
                                ? "Waiting for a decision — one at a time."
                                : "Anything you capture lands here first."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    MomentumChip(
                        text: HomeInboxPeek.countLine(inboxCount),
                        background: inboxCount > 0
                            ? Color("StateWarn").opacity(0.16)
                            : Color("CardSurfaceSecondary"),
                        foreground: inboxCount > 0 ? Color("StateWarn") : Color("LabelSecondary")
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Capture inbox, \(HomeInboxPeek.countLine(inboxCount))")
            .accessibilityHint("Opens the inbox for triage")

            ForEach(inboxPeek) { capture in
                inboxPeekRow(capture)
            }
            if let overflow = HomeInboxPeek.overflowLine(total: inboxCount) {
                Text(overflow)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let handled = HomeInboxPeek.handledLine(inboxHandledToday) {
                Label(handled, systemImage: "checkmark.circle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("StateGoVivid"))
                    .accessibilityIdentifier("homeInboxHandledLine")
            }
            if inboxCount > 0 {
                Button("Clear the deck") {
                    Haptics.play(.light)
                    onOpenCaptures?()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("homeInboxClearDeckButton")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .accessibilityIdentifier("homeInboxPeekCard")
    }

    /// One waiting capture as a full 44pt door into its detail — the inbox row's visual language
    /// at card scale: the kind's glyph in its tinted tile, the title with room to breathe, and
    /// the caption that says when and how it arrived.
    private func inboxPeekRow(_ capture: Capture) -> some View {
        Button {
            inspectingHomeCapture = capture
        } label: {
            HStack(spacing: 8) {
                Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: capture.kind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CaptureKindAccent.color(for: capture.kind))
                    .frame(width: 36, height: 36)
                    .background(
                        CaptureKindAccent.color(for: capture.kind).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(CaptureRowPresentation.primaryText(for: capture))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(CaptureRowPresentation.caption(for: capture))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this capture")
        .accessibilityIdentifier("homeInboxPeekRow-\(capture.id)")
    }

    /// Each completed drag persists immediately (E's per-move decision): reorder `arrangeAreas`
    /// optimistically, then fire ONE serialised bulk reorder carrying the full ordering. TRAP 6's
    /// serialisation + coalescing lives in `HomeService.submitReorder`.
    func moveArrangeAreas(from source: IndexSet, to destination: Int) {
        arrangeAreas.move(fromOffsets: source, toOffset: destination)
        Task { await homeService.submitReorder(activeInNewOrder: arrangeAreas) }
    }

    /// Today's nudges module. Nudges lost their tab on 2026-08-28 (Captures took the slot back),
    /// so this is where a due nudge is met AND dismissed — restoring the inline dismissal that
    /// F-V3-Today had traded for a row that only crossed to the tab. Everything the module cannot
    /// hold — creating, editing, rescheduling, the history — is one push away.
    ///
    /// Silent when there is nothing due AND nothing scheduled: an empty schedule is not news, and
    /// Today does not need a card to say so.
    @ViewBuilder
    var nudgesSection: some View {
        let due = nudgesService.dueNudges()
        let scheduled = HomeNudgesSection.scheduledCount(all: nudgesService.nudges, due: due)
        if !due.isEmpty || scheduled > 0 {
            VStack(alignment: .leading, spacing: 8) {
                Text(HomeNudgesSection.countLine(dueCount: due.count, scheduledCount: scheduled))
                    .sectionLabel()
                    .foregroundStyle(due.isEmpty ? Color("LabelSecondary") : Color("StateWarn"))
                ForEach(HomeNudgesSection.cards(due)) { nudge in
                    NudgeDueCard(
                        nudge: nudge,
                        showStreaks: momentumPreferences.showStreaks,
                        onDismiss: { await nudgesService.dismiss(nudge) }
                    )
                }
                if let overflow = HomeNudgesSection.overflowLine(dueCount: due.count) {
                    Text(overflow)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                manageNudgesRow
            }
            // `.contain`, not a bare identifier: applied alone, a container's identifier is
            // inherited by every descendant, so both buttons in here answered to
            // "homeNudgesSection" and `nudgeDismissButton-<id>` stopped existing entirely. The
            // section still rendered perfectly — only the UI journey could see this. Same fix as
            // `captureInboxSortAreaChips`.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("homeNudgesSection")
        }
    }

    private var manageNudgesRow: some View {
        Button {
            Haptics.play(.light)
            isPresentingNudges = true
        } label: {
            HStack(spacing: 8) {
                Text("Manage nudges")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color("LabelSecondary"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityIdentifier("homeManageNudgesRow")
    }

    /// v3's Today header: the date eyebrow over the big title, with settings as a 40pt well.
    ///
    /// The badged inbox tray well that sat beside it is gone: Captures is a tab now, the tab
    /// carries the badge, and a header icon that merely selected another tab was the third of
    /// five doors into one queue (round 2's audit).
    var todayHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                Text("Today")
                    .font(.largeTitle.bold())
                    .tracking(-0.5)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                headerIconWell(systemImage: "gearshape")
            }
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("settingsButton")
        }
    }

    func headerIconWell(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(Color("LabelSecondary"))
            .frame(width: 40, height: 40)
            .background(Color.cardSurface, in: Circle())
            .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
            .contentShape(Circle())
    }
}
