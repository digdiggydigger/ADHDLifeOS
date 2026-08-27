//
//  CaptureInboxSections.swift
//  ADHD LifeOS
//
//  The v3 inbox's decision card, count header and health chart (F-V3-Inbox), split from
//  `CaptureInboxView.swift` for its length budgets.
//

import SwiftUI

extension CaptureInboxView {
    func topCaptureCard(_ capture: Capture) -> some View {
        let slot = CaptureFan.slot(for: capture.kind)
        let tags = CaptureRowPresentation.tags(for: capture, from: allTags)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                MomentumChip(
                    text: "\(CaptureComposerCopy.title(for: capture.kind))",
                    background: Color(slot.fillAssetName).opacity(0.16),
                    foreground: Color(slot.fillAssetName)
                )
                if let ageLine = CaptureInboxSummary.oldestLine(for: [capture]) {
                    MomentumChip(
                        text: ageLine.replacingOccurrences(of: "oldest is ", with: ""),
                        background: Color("CardSurfaceSecondary"),
                        foreground: Color("LabelSecondary")
                    )
                }
            }
            Text(capture.title ?? capture.content)
                .font(.title3.bold())
                .tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)
            // The triage card is a SEPARATE view from `CaptureRowView`, so the place has to be
            // said here too — E caught it showing on the THEN rows and not on the top card
            // (2026-08-27). Same rule: named places only, nothing when there wasn't one.
            if let place = CapturePlaceLabel.label(for: capture, places: service.places) {
                Text(place)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Captured at \(place)")
                    .accessibilityIdentifier("captureInboxTopCardPlace")
            }
            if !tags.isEmpty {
                TagChipsRow(tags: tags)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .onTapGesture { inspectingCapture = capture }
        .accessibilityIdentifier("captureInboxTopCard")
    }

    /// The decision, in three separated blocks (E's 2026-08-28 note: "clearly yet subtly
    /// highlighted… to allow clear distinction"). Each is its own `bentoCard()` — what this IS,
    /// where it LIVES, and what to DO about it — so the eye never has to parse one wall of card.
    func topCaptureDecision(_ capture: Capture) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            topCaptureCard(capture)
            sortAreaSection(capture)
            topCardActions(capture)
                .bentoCard()
        }
    }

    /// Where does this live? The chips are always visible, and picking one is what unlocks Sorted
    /// — E chose the deliberate two-step over one-tap-per-area, so the button being unavailable is
    /// what says the choice is still outstanding.
    private func sortAreaSection(_ capture: Capture) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where does this live?")
                .sectionLabel()
                .foregroundStyle(Color.accentColor)
            ComposerAreaChips(
                lifeAreas: lifeAreas.filter { !$0.archived },
                // No escape chip here: an area is the requirement, and with nothing chosen the
                // escape rendered in the accent — "no decision" looking like a made one.
                noSelectionLabel: nil,
                selection: Binding(
                    get: { selectedArea(for: capture) },
                    set: { newValue in
                        sortSelection = newValue.map {
                            SortSelection(captureId: capture.id, lifeAreaId: $0)
                        }
                    }
                )
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("captureInboxSortAreaChips")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }

    /// The chips read the pick made for THIS capture, falling back to whatever it was already
    /// filed under — never a selection made for the capture before it in the queue.
    func selectedArea(for capture: Capture) -> UUID? {
        if let sortSelection, sortSelection.captureId == capture.id {
            return sortSelection.lifeAreaId
        }
        return CaptureTriage.initialSelection(for: capture)
    }

    /// v3's inbox health (chartsOn): captured-per-day bars with the honest cleared line and the
    /// backlog said out loud in warn.
    @ViewBuilder
    var healthSection: some View {
        if momentumPreferences.showCharts,
           let health = service.weekHealth,
           service.filter == .unprocessed {
            VStack(alignment: .leading, spacing: 8) {
                Text("Inbox health")
                    .sectionLabel()
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 8) {
                    WeekBarStrip(
                        fractions: MomentumWeekCharts.barFractions(health.capturedPerDay)
                    )
                    Text("Captured this week: \(health.captured). Cleared: \(health.cleared).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let sitting = CaptureInboxSummary.sittingLine(count: service.displayedCaptures.count) {
                        Text(sitting)
                            .font(.footnote)
                            .foregroundStyle(Color("StateWarn"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .bentoCard()
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("captureInboxHealth")
        }
    }

    private func topCardActions(_ capture: Capture) -> some View {
        let area = selectedArea(for: capture)
        return VStack(spacing: 8) {
            Button {
                Haptics.play(.success)
                promotingCapture = capture
            } label: {
                Label("Task it", systemImage: "text.badge.checkmark")
            }
            .buttonStyle(MomentumSolidButtonStyle(fill: .accentColor, foreground: AreaPalette.work.onColor))
            .accessibilityIdentifier("captureInboxTaskItButton")
            HStack(spacing: 8) {
                Button("Journal it") {
                    Haptics.play(.success)
                    Task { await service.logToJournal(capture: capture) }
                }
                .buttonStyle(MomentumBorderedButtonStyle())
                .accessibilityIdentifier("captureInboxJournalItButton")
                // Skip took the Bin's slot (BUG-b8 → SUGG-b9, E's calls): triage is for
                // deciding, and "not now" is a decision — the card goes to the back of the
                // queue, nothing is written. Binning lives on the full-screen capture view,
                // behind its own confirmation. Kept unchanged as a peer of the real verbs
                // (E, 2026-08-28) — an undecidable capture still needs somewhere to go.
                Button("Skip") {
                    Haptics.play(.light)
                    service.skip(capture)
                }
                .buttonStyle(MomentumBorderedButtonStyle())
                .accessibilityIdentifier("captureInboxSkipButton")
            }
            sortedButton(capture, area: area)
        }
    }

    /// Lit only once an area is chosen — E's 2026-08-28 note. The emphasis comes from
    /// `CaptureTriage.emphasis`, which is derived from `canSort`, so a glowing button can never be
    /// one the tap would refuse. `SortedButtonStyle` carries both faces.
    @ViewBuilder
    private func sortedButton(_ capture: Capture, area: UUID?) -> some View {
        let emphasis = CaptureTriage.emphasis(
            selected: sortSelection?.captureId == capture.id ? sortSelection?.lifeAreaId : nil,
            existing: capture.lifeAreaId
        )
        let isReady = emphasis == .ready
        Button {
            guard let area else { return }
            Haptics.play(.success)
            Task {
                if await service.sort(capture: capture, into: area) { sortSelection = nil }
            }
        } label: {
            Label("Sorted", systemImage: "checkmark.circle.fill")
        }
        .buttonStyle(SortedButtonStyle(isReady: isReady))
        .disabled(!isReady)
        .accessibilityIdentifier("captureInboxSortedButton")
        .accessibilityHint(isReady ? "Files it and clears the inbox" : "Pick a life area first")
    }

    func summaryHeader(_ captures: [Capture]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if service.filter == .unprocessed, !captures.isEmpty {
                    Text("\(captures.count)")
                        .font(.largeTitle.bold())
                        .tracking(-1)
                        .monospacedDigit()
                        .foregroundStyle(Color("StateWarn"))
                    Text("left")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(CaptureInboxSummary.headline(count: captures.count, filter: service.filter))
                        .font(.title2.bold())
                        .tracking(-0.5)
                        .minimumScaleFactor(0.8)
                }
            }
            clearedProgressBar
            let breakdown = CaptureInboxSummary.breakdown(for: captures)
            if !breakdown.isEmpty {
                Text(breakdown)
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // The ageing counterweight (Concept C, M5): a frictionless capture button needs the
            // screen to admit how long things have sat.
            if let oldestLine = CaptureInboxSummary.oldestLine(for: captures) {
                Text(oldestLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("captureInboxOldestLine")
            }
            // S1's weekly ledger (M10): captured vs cleared over the trailing seven days — the
            // second honest counterweight beside the ageing line.
            if let weekLine = service.weekCounterweightLine {
                Text(weekLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("captureInboxWeekCounterweight")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("captureInboxSummary")
    }

    /// The thin cleared-vs-captured bar under the count (v3's header progress).
    @ViewBuilder
    private var clearedProgressBar: some View {
        if service.filter == .unprocessed,
           let health = service.weekHealth,
           let fraction = CaptureInboxSummary.progressFraction(
               captured: health.captured, cleared: health.cleared
           ) {
            Capsule()
                .fill(Color("TrackNeutral"))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Color("StateGoVivid"))
                            .frame(width: proxy.size.width * fraction)
                    }
                }
                .accessibilityLabel(
                    "\(health.cleared) of \(health.captured) captured this week cleared"
                )
        }
    }
}

// MARK: - Undo (E, 2026-08-28: "both")
//
// Two affordances, deliberately, because they answer different questions. The bar says WHAT just
// happened at the moment it happens and offers to take it back; the header arrow is the safety net
// you reach for later, when you have already looked away. Both drive the one spent-once action in
// `CaptureInboxService+Triage`, so they can never disagree about what would be reversed.

extension CaptureInboxView {
    @ViewBuilder
    var undoBar: some View {
        if let action = service.lastTriageAction {
            HStack(spacing: 8) {
                Label(
                    CaptureTriage.confirmation(
                        for: action, sortedInto: service.lastSortedAreaId, lifeAreas: lifeAreas
                    ),
                    systemImage: "arrow.uturn.backward"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Button("Undo") {
                    Haptics.play(.light)
                    Task { await service.undoLastTriageAction() }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(minHeight: 44)
            }
            .padding(.leading, 16)
            // Trailing room for the capture disc, which otherwise floats directly over the Undo
            // button and makes it untappable (E's screenshot, 2026-08-28).
            .padding(.trailing, CaptureDiscMetrics.clearance)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(
                .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
                value: service.lastTriageAction
            )
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("captureInboxUndoBar")
        }
    }

    /// Always present once there is something to take back, so the net does not depend on noticing
    /// the bar before it goes.
    @ViewBuilder
    var undoHeaderButton: some View {
        if service.lastTriageAction != nil {
            Button {
                Haptics.play(.light)
                Task { await service.undoLastTriageAction() }
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Undo the last triage action")
            .accessibilityIdentifier("captureInboxUndoHeaderButton")
        }
    }
}
