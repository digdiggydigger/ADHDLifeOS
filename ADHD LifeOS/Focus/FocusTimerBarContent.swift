//
//  FocusTimerBarContent.swift
//  ADHD LifeOS
//
//  Split out of `FocusTimerBar` in F-FocusCard-1, preemptively rather than when lint failed: the
//  file was at 250 of SwiftLint's 400-line ceiling before a second layout state, a grabber, a
//  chevron button and three gestures were added to it (the `FocusSessionService+Persistence`
//  precedent).
//
//  The split is on a seam, not on a line count. Everything here is what the card *shows*; the
//  card's chrome, its gestures and the two `@State` presentations stay in `FocusTimerBar`, so the
//  gesture wiring lives in one file with the thing its call-site tests read. Nothing in this file
//  can open the detail sheet — see `testTheRowIsNoLongerItsOwnDoor`.
//

import SwiftUI

/// The focus card's contents in both states.
///
/// **Collapsed carries exactly three things** — the progress ring, the sprint name, and Pause —
/// plus the two toggle affordances that are present in both states (the grabber and the chevron).
/// `+30s`, `+5m` and `Stop` are expanded-only: E chose *"Gone — expand to reach them"* over
/// keeping Stop and over cramming all four controls into the collapsed row.
struct FocusTimerBarContent: View {
    let session: FocusSession
    let isCollapsed: Bool
    let checkpointBanner: String?
    /// Passed in rather than read from the environment here, so the ring's per-second sweep and
    /// the card's own transitions are stilled by one decision made in `FocusTimerBar`.
    let reduceMotion: Bool
    let onToggleCollapse: () -> Void
    let onTogglePause: () -> Void
    let onExtend: (Int) -> Void
    let onRequestStop: () -> Void

    private var ringSize: CGFloat {
        isCollapsed ? FocusBarMetrics.collapsedRingSize : FocusBarMetrics.expandedRingSize
    }

    private var ringLineWidth: CGFloat {
        isCollapsed ? FocusBarMetrics.collapsedRingLineWidth : FocusBarMetrics.expandedRingLineWidth
    }

    var body: some View {
        if isCollapsed {
            collapsedBody
        } else {
            expandedBody
        }
    }

