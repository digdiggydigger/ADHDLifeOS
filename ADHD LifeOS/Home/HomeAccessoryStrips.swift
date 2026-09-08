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
    /// Silent when there is nothing due AND nothing scheduled — an empty schedule is not news,
    /// and Today does not need a card to say so — EXCEPT on a first run, when this card is the
    /// only route to the Nudges screen and hiding it made the feature unreachable. See
    /// `HomeNudgesSection.shouldRenderSection`.
    @ViewBuilder
    var nudgesSection: some View {
        // A failed load leaves `nudges` empty, which renders EXACTLY like a clean schedule with
        // nothing due. Today would then quietly stop mentioning nudges at all, and the user's
        // only clue would be a reminder that never arrived. Say so instead.
        if case .failed(let message) = nudgesService.state {
            nudgesFailureCard(message)
        } else {
            loadedNudgesSection
        }
    }

    private func nudgesFailureCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Couldn't load your nudges", systemImage: "exclamationmark.triangle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color("StateWarn"))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeNudgesFailureCard")
    }

    @ViewBuilder
    private var loadedNudgesSection: some View {
        let due = nudgesService.dueNudges()
        let scheduled = HomeNudgesSection.scheduledCount(all: nudgesService.nudges, due: due)
        let hasAny = !due.isEmpty || scheduled > 0
        if HomeNudgesSection.shouldRenderSection(hasAny: hasAny, hasEverHadAny: hasEverHadNudges) {
            VStack(alignment: .leading, spacing: 8) {
                // Due nudges come FIRST and carry the urgent surface — the door below is a card
                // now, so the loud thing has to be visibly louder rather than merely earlier.
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
                nudgesDoorCard(due: due, scheduled: scheduled, isFirstRun: !hasAny)
            }
            // `.contain`, not a bare identifier: applied alone, a container's identifier is
            // inherited by every descendant, so both buttons in here answered to
            // "homeNudgesSection" and `nudgeDismissButton-<id>` stopped existing entirely. The
            // section still rendered perfectly — only the UI journey could see this. Same fix as
            // `captureInboxSortAreaChips`.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("homeNudgesSection")
            // Latch the moment a nudge exists, so the first-run door is genuinely first-run.
            // `.task` covers arriving with content already loaded AND reads the stored answer for
            // whichever account is signed in; `.onChange` covers the list arriving afterwards and
            // the user creating their very first nudge. Writing this in the body instead would
            // mutate state during view evaluation.
            .task { refreshNudgeFirstRunMarker(hasAny: hasAny) }
            .onChange(of: hasAny) { any in
                refreshNudgeFirstRunMarker(hasAny: any)
            }
        }
    }

    /// Today's nudges DOOR, built to the Capture inbox card's anatomy — icon tile, title,
    /// subtitle, count chip — because E chose that shape for it (2026-08-28) and it is already the
    /// screen's vocabulary for "a place with things in it".
    ///
    /// What it replaced: a grey caps eyebrow over a grey chevron row, sitting between a bold ring
    /// and a loud blue CTA, which read as the end of the screen rather than a part of it. The
    /// upcoming rows are the point of the extra height — "4 scheduled" states a number, "Water the
    /// plants, Today 18:00" states something you can plan around.
    private func nudgesDoorCard(due: [Nudge], scheduled: Int, isFirstRun: Bool) -> some View {
        let upcoming = HomeNudgesSection.upcoming(
            all: nudgesService.nudges, due: due, now: Date()
        )
        return VStack(alignment: .leading, spacing: 8) {
            nudgesDoorHeader(dueCount: due.count, scheduled: scheduled, isFirstRun: isFirstRun)
            if isFirstRun {
                firstNudgeDirective
            } else {
                ForEach(upcoming) { nudge in
                    upcomingNudgeRow(nudge)
                }
                if let overflow = HomeNudgesSection.upcomingOverflowLine(scheduledCount: scheduled) {
                    Text(overflow)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }

    /// The door's header row, split out only because the card was over its 50-line budget with it
    /// inline. Mirrors `inboxPeekCard`'s header exactly: 44pt tinted tile, title, subtitle, chip.
    /// Reads, and where warranted latches, the signed-in account's first-run marker.
    ///
    /// Keyed by uid rather than by device — see `NudgeFirstRunMarker`. With no signed-in user
    /// there is nothing to key on, so the door stays in its ordinary state rather than guessing.
    func refreshNudgeFirstRunMarker(hasAny: Bool) {
        guard let uid = authService.signedInUser?.id.uuidString else { return }
        if hasAny { NudgeFirstRunMarker.markHasHadNudges(uid: uid) }
        hasEverHadNudges = NudgeFirstRunMarker.hasEverHadNudges(uid: uid)
    }

    /// The card's one bright control on a first run — muted context, lit action.
    ///
    /// A separate 44pt button rather than text inside the header, because "Add your first nudge"
    /// has to BE pressable to mean what it says. Both it and the header open the same screen.
    private var firstNudgeDirective: some View {
        Button {
            Haptics.play(.light)
            isPresentingNudges = true
        } label: {
            Label(HomeNudgesSection.firstRunDirective, systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("homeNudgesFirstRunDirective")
    }

    private func nudgesDoorHeader(dueCount: Int, scheduled: Int, isFirstRun: Bool) -> some View {
        let chip = HomeNudgesSection.chipText(dueCount: dueCount, scheduledCount: scheduled)
        return Button {
            Haptics.play(.light)
            isPresentingNudges = true
        } label: {
            HStack(spacing: 8) {
                Text("⏰")
                    .font(.title3)
                    // `.grayscale`, not `.opacity`: an emoji cannot be de-emphasised with
                    // `foregroundStyle`, and a translucent glyph over a card reads as broken
                    // rather than quiet. §4 bans opacity as a substitute for semantic colour;
                    // desaturating a picture is a different thing and is the honest tool here.
                    .grayscale(isFirstRun ? 1 : 0)
                    .frame(width: 44, height: 44)
                    .background(
                        isFirstRun
                            ? AnyShapeStyle(Color("CardSurfaceSecondary"))
                            : AnyShapeStyle(Color.accentColor.opacity(0.12)),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nudges")
                        .font(.headline)
                        .foregroundStyle(isFirstRun ? Color.secondary : Color.primary)
                    Text(HomeNudgesSection.doorSubtitle(dueCount: dueCount, scheduledCount: scheduled))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                MomentumChip(
                    text: chip,
                    background: dueCount == 0
                        ? Color("CardSurfaceSecondary")
                        : Color("StateWarn").opacity(0.16),
                    foreground: dueCount == 0 ? Color("LabelSecondary") : Color("StateWarn")
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nudges, \(chip)")
        .accessibilityHint("Opens your nudge schedule")
        .accessibilityIdentifier("homeManageNudgesRow")
    }

    /// One upcoming nudge: what it is, and when it next fires. A schedule the app cannot parse
    /// shows the label alone rather than an invented time (`nextFireLine` returns nil).
    private func upcomingNudgeRow(_ nudge: Nudge) -> some View {
        HStack(spacing: 8) {
            Text(nudge.label)
                .font(.callout.weight(.medium))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            if let fires = HomeNudgesSection.nextFireLine(for: nudge, now: Date()) {
                Text(fires)
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .layoutPriority(1)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("homeUpcomingNudgeRow")
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
                    .accessibilityIdentifier("homeTitle")
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
