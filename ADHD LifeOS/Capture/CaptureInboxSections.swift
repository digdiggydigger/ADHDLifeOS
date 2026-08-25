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
        let area = lifeAreas.first { $0.id == capture.lifeAreaId }
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
            if let area {
                Text("Filed to \(area.colour) \(area.name)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            topCardActions(capture)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .onTapGesture { inspectingCapture = capture }
        .accessibilityIdentifier("captureInboxTopCard")
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
        VStack(spacing: 8) {
            Button {
                promotingCapture = capture
            } label: {
                Label("Task it", systemImage: "text.badge.checkmark")
            }
            .buttonStyle(MomentumSolidButtonStyle(fill: .accentColor, foreground: AreaPalette.work.onColor))
            .accessibilityIdentifier("captureInboxTaskItButton")
            HStack(spacing: 8) {
                Button("Journal it") {
                    Task { await service.logToJournal(capture: capture) }
                }
                .buttonStyle(MomentumBorderedButtonStyle())
                .accessibilityIdentifier("captureInboxJournalItButton")
                Button("Bin") {
                    binningCapture = capture
                }
                .buttonStyle(MomentumBorderedButtonStyle())
                .accessibilityIdentifier("captureInboxBinButton")
            }
        }
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
