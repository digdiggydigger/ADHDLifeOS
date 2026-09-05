//
//  PlaceAutoRunExecutor.swift
//  ADHD LifeOS
//
//  The auto-run write, extracted (Block A). It used to be a private method on
//  `PlaceTriggerEventHandler`, which was right while a crossing was the only thing that ever
//  ran an auto step. Deferred logging gives it a SECOND caller — the notification tap — and a
//  copy of this logic in the activator is exactly how the two paths would drift apart on the
//  next change to stamping or validation.
//

import Foundation

/// Runs one auto-run action (a journal line, a capture) and reports whether the write landed.
///
/// The writers are closures for the `locationStamp` reason the handler already documented: the
/// defaults do the real Firestore work, a test hands over recorders, and the unit-test target
/// never has to reach a Firebase symbol to exercise the decision around them.
struct PlaceAutoRunExecutor {
    let journalWriter: (NormalizedCreateLogInput) async -> Bool
    let captureWriter: (NormalizedCreateCaptureInput) async -> Bool

    /// The production wiring. Built lazily inside the closures on purpose — constructing the
    /// adapters eagerly would touch the Firebase SDK the moment anything made an executor.
    static func live() -> PlaceAutoRunExecutor {
        PlaceAutoRunExecutor(
            journalWriter: { input in
                (try? await FirebaseJournalClientAdapter().createLog(input)) != nil
            },
            captureWriter: { input in
                (try? await FirebaseCaptureClientAdapter().createCapture(input)) != nil
            }
        )
    }

    /// `false` — a failed write, or a kind that cannot auto-run — reports nothing and consumes
    /// nothing: the caller's cooldown stays unspent so the next crossing gets its retry.
    func run(_ action: PlaceAction, stamp: LocationStamp?) async -> Bool {
        switch action.kind {
        case .journalLine(let body):
            guard case .success(var input) = LogValidation.normalizeCreateLogInput(
                body: body, type: .log, lifeAreaId: nil
            ) else { return false }
            input.locationStamp = stamp
            return await journalWriter(input)
        case .createCapture(let text):
            guard case .success(var input) = CaptureValidation.normalizeCreateCaptureInput(
                content: text, kind: .note
            ) else { return false }
            input.locationStamp = stamp
            return await captureWriter(input)
        default:
            return false
        }
    }
}

/// The stamp an auto-run write carries: the PLACE itself, not a live fix. The crossing is the
/// evidence the user is here, so a background wake never asks for one — and a tap minutes later
/// is stamped with where the routine started rather than where the phone happens to be now.
enum PlaceAutoRunStamp {
    static func make(entry: AtPlaceSnapshot.PlaceEntry?, placeId: UUID) -> LocationStamp? {
        guard let entry, let latitude = entry.latitude, let longitude = entry.longitude else {
            return nil
        }
        return LocationStamp(
            coordinate: PlaceCoordinate(latitude: latitude, longitude: longitude),
            placeId: placeId
        )
    }
}
