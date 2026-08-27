//
//  CaptureLocationChoice.swift
//  ADHD LifeOS
//

import Foundation

/// The per-capture location switch (E, 2026-08-27).
///
/// It lives in the COMPOSER rather than on a saved capture, deliberately: decided before saving,
/// the coordinate recorded is always the true one. A switch on an existing capture could only ever
/// remove a location — turning it on later would stamp where you are now, not where you were.
enum CaptureLocationChoice {
    /// What the composer opens with: the global Settings toggle, overridden to off when the app
    /// has no permission — a control defaulting to on while promising something it cannot deliver
    /// is worse than no control.
    static func defaultValue(
        globalEnabled: Bool,
        authorization: LocationAuthorizationState
    ) -> Bool {
        guard authorization.allowsTagging else { return false }
        return globalEnabled
    }

    /// Whether to show the switch at all. Permission is the only condition — NOT the global
    /// setting, because the override has to work in both directions: with tagging globally off,
    /// E can still opt a single capture in.
    static func isAvailable(authorization: LocationAuthorizationState) -> Bool {
        authorization.allowsTagging
    }
}

/// What a capture row says about where it happened.
enum CapturePlaceLabel {
    /// `nil` unless the capture landed inside a NAMED place.
    ///
    /// E's call, and it suits the list: a bare coordinate means little at a glance, and most
    /// captures happen away from a saved place — a line on every row would be noise in something
    /// that exists to be scanned. A dangling id (place deleted since) also reads as no label
    /// rather than a raw UUID.
    ///
    /// Resolved through the place's CURRENT record, so renaming a place updates every row that
    /// references it. That is the whole reason the id is stored rather than the name.
    static func label(for capture: Capture, places: [Place]) -> String? {
        guard let placeId = capture.placeId,
              let place = places.first(where: { $0.id == placeId }) else { return nil }
        guard let emoji = place.emoji, !emoji.isEmpty else { return place.name }
        return "\(emoji) \(place.name)"
    }
}
