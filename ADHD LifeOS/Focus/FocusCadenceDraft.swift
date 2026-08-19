//
//  FocusCadenceDraft.swift
//  ADHD LifeOS
//

import Foundation

/// The live cadence editor's state, held apart from the view so its rules — the 30-second interval
/// floor, the seconds/minutes unit switch, the non-negative nudge count — are pure and unit-tested
/// rather than tangled into SwiftUI bindings.
///
/// Ported from the web modal's in-session nudge config (`showConfig` in
/// `src/components/FocusTimerBar.tsx`), which keeps `nudgeMode`, `intervalVal`, `intervalUnit` and
/// `countVal` as four independent `useState`s and resolves them only on "Apply to Session". The
/// draft does the same: editing it changes nothing until the sheet hands `resolvedCadence` to
/// `FocusSessionService.updateCadence(_:)`.
struct FocusCadenceDraft: Equatable {
    enum Mode: String, CaseIterable, Identifiable {
        case count, interval
        var id: String { rawValue }

        var title: String {
            switch self {
            case .count: return "By count"
            case .interval: return "By interval"
            }
        }
    }

    enum IntervalUnit: String, CaseIterable, Identifiable {
        case seconds, minutes
        var id: String { rawValue }

        var title: String {
            switch self {
            case .seconds: return "Sec"
            case .minutes: return "Min"
            }
        }
    }

    /// The web offers 1–5 total nudges as quick chips. The stepper spans the full per-task range
    /// (`FocusSprintConfiguration`), because a task's stored config can already ask for up to 10 —
    /// snapping such a sprint down to a chip value would silently rewrite its plan on open.
    static let countChoices = [1, 2, 3, 4, 5]
    static let countRange = 0...FocusSprintConfiguration.maximumNudgeCount
    /// The web's quick interval presets, in seconds.
    static let intervalPresetSeconds = [30, 45, 60, 120]

    var mode: Mode
    var count: Int
    var intervalValue: Int
    var intervalUnit: IntervalUnit

    /// Seeds from what the sprint is currently running, filling BOTH sides so switching mode in
    /// the sheet can never land on a nonsense value (the web keeps two independent states for the
    /// same reason).
    init(cadence: FocusNudgeCadence) {
        switch cadence {
        case .count(let count):
            self.mode = .count
            self.count = count
            self.intervalValue = FocusCheckpoints.minimumIntervalSeconds
            self.intervalUnit = .seconds
        case .interval(let seconds):
            self.mode = .interval
            self.count = 1
            if seconds >= 60, seconds % 60 == 0 {
                self.intervalValue = seconds / 60
                self.intervalUnit = .minutes
            } else {
                self.intervalValue = seconds
                self.intervalUnit = .seconds
            }
        }
    }

    /// What "Apply to Session" would schedule.
    var resolvedCadence: FocusNudgeCadence {
        switch mode {
        case .count:
            return .count(FocusSprintConfiguration.clampNudgeCount(count))
        case .interval:
            return .interval(seconds: resolvedIntervalSeconds)
        }
    }

    /// The interval in seconds after unit conversion and the web's `Math.max(30, …)` floor.
    var resolvedIntervalSeconds: Int {
        let raw = intervalUnit == .minutes ? intervalValue * 60 : intervalValue
        return max(FocusCheckpoints.minimumIntervalSeconds, raw)
    }

    /// Switching to seconds lifts a value that only made sense as minutes (`2`) up to the floor,
    /// exactly as the web's unit button does — otherwise the field reads as an invalid 2-second
    /// cadence until the user notices.
    mutating func selectIntervalUnit(_ unit: IntervalUnit) {
        intervalUnit = unit
        if unit == .seconds, intervalValue < FocusCheckpoints.minimumIntervalSeconds {
            intervalValue = FocusCheckpoints.minimumIntervalSeconds
        }
    }

    /// Plain-language preview of the result, so applying a cadence is never a leap of faith —
    /// counted from the marks the cadence actually produces for this sprint length, not from the
    /// requested number (a 5-minute interval over a 6-minute sprint schedules one nudge, not two).
    func summary(forDurationSeconds duration: Int) -> String {
        let scheduled = resolvedCadence.checkpoints(forDurationSeconds: duration).count
        guard scheduled > 0 else { return "No nudges" }
        let nudges = scheduled == 1 ? "1 nudge" : "\(scheduled) nudges"
        guard mode == .interval else { return nudges }
        return "\(nudges) — every \(FocusTimeFormatting.human(seconds: resolvedIntervalSeconds))"
    }
}
