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
        // Permission only. The ENABLED gate lives with the caller now: `CaptureInboxService` holds
        // a per-capture flag seeded from the global setting, and re-checking the global here would
        // veto an explicit per-capture opt-in — which is exactly what the override exists to allow.
        guard CoreLocationFixProvider.shared.authorizationState.allowsTagging else { return nil }
        let known = (try? await places.fetchPlaces()) ?? []
        let resolved = stamper ?? LocationStamping(provider: CoreLocationFixProvider.shared)
        return await resolved.stamp(against: known)
    }
}
