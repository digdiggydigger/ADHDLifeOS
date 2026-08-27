//
//  TaskFocusPlanSection.swift
//  ADHD LifeOS
//

import SwiftUI

/// The Task Detail screen's focus-sprint planner, ported from the web prototype's
/// `TaskDetailModal.tsx` "Launch Focus Sprint" hero + "Target Focus & Nudges Configuration"
/// panel: a start affordance summarising the staged plan, the quick duration presets
/// (30s–25m), a seconds/minutes fine-tune stepper, the in-sprint nudge count, and a cadence
/// preview of exactly when each checkpoint chime will fire.
///
/// Deviations from the React source, per CLAUDE.md precedence:
/// - §4 zero-hex: the web's coral `#FF5B5B` accent becomes `.tint` over semantic fills.
/// - The free-form numeric input becomes a unit-aware `Stepper` bounded to the web's own
///   30s–120m range — no keyboard, no live clamping fights, same reachable values.
/// - Duration/nudges stay STAGED behind Save like every other field on this screen (the web
///   modal stages them too); the launch row is the exception and is handled by the parent,
///   which saves-then-starts so a sprint never runs against config the stored task lacks.
struct TaskFocusPlanSection: View {
    @Binding var durationSeconds: Int
    @Binding var nudgeCount: Int
    /// The staged plan summary the parent renders into the launch row; `nil` hides the row
    /// (hosts with no `FocusSessionService` wired, e.g. isolated previews).
    let onStart: (() -> Void)?

    /// Which unit the fine-tune stepper speaks. Seeded from the current value; presets and
    /// external reseeds re-derive it (a sub-minute or non-whole-minute duration needs seconds).
    @State private var unit: DurationUnit

    enum DurationUnit: String, CaseIterable {
        case seconds
        case minutes

        var label: String { rawValue.capitalized }
    }

    init(durationSeconds: Binding<Int>, nudgeCount: Binding<Int>, onStart: (() -> Void)?) {
        _durationSeconds = durationSeconds
        _nudgeCount = nudgeCount
        self.onStart = onStart
        _unit = State(initialValue: Self.naturalUnit(for: durationSeconds.wrappedValue))
    }

    private var checkpoints: [Int] {
        FocusCheckpoints.evenlySpaced(durationSeconds: durationSeconds, count: nudgeCount)
    }

    var body: some View {
        Section {
            if onStart != nil {
                launchRow
            }
            presetChipsRow
            fineTuneRow
            nudgeCountRow
            cadencePreview
        } header: {
            Text("Focus Sprint")
        } footer: {
            Text(
                "At each checkpoint a chime and haptic pulse mark elapsed time, "
                    + "so you stay grounded in the micro-step."
            )
        }
        .onChange(of: durationSeconds) { newValue in
            // A preset tap or an external reseed can land on a value the current unit can't
            // represent truthfully (sub-minute, or not a whole minute) — follow it.
            if unit == .minutes, newValue % 60 != 0 {
                unit = .seconds
            }
        }
    }

    // MARK: - Launch (web: "Launch Focus Sprint" hero)

