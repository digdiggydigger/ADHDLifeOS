//
//  CaptureLocationStamp.swift
//  ADHD LifeOS
//

import Foundation

/// The production "where am I" used by capture creation: fetch the named places, take one fix,
/// resolve which place it fell inside.
///
/// A free function rather than an injected object because the alternative was threading a stamper
/// AND a places client through `CaptureInboxService`'s constructor and every preview that builds
/// one. Callers that need determinism pass their own closure instead.
///
/// Every failure path returns `nil`, deliberately and quietly. A capture is never blocked, delayed
/// past its fix timeout, or failed because location was unavailable — the stamp is a bonus.
@MainActor
enum CaptureLocationStamp {
    /// `stamper` is built inside the body rather than as a default argument: `LocationStamping`
    /// is `@MainActor`, and a default argument is evaluated in a nonisolated context.
    static func current(
        places: PlacesClientAdapting = FirebasePlacesClientAdapter(),
        stamper: LocationStamping? = nil
    ) async -> LocationStamp? {
        // Cheapest gate first: with tagging off or permission absent there is no reason to spend
        // a Firestore read on the places list at all.
        guard AppFeedback.locationTaggingEnabled(),
              CoreLocationFixProvider.shared.authorizationState.allowsTagging else { return nil }
        let known = (try? await places.fetchPlaces()) ?? []
        let resolved = stamper ?? LocationStamping(provider: CoreLocationFixProvider.shared)
        return await resolved.stamp(against: known)
    }
}
