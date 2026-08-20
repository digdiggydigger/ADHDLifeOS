//
//  FocusSprintDetailView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The full-screen focus modal, ported from the web prototype's `src/components/FocusTimerBar.tsx`
/// ("Main Focus Modal View"): the visual sprint timeline with tappable checkpoint pins, the
/// checkpoint inspector with its ADHD coaching copy, the session phase cards, the live in-session
/// cadence editor, and the pause / stop / extend controls.
///
/// Split across three files so each stays inside SwiftLint's type-body budget: this shell plus
/// `FocusSprintTimelineCard` (timeline + inspector + phases) and `FocusCadenceEditorCard` (the
/// live cadence editor).
///
/// Deviations from the React source, per `CLAUDE.md` precedence:
/// - §4 zero-hex: the web's permanently-dark `dark-card` + `#FF5B5B` becomes the project's token
///   layer (`Color.pageBackground`, `.bentoCard()`, `Color.accentColor`), so the sheet reads
///   correctly in Light as well as Dark.
/// - §1 semantic type: the web's `text-7xl` countdown becomes `.largeTitle` in a monospaced design
///   — the largest semantic style there is, so the hero still scales with Dynamic Type instead of
///   being pinned to a point size.
/// - The web's ~500-line in-modal "Automated 30s Test Suite" debugger stays unported (the same
///   call `FocusTimerBar` documented): its assertions live in `FocusCheckpointsTests`,
///   `FocusCadenceReplanTests` and `FocusSessionServiceCadenceTests`, which is where they belong
///   natively.
/// - The web's "Preview Chime" button is dropped: the native app ships no chime asset —
///   checkpoints announce themselves through the banner and the Live Activity.
struct FocusSprintDetailView: View {
    @ObservedObject var service: FocusSessionService

    @Environment(\.dismiss) private var dismiss
    @State private var controlHapticTrigger = false
    @State private var isConfirmingStop = false

    var body: some View {
        NavigationStack {
            Group {
                if let session = service.session {
                    sprintContent(session)
                } else {
                    finishedPlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground.ignoresSafeArea())
            .navigationTitle("Focus sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("focusModalDone")
                }
            }
        }
        .saveSuccessHaptic(trigger: controlHapticTrigger)
        .accessibilityIdentifier("focusSprintModal")
    }

    // MARK: - Layout

