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
        .haptic(.solid, trigger: controlHapticTrigger)
        .accessibilityIdentifier("focusSprintModal")
    }

    // MARK: - Layout

    private func sprintContent(_ session: FocusSession) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if let banner = service.checkpointBanner {
                    checkpointBanner(banner)
                }
                countdown(session)
                identity(session)
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
                .foregroundStyle(Color("StateGo"))
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

    /// v3's centred identity under the ring: the title, then the emoji with the start time.
    private func identity(_ session: FocusSession) -> some View {
        VStack(spacing: 8) {
            Text(session.taskTitle)
                .font(.title3.bold())
                .tracking(-0.4)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Text(identityLine(session))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func identityLine(_ session: FocusSession) -> String {
        var line = session.lifeAreaEmoji
        if session.isPaused {
            line += " · paused"
        }
        if let started = service.sprintStartedAt {
            line += " · started " + started.formatted(date: .omitted, time: .shortened)
        }
        return line
    }

    private func checkpointBanner(_ message: String) -> some View {
        Label(message, systemImage: "bell.badge.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color("StateWarn"))
            .fixedSize(horizontal: false, vertical: true)
            .bentoCard()
            .accessibilityIdentifier("focusModalBanner")
    }

    /// v3's S4 hero: the 236pt countdown ring — elapsed progress in motion-blue (muted while
    /// paused), the remaining time large inside, the logged-of-planned line under it.
    private func countdown(_ session: FocusSession) -> some View {
        VStack(spacing: 16) {
            ClosureRing(
                progress: session.progress,
                size: 236,
                lineWidth: 12,
                arcStyle: session.isPaused
                    ? AnyShapeStyle(Color("LabelTertiary"))
                    : AnyShapeStyle(Color.accentColor)
            ) {
                VStack(spacing: 4) {
                    Text(FocusTimeFormatting.digital(session.remainingSeconds))
                        .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                        .tracking(-1)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .accessibilityLabel(Self.remainingAccessibilityLabel(session.remainingSeconds))
                        .accessibilityIdentifier("focusModalRemaining")
                    Text("\(session.elapsedSeconds / 60) of \(session.durationSeconds / 60) min logged")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .shadow(color: Color.accentColor.opacity(session.isPaused ? 0 : 0.12), radius: 10, x: 0, y: 4)
            nextNudgeStatus(session)
        }
        .frame(maxWidth: .infinity)
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
                tint: Color("StateWarn")
            )
        } else if session.nudgeCheckpoints.isEmpty {
            FocusStatusPill(title: "No nudges scheduled this sprint", systemImage: "bell.slash", tint: .secondary)
        } else {
            FocusStatusPill(
                title: "All \(session.nudgeCheckpoints.count) checkpoints reached",
                systemImage: "checkmark.circle.fill",
                tint: Color("StateGo")
            )
        }
    }

    // MARK: - Controls

    private var extendChips: some View {
        HStack(spacing: 8) {
            secondaryControl("+1 min", systemImage: "goforward", identifier: "focusModalAdd1m") {
                service.addSeconds(60)
            }
            secondaryControl("+5 min", systemImage: "goforward.plus", identifier: "focusModalAdd5m") {
                service.addSeconds(300)
            }
            secondaryControl("+10 min", systemImage: "goforward.10", identifier: "focusModalAdd10m") {
                service.addSeconds(600)
            }
        }
    }

    private func controls(_ session: FocusSession) -> some View {
        VStack(spacing: 8) {
            extendChips

            HStack(spacing: 8) {
                Button {
                    controlHapticTrigger.toggle()
                    service.togglePause()
                } label: {
                    Label(
                        session.isPaused ? "Resume" : "Pause",
                        systemImage: session.isPaused ? "play.fill" : "pause.fill"
                    )
                }
                .buttonStyle(MomentumBorderedButtonStyle(minHeight: 54))
                .accessibilityIdentifier("focusModalPause")

                Button {
                    controlHapticTrigger.toggle()
                    isConfirmingStop = true
                } label: {
                    Label("Close it", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(MomentumSolidButtonStyle(fill: Color("StateGo"), foreground: Color("OnStateGo")))
                .accessibilityIdentifier("focusModalStop")
            }

            Text("Stopping early still logs the minutes you did.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

        }
        // Stop ends the sprint and writes history, and a mis-tap used to be unrecoverable
        // (E, 2026-08-20) — the dialog survives the v3 restyle, attached to the stack.
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
    /// An alternate wardrobe. `nil` — the default — is the app's ordinary chip in every one of the
    /// seven screens that use this style; only the journal pad passes one, so this cannot change
    /// anything it was not pointed at. See `ComposerChipPalette`.
    var palette: ComposerChipPalette?

    private var fill: AnyShapeStyle {
        guard let palette else {
            return isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.cardSurface)
        }
        return AnyShapeStyle(Color(isSelected ? palette.selectedFill : palette.quietSurface))
    }

    private var label: AnyShapeStyle {
        guard let palette else {
            return isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.primary)
        }
        return AnyShapeStyle(Color(isSelected ? palette.selectedLabel : palette.quietLabel))
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(label)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill)
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
