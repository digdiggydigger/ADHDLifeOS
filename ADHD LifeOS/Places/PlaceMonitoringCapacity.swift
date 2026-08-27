//
//  PlaceMonitoringCapacity.swift
//  ADHD LifeOS
//

import Foundation

/// How many places exist, against how many iOS will actually watch.
///
/// This exists to make an INVISIBLE failure visible. iOS monitors at most 20 regions per app and
/// enforces it silently — define a 21st place and one of them simply stops triggering, with no
/// error, no callback and nothing on screen. Without this line the only way to find the cap is to
/// notice a nudge that never arrived, which is exactly the kind of thing this app should not do
/// to someone.
///
/// Over the cap is not a fault, and the copy says so: `PlaceGeometry.placesToMonitor` keeps the
/// nearest 20 and re-picks on every significant-change wake, so the extra places aren't broken —
/// they're just not the ones being watched from here.
enum PlaceMonitoringCapacity {
    /// One source of truth with the selection itself; a counter that disagreed would be a lie.
    static var limit: Int { PlaceGeometry.regionMonitoringLimit }

    static func isOverCapacity(placeCount: Int) -> Bool {
        placeCount > limit
    }

    static func remaining(placeCount: Int) -> Int {
        max(0, limit - max(0, placeCount))
    }

    static func summary(placeCount: Int) -> String {
        if placeCount > limit {
            return "\(placeCount) places — iOS watches the \(limit) nearest you"
        }
        if placeCount == limit {
            return "\(limit) of \(limit) places — that's the limit"
        }
        return "\(placeCount) of \(limit) places"
    }

    /// `nil` when there is nothing worth saying — an empty list already says "No places yet", and
    /// "0 of 20" beneath it is noise at the moment E has nothing to reason about.
    static func summaryIfWorthShowing(placeCount: Int) -> String? {
        guard placeCount > 0 else { return nil }
        return summary(placeCount: placeCount)
    }
}