    private var launchRow: some View {
        Button {
            onStart?()
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Launch Focus Sprint", systemImage: "sparkles")
                        .font(.footnote.monospaced().weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(.tint)
                    Text(planSummary)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Label("Start", systemImage: "play.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color(.systemBackground))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(.tint, in: Capsule())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel("Start focus sprint: \(planSummary)")
        .accessibilityIdentifier("taskDetailStartFocusButton")
    }

    private var planSummary: String {
        let duration = FocusTimeFormatting.human(seconds: durationSeconds)
        let nudges = nudgeCount == 1 ? "1 nudge" : "\(nudgeCount) nudges"
        return "\(duration) sprint · \(nudges)"
    }

    // MARK: - Duration presets (web: quick preset chips)

    private var presetChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FocusSprintConfiguration.presetDurationsSeconds, id: \.self) { preset in
                    presetChip(seconds: preset)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("taskDetailFocusPresets")
    }

    private func presetChip(seconds: Int) -> some View {
        let isSelected = durationSeconds == seconds
        return Button {
            Haptics.play(.light)
            durationSeconds = seconds
            unit = Self.naturalUnit(for: seconds)
        } label: {
            Text(FocusTimeFormatting.human(seconds: seconds))
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.tertiarySystemFill)),
                    in: Capsule()
                )
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(FocusTimeFormatting.human(seconds: seconds)) sprint")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Fine-tune (web: numeric input + seconds/minutes toggle)

    @ViewBuilder
    private var fineTuneRow: some View {
        Picker("Unit", selection: unitBinding) {
            ForEach(DurationUnit.allCases, id: \.self) { option in
                Text(option.label).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("taskDetailFocusUnitPicker")

        Stepper(
            value: stepperBinding,
            in: unit == .seconds
                ? FocusSprintConfiguration.minimumDurationSeconds...FocusSprintConfiguration.maximumDurationSeconds
                : 1...(FocusSprintConfiguration.maximumDurationSeconds / 60),
            step: unit == .seconds ? 5 : 1,
            onEditingChanged: { editing in
                // Once, on release — see the Settings steppers (E, 2026-08-27).
                if !editing { Haptics.play(.selection) }
            },
            label: {
                LabeledContent("Target", value: FocusTimeFormatting.human(seconds: durationSeconds))
            }
        )
        .accessibilityIdentifier("taskDetailFocusDurationStepper")
    }

    /// Switching to minutes rounds to the nearest whole minute and writes it back (the web's
    /// toggle does the same), so the stepper never displays a value the unit can't express.
    private var unitBinding: Binding<DurationUnit> {
        Binding(
            get: { unit },
            set: { newUnit in
                unit = newUnit
                if newUnit == .minutes {
                    let minutes = max(1, Int((Double(durationSeconds) / 60).rounded()))
                    durationSeconds = FocusSprintConfiguration.clampDuration(minutes * 60)
                }
            }
        )
    }

    private var stepperBinding: Binding<Int> {
        Binding(
            get: {
                unit == .seconds
                    ? durationSeconds
                    : max(1, Int((Double(durationSeconds) / 60).rounded()))
            },
            set: { newValue in
                let seconds = unit == .seconds ? newValue : newValue * 60
                durationSeconds = FocusSprintConfiguration.clampDuration(seconds)
            }
        )
    }

    // MARK: - Nudges (web: in-session nudge count + cadence timeline)

    private var nudgeCountRow: some View {
        Stepper(value: $nudgeCount, in: 0...FocusSprintConfiguration.maximumNudgeCount) {
            LabeledContent("In-Sprint Nudges", value: nudgeLabel)
        }
        .accessibilityIdentifier("taskDetailNudgeCountStepper")
    }

    private var nudgeLabel: String {
        switch nudgeCount {
        case 0: return "Off"
        case 1: return "1 · halfway"
        default: return "\(nudgeCount)"
        }
    }

    @ViewBuilder
    private var cadencePreview: some View {
        if nudgeCount == 0 {
            Label("Silent countdown — no checkpoint chimes this sprint.", systemImage: "bell.slash")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                cadenceTimeline
                Label(
                    "Nudges at \(checkpoints.map { FocusTimeFormatting.human(seconds: $0) }.joined(separator: " · "))",
                    systemImage: "bell"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("taskDetailNudgeCadencePreview")
        }
    }

    /// The web modal's slim timeline bar: a full-width track with one dot per checkpoint at its
    /// fractional position. Purely decorative — the label underneath carries the information.
    private var cadenceTimeline: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 4)
                ForEach(checkpoints, id: \.self) { checkpoint in
                    Circle()
                        .fill(.tint)
                        .frame(width: 8, height: 8)
                        .offset(
                            x: (geometry.size.width - 8)
                                * CGFloat(checkpoint) / CGFloat(max(1, durationSeconds))
                        )
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    private static func naturalUnit(for durationSeconds: Int) -> DurationUnit {
        durationSeconds % 60 == 0 ? .minutes : .seconds
    }
}

#if DEBUG
private struct FocusPlanPreviewHost: View {
    @State private var duration = 900
    @State private var nudges = 2

    var body: some View {
        Form {
            TaskFocusPlanSection(durationSeconds: $duration, nudgeCount: $nudges, onStart: {})
        }
    }
}

#Preview("Focus plan — Light") {
    FocusPlanPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Focus plan — Dark") {
    FocusPlanPreviewHost()
        .preferredColorScheme(.dark)
}
#endif
