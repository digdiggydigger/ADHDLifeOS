//
//  PlaceActionEditing.swift
//  ADHD LifeOS
//

import Foundation

/// Scheme normalization for the "open this app" path. The 10-entry `apps` catalogue that
/// lived here (F-PlaceActions-2-Editor) was superseded by the full searchable directory
/// (`PlaceAppDirectoryBundled`, F-AppDirectory-1) — its ten schemes all live on there, pinned
/// by the bundled sweep's continuity test.
enum PlaceActionCatalog {
    /// What E typed into the custom field, reduced to a bare scheme: trimmed, lowercased, and
    /// stripped of a pasted "://..." tail — "Spotify://" and "spotify://open" both mean
    /// "spotify". `nil` when nothing usable remains.
    static func normalizedScheme(_ raw: String) -> String? {
        var scheme = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let separator = scheme.range(of: "://") {
            scheme = String(scheme[..<separator.lowerBound])
        }
        guard !scheme.isEmpty, scheme.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." })
        else { return nil }
        return scheme
    }
}

/// The in-app destinations an `openScreen` action can land on — the five tabs, by the same
/// tokens `AppTab` spells (block 3's router will map them back). A tab is the honest ceiling
/// for now: deeper destinations (one task, one place) can join the catalogue later without a
/// wire change, because the token is already a free string on the wire.
enum PlaceActionScreen: String, CaseIterable, Equatable, Sendable {
    case today
    case tasks
    case areas
    case journal
    case captures

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .tasks: return "Tasks"
        case .areas: return "Life Areas"
        case .journal: return "Journal"
        case .captures: return "Captures"
        }
    }
}

/// Everything the action editor sheet can hold, kind fields side by side — switching kind must
/// not wipe what E typed under another kind (the composer-type precedent), so all fields
/// coexist and validation reads only the chosen kind's.
struct PlaceActionDraft: Equatable {
    enum KindChoice: String, CaseIterable, Equatable {
        case openApp
        case openURL
        case textContact
        case startSprint
        case createCapture
        case journalLine
        case openScreen

        var displayName: String {
            switch self {
            case .openApp: return "Open an app"
            case .openURL: return "Open a website"
            case .textContact: return "Text someone"
            case .startSprint: return "Start a sprint"
            case .createCapture: return "Capture a note"
            case .journalLine: return "Write a journal line"
            case .openScreen: return "Go to a screen"
            }
        }
    }

    var direction: PlaceActionDirection = .arrival
    var kindChoice: KindChoice = .openApp
    var appScheme = ""
    var appName = ""
    var urlString = ""
    var contactName = ""
    var contactPhone = ""
    var messageBody = ""
    /// Empty means "use the default sprint length" — a valid choice, not a missing one.
    var sprintMinutes = ""
    var captureText = ""
    var journalBody = ""
    var screen: PlaceActionScreen = .today
    /// A newer build's extra fields on the action being edited, carried so the save's rebuild
    /// doesn't strip them (the makePlace rebuild-on-save trap, at the action level). They
    /// re-attach only while the kind stays what it was seeded as — switching kind is E
    /// deliberately replacing the action, and the old kind's future fields don't ride along.
    var extraPayload: [String: PlaceActionValue] = [:]
    var seededKindChoice: KindChoice?

    init() {}

    /// Seeds the sheet from an existing action for editing. `nil` for `.unsupported` — an
    /// action this build cannot represent cannot be edited by it, only kept or deleted.
    init?(editing action: PlaceAction) {
        self.init()
        direction = action.direction
        extraPayload = action.extraPayload
        defer { seededKindChoice = kindChoice }
        switch action.kind {
        case .openApp(let scheme, let displayName):
            kindChoice = .openApp
            appScheme = scheme
            appName = displayName
        case .openURL(let urlString):
            kindChoice = .openURL
            self.urlString = urlString
        case .textContact(let contactName, let phoneNumber, let messageBody):
            kindChoice = .textContact
            self.contactName = contactName
            contactPhone = phoneNumber
            self.messageBody = messageBody
        case .startSprint(let minutes):
            kindChoice = .startSprint
            sprintMinutes = minutes.map(String.init) ?? ""
        case .createCapture(let text):
            kindChoice = .createCapture
            captureText = text
        case .journalLine(let body):
            kindChoice = .journalLine
            journalBody = body
        case .openScreen(let screen):
            kindChoice = .openScreen
            guard let known = PlaceActionScreen(rawValue: screen) else { return nil }
            self.screen = known
        case .unsupported:
            return nil
        }
    }
}

