//
//  RoutineRunReconciliation.swift
//  ADHD LifeOS
//
//  The passive endings of the routine record (F-RoutineRecord-1, site 6). iOS never reports
//  a banner nobody touched, and the arc deliberately owns no timer and no background wake —
//  so "timed out" is DERIVED on read, by the same lifetime rules a live run already obeys,
//  and then written once. The stamp is the moment the lifetime actually lapsed, not the moment
//  somebody happened to open the Journal.
//

import Foundation

enum RoutineRunReconciliation {
    enum Update: Equatable {
        /// An offer nobody opened, past its lifetime.
        case expired(runId: UUID, lapsedAt: Date)
        /// A started run that outlived its window or its day without being ended by anything.
        case ended(runId: UUID, reason: RoutineRunEndReason, lapsedAt: Date)
    }

    /// Everything in `records` that has lapsed and not yet been told so. The LIVE run — the one
    /// the local store still holds — is never touched: the store owns ending it, and a run the
    /// store still considers live is by definition not lapsed. Terminal documents are never
    /// touched twice.
    static func updates(
        records: [RoutineRunRecord], liveRunId: UUID?, now: Date, calendar: Calendar = .current
    ) -> [Update] {
        records.compactMap { record in
            guard record.id != liveRunId else { return nil }
            let lapse = RoutineRunLifecycle.expiry(
                direction: record.direction, startedAt: record.offeredAt, calendar: calendar
            )
            guard now >= lapse else { return nil }
            switch record.phase {
            case .offered:
                return .expired(runId: record.id, lapsedAt: lapse)
            case .started:
                let window = record.offeredAt.addingTimeInterval(RoutineDefaults.departureRunWindow)
                let reason: RoutineRunEndReason =
                    record.direction == .departure && lapse == window ? .windowLapsed : .dayEnded
                return .ended(runId: record.id, reason: reason, lapsedAt: lapse)
            case .dismissed, .expired, .ended:
                return nil
            }
        }
    }

    /// The same transitions applied to the local copies, so the screen is right the moment the
    /// updates are decided rather than after the writes land and the reload returns.
    static func applying(_ updates: [Update], to records: [RoutineRunRecord]) -> [RoutineRunRecord] {
        records.map { record in
            var updated = record
            for update in updates {
                switch update {
                case .expired(let runId, let lapsedAt) where runId == record.id:
                    updated.expired(at: lapsedAt)
                case .ended(let runId, let reason, let lapsedAt) where runId == record.id:
                    updated.ended(at: lapsedAt, reason: reason)
                default:
                    continue
                }
            }
            return updated
        }
    }
}
