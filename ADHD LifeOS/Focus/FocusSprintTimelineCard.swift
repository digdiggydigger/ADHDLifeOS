//
//  FocusSprintTimelineCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// The modal's "Dynamic Visual Session Timeline & Checkpoint Track" (web
/// `src/components/FocusTimerBar.tsx`): a progress track with a tappable pin per checkpoint, the
/// inspector box that explains the selected — or next — checkpoint in ADHD coaching language, and
/// the session phase cards.
///
/// Two deliberate departures from the web track: the per-pin time labels are dropped (they collide
/// on a phone-width track; the inspector names the mark instead), and each pin carries a full 44pt
/// hit target around its 24pt badge (§3).
struct FocusSprintTimelineCard: View {
    let session: FocusSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The pin the user tapped — the web's `selectedCheckpointIndex`. Local to the card: nothing
    /// outside it cares, and it is cleared automatically when a re-plan shortens the list.
    @State private var selectedCheckpointIndex: Int?
    @State private var pinHapticTrigger = false

    private var total: Int { session.nudgeCheckpoints.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledContent {
                Text("\(session.triggeredCheckpointIndices.count) of \(total) passed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Sprint timeline", systemImage: "clock")
                    .sectionLabel()
            }

            VStack(alignment: .leading, spacing: 4) {
                track
                HStack {
                    Text("00:00")
                    Spacer(minLength: 0)
                    Text(FocusTimeFormatting.human(seconds: session.durationSeconds))
                }
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
            }

            inspector
            phaseCards
        }
        .bentoCard()
        .haptic(.solid, trigger: pinHapticTrigger)
    }

    // MARK: - Track

    private var track: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 8)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, width * session.progress), height: 8)
                ForEach(Array(session.nudgeCheckpoints.enumerated()), id: \.offset) { index, mark in
                    pin(index: index, mark: mark)
                        .position(x: pinCentre(mark: mark, width: width), y: 24)
                }
            }
            .frame(height: 48)
        }
        .frame(height: 48)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
            value: session.nudgeCheckpoints
        )
    }

    private func pin(index: Int, mark: Int) -> some View {
        let state = FocusCheckpointDotState.resolve(index: index, session: session)
        let isTriggered = state == .reached
        let isNext = state == .next
        let isSelected = selectedCheckpointIndex == index

        return Button {
            pinHapticTrigger.toggle()
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
                selectedCheckpointIndex = isSelected ? nil : index
            }
        } label: {
            ZStack {
                Circle()
                    .fill(pinFill(isTriggered: isTriggered, isNext: isNext))
                    .frame(width: 24, height: 24)
                Circle()
                    .strokeBorder(isSelected ? Color.primary : Color.cardBorder, lineWidth: isSelected ? 2 : 0.5)
                    .frame(width: 24, height: 24)
                Image(systemName: isTriggered ? "checkmark" : "bell.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(pinGlyph(isTriggered: isTriggered, isNext: isNext))
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(CheckpointPinButtonStyle())
        .accessibilityLabel("Checkpoint \(index + 1) at \(FocusTimeFormatting.human(seconds: mark))")
        .accessibilityValue(state.accessibilityDescription)
        .accessibilityIdentifier("focusCheckpointPin\(index)")
    }

    /// Shares `FocusCheckpointDotState`'s palette with the bar, so "next" means the same colour
    /// on both tracks — it used to be orange here and orange there, both washing out against the
    /// coral fill (E, 2026-08-20).
    private func pinFill(isTriggered: Bool, isNext: Bool) -> Color {
        if isTriggered { return FocusCheckpointDotState.reached.color }
        if isNext { return FocusCheckpointDotState.next.color }
        return Color.cardSurface
    }

    /// Status is never carried by colour alone — the glyph switches to a checkmark once a pin has
    /// fired, and VoiceOver reads the state from `accessibilityValue`.
    private func pinGlyph(isTriggered: Bool, isNext: Bool) -> Color {
        isTriggered || isNext ? Color(.systemBackground) : .secondary
    }

    /// Keeps a 44pt hit target fully on-track at either end.
    private func pinCentre(mark: Int, width: CGFloat) -> CGFloat {
        guard session.durationSeconds > 0, width > 0 else { return 0 }
        let fraction = min(1, max(0, Double(mark) / Double(session.durationSeconds)))
        return min(width - 16, max(16, width * fraction))
    }

    // MARK: - Inspector

    @ViewBuilder
    private var inspector: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let index = selectedCheckpointIndex, index < total {
                inspectorHeader(
                    title: "Checkpoint \(index + 1)",
                    systemImage: "info.circle.fill",
                    tint: Color.accentColor,
                    detail: inspectorDetail(index: index)
                )
                Text(FocusSession.checkpointPrompt(index: index, total: total))
            } else if let next = session.nextCheckpoint {
                inspectorHeader(
                    title: "Up next · checkpoint \(next.index + 1)",
                    systemImage: "bolt.fill",
                    tint: .orange,
                    detail: "at \(FocusTimeFormatting.human(seconds: next.atSeconds))"
                )
                Text(FocusSession.checkpointPrompt(index: next.index, total: total))
            } else if total == 0 {
                Label("No checkpoints scheduled — set a cadence below to get nudged.", systemImage: "bell.slash")
                    .foregroundStyle(.secondary)
            } else {
                Label("Every checkpoint crossed. Finish strong.", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .background(Color.pageBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("focusCheckpointInspector")
    }

    /// `LabeledContent` rather than a hand-rolled `HStack` + `Spacer`: it reflows into stacked
    /// lines at accessibility Dynamic Type sizes instead of squeezing the value into a column.
    private func inspectorHeader(title: String, systemImage: String, tint: Color, detail: String) -> some View {
        LabeledContent {
            Text(detail)
                .font(.caption2.monospaced())
        } label: {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.bold))
                .foregroundStyle(tint)
        }
    }

    private func inspectorDetail(index: Int) -> String {
        let mark = session.nudgeCheckpoints[index]
        guard !session.triggeredCheckpointIndices.contains(index) else {
            return "\(FocusTimeFormatting.human(seconds: mark)) · reached"
        }
        return "in \(FocusTimeFormatting.digital(max(0, mark - session.elapsedSeconds)))"
    }

    // MARK: - Phase cards

    /// The web's "Session Phase Sequence Cards".
    private var phaseCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            phaseCard(
                title: "Deep entry",
                value: "00:00 → \(FocusTimeFormatting.human(seconds: firstMark))",
                caption: session.elapsedSeconds >= firstMark ? "Completed" : "In progress"
            )
            phaseCard(
                title: "Cadence",
                value: total == 1 ? "1 checkpoint" : "\(total) checkpoints",
                caption: total == 0 ? "None scheduled" : "Banner + Lock Screen"
            )
            phaseCard(
                title: "Sprint target",
                value: FocusTimeFormatting.human(seconds: session.durationSeconds),
                caption: "Logged on finish"
            )
        }
    }

    /// The first checkpoint, or the finish line when the sprint has none — the boundary the deep
    /// entry phase runs up to either way.
    private var firstMark: Int {
        session.nudgeCheckpoints.first ?? session.durationSeconds
    }

    private func phaseCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.bold))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.pageBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The timeline pin's press style: the badge is only 24pt, so it scales a touch harder than the
/// 0.97 used by full-width controls to still read as feedback inside its 44pt hit target.
private struct CheckpointPinButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

#if DEBUG
private struct FocusSprintTimelineCardPreview: View {
    @StateObject private var service = focusSprintPreviewService()

    var body: some View {
        Group {
            if let session = service.session {
                FocusSprintTimelineCard(session: session)
            }
        }
        .padding(16)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    FocusSprintTimelineCardPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusSprintTimelineCardPreview()
        .preferredColorScheme(.dark)
}
#endif