/// Draft → `PlaceAction`, or `nil` when it isn't saveable — the `PlaceEditorValidation` shape.
/// Every text field is trimmed, and trimmed-to-empty is REJECTED rather than saved as "" (the
/// arrivalMessage rule: "" on the wire would count as content and misfire).
enum PlaceActionValidation {
    static func canSave(_ draft: PlaceActionDraft) -> Bool {
        makeAction(from: draft, id: UUID()) != nil
    }

    static func makeAction(from draft: PlaceActionDraft, id: UUID) -> PlaceAction? {
        kind(from: draft).map {
            PlaceAction(
                id: id, direction: draft.direction, kind: $0,
                extraPayload: draft.kindChoice == draft.seededKindChoice ? draft.extraPayload : [:]
            )
        }
    }

    private static func kind(from draft: PlaceActionDraft) -> PlaceAction.Kind? {
        switch draft.kindChoice {
        case .openApp: return openAppKind(from: draft)
        case .openURL: return normalizedWebAddress(draft.urlString).map { .openURL(urlString: $0) }
        case .textContact: return textContactKind(from: draft)
        case .startSprint: return sprintKind(from: draft)
        case .createCapture: return trimmed(draft.captureText).map { .createCapture(text: $0) }
        case .journalLine: return trimmed(draft.journalBody).map { .journalLine(body: $0) }
        case .openScreen: return .openScreen(screen: draft.screen.rawValue)
        }
    }

    private static func openAppKind(from draft: PlaceActionDraft) -> PlaceAction.Kind? {
        guard let scheme = PlaceActionCatalog.normalizedScheme(draft.appScheme) else { return nil }
        return .openApp(scheme: scheme, displayName: trimmed(draft.appName) ?? scheme)
    }

    private static func textContactKind(from draft: PlaceActionDraft) -> PlaceAction.Kind? {
        guard let phone = trimmed(draft.contactPhone),
              phone.contains(where: \.isNumber),
              let body = trimmed(draft.messageBody) else { return nil }
        return .textContact(
            contactName: trimmed(draft.contactName) ?? phone,
            phoneNumber: phone,
            messageBody: body
        )
    }

    private static func sprintKind(from draft: PlaceActionDraft) -> PlaceAction.Kind? {
        guard let raw = trimmed(draft.sprintMinutes) else { return .startSprint(minutes: nil) }
        guard let minutes = Int(raw),
              MomentumPreferences.sprintMinutesRange.contains(minutes) else { return nil }
        return .startSprint(minutes: minutes)
    }

    /// "example.com" is what people type; "https://example.com" is what opens. Anything already
    /// carrying a scheme must be http(s) — an app scheme pasted here belongs in "Open an app",
    /// and letting it through would make two rows that mean the same thing behave differently.
    static func normalizedWebAddress(_ raw: String) -> String? {
        guard var address = trimmed(raw) else { return nil }
        if let separator = address.range(of: "://") {
            let scheme = address[..<separator.lowerBound].lowercased()
            guard scheme == "http" || scheme == "https" else { return nil }
        } else {
            address = "https://" + address
        }
        guard let url = URL(string: address), let host = url.host, !host.isEmpty else { return nil }
        return address
    }

    private static func trimmed(_ raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

/// The list row's words — pure so the honesty rules are pinned: an unsupported action says so
/// out loud instead of rendering as a blank row or being hidden (the dead-shared-component
/// lesson: what E cannot see, E cannot trust).
enum PlaceActionRowLabel {
    static func title(for action: PlaceAction) -> String {
        switch action.kind {
        case .openApp(_, let displayName):
            return "Open \(displayName)"
        case .openURL(let urlString):
            return "Open \(URL(string: urlString)?.host ?? urlString)"
        case .textContact(let contactName, _, _):
            return "Text \(contactName)"
        case .startSprint(let minutes):
            guard let minutes else { return "Start a sprint (default length)" }
            return "Start a \(minutes)-minute sprint"
        case .createCapture(let text):
            return "Capture \u{201C}\(text)\u{201D}"
        case .journalLine(let body):
            return "Journal \u{201C}\(body)\u{201D}"
        case .openScreen(let screen):
            let name = PlaceActionScreen(rawValue: screen)?.displayName ?? screen
            return "Go to \(name)"
        case .unsupported(let rawKind, _):
            return "Unavailable action (\(rawKind))"
        }
    }

    /// The toggles' own words, so the section reads as one voice.
    static func subtitle(for action: PlaceAction) -> String {
        switch action.direction {
        case .arrival: return "On arrival"
        case .departure: return "When leaving"
        }
    }

    /// Only the footnote for an action from a newer build — everything else explains itself.
    static let unsupportedExplainer =
        "Added by a newer version of the app. It's kept safe and will work again after an update."
}
