//
//  LifeOSAppIntents.swift
//  ADHD LifeOS
//
//  The Shortcuts-facing layer (F-PlaceActions-4-Shortcuts): the in-app actions as App Intents,
//  so Apple's own location automations can drive them ZERO-touch — the half of "arrive → things
//  happen" that iOS reserves for itself. These structs are system-instantiated glue over the
//  tested seams (`ShortcutIntentRunner`, `PlaceActionNotificationRouter`), the same thin-glue
//  discipline as the notification delegate.
//
//  iOS floor check (app target is 16.0): `AppIntent`, `@Parameter`, `IntentDialog`,
//  `ParameterSummary` and `openAppWhenRun` are all iOS 16.0. `AppShortcutsProvider` is 16.0 but
//  the `shortTitle:systemImageName:` AppShortcut initialiser is 16.4 — hence the gate below;
//  on 16.0–16.3 the intents still appear in the Shortcuts action library, they just aren't
//  surfaced as ready-made App Shortcuts.
//

import AppIntents

/// A refusal travels to Shortcuts as a thrown error — that is what an automation surfaces to
/// the user, and what a "Stop and output" step can branch on.
enum ShortcutIntentError: Error, CustomLocalizedStringResourceConvertible {
    case message(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .message(let text): return "\(text)"
        }
    }
}

private func dialog(for outcome: ShortcutIntentOutcome) throws -> IntentDialog {
    switch outcome {
    case .saved(let confirmation):
        return IntentDialog("\(confirmation)")
    case .rejected(let reason):
        throw ShortcutIntentError.message(reason)
    }
}

struct CaptureNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a note"
    static var description = IntentDescription(
        "Drops a note into your capture inbox — stamped with where you are, if location tagging is on."
    )

    @Parameter(title: "Note")
    var note: String

    static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$note)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: try dialog(for: await ShortcutIntentRunner().captureNote(note)))
    }
}

struct LogJournalLineIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a journal line"
    static var description = IntentDescription(
        "Writes a line into your journal timeline — stamped with where you are, if location tagging is on."
    )

    @Parameter(title: "Line")
    var line: String

    static var parameterSummary: some ParameterSummary {
        Summary("Journal \(\.$line)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: try dialog(for: await ShortcutIntentRunner().journalLine(line)))
    }
}

/// Opens the app and starts the sprint there — deliberately, not apologetically: ActivityKit
/// refuses to start a Live Activity from the background (the block-3 precedent), and a sprint
/// belongs in the foreground with its timer bar anyway. The door rides the same pending/replay
/// router as a notification tap, so an intent that cold-launches the app still lands.
struct StartSprintIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a sprint"
    static var description = IntentDescription(
        "Opens the app and starts a focus sprint. Leave Minutes empty to use your default length."
    )
    static var openAppWhenRun = true

    @Parameter(title: "Minutes")
    var minutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Start a sprint of \(\.$minutes) minutes")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        PlaceActionNotificationRouter.shared.open(.sprint(minutes: minutes))
        return .result()
    }
}

/// Ready-made App Shortcuts, so the three intents show up under the app in Shortcuts (and to
/// Siri) with zero setup.
@available(iOS 16.4, *)
struct LifeOSAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureNoteIntent(),
            phrases: ["Capture a note in \(.applicationName)"],
            shortTitle: "Capture a note",
            systemImageName: "tray.and.arrow.down.fill"
        )
        AppShortcut(
            intent: LogJournalLineIntent(),
            phrases: ["Log a journal line in \(.applicationName)"],
            shortTitle: "Log a journal line",
            systemImageName: "book.fill"
        )
        AppShortcut(
            intent: StartSprintIntent(),
            phrases: ["Start a sprint in \(.applicationName)"],
            shortTitle: "Start a sprint",
            systemImageName: "timer"
        )
    }
}
