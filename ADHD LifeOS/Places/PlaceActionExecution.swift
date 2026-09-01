//
//  PlaceActionExecution.swift
//  ADHD LifeOS
//
//  What a crossing DOES with a place's actions (F-PlaceActions-3-Execution). Pure decisions
//  here; the fan-out lives in `PlaceTriggerEventHandler`, the tap routing in
//  `PlaceActionNotificationRouter` below.
//

import Foundation

/// Which of a place's actions a crossing runs, split by HOW they run.
///
/// The split is iOS's, not ours: a background wake may write data but may not open another app,
/// start a Live Activity, or send a message — so journal lines and captures RUN THEMSELVES,
/// and everything else becomes its own one-tap notification. One tap can only do one thing,
/// which is why externals are one notification EACH rather than one shared nudge.
///
/// `startSprint` is deliberately in the tap set even though the spec block sketched it
/// auto-running: ActivityKit refuses to start a Live Activity from the background, and a sprint
/// silently half-spent before E sits down punishes the arrival it was meant to reward. The tap
/// starts it properly, in the foreground, timer bar and all.
enum PlaceActionPlan {
    static func split(
        _ actions: [PlaceAction]?, for kind: PlaceTriggerEvent.Kind
    ) -> (autoRun: [PlaceAction], external: [PlaceAction]) {
        let matching = (actions ?? []).filter { $0.direction.matches(kind) }
        var autoRun: [PlaceAction] = []
        var external: [PlaceAction] = []
        for action in matching {
            switch action.kind {
            case .journalLine, .createCapture:
                autoRun.append(action)
            case .openApp, .openLink, .openURL, .textContact, .startSprint, .openScreen:
                external.append(action)
            case .unsupported:
                // Holds its fence (the intent came from a newer build) but cannot run here —
                // and must not post a notification whose tap this build couldn't honour.
                break
            }
        }
        return (autoRun, external)
    }
}

extension PlaceActionDirection {
    func matches(_ kind: PlaceTriggerEvent.Kind) -> Bool {
        switch (self, kind) {
        case (.arrival, .arrival), (.departure, .departure): return true
        case (.arrival, .departure), (.departure, .arrival): return false
        }
    }
}

/// The words for what a crossing did or offers — pure, so every phrasing is pinned.
enum PlaceActionNotificationContent {
    /// The one-tap notification for an external action. Title is the action's own name (the
    /// row label the editor already taught E to read); the body says where and what the tap
    /// does — including, for texts, that the final Send stays with E (Apple's floor, said
    /// honestly rather than discovered as a surprise).
    static func external(
        for action: PlaceAction, placeName: String, kind: PlaceTriggerEvent.Kind
    ) -> (title: String, body: String) {
        let moment = kind == .arrival ? "You're at \(placeName)" : "Leaving \(placeName)"
        let tap: String
        switch action.kind {
        case .textContact:
            tap = "tap to fill the message in — sending stays with you."
        case .startSprint:
            tap = "tap to start."
        case .openScreen:
            tap = "tap to go."
        default:
            tap = "tap to open."
        }
        return (title: PlaceActionRowLabel.title(for: action), body: "\(moment) — \(tap)")
    }

    /// What an auto-run action reports on the crossing nudge once it has actually run.
    static func ranLine(for action: PlaceAction) -> String? {
        switch action.kind {
        case .journalLine(let body):
            return "Journaled \u{201C}\(body)\u{201D}"
        case .createCapture(let text):
            return "Captured \u{201C}\(text)\u{201D} to your inbox"
        default:
            return nil
        }
    }

    // MARK: - The wire between a posted notification and its tap

    static let identifierPrefix = "placeAction-"
    static let userInfoKey = "place_action_json"

    static func identifier(for action: PlaceAction) -> String {
        "\(identifierPrefix)\(action.id.uuidString)"
    }

    /// The action rides its own notification as JSON — the tap may land in a cold launch where
    /// no snapshot has been read yet, so the notification must carry everything the tap needs.
    static func userInfo(for action: PlaceAction) -> [String: String]? {
        guard let data = try? JSONEncoder().encode(action),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return [userInfoKey: json]
    }

    static func action(fromUserInfo userInfo: [AnyHashable: Any]) -> PlaceAction? {
        guard let json = userInfo[userInfoKey] as? String,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PlaceAction.self, from: data)
    }
}

/// What a tap on an external action's notification should DO — pure, UIKit-free.
enum PlaceActionTapRoute: Equatable {
    /// Hand this URL to the system: another app's scheme, a web page, or an `sms:` compose.
    case open(URL)
    /// In-app doors, routed through `RootView` like the widget links.
    case goToScreen(PlaceActionScreen)
    case startSprint(minutes: Int?)

