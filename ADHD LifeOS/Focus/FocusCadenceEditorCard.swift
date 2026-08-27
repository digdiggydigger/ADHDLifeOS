//
//  FocusCadenceEditorCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// The modal's live in-session nudge configuration (the web's `showConfig` block in
/// `src/components/FocusTimerBar.tsx`): mode toggle, count chips or interval stepper + presets, a
/// plain-language preview of what applying would schedule, and the Apply action that re-plans the
/// running sprint through `FocusSessionService.updateCadence(_:)`.
///
/// Editing changes nothing until Apply — `FocusCadenceDraft` holds the pending state, and every one
/// of its rules (30-second floor, unit conversion, non-negative count) is unit-tested away from the
/// view.
struct FocusCadenceEditorCard: View {
    @ObservedObject var service: FocusSessionService
    let session: FocusSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isEditing = false
    @State private var draft = FocusCadenceDraft(cadence: .count(1))
    @State private var hapticTrigger = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledContent {
                Text(currentCadenceDescription)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            } label: {
                Label("Nudge cadence", systemImage: "slider.horizontal.3")
                    .sectionLabel()
            }

            Button {
                hapticTrigger.toggle()
                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
                    if !isEditing { draft = FocusCadenceDraft(cadence: service.cadence) }
                    isEditing.toggle()
                }
            } label: {
                Label(
                    isEditing ? "Hide cadence options" : "Change cadence",
                    systemImage: isEditing ? "chevron.up" : "chevron.down"
                )
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .accessibilityIdentifier("focusCadenceToggle")

            if isEditing {
                editor
            }
        }
        .bentoCard()
        .haptic(.solid, trigger: hapticTrigger)
    }

    private var currentCadenceDescription: String {
        switch service.cadence {
        case .count(let count):
            return count == 1 ? "1 nudge" : "\(count) nudges"
        case .interval(let seconds):
            return "every \(FocusTimeFormatting.human(seconds: seconds))"
        }
    }

    // MARK: - Editor

    private var editor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Cadence mode", selection: $draft.mode) {
                ForEach(FocusCadenceDraft.Mode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("focusCadenceMode")

            if draft.mode == .count {
                countEditor
            } else {
                intervalEditor
            }

            Text(draft.summary(forDurationSeconds: session.durationSeconds))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("focusCadenceSummary")

            Text("Checkpoints you've already passed stay put — only the ones still ahead move.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Apply to sprint") { apply() }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("focusCadenceApply")
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var countEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total nudges this sprint")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // The chips cover the web's 1–5; the stepper reaches the rest of the per-task range,
            // so a sprint started with 10 nudges stays adjustable instead of unrepresentable.
            Stepper(value: $draft.count, in: FocusCadenceDraft.countRange) {
                Text(draft.count == 1 ? "1 nudge" : "\(draft.count) nudges")
                    .font(.footnote.weight(.bold))
                    .monospacedDigit()
            }
            .accessibilityIdentifier("focusCadenceCountStepper")

            HStack(spacing: 8) {
                ForEach(FocusCadenceDraft.countChoices, id: \.self) { choice in
                    Button {
                        hapticTrigger.toggle()
                        draft.count = choice
                    } label: {
                        Text("\(choice)")
                            .font(.footnote.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ChoiceChipButtonStyle(isSelected: draft.count == choice))
                    .accessibilityLabel(choice == 1 ? "1 nudge" : "\(choice) nudges")
                    .accessibilityAddTraits(draft.count == choice ? [.isSelected] : [])
                }
            }
        }
    }

    /// A `Stepper` plus preset chips rather than the web's number field: no keyboard to raise and
    /// dismiss inside a sheet, and the 30-second floor is enforced by the control's own range
    /// instead of by validating after the fact.
    private var intervalEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nudge me every…")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker("Interval unit", selection: intervalUnitBinding) {
                ForEach(FocusCadenceDraft.IntervalUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("focusCadenceIntervalUnit")

            Stepper(value: $draft.intervalValue, in: intervalRange, step: intervalStep) {
                Text(FocusTimeFormatting.human(seconds: draft.resolvedIntervalSeconds))
                    .font(.footnote.weight(.bold))
                    .monospacedDigit()
            }
            .accessibilityIdentifier("focusCadenceIntervalStepper")

            HStack(spacing: 8) {
                ForEach(FocusCadenceDraft.intervalPresetSeconds, id: \.self) { preset in
                    Button {
                        hapticTrigger.toggle()
                        draft.intervalUnit = .seconds
                        draft.intervalValue = preset
                    } label: {
                        Text("\(preset)s")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ChoiceChipButtonStyle(isSelected: isPresetSelected(preset)))
                    .accessibilityLabel("Every \(preset) seconds")
                }
            }
        }
    }

    private func isPresetSelected(_ preset: Int) -> Bool {
        draft.intervalUnit == .seconds && draft.intervalValue == preset
    }

    private var intervalUnitBinding: Binding<FocusCadenceDraft.IntervalUnit> {
        Binding(
            get: { draft.intervalUnit },
            set: { draft.selectIntervalUnit($0) }
        )
    }

    private var intervalRange: ClosedRange<Int> {
        draft.intervalUnit == .minutes ? 1...60 : FocusCheckpoints.minimumIntervalSeconds...300
    }

    private var intervalStep: Int {
        draft.intervalUnit == .minutes ? 1 : 5
    }

    private func apply() {
        hapticTrigger.toggle()
        service.updateCadence(draft.resolvedCadence)
        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
            isEditing = false
        }
    }
}

#if DEBUG
private struct FocusCadenceEditorCardPreview: View {
    @StateObject private var service = focusSprintPreviewService()

    var body: some View {
        Group {
            if let session = service.session {
                FocusCadenceEditorCard(service: service, session: session)
            }
        }
        .padding(16)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    FocusCadenceEditorCardPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusCadenceEditorCardPreview()
        .preferredColorScheme(.dark)
}
#endif
