//
//  PlaceRoutineCompletion.swift
//  ADHD LifeOS
//
//  The routine Completed flow's PURE layer (`F-CTACelebrations-6`, E's R1–R5 plus the nine
//  answers E gave on 2026-09-13). Every word, every duration and every spacing the flow needs
//  lives here rather than in a SwiftUI body, because a body is the one place no test can read.
//
//  **Five of E's nine answers are E's own wording or a reversal of what was offered**, so the
//  strings below are quoted rather than derived. In particular `completedTitle`'s separator is
//  a HYPHEN-MINUS because that is how E typed it; the rest of this app uses an em dash, and
//  "correcting" it would silently overwrite a decision E made by writing it out.
//

import CoreGraphics
import Foundation

/// Every string the Completed card and the congratulation say.
enum PlaceRoutineCompletionCopy {
    /// The eyebrow over the card that replaces the next-step slot once nothing is pending.
    static let completedEyebrow = "ALL DONE"
    /// E's R1 named this button, and it is what both UI journeys tap.
    static let completedButton = "Completed"
    /// The congratulation removes the Close button for up to 5.4 s, so for VoiceOver this
    /// action is the ONLY way out (the plan's risk 7). It sits on the view's root.
    static let skipAction = "Skip"
    /// …and a sighted user has no Close button either, so the view says so in words.
    static let skipHint = "Tap anywhere to skip"

    /// E's answer 3, verbatim: **"4 of 4 done - Ready to finish?"**.
    ///
    /// The count is done-of-total (E's answer 5) rather than resolved-of-total, so the card, the
    /// congratulation's summary line and the step list beneath it can never disagree — a run
    /// with a skipped step reads "3 of 4 done", and the list shows why.
    static func completedTitle(for run: RoutineRun) -> String {
        "\(PlaceRoutineProgress.doneCount(run)) of \(run.steps.count) done - Ready to finish?"
    }

    /// E's R4: the ACCOUNT display name, the one Settings' account row shows — not the
    /// routine's name. With no name (or a name that is only whitespace) the greeting drops it
    /// rather than greeting an empty string.
    static func greeting(for displayName: String?) -> String {
        let name = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Nice one" : "Nice one, \(name)"
    }

    /// E's answer 2, the line under the greeting: the routine's name, the verb, and the count.
    static func summary(for run: RoutineRun) -> String {
        "\(run.displayName) routine done — \(PlaceRoutineProgress.doneCount(run))"
            + " of \(run.steps.count) steps"
    }

    /// E's answers 4 and 9: a state is a WORD, never a second glyph and never a cross. An
    /// auto-done step draws the same accent circle and checkmark a tapped one does, and it is
    /// this word that tells them apart.
    ///
    /// `pending` cannot reach the list — it is only built for a fully-resolved run — but the
    /// function is total rather than optional so no caller has to decide what a gap means.
    static func stateWord(for state: RoutineStepState) -> String {
        switch state {
        case .done: return "Done"
        case .autoDone: return "Auto"
        case .skipped: return "Skipped"
        case .pending: return "To do"
        }
    }
}

/// R5: how long the congratulation stays up.
enum PlaceRoutineCongratulationLength {
    /// **The one new duration this feature introduces.** E's answers 1 and 7 made the
    /// switch-OFF case and R-f's unearned run the SAME beat — the same view, the full step
    /// list, just shorter and with no confetti.
    static let quietBeat: TimeInterval = 2.0

    /// E's R5: "auto-leave when the confetti ends". A full celebration's length is
    /// `ConfirmCelebrationClock.everyConfirmLength` and is never re-typed as a fresh `5.4`.
    static func hold(for outcome: CelebrationOutcome) -> TimeInterval {
        outcome == .fullScreen ? ConfirmCelebrationClock.everyConfirmLength : quietBeat
    }
}

/// How the congratulation ARRIVES — CLAUDE.md §7.2, resolved by the screen and passed to the
/// leaf as a parameter, because `accessibilityReduceMotion` cannot be injected through
/// `.environment(\.)` and the leaf has to be renderable in both modes.
///
/// A pure enum rather than an `AnyTransition` for the same reason: `AnyTransition` is not
/// `Equatable`, so a test could never read which one a state produced.
enum PlaceRoutineCongratulationEntrance: Equatable {
    /// The screen's OWN existing spring and the house 0.9 scale — no new motion vocabulary.
    case spring
    /// §7.2: under Reduce Motion the entrance is REPLACED by a fade, never removed. A `nil`
    /// animation here would be a hard cut, which is the bug rather than the fix.
    case fade

    static func resolve(reduceMotion: Bool) -> PlaceRoutineCongratulationEntrance {
        reduceMotion ? .fade : .spring
    }
}

/// E's answer 6: *"showing every step as outlined is appropriate"* — a long routine shows every
/// step and SHRINKS to fit, rather than scrolling (a scroll gesture would fight tap-to-skip) or
/// truncating (which would make the list disagree with the count above it).
///
/// **A pure table rather than `ViewThatFits`**, which was rejected deliberately: its candidates
/// are hand-authored, so the same table exists either way — just unverifiable — and when every
/// candidate overflows it silently picks the last and overflows anyway.
///
/// **The glyph has to shrink too.** `PlaceRoutineStepCircle` is a hard 28×28, so twenty rows is
/// 560 pt of glyph alone, and `.minimumScaleFactor` scales `Text` and never a `Circle`. So the
/// circle takes a size from here; `.minimumScaleFactor(0.8)` stays as a net for long TITLES,
/// never for row count.
///
/// The rows carry no controls — the whole screen is one tap target — so §3's 44 pt minimum does
/// not apply to them.
struct PlaceRoutineCongratulationDensity: Equatable {
    let circleSize: CGFloat
    let rowSpacing: CGFloat
    let rowHeight: CGFloat

    /// The list's vertical room on the SMALLEST screen the 16.0 floor reaches — the 667 pt
    /// iPhone SE — with every other element on the congratulation subtracted by name:
    ///
    ///     667 − 20 status bar − 32 page margins − 41 greeting − 8 gap − 20 summary
    ///         − 24 gap above − 24 gap below − 18 skip hint = 480
    static let listBudget: CGFloat = 480

    /// Three tiers. Every spacing is on CLAUDE.md §2's 4/8/16/24 grid, which a density table is
    /// exactly the kind of place to quietly break.
    static func forStepCount(_ count: Int) -> PlaceRoutineCongratulationDensity {
        switch count {
        case ..<7:
            return PlaceRoutineCongratulationDensity(circleSize: 28, rowSpacing: 16, rowHeight: 28)
        case ..<13:
            return PlaceRoutineCongratulationDensity(circleSize: 24, rowSpacing: 8, rowHeight: 24)
        default:
            return PlaceRoutineCongratulationDensity(circleSize: 20, rowSpacing: 4, rowHeight: 20)
        }
    }

    /// What the list will occupy at `count` steps, so the ceiling is a NAMED boundary rather
    /// than something discovered on the phone: twenty steps fit, twenty-one do not.
    static func estimatedHeight(forStepCount count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        let density = forStepCount(count)
        return CGFloat(count) * density.rowHeight + CGFloat(count - 1) * density.rowSpacing
    }
}
