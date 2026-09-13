//
//  PlaceRoutineRunTimeline.swift
//  ADHD LifeOS
//
//  The congratulation's DETAIL section (`F-CTACelebrations-6`, E's 2026-09-13 addition):
//  *"a small section within the empty-space … that display detailed data and info about that
//  specific routine that was run."*
//
//  **E was asked which "started" and which "finished" and answered BOTH to each**, which is the
//  right answer because the model genuinely holds four different moments and they answer four
//  different questions. The one thing this file must never do is invent a FIFTH — see
//  `workedDuration`.
//

import Foundation

/// The four moments of one run, kept apart on purpose.
struct PlaceRoutineRunTimeline: Equatable {
    /// The geofence crossing — "when did I get to the gym". `RoutineRun.startedAt`, which is
    /// the crossing's own moment and not the routine's.
    let arrivedAt: Date
    /// The notification tap that made the routine real and pre-ticked its automatic steps.
    /// `nil` for a run minted by an older build, which never stamped one.
    let startedAt: Date?
    /// The LATEST step resolution — when the work actually stopped.
    let lastStepAt: Date?
    /// E's R1 Completed tap. Can be long after `lastStepAt`: a fully-ticked run stays live and
    /// can be confirmed later, which is exactly what R1 asked for.
    let confirmedAt: Date

    /// **Activation → last step, and deliberately NOT to `confirmedAt`.**
    ///
    /// `RoutineRunRecord.timeSpentSeconds` already defines the length of a run this way, with
    /// the reason written beside it: *"To the LAST STEP INTERACTION, never to the end stamp: a
    /// run ended by a departure an hour later, or left open on a screen, must not claim that
    /// hour."* Deriving a different total here would let one run report two lengths — this
    /// screen and the Journal disagreeing about the same gym session.
    ///
    /// `nil` rather than a number measured from the crossing: a run that was never activated
    /// has no start to measure from, and using the crossing would silently bill the forty
    /// minutes before anyone opened it.
    let workedDuration: TimeInterval?

    static func make(run: RoutineRun, confirmedAt: Date) -> PlaceRoutineRunTimeline {
        let lastStepAt = run.steps.compactMap(\.resolvedAt).max()
        var worked: TimeInterval?
        if let activatedAt = run.activatedAt, let lastStepAt {
            worked = max(0, lastStepAt.timeIntervalSince(activatedAt))
        }
        return PlaceRoutineRunTimeline(
            arrivedAt: run.startedAt,
            startedAt: run.activatedAt,
            lastStepAt: lastStepAt,
            confirmedAt: confirmedAt,
            workedDuration: worked
        )
    }
}

/// E's answer 3: the time each step took.
enum PlaceRoutineStepDuration {
    /// Each resolved step's own stretch — from whatever was resolved immediately BEFORE it to
    /// its own stamp, or from the activation for the first.
    ///
    /// The previous resolution is found in TIME order rather than in list order, because Undo
    /// clears a stamp and a step can be re-resolved after later ones: in list order a re-done
    /// step would otherwise claim a negative stretch or swallow its neighbours'.
    ///
    /// Automatic steps all resolve at the activation, so they read as instant — which is true.
    static func durations(for run: RoutineRun) -> [TimeInterval?] {
        let stamps = run.steps.compactMap(\.resolvedAt).sorted()
        return run.steps.map { step in
            guard let resolved = step.resolvedAt else { return nil }
            guard let start = stamps.last(where: { $0 < resolved }) ?? run.activatedAt else {
                return nil
            }
            return max(0, resolved.timeIntervalSince(start))
        }
    }
}

/// E's answer 3: how this run compares with the usual one.
enum PlaceRoutineComparison {
    enum Verdict: Equatable {
        /// This routine has never been finished before, so there is nothing to compare with.
        case noHistory
        case fastestYet
        case usual(typical: TimeInterval)
        case longerThanUsual(typical: TimeInterval)
    }

    /// How wide "about the same" is: a fifth of the usual length, and never less than a minute,
    /// so a routine that is nine seconds off its median does not claim a result.
    private static func band(around typical: TimeInterval) -> TimeInterval {
        max(60, typical * 0.2)
    }

    /// Only THIS routine's own finished runs count — the same place AND the same direction.
    /// Leaving the office says nothing about how long arriving at the gym takes.
    ///
    /// A run that is much faster than usual but not a record reads as `usual` on purpose:
    /// "fastest yet" is the one claim worth making, and a second, weaker one competing with it
    /// would dilute it.
    static func verdict(
        worked: TimeInterval?, history: [RoutineRunRecord],
        placeId: UUID, direction: PlaceTriggerEvent.Kind
    ) -> Verdict {
        guard let worked else { return .noHistory }
        let mine = history
            .filter {
                $0.placeId == placeId && $0.direction == direction
                    && $0.status == .ended && $0.timeSpentSeconds > 0
            }
            .map { TimeInterval($0.timeSpentSeconds) }
            .sorted()
        guard let quickest = mine.first else { return .noHistory }
        if worked < quickest { return .fastestYet }
        let typical = median(of: mine)
        if worked > typical + band(around: typical) {
            return .longerThanUsual(typical: typical)
        }
        return .usual(typical: typical)
    }

    private static func median(of sorted: [TimeInterval]) -> TimeInterval {
        guard !sorted.isEmpty else { return 0 }
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }
}

/// The words for a length of time.
enum PlaceRoutineTimeFormatting {
    /// A wall-clock time. **E asked for `hh:mm:ss` by name, so the seconds stay** — but
    /// through the reader's own locale rather than a hard 24-hour format, because this app is
    /// headed for a public launch and half the world writes 1:00:00 PM. `.medium` is exactly
    /// "the short time, with seconds" in every locale.
    static func clock(
        _ date: Date, locale: Locale = .current, timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    /// Seconds below a minute, because a routine step is often that quick and "0 min" would
    /// read as a bug; whole hours drop the trailing "0m".
    static func duration(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        guard seconds > 0 else { return "instant" }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let remainder = minutes % 60
        return remainder == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(remainder)m"
    }
}
