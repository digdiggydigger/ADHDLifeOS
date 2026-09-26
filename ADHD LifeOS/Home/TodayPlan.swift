//
//  TodayPlan.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`: Today is ONE card, a short "then" list, and one quiet done line (E's round
//  3, *"C · One next thing"*). This file decides what goes in the card and what goes in the list;
//  the views only draw the answer, so the order E chose is tested here rather than in a body.
//

import Foundation

/// A commitment the user must LEAVE for — round 5a's top rank (*"Only a hard deadline outranks
/// where you are"*). **Nothing produces one yet:** it needs the calendar read `F-F5` builds, so
/// Today passes `nil` and the rank waits here, tested, for its input.
struct TodayLeaveBy: Equatable {
    let title: String
    let leaveAt: Date
}

/// A PAUSED sprint, projected for the Resume card (round 4a: *"A paused sprint shows 'Paused · N
/// min in · Resume', which feeds the Resume card"*). A running sprint is not one — the focus card
/// is already counting it down, and Today does not compete with it.
struct TodayPausedSprint: Equatable {
    let taskId: UUID?
    let taskTitle: String
    let durationSeconds: Int
    let remainingSeconds: Int

    var elapsedSeconds: Int { max(0, durationSeconds - remainingSeconds) }

    /// Built from the two halves Home already receives: `activeSprint` says WHETHER it is paused
    /// and on which task, `widgetSprint` carries the title and the frozen remainder. Both must say
    /// paused, or there is nothing to resume — Resume calls a TOGGLE, so offering it on a running
    /// sprint would pause it instead.
    static func from(
        status: ActiveSprintStatus?,
        sprint: FocusWidgetSnapshot.ActiveSprint?
    ) -> TodayPausedSprint? {
        guard let status, status.isPaused, let sprint, let remaining = sprint.pausedRemainingSeconds else {
            return nil
        }
        return TodayPausedSprint(
            taskId: status.taskId,
            taskTitle: sprint.taskTitle,
            durationSeconds: sprint.durationSeconds,
            remainingSeconds: remaining
        )
    }
}

/// What holds Today's one card, in E's order (round 5a).
enum TodaySlot: Equatable {
    case leaveBy(TodayLeaveBy, task: TaskSummary?)
    /// The live-routine card and/or the arrival card. E, 2026-09-24: *"the live-routine card and
    /// the arrival card together COUNT AS the one card, unchanged"* — so the pair draws itself and
    /// no task card is added beside it.
    case place
    case paused(TodayPausedSprint)
    case pinned(TaskSummary)
    case suggested(TaskSummary)
    case nothing

    /// The task the card is already showing, kept out of the "then" list so nothing is listed
    /// twice.
    var shownTaskId: UUID? {
        switch self {
        case .leaveBy(_, let task): return task?.id
        case .paused(let sprint): return sprint.taskId
        case .pinned(let task), .suggested(let task): return task.id
        case .place, .nothing: return nil
        }
    }
}

struct TodayPlan: Equatable {
    let slot: TodaySlot
    let thenTasks: [TaskSummary]
    /// The task the card leads with whenever it leads with a task: the pin, else the suggestion.
    /// **The Home Screen widget publishes this too.** It used to publish `topTask` while Today led
    /// with `bestNextMove`, so the two disagreed whenever anything was due.
    let headlineTask: TaskSummary?

    static func build(
        openTasks: [TaskSummary],
        pinnedTaskId: UUID?,
        skippedTaskIds: Set<UUID>,
        pausedSprint: TodayPausedSprint?,
        hasPlaceCard: Bool,
        leaveBy: TodayLeaveBy? = nil,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> TodayPlan {
        let open = openTasks.filter { $0.status == .open }
        // A pin on a task that closed or was deleted is no pin: the slot falls through. It is
        // left in the store on purpose — an Undo reopens the task, and the pin comes back with it.
        let pinned = pinnedTaskId.flatMap { id in open.first { $0.id == id } }
        // "Not this one" narrows the SUGGESTION only (round 5b); a pin is the later, explicit
        // choice and outranks an earlier skip.
        let suggestion = MomentumScoreboard.bestNextMove(
            in: open.filter { !skippedTaskIds.contains($0.id) }, asOf: now, calendar: calendar
        )
        let headline = pinned ?? suggestion
        let slot: TodaySlot
        if let leaveBy {
            slot = .leaveBy(leaveBy, task: headline)
        } else if hasPlaceCard {
            slot = .place
        } else if let pausedSprint {
            slot = .paused(pausedSprint)
        } else if let pinned {
            slot = .pinned(pinned)
        } else if let suggestion {
            slot = .suggested(suggestion)
        } else {
            slot = .nothing
        }
        return TodayPlan(
            slot: slot,
            thenTasks: thenList(
                open: open, pinned: pinned, skipped: skippedTaskIds, excluding: slot.shownTaskId,
                isDue: { task in
                    guard let due = task.dueDate else { return false }
                    return calendar.startOfDay(for: due) <= calendar.startOfDay(for: now)
                }
            ),
            headlineTask: headline
        )
    }

    /// What is due (today or before), plus two things that are not necessarily due but must not
    /// vanish: a skipped task (*"Back in the list"* — even an undated one, which `bestNextMove`'s
    /// fallback can suggest) and a pinned task something else displaced from the card, which
    /// leads because the user chose it.
    private static func thenList(
        open: [TaskSummary],
        pinned: TaskSummary?,
        skipped: Set<UUID>,
        excluding shown: UUID?,
        isDue: (TaskSummary) -> Bool
    ) -> [TaskSummary] {
        let listed = open.filter { task in
            guard task.id != pinned?.id else { return false }
            return skipped.contains(task.id) || isDue(task)
        }
        return ((pinned.map { [$0] } ?? []) + listed).filter { $0.id != shown }
    }
}