    static func route(for action: PlaceAction) -> PlaceActionTapRoute? {
        switch action.kind {
        case .openApp(let scheme, _):
            return URL(string: "\(scheme)://").map { .open($0) }
        case .openLink(_, let link, _):
            return URL(string: link).map { .open($0) }
        case .openURL(let urlString):
            return URL(string: urlString).map { .open($0) }
        case .textContact(_, let phoneNumber, let messageBody):
            return smsURL(phoneNumber: phoneNumber, body: messageBody).map { .open($0) }
        case .startSprint(let minutes):
            return .startSprint(minutes: minutes)
        case .openScreen(let screen):
            return PlaceActionScreen(rawValue: screen).map { .goToScreen($0) }
        case .journalLine, .createCapture, .unsupported:
            // Auto-run kinds never post a tap notification, and an unsupported action from a
            // newer build cannot be honoured — no route, on purpose.
            return nil
        }
    }

    /// `sms:` opens Messages pre-filled — the one compose path that needs no in-app UI. The
    /// number keeps only dialable characters; the body is percent-encoded.
    static func smsURL(phoneNumber: String, body: String) -> URL? {
        let number = phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard !number.isEmpty,
              let encoded = body.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        else { return nil }
        return URL(string: "sms:\(number)&body=\(encoded)")
    }
}

/// The in-app doors a tap can open, drained by `RootView` exactly like the widget links: a tap
/// on a cold launch arrives while auth is still restoring, before the tabs exist, so the router
/// holds it as pending instead of dropping it (`FocusNotificationRouter`'s replay pattern).
enum PlaceActionDoor: Equatable {
    case screen(PlaceActionScreen)
    case sprint(minutes: Int?)
}

/// Routes a tap on a place-action notification. `openURL` is injected so the routing rules are
/// testable without UIKit; `RootView` connects the doors.
@MainActor
final class PlaceActionNotificationRouter {
    static let shared = PlaceActionNotificationRouter()

    private var openDoor: ((PlaceActionDoor) -> Void)?
    private var pendingDoor: PlaceActionDoor?

    func connect(openDoor: @escaping (PlaceActionDoor) -> Void) {
        self.openDoor = openDoor
        guard let pendingDoor else { return }
        self.pendingDoor = nil
        openDoor(pendingDoor)
    }

    /// `true` when the notification was ours — the app delegate's delegate method uses this to
    /// leave every other identifier for the focus router.
    ///
    /// `openURL` receives the words to surface if the open FAILS (an uninstalled app is the
    /// likely cause, and iOS reports it only through `open`'s completion) — silence there would
    /// teach E the whole feature is broken.
    @discardableResult
    func handle(
        notificationIdentifier: String,
        userInfo: [AnyHashable: Any],
        openURL: (URL, _ failureBody: String) -> Void
    ) -> Bool {
        guard notificationIdentifier.hasPrefix(PlaceActionNotificationContent.identifierPrefix)
        else { return false }
        guard let action = PlaceActionNotificationContent.action(fromUserInfo: userInfo),
              let route = PlaceActionTapRoute.route(for: action) else { return true }
        switch route {
        case .open(let url):
            let title = PlaceActionRowLabel.title(for: action)
            openURL(url, "\u{201C}\(title)\u{201D} didn't work — the app may not be installed.")
        case .goToScreen(let screen):
            deliver(.screen(screen))
        case .startSprint(let minutes):
            deliver(.sprint(minutes: minutes))
        }
        return true
    }

    /// Block 4's second way IN: the "Start a sprint" App Intent hands its door here directly —
    /// no notification involved, but the same pending/replay rules apply, because an intent can
    /// be the very thing that cold-launches the app.
    func open(_ door: PlaceActionDoor) {
        deliver(door)
    }

    private func deliver(_ door: PlaceActionDoor) {
        if let openDoor {
            openDoor(door)
        } else {
            pendingDoor = door
        }
    }
}

extension PlaceActionScreen {
    /// The tab this screen token lands on — total over both enums, so a new tab or screen
    /// token cannot be added without deciding its mapping here.
    var appTab: AppTab {
        switch self {
        case .today: return .today
        case .tasks: return .tasks
        case .areas: return .areas
        case .journal: return .journal
        case .captures: return .captures
        }
    }
}

/// The sprint a tapped sprint door starts. Task-less on purpose — the place IS the context —
/// and `nil` minutes resolve to E's default length at TAP time, so a Settings change between
/// configuring the action and arriving is honoured.
enum PlaceActionSprint {
    static func plan(minutes: Int?, defaultMinutes: Int) -> FocusSprintPlan {
        FocusSprintPlan(
            taskId: nil,
            taskTitle: "Focus sprint",
            lifeAreaEmoji: "🎯",
            durationSeconds: (minutes ?? defaultMinutes) * 60,
            nudgeCount: 1
        )
    }
}