    private func sprintContent(_ session: FocusSession) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                statusRow(session)
                identity(session)
                if let banner = service.checkpointBanner {
                    checkpointBanner(banner)
                }
                countdown(session)
                FocusSprintTimelineCard(session: session)
                FocusCadenceEditorCard(service: service, session: session)
                controls(session)
            }
            .padding(16)
        }
    }

    /// Shown between a sprint ending (naturally, or via this sheet's own Stop) and the sheet being
    /// dismissed — never a dead end, and never a timeline frozen at 00:00.
    private var finishedPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Sprint finished")
                .font(.title2.bold())
                .tracking(-0.5)
            Text("Your focus time has been logged.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.horizontal, 24)
        }
        .padding(16)
    }

    private func statusRow(_ session: FocusSession) -> some View {
        Label {
            Text(session.isPaused ? "Session paused" : "Active focus sprint")
                .sectionLabel()
        } icon: {
            Image(systemName: session.isPaused ? "pause.circle.fill" : "record.circle")
                .foregroundStyle(session.isPaused ? Color.secondary : Color.accentColor)
        }
        .foregroundStyle(.secondary)
    }

    private func identity(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.lifeAreaEmoji)
                .font(.title)
                .frame(width: 56, height: 56)
                .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            Text("ADHD focus & checkpoint system")
                .sectionLabel()
                .foregroundStyle(Color.accentColor)

            Text(session.taskTitle)
                .font(.title2.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

    private func checkpointBanner(_ message: String) -> some View {
        Label(message, systemImage: "bell.badge.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
            .bentoCard()
            .accessibilityIdentifier("focusModalBanner")
    }

    private func countdown(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(FocusTimeFormatting.digital(session.remainingSeconds))
                .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .accessibilityLabel(Self.remainingAccessibilityLabel(session.remainingSeconds))
                .accessibilityIdentifier("focusModalRemaining")

            nextNudgeStatus(session)
        }
    }

    private static func remainingAccessibilityLabel(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return "\(clamped / 60) minutes \(clamped % 60) seconds remaining"
    }

    @ViewBuilder
    private func nextNudgeStatus(_ session: FocusSession) -> some View {
        if let next = session.nextCheckpoint, let untilNext = session.secondsUntilNextCheckpoint {
            FocusStatusPill(
                title: "Next nudge in \(FocusTimeFormatting.digital(untilNext))"
                    + " · at \(FocusTimeFormatting.human(seconds: next.atSeconds))",
                systemImage: "bell.badge.fill",
                tint: .orange
            )
        } else if session.nudgeCheckpoints.isEmpty {
            FocusStatusPill(title: "No nudges scheduled this sprint", systemImage: "bell.slash", tint: .secondary)
        } else {
            FocusStatusPill(
                title: "All \(session.nudgeCheckpoints.count) checkpoints reached",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
        }
    }

    // MARK: - Controls

    private func controls(_ session: FocusSession) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                secondaryControl(
                    session.isPaused ? "Resume" : "Pause",
                    systemImage: session.isPaused ? "play.fill" : "pause.fill",
                    identifier: "focusModalPause"
                ) {
                    service.togglePause()
                }
                secondaryControl("+30s", systemImage: "goforward.30", identifier: "focusModalAdd30") {
                    service.addSeconds(30)
                }
                secondaryControl("+5m", systemImage: "goforward.plus", identifier: "focusModalAdd5m") {
                    service.addSeconds(300)
                }
            }

            Button("Complete & stop") {
                controlHapticTrigger.toggle()
                isConfirmingStop = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("focusModalStop")
            // Stop ends the sprint and writes history; it sits a thumb-width from +5m, and a
            // mis-tap used to be unrecoverable (E, 2026-08-20).
            .confirmationDialog(
                FocusStopConfirmation.title,
                isPresented: $isConfirmingStop,
                titleVisibility: .visible
            ) {
                Button(FocusStopConfirmation.confirmTitle, role: .destructive) {
                    Task {
                        await service.stop()
                        dismiss()
                    }
                }
                Button(FocusStopConfirmation.cancelTitle, role: .cancel) {}
            } message: {
                Text(FocusStopConfirmation.message(for: session))
            }
        }
    }

    private func secondaryControl(
        _ title: String,
        systemImage: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            controlHapticTrigger.toggle()
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.bold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: false))
        .accessibilityIdentifier(identifier)
    }
}

/// The modal's status capsules (next nudge / all-clear / none scheduled) — one shape so the three
/// states can't drift apart.
struct FocusStatusPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.cardSurface, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: 0.5))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A selectable chip: filled with the accent when chosen, the card surface otherwise, and scaled
/// to `0.97` on press (§3 — an explicit primitive press style, never a raw opacity flash; §5 — a
/// spring, never linear easing).
struct ChoiceChipButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.primary))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.cardSurface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

#if DEBUG
/// Preview-only service running a mid-flight sprint with a crossed checkpoint, so both previews
/// render the timeline in its interesting state.
@MainActor
func focusSprintPreviewService() -> FocusSessionService {
    let service = FocusSessionService()
    service.start(
        taskId: UUID(), taskTitle: "Draft the quarterly review",
        lifeAreaEmoji: "💼", durationSeconds: 1500, cadence: .count(4)
    )
    return service
}

#Preview("Light") {
    FocusSprintDetailView(service: focusSprintPreviewService())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusSprintDetailView(service: focusSprintPreviewService())
        .preferredColorScheme(.dark)
}
#endif
