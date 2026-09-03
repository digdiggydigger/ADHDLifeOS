//
//  PlaceRoutinePlan.swift
//  ADHD LifeOS
//
//  The pure core of the Routines arc (F-Routines-1-Order): a crossing's actions, in the
//  place's saved array order, seen as ONE ordered routine. Place-scoped by E's settled call
//  (Option A) — the routine IS the place's actions, and the screen that eventually shows
//  these steps must never learn where they came from, so first-class routines can arrive
//  later without touching it.
//

import Foundation

/// A crossing direction's runnable actions as an ordered routine.
///
/// Classification (what runs itself vs what needs a tap) is `PlaceActionPlan.split`'s — this
/// type reuses it rather than re-deciding, so the handler and the routine can never disagree
/// about membership. What this type ADDS is the order: `split` returns two separate arrays,
/// which is right for the per-action fan-out and loses the interleaving a routine is made of.
struct PlaceRoutinePlan: Equatable, Sendable {
    struct Step: Equatable, Sendable {
        let action: PlaceAction
        /// `true` for the kinds a background wake runs itself (journal lines, captures) —
        /// the routine screen shows these pre-ticked. `false` is a tap-step.
        let runsAutomatically: Bool
    }

    /// Every runnable step for the direction, auto and tap interleaved exactly as E arranged
    /// them in the editor. `.unsupported` is absent: this build can neither run it nor honour
    /// its tap, and a step the screen would show as forever-pending is worse than no step.
    let steps: [Step]

    var autoRunSteps: [PlaceAction] { steps.filter(\.runsAutomatically).map(\.action) }
    var tapSteps: [PlaceAction] { steps.filter { !$0.runsAutomatically }.map(\.action) }

    /// The ≥2 decision (E's settled call): one routine notification only when the crossing
    /// has `RoutineDefaults.stepThreshold` or more tap-steps. Exactly one keeps today's
    /// direct one-tap notification; auto-runs never count — they happen either way.
    var qualifiesAsRoutine: Bool { tapSteps.count >= RoutineDefaults.stepThreshold }

    static func make(_ actions: [PlaceAction]?, for kind: PlaceTriggerEvent.Kind) -> PlaceRoutinePlan {
        let (autoRun, external) = PlaceActionPlan.split(actions, for: kind)
        let autoIds = Set(autoRun.map(\.id))
        let runnableIds = autoIds.union(external.map(\.id))
        let steps = (actions ?? [])
            .filter { runnableIds.contains($0.id) }
            .map { Step(action: $0, runsAutomatically: autoIds.contains($0.id)) }
        return PlaceRoutinePlan(steps: steps)
    }
}
