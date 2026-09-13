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
import SwiftUI

/// Every string the Completed card and the congratulation say.
enum PlaceRoutineCompletionCopy {
    /// The eyebrow over the card that replaces the next-step slot once nothing is pending.
    static let completedEyebrow = "ALL DONE"
    /// E's R1 named this button, and it is what both UI journeys tap.
    static let completedButton = "Completed"
    /// The congratulation takes the screen's Close button away, and since E reversed R5 on
    /// 2026-09-13 it stays until dismissed — so for VoiceOver this action is the only way out
    /// and no timer will rescue anyone who misses it. It sits on the view's root.
    ///
    /// "Close", not "Skip": with the auto-leave gone there is nothing left to skip.
    static let closeAction = "Close"
    /// …and a sighted user has no button either, so the view says so in words.
    static let closeHint = "Tap anywhere to close"

    /// The detail block's row labels — E's answers 1 and 2, which asked for BOTH moments in
    /// each pair because the model holds four and they answer four different questions.
    static let arrivedLabel = "Arrived"
    static let startedLabel = "Started"
    static let lastStepLabel = "Last step"
    static let confirmedLabel = "Confirmed"
    static let totalLabel = "Time on the routine"

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
    /// A step's state and its own stretch of time, worded so the number cannot be misread.
    ///
    /// **E, 2026-09-13, on seeing the render: "reword the 'Skipped 2m' so that it fits
    /// accordingly."** The number is the time that ran BEFORE the step was resolved, so
    /// "Skipped · 2m" read as though skipping had taken two minutes. Each state now says what
    /// its own number means: a done step took it, a skipped step sat there for it.
    ///
    /// An automatic step never carries one at all — it resolves at the activation, so its
    /// stretch is always instant and a number beside it would say nothing.
    static func stateAndDuration(for state: RoutineStepState, took: TimeInterval?) -> String {
        let word = stateWord(for: state)
        guard state != .autoDone, let took, took > 0 else { return word }
        switch state {
        case .done: return "\(word) in \(PlaceRoutineTimeFormatting.duration(took))"
        case .skipped: return "\(word) after \(PlaceRoutineTimeFormatting.duration(took))"
        case .autoDone, .pending: return word
        }
    }

    static func stateWord(for state: RoutineStepState) -> String {
        switch state {
        case .done: return "Done"
        case .autoDone: return "Auto"
        case .skipped: return "Skipped"
        case .pending: return "To do"
        }
    }
}

/// How strongly the congratulation's own done-green wash reads, per appearance.
///
/// **Both values were approved by E BY LOOKING, and they are deliberately different.** E asked
/// to *"increase the visibility of the coloured Tint/Glow WHEN IN LIGHT-MODE on this view"*,
/// was shown a rendered ladder of 0.14 / 0.22 / 0.30 / 0.40 / 0.50 on the finished layout, and
/// chose **0.40**. Dark was never part of that question and keeps what it shipped with, because
/// the same wash reads far stronger against a dark page — which is why light needed lifting and
/// dark did not.
///
/// Like `FocusCompletionStackLayout.peekStep`, these are values chosen by sight.
/// **Do not "tidy" them into one number**: that would silently undo a decision E made by eye.
enum PlaceRoutineCongratulationWash {
    static func opacity(for scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.14 : 0.40
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

    /// The animation the SWAP runs under. **Neither case is `nil`, and that is the whole of
    /// §7.2 for this block:** `reduceMotion ? nil : …` is right for continuous re-layout, where
    /// the tween IS the motion, and wrong for anything that appears — which this is. §5 carries
    /// the clause that lets the reduced case be a plain ease.
    var animation: Animation {
        switch self {
        case .spring: return .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
        case .fade: return .easeOut(duration: 0.25)
        }
    }

    /// §7.2's opening-pose rule, expressed as the only place it can be true: the reduced case
    /// carries NO geometry, so the congratulation's first frame is already at final scale and
    /// only opacity travels. A reduced path that opened at 0.9 and snapped to 1 would be the
    /// bug the rule names, and it is one word away from here.
    var transition: AnyTransition {
        switch self {
        case .spring: return .scale(scale: 0.9).combined(with: .opacity)
        case .fade: return .opacity
        }
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

}
