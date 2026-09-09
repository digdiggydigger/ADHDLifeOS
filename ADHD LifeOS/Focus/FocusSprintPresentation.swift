//
//  FocusSprintPresentation.swift
//  ADHD LifeOS
//

import SwiftUI

/// What the app-wide sprint engine looks like to a screen that doesn't own it. Just enough for
/// Home's hero to know whether the sprint on screen is ITS task's, and what state it is in.
struct ActiveSprintStatus: Equatable, Sendable {
    let taskId: UUID?
    let isPaused: Bool
}

/// The Active Goal hero's primary button.
///
/// Before this it always read "START SESSION" — even while that exact task's sprint was running, so
/// Home showed no sign a sprint was live and its most obvious button silently replaced it. The
/// title now states what IS, and the glyph shows what the tap will DO.
enum ActiveGoalSprintState: Equatable {
    case idle
    case running
    case paused

    static func resolve(taskId: UUID?, sprint: ActiveSprintStatus?) -> ActiveGoalSprintState {
        // An unfiled task (`nil` id) must never adopt a sprint that also has no task — two absent
        // ids are not a match.
        guard let taskId, let sprint, sprint.taskId == taskId else { return .idle }
        return sprint.isPaused ? .paused : .running
    }

    var title: String {
        switch self {
        case .idle: return "Start Session"
        case .running: return "Session Active"
        case .paused: return "Session Paused"
        }
    }

    /// The ACTION's glyph, not the state's: tapping a running sprint pauses it, tapping a paused
    /// one resumes. Status is carried by the title, so meaning never rests on the icon alone (§4).
    var systemImage: String {
        switch self {
        case .idle, .paused: return "play.fill"
        case .running: return "pause.fill"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .idle: return "Starts a focus sprint for this task"
        case .running: return "Pauses the running sprint"
        case .paused: return "Resumes the paused sprint"
        }
    }
}

/// A checkpoint marker's state on a sprint progress track.
///
/// Split out so the bar and the modal's timeline agree, and so "which dot is next" is unit-tested
/// rather than re-derived inline in two views.
enum FocusCheckpointDotState: Equatable {
    case reached
    case next
    case pending

    static func resolve(index: Int, session: FocusSession) -> FocusCheckpointDotState {
        if session.triggeredCheckpointIndices.contains(index) { return .reached }
        return session.nextCheckpoint?.index == index ? .next : .pending
    }

    /// The palette E asked for on 2026-08-20: the old "next" marker was ORANGE sitting on the
    /// coral progress fill, which is barely a colour change at a glance.
    ///
    /// - reached → green: unmistakably "done", and nothing else on the track is green.
    /// - next → `LabelPrimary`, **not `.primary`, and that distinction is the whole bug fix**
    ///   (2026-09-09). `Color.primary` is a HIERARCHICAL style: over a `Material` SwiftUI resolves
    ///   it with vibrancy rather than as a flat colour, so on the timer bar's `.regularMaterial`
    ///   card the 12pt disc landed mid-grey instead of white and read as a hole punched in the
    ///   card. `.next` was the only hierarchical value in this enum and the only one that rendered
    ///   wrong — `.reached` and `.pending` are concrete and were always fine. `LabelPrimary` is
    ///   the opaque token with the same intent, so the mark now looks identical on the material
    ///   card, the page-backed timeline and anywhere else.
    /// - pending → a muted label grey that still reads on the coral fill (the old `systemFill`
    ///   nearly vanished on it).
    var color: Color {
        switch self {
        case .reached: return .green
        case .next: return Color("LabelPrimary")
        case .pending: return Color(.tertiaryLabel)
        }
    }

    /// The next marker is drawn LARGER as well as recoloured, so it is identifiable by SHAPE too
    /// — never by colour alone (§4). 12 against 8 is that shape difference, and it is the only one
    /// needed: the `Color(.systemBackground)` ring that used to sit around it was deleted on
    /// 2026-09-09. That ring's premise — "a page-colour ring separates the marker from the fill" —
    /// was false twice over. The marker sits on a MATERIAL card, which is a blur no colour can
    /// match, and `systemBackground` (#FFF / #000) was never this app's page colour anyway
    /// (`PageBackground` is #F2F3F7 / #15171C). In dark mode it painted a literal black ring.
    var diameter: CGFloat {
        self == .next ? 12 : 8
    }

    var accessibilityDescription: String {
        switch self {
        case .reached: return "Reached"
        case .next: return "Up next"
        case .pending: return "Scheduled"
        }
    }
}

/// The always-visible floating bar's status.
///
/// The bar is where a sprint is actually managed — it outlives every screen — so it has to state
/// paused-ness as plainly as Home's hero does. A "Resume" button on its own reads as an option you
/// could take, not as the state you are already in (E, 2026-08-20).
enum FocusBarStatus {
    /// The badge shown beside the countdown while paused; `nil` while running, so a live sprint
    /// stays uncluttered.
    static func pausedBadge(for session: FocusSession) -> String? {
        session.isPaused ? "Paused" : nil
    }

    /// One spoken string for the whole readout, so VoiceOver hears the STATE and not just a clock
    /// that has mysteriously stopped counting.
    static func accessibilityLabel(for session: FocusSession) -> String {
        let clock = FocusTimeFormatting.digital(session.remainingSeconds)
        return session.isPaused ? "Paused, \(clock) remaining" : "\(clock) remaining"
    }
}

/// Copy for the sprint-stop confirmation. Stop is destructive and sits a thumb-width from `+5m`, so
/// it asks first — and the question names what is actually at stake: the focus already banked.
enum FocusStopConfirmation {
    static let title = "Stop this sprint?"
    static let confirmTitle = "Stop sprint"
    static let cancelTitle = "Keep going"

    static func message(for session: FocusSession) -> String {
        let elapsed = session.elapsedSeconds
        guard elapsed >= 60 else {
            return "This sprint will end and nothing will be logged."
        }
        return "You've focused for \(FocusTimeFormatting.human(seconds: elapsed)). "
            + "Stopping logs that and ends the sprint."
    }
}
