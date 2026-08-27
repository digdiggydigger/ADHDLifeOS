//
//  CaptureInboxService+Create.swift
//  ADHD LifeOS
//
//  The create path, in its own file so `CaptureInboxService` stays inside its length budgets —
//  the same arrangement as `+Triage`, `+Tags` and `+Media`. Everything it touches is already
//  internal rather than private for exactly this reason.
//

import Foundation

@MainActor
extension CaptureInboxService {
    @discardableResult
    func createCapture() async -> Bool {
        createCaptureErrorMessage = nil

        let normalized: NormalizedCreateCaptureInput
        switch CaptureValidation.normalizeCreateCaptureInput(
            content: content, kind: kind, lifeAreaId: newCaptureLifeAreaId
        ) {
        case .success(let value):
            normalized = value
        case .failure(let error):
            createCaptureErrorMessage = error.errorDescription
            return false
        }

        isSubmittingCapture = true
        defer { isSubmittingCapture = false }

        // Stamped here, after validation and before the write: a fix that never arrives must
        // never be the reason a thought doesn't get written down, so this can only ever ADD a
        // field — it has no failure path back to the caller.
        var stamped = normalized
        // The per-capture switch is the enabled-gate. Off means no fix is even requested.
        stamped.locationStamp = attachLocation ? await locationStamp() : nil

        do {
            let created = try await client.createCapture(stamped)
            await attachDraftTags(to: created)
            content = ""
            kind = CaptureValidation.defaultKind
            newCaptureLifeAreaId = nil
            // A one-off override must not outlive its capture.
            resetLocationChoice()
            return true
        } catch {
            createCaptureErrorMessage = Self.message(for: error)
            return false
        }
    }
}
