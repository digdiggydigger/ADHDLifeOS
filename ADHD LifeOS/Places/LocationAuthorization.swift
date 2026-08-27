//
//  LocationAuthorization.swift
//  ADHD LifeOS
//

import CoreLocation
import Foundation

/// What the app is allowed to do with location, and what it should ask for next.
///
/// The whole point of naming this separately from `CLAuthorizationStatus` is that E's two
/// requirements need DIFFERENT grants, and mixing them up fails silently:
/// - tagging where something happened works on When In Use;
/// - arrival triggering needs Always — both the geofences and the significant-change fallback
///   stop delivering in the background without it, with no error and no callback to notice.
enum LocationAuthorizationState: CaseIterable, Equatable, Sendable {
    case notDetermined
    case denied
    case restricted
    case whenInUse
    case always

    init(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .restricted: self = .restricted
        case .authorizedWhenInUse: self = .whenInUse
        case .authorizedAlways: self = .always
        @unknown default: self = .notDetermined
        }
    }

    /// Recording where a capture/log/task/sprint happened. Foreground is enough.
    var allowsTagging: Bool {
        self == .whenInUse || self == .always
    }

    /// Registering geofences that can actually fire while the app is backgrounded or terminated.
    /// When In Use is NOT enough — regions registered under it deliver only in the foreground,
    /// which defeats the point of an arrival trigger.
    var allowsTriggering: Bool {
        self == .always
    }

    /// The significant-change fallback rides the same grant as the geofences it backstops.
    var allowsBackgroundWake: Bool {
        allowsTriggering
    }

    /// Only Settings can undo these — re-prompting does nothing.
    var requiresSettingsTrip: Bool {
        self == .denied || self == .restricted
    }

    /// What to ask for next, or `nil` when there is nothing left to ask.
    ///
    /// Never asks for Always up front: iOS shows a weaker prompt for a cold Always request and
    /// users decline it markedly more often. The supported path is When In Use first, then
    /// escalate once the feature is actually being used — so the escalation is only offered when
    /// triggering is wanted at all.
    func nextRequest(wantsTriggering: Bool) -> LocationAuthorizationRequest? {
        switch self {
        case .notDetermined:
            return .whenInUse
        case .whenInUse:
            return wantsTriggering ? .always : nil
        case .always, .denied, .restricted:
            return nil
        }
    }
}

/// The two prompts the app can raise, in the order iOS supports raising them.
enum LocationAuthorizationRequest: Equatable, Sendable {
    case whenInUse
    case always
}
