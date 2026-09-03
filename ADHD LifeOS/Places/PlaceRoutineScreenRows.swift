//
//  PlaceRoutineScreenRows.swift
//  ADHD LifeOS
//
//  The routine screen's rows (F-Routines-3), split for `PlaceRoutineScreen`'s type-length
//  budget. Standalone value views on purpose — they take the step and callbacks, never the
//  screen's state, so the split cannot smuggle in file-scope coupling.
//

import SwiftUI

@available(iOS 17.0, *)
struct PlaceRoutineResolvedRow: View {
    let step: RoutineRun.Step
    let direction: PlaceTriggerEvent.Kind
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PlaceRoutineStepCircle(state: step.state)
            VStack(alignment: .leading, spacing: 2) {
                Text(PlaceActionRowLabel.title(for: step.action))
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            if step.state != .autoDone {
                // Undo over confirm (E's settled call #6) — a chip, not a bare link: the
                // unambiguous-affordance directive.
                Button(action: onUndo) {
                    Text(PlaceRoutineScreenCopy.undoLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel("Undo \(PlaceActionRowLabel.title(for: step.action))")
            }
        }
    }

    private var subtitle: String {
        switch step.state {
        case .autoDone: return PlaceRoutineScreenCopy.autoRanSubtitle(for: direction)
        case .skipped: return PlaceRoutineScreenCopy.skippedSubtitle
        default: return PlaceRoutineScreenCopy.doneSubtitle
        }
    }
}

@available(iOS 17.0, *)
struct PlaceRoutineUpcomingRow: View {
    let step: RoutineRun.Step
    let stepNumber: Int
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            PlaceRoutineStepCircle(state: .pending)
            VStack(alignment: .leading, spacing: 2) {
                Text(PlaceActionRowLabel.title(for: step.action))
                    .foregroundStyle(.secondary)
                Text(PlaceRoutineScreenCopy.upcomingSubtitle(stepNumber: stepNumber, of: total))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 17.0, *)
struct PlaceRoutineStepCircle: View {
    let state: RoutineStepState

    var body: some View {
        ZStack {
            switch state {
            case .autoDone, .done:
                Circle().fill(Color.accentColor)
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            case .skipped:
                Circle().fill(Color.cardBorder)
                Image(systemName: "minus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            case .pending:
                Circle().strokeBorder(Color.cardBorder, lineWidth: 1.5)
            }
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true) // the subtitle words carry the state — never colour alone
    }
}
