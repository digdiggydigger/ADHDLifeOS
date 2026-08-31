//
//  ShortcutIntentRunner.swift
//  ADHD LifeOS
//

import Foundation

/// What running one of our App Intents answers back to Shortcuts. Both cases carry their words:
/// an automation is exactly where a silent failure would go unnoticed for weeks.
enum ShortcutIntentOutcome: Equatable {
    case saved(confirmation: String)
    case rejected(reason: String)
}

/// The work behind the "Capture a note" and "Log a journal line" App Intents
/// (F-PlaceActions-4-Shortcuts). The intent structs are system-instantiated glue, so everything
/// decidable lives here behind injected writers — the `PlaceTriggerEventHandler` arrangement,
/// and the same no-screen discipline: a Shortcuts automation may run these in a background
/// launch where no UI ever mounts.
struct ShortcutIntentRunner {
    private let journalWriter: (NormalizedCreateLogInput) async -> Bool
    private let captureWriter: (NormalizedCreateCaptureInput) async -> Bool
    /// `RecordLocationStamp` in production — the global-toggle-gated, no-per-record-switch path,
    /// because an intent has no composer to carry a per-record switch.
    private let locationStamp: () async -> LocationStamp?

    init(
        journalWriter: ((NormalizedCreateLogInput) async -> Bool)? = nil,
        captureWriter: ((NormalizedCreateCaptureInput) async -> Bool)? = nil,
        locationStamp: (() async -> LocationStamp?)? = nil
    ) {
        self.journalWriter = journalWriter ?? { input in
            (try? await FirebaseJournalClientAdapter().createLog(input)) != nil
        }
        self.captureWriter = captureWriter ?? { input in
            (try? await FirebaseCaptureClientAdapter().createCapture(input)) != nil
        }
        self.locationStamp = locationStamp ?? { await RecordLocationStamp.current() }
    }

    func captureNote(_ text: String) async -> ShortcutIntentOutcome {
        // The refusal comes before any work — no location fix is burned on an empty note.
        guard case .success(var input) = CaptureValidation.normalizeCreateCaptureInput(
            content: text, kind: .note
        ) else {
            return .rejected(reason: "The note was empty, so nothing was captured.")
        }
        input.locationStamp = await locationStamp()
        guard await captureWriter(input) else { return .rejected(reason: Self.failedWrite) }
        DataChangeSignal.post()
        return .saved(confirmation: "Captured \u{201C}\(input.content)\u{201D} to your inbox.")
    }

    func journalLine(_ line: String) async -> ShortcutIntentOutcome {
        guard case .success(var input) = LogValidation.normalizeCreateLogInput(
            body: line, type: .log, lifeAreaId: nil
        ) else {
            return .rejected(reason: "The line was empty, so nothing was journaled.")
        }
        input.locationStamp = await locationStamp()
        guard await journalWriter(input) else { return .rejected(reason: Self.failedWrite) }
        DataChangeSignal.post()
        return .saved(confirmation: "Journaled \u{201C}\(input.body)\u{201D}.")
    }

    /// One honest sentence for the only failure Shortcuts can meet past validation: the write
    /// didn't land, and being signed out or offline are the two causes E can actually fix.
    private static let failedWrite = "That didn't save — check you're signed in and online."
}
