//
//  NotificationPermissionState.swift
//  ADHD LifeOS
//

import SwiftUI
import UserNotifications

/// Pure, unit-testable mapping of iOS notification authorization into a user-facing state for the
/// Settings → Notifications section. This decides *what label / glyph / tint* the row shows, never
/// how it is laid out, mirroring the `CaptureRowPresentation` presentation-seam precedent.
///
/// `.unknown` is the pre-read loading state the view holds before its `.task` completes — it is
/// deliberately NOT produced by `init(authorizationStatus:)`, so the row never flashes a wrong
/// value (e.g. "Allowed") before the real status is read.
enum NotificationPermissionState: Equatable {
    /// Status has not been read yet (view just appeared). Loading, not a real iOS status.
    case unknown
    case authorized
    case provisional
    case ephemeral
    case notDetermined
    case denied

    /// Maps a live `UNAuthorizationStatus` into a display state. `UNAuthorizationStatus` is a
    /// non-frozen system enum, so Swift cannot turn a future SDK case into a compile error here —
    /// `@unknown default` is the only tool available and is mapped conservatively to `.denied`
    /// (never optimistically to an "Allowed" variant), so an unrecognised future status errs
    /// toward "check your Settings" rather than silently claiming permission was granted.
    init(authorizationStatus: UNAuthorizationStatus) {
        switch authorizationStatus {
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        case .ephemeral: self = .ephemeral
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        @unknown default: self = .denied
        }
    }

    /// User-facing status label. Exhaustive switch over this app's own enum with **no `default:`**,
    /// so adding a state fails the build loudly rather than shipping a missing label — the
    /// `CaptureRowPresentation` glyph-switch guarantee.
    var displayText: String {
        switch self {
        case .unknown: return "Checking…"
        case .authorized: return "Allowed"
        case .provisional: return "Allowed (Quiet)"
        case .ephemeral: return "Allowed (Temporary)"
        case .notDetermined: return "Not requested yet"
        case .denied: return "Turned off"
        }
    }

    /// SF Symbol shown alongside the label. Exhaustive, no `default:` (see `displayText`).
    var iconSystemImageName: String {
        switch self {
        case .unknown: return "clock"
        case .authorized: return "checkmark.circle.fill"
        case .provisional: return "checkmark.circle"
        case .ephemeral: return "checkmark.circle"
        case .notDetermined: return "questionmark.circle"
        case .denied: return "xmark.circle.fill"
        }
    }

    /// Semantic tint for the status label/glyph. Uses adaptive system colours (`.green`/`.orange`/
    /// `.red`/`.secondary`) — never a hardcoded hex — per `CLAUDE.md` §4. Exhaustive, no `default:`.
    var tint: Color {
        switch self {
        case .unknown: return .secondary
        case .authorized, .provisional, .ephemeral: return .green
        case .notDetermined: return .orange
        case .denied: return .red
        }
    }
}