    /// **E's 2026-09-09 layout**: the sprint title gets the row to itself, and Pause — now an
    /// icon with no text label, enlarged to compensate — sits BELOW it beside the chevron.
    ///
    /// The previous single row put ring + emoji + title + chevron + PAUSED badge + a labelled
    /// Pause button on one line. At 305pt the title had collapsed to "9…" and the badge had
    /// wrapped onto two lines. Stacking the controls under the title is what buys the width back.
    private var collapsedBody: some View {
        HStack(spacing: 8) {
            sprintRing

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(session.lifeAreaEmoji)
                        .font(.caption)
                    Text(session.taskTitle)
                        .font(.footnote.weight(.bold))
                        .lineLimit(1)
                        // §1's layout safety. Without it the `Spacer` below yields first and the
                        // title truncates before anything else gives — the exact failure E
                        // photographed.
                        .layoutPriority(1)
                    Spacer(minLength: 0)
                }

                HStack(spacing: 16) {
                    pauseControl
                    collapseChevron
                    if let badge = FocusBarStatus.pausedBadge(for: session) {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .accessibilityHidden(true)
                            .accessibilityIdentifier("focusBarPausedBadge")
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var expandedBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let banner = checkpointBanner {
                Label(banner, systemImage: "bell.badge.fill")
                    .font(.caption2)
                    .foregroundStyle(Color("StateWarn"))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("focusCheckpointBanner")
            }

            HStack(spacing: 8) {
                sprintRing
                titleColumn
            }

            if !isCollapsed {
                HStack(spacing: 8) {
                    controlButton(
                        session.isPaused ? "Resume" : "Pause",
                        systemImage: session.isPaused ? "play.fill" : "pause.fill",
                        identifier: "focusBarPause",
                        action: onTogglePause
                    )

                    controlButton("+30s", systemImage: "goforward.30", identifier: "focusBarAdd30") {
                        onExtend(30)
                    }

                    controlButton("+5m", systemImage: "goforward.plus", identifier: "focusBarAdd5m") {
                        onExtend(300)
                    }

                    Spacer(minLength: 0)

                    controlButton(
                        "Stop", systemImage: "stop.fill",
                        identifier: "focusBarStop", isDestructive: true
                    ) {
                        onRequestStop()
                    }
                }
            }
        }
    }

    // MARK: - The two toggle affordances

    /// Before F-FocusCard-1 this was a decorative `Image` that pointed up and did nothing — the
    /// row around it was the button. E chose to make it a real control that flips with the state.
    private var collapseChevron: some View {
        Button(action: onToggleCollapse) {
            Image(systemName: isCollapsed ? "chevron.up" : "chevron.down")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(
                    width: FocusBarMetrics.collapsedControlHeight,
                    height: FocusBarMetrics.collapsedControlHeight
                )
                .padding(.vertical, FocusBarMetrics.collapsedControlHitOverflow)
                .contentShape(Rectangle())
                .padding(.vertical, -FocusBarMetrics.collapsedControlHitOverflow)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCollapsed ? "Expand the sprint card" : "Collapse the sprint card")
        .accessibilityIdentifier("focusBarExpand")
    }

    /// Pause/Resume as a GLYPH ONLY — E: *"remove the label from the PAUSE icon and make the icon
    /// bigger to make up for the removed label"*. The play/pause glyph swap is what conveys the
    /// state, which is shape rather than colour and so satisfies §4; VoiceOver gets the word.
    private var pauseControl: some View {
        Button(action: onTogglePause) {
            Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                .font(.title3.weight(.semibold))
                .frame(
                    width: FocusBarMetrics.collapsedControlHeight,
                    height: FocusBarMetrics.collapsedControlHeight
                )
                .padding(.vertical, FocusBarMetrics.collapsedControlHitOverflow)
                .contentShape(Rectangle())
                .padding(.vertical, -FocusBarMetrics.collapsedControlHitOverflow)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel(session.isPaused ? "Resume sprint" : "Pause sprint")
        .accessibilityIdentifier("focusBarPause")
    }

    // MARK: - The three things the collapsed card keeps

    /// S4's sprint ring: the scoreboard's `ClosureRing` with the countdown in its centre. The arc
    /// FILLS with elapsed time (the scoreboard's fill-toward-done direction, E's call on the
    /// plan); the centre text does the counting down. Paused, the arc mutes exactly as the old
    /// pill background did — a held state, not the live one.
    private var sprintRing: some View {
        ClosureRing(
            progress: session.progress,
            size: ringSize,
            lineWidth: ringLineWidth,
            arcStyle: session.isPaused
                ? AnyShapeStyle(Color(.secondaryLabel))
                : AnyShapeStyle(.tint)
        ) {
            Text(FocusTimeFormatting.digital(session.remainingSeconds))
                .font(.caption2.monospaced().weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .accessibilityLabel(FocusBarStatus.accessibilityLabel(for: session))
                .accessibilityIdentifier("focusRemainingTime")
        }
        .overlay(checkpointDots)
        // The per-second tick sweeps through ClosureRing's own spring; Reduce Motion stills it
        // the same way the card's own transitions are stilled.
        .transaction { transaction in
            if reduceMotion { transaction.animation = nil }
        }
    }

    /// Expanded only — the collapsed card builds its own two-line column in `collapsedBody`.
    private var titleColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(session.lifeAreaEmoji)
                    .font(.footnote)
                Text(session.taskTitle)
                    .font(.footnote.weight(.bold))
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: 0)
                collapseChevron
                if let badge = FocusBarStatus.pausedBadge(for: session) {
                    Text(badge)
                        .font(.caption2.monospaced().weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                        .accessibilityIdentifier("focusBarPausedBadge")
                }
            }

            Group {
                if let untilNext = session.secondsUntilNextCheckpoint {
                    Text("🔔 Next checkpoint in \(FocusTimeFormatting.digital(untilNext))")
                        .foregroundStyle(Color("StateWarn"))
                } else if session.nudgeCheckpoints.isEmpty {
                    Text("No checkpoints this sprint")
                        .foregroundStyle(.secondary)
                } else {
                    Text("✓ All \(session.nudgeCheckpoints.count) checkpoints reached")
                        .foregroundStyle(Color("StateGo"))
                }
            }
            .font(.caption2.monospaced())
        }
    }

    // MARK: - Shared pieces

    /// The checkpoint dots on the dial: the same `FocusCheckpointDotState` states, colours and
    /// sizes in both card states — only the dial they sit on shrinks, and that arithmetic lives in
    /// `SprintRingGeometry`, where it is unit-tested.
    private var checkpointDots: some View {
        ZStack {
            ForEach(Array(session.nudgeCheckpoints.enumerated()), id: \.offset) { index, checkpoint in
                let state = FocusCheckpointDotState.resolve(index: index, session: session)
                Circle()
                    .fill(state.color)
                    .frame(width: state.diameter, height: state.diameter)
                    // The page-colour ring that separated the next marker from the coral fill on
                    // the old track does the same job on the dial (§4: shape, never colour alone).
                    .overlay(
                        Circle().strokeBorder(Color(.systemBackground), lineWidth: state == .next ? 2 : 0)
                    )
                    .position(
                        SprintRingGeometry.dotCenter(
                            checkpoint: checkpoint, durationSeconds: session.durationSeconds,
                            size: ringSize
                        )
                    )
            }
        }
        .accessibilityHidden(true)
    }

    private func controlButton(
        _ title: String,
        systemImage: String,
        identifier: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isDestructive ? Color("StateRisk") : Color.accentColor)
        .accessibilityIdentifier(identifier)
    }
}
