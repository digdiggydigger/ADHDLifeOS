//
//  FocusTimerBar.swift
//  ADHD LifeOS
//

import SwiftUI

/// SwiftUI port of the web prototype's `src/components/FocusTimerBar.tsx` — specifically its
/// persistent "Bottom Floating Bar": life-area emoji chip, task title, live `MM:SS` pill, the
/// mini timeline with checkpoint dots (fired / next / pending), the next-checkpoint caption, and
/// the pause-resume + stop controls, plus the modal's `+30s` / `+5m` extend actions.
///
/// Deviations from the React source, per CLAUDE.md precedence:
/// - §4 zero-hex: the web's fixed dark card (`dark-card`, white text, `#FF5B5B` accent) becomes
///   `.regularMaterial` over adaptive semantic colour, so the bar reads correctly in both light
///   and dark mode instead of being permanently dark.
/// - The web file's ~500-line in-app "Automated 30s Test Suite" debugger panel is deliberately
///   NOT ported: it is a development harness that asserts the checkpoint maths in the UI. Its
///   assertions live in `FocusCheckpointsTests` / `FocusSessionServiceTests` instead, which is
///   where they belong in a native app.
/// - The full-screen focus modal (timeline inspector, live cadence editor) now exists as
///   `FocusSprintDetailView`, presented as a sheet by tapping the bar's task row.
struct FocusTimerBar: View {
    @ObservedObject var service: FocusSessionService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresentingDetail = false
    @State private var isConfirmingStop = false

    var body: some View {
        if let session = service.session {
            VStack(alignment: .leading, spacing: 8) {
                if let banner = service.checkpointBanner {
                    Label(banner, systemImage: "bell.badge.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("focusCheckpointBanner")
                }

                // The whole task row opens the full sprint view (timeline inspector + live cadence
                // editor) — the web's `isOpenModal`, which the bar likewise raised on tap.
                Button {
                    isPresentingDetail = true
                } label: {
                    HStack(spacing: 8) {
                        Text(session.lifeAreaEmoji)
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(
                                Color(.tertiarySystemFill),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(session.taskTitle)
                                    .font(.footnote.weight(.bold))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.up")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                if let badge = FocusBarStatus.pausedBadge(for: session) {
                                    Text(badge)
                                        .font(.caption2.monospaced().weight(.bold))
                                        .textCase(.uppercase)
                                        .foregroundStyle(.secondary)
                                        .accessibilityHidden(true)
                                        .accessibilityIdentifier("focusBarPausedBadge")
                                }
                                Text(FocusTimeFormatting.digital(session.remainingSeconds))
                                    .font(.caption.monospaced().weight(.bold))
                                    .foregroundStyle(Color(.systemBackground))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    // A paused countdown is a held state, not the live one — the
                                    // pill stops shouting in coral until it is resumed.
                                    .background(
                                        session.isPaused ? AnyShapeStyle(Color(.secondaryLabel)) : AnyShapeStyle(.tint),
                                        in: Capsule()
                                    )
                                    .accessibilityLabel(FocusBarStatus.accessibilityLabel(for: session))
                                    .accessibilityIdentifier("focusRemainingTime")
                            }

                            timelineTrack(session: session)

                            Group {
                                if let untilNext = session.secondsUntilNextCheckpoint {
                                    Text("🔔 Next checkpoint in \(FocusTimeFormatting.digital(untilNext))")
                                        .foregroundStyle(.orange)
                                } else if session.nudgeCheckpoints.isEmpty {
                                    Text("No checkpoints this sprint")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("✓ All \(session.nudgeCheckpoints.count) checkpoints reached")
                                        .foregroundStyle(.green)
                                }
                            }
                            .font(.caption2.monospaced())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the full sprint view")
                .accessibilityIdentifier("focusBarExpand")

                HStack(spacing: 8) {
                    controlButton(
                        session.isPaused ? "Resume" : "Pause",
                        systemImage: session.isPaused ? "play.fill" : "pause.fill",
                        identifier: "focusBarPause"
                    ) {
                        service.togglePause()
                    }

                    controlButton("+30s", systemImage: "goforward.30", identifier: "focusBarAdd30") {
                        service.addSeconds(30)
                    }

                    controlButton("+5m", systemImage: "goforward.plus", identifier: "focusBarAdd5m") {
                        service.addSeconds(300)
                    }

                    Spacer(minLength: 0)

                    controlButton("Stop", systemImage: "stop.fill", identifier: "focusBarStop", isDestructive: true) {
                        isConfirmingStop = true
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: session.isPaused)
            .accessibilityIdentifier("focusTimerBar")
            .sheet(isPresented: $isPresentingDetail) {
                FocusSprintDetailView(service: service)
            }
            // The same guard the modal's Complete & stop has (E, 2026-08-20): this Stop is the one
            // most likely to be mis-tapped — it sits beside +5m in a bar that is always on screen.
            .confirmationDialog(
                FocusStopConfirmation.title,
                isPresented: $isConfirmingStop,
                titleVisibility: .visible
            ) {
                Button(FocusStopConfirmation.confirmTitle, role: .destructive) {
                    Task { await service.stop() }
                }
                Button(FocusStopConfirmation.cancelTitle, role: .cancel) {}
            } message: {
                Text(FocusStopConfirmation.message(for: session))
            }
        }
    }

    /// The mini timeline: progress fill plus a dot per checkpoint — green once fired, orange for
    /// the one coming up, muted for the rest (the web's emerald / amber-ping / white-60 states).
    private func timelineTrack(session: FocusSession) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 8)
                Capsule()
                    .fill(.tint)
                    .frame(width: width * session.progress, height: 8)
                ForEach(Array(session.nudgeCheckpoints.enumerated()), id: \.offset) { index, checkpoint in
                    let state = FocusCheckpointDotState.resolve(index: index, session: session)
                    Circle()
                        .fill(state.color)
                        .frame(width: state.diameter, height: state.diameter)
                        // A ring in the page colour separates the marker from the coral fill it
                        // sits on, so the next checkpoint reads as a distinct object, not a tint.
                        .overlay(
                            Circle().strokeBorder(Color(.systemBackground), lineWidth: state == .next ? 2 : 0)
                        )
                        .offset(
                            x: dotOffset(
                                checkpoint: checkpoint, session: session,
                                width: width, diameter: state.diameter
                            )
                        )
                }
            }
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    private func dotOffset(
        checkpoint: Int, session: FocusSession, width: CGFloat, diameter: CGFloat
    ) -> CGFloat {
        guard session.durationSeconds > 0 else { return 0 }
        let fraction = min(1, max(0, Double(checkpoint) / Double(session.durationSeconds)))
        return (width * fraction) - (diameter / 2)  // centre the marker on its position
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
        .foregroundStyle(isDestructive ? Color.red : Color.accentColor)
        .accessibilityIdentifier(identifier)
    }
}

#if DEBUG
/// Preview-only service pre-loaded with a mid-flight sprint, so both previews render the bar in
/// its interesting state rather than empty.
@MainActor
private func previewService() -> FocusSessionService {
    let service = FocusSessionService()
    service.start(
        taskId: UUID(), taskTitle: "Draft the quarterly review",
        lifeAreaEmoji: "💼", durationSeconds: 1500, cadence: .count(3)
    )
    return service
}

#Preview("Light") {
    FocusTimerBar(service: previewService())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusTimerBar(service: previewService())
        .preferredColorScheme(.dark)
}
#endif
