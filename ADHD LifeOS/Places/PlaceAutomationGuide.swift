//
//  PlaceAutomationGuide.swift
//  ADHD LifeOS
//

import Foundation

/// The "Make this automatic" walkthrough (F-PlaceActions-4-Shortcuts): the step-by-step that
/// walks E into Apple's Shortcuts app, where "arrive → open app / send text" can genuinely run
/// zero-touch on Apple's own location automations. Apple allows NO programmatic creation of
/// automations, so a guide is the honest ceiling — and because the guide IS the feature, its
/// words are pinned by tests like any other behaviour.
struct PlaceAutomationGuide: Equatable {
    let title: String
    let intro: String
    let steps: [String]
    let afterword: String

    /// Opening Apple's app is the one step we CAN take for E.
    static let shortcutsAppURLString = "shortcuts://"

    /// `nil` for a kind Shortcuts cannot automate: journal lines and captures already run
    /// zero-touch on OUR fences, no Shortcuts action can reach one screen inside this app, and
    /// an unsupported action is a promise this build cannot read, let alone teach. Overpromising
    /// here would burn trust in the whole walkthrough.
    static func make(for action: PlaceAction, placeName: String) -> PlaceAutomationGuide? {
        guard let actionStep = actionStep(for: action.kind) else { return nil }
        let trimmedName = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedName.isEmpty ? "this place" : trimmedName
        let crossing = action.direction == .arrival ? "Arrive" : "Leave"
        return PlaceAutomationGuide(
            title: "Make \u{201C}\(PlaceActionRowLabel.title(for: action))\u{201D} automatic",
            intro: "Apple doesn't let any app build an automation for you, so every step here "
                + "is yours to tap. There are only a few — and once it's set up, this runs "
                + "with no taps at all.",
            steps: [
                "In Shortcuts, open the Automation tab and tap +.",
                "Choose \u{201C}\(crossing)\u{201D}, and set the location to \(name).",
                "Pick \u{201C}Run Immediately\u{201D}, so it doesn't ask you first each time.",
                actionStep
            ],
            afterword: "Once the automation is running, you can delete this action here — "
                + "otherwise you'll keep getting its one-tap notification as well."
        )
    }

    private static func actionStep(for kind: PlaceAction.Kind) -> String? {
        switch kind {
        case .openApp(_, let displayName):
            return "Add the \u{201C}Open App\u{201D} action and choose \(displayName)."
        case .openURL(let urlString):
            return "Add the \u{201C}Open URLs\u{201D} action and enter \(urlString)."
        case .textContact(let contactName, _, let messageBody):
            return "Add the \u{201C}Send Message\u{201D} action, send it to \(contactName), "
                + "and type the message: \u{201C}\(messageBody)\u{201D}."
        case .startSprint(let minutes):
            let length = minutes.map { "set Minutes to \($0)" }
                ?? "leave Minutes empty to use your default length"
            return "Add ADHD LifeOS's \u{201C}Start a sprint\u{201D} action and \(length) — "
                + "it opens the app to run the timer."
        case .createCapture, .journalLine, .openScreen, .unsupported:
            return nil
        }
    }
}
