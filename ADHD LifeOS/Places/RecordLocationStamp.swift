//
//  RecordLocationStamp.swift
//  ADHD LifeOS
//

import Foundation

/// The production "where am I" for records WITHOUT a per-record switch — journal entries, closed
/// tasks, finished focus sprints (block 3's remainder).
///
/// Captures are the exception, not the rule: their composer carries a per-capture switch, so
/// `CaptureLocationStamp` deliberately leaves the enabled-gate to its caller. Everything else has
/// no such switch, which makes the global Settings toggle the enabled-gate again — checked here,
/// first, because it is the cheapest of the three gates and "off" must not cost a places fetch,
/// let alone a fix request.
///
/// Every failure path returns `nil`, quietly, for the same reason as captures: location is a
/// bonus on a record that already deserves to be written.
@MainActor
enum RecordLocationStamp {
    static func current(
        places: PlacesClientAdapting = FirebasePlacesClientAdapter(),
        stamper: LocationStamping? = nil,
        isEnabled: () -> Bool = { AppFeedback.locationTaggingEnabled() }
    ) async -> LocationStamp? {
        guard isEnabled() else { return nil }
        return await CaptureLocationStamp.current(places: places, stamper: stamper)
    }
}
