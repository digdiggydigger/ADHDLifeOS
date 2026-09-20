//
//  ComposerDraftFiling.swift
//  ADHD LifeOS
//
//  `F-C2-DraftsToInbox`: what a composer closed on typed text does with it.
//
//  E, round 2: *"Unsent text → 'Inbox catches it'. A composer closed with text files it into the
//  Capture Inbox as a note. A bar, 'Kept in your inbox · Reopen', stays until the next action."*
//  Q4 (opener): *"When a composer containing typed text is swiped down, silently save as a draft /
//  quick capture item in the background — never block with a modal and never lose user input."*
//
//  **One rule for three composers, and that is the point.** Quick Capture, the task composer and
//  the journal composer each close in their own way and hold their text in their own place; if
//  each decided for itself what counts as "text worth keeping", they would drift apart the first
//  time one of them changed. The decision lives here, pure and tested; the three call it.
//

import Foundation

enum ComposerDraftFiling {
    /// How much of a draft the capsule names.
    ///
    /// **VoiceOver is what sets this, not the drawing.** The capsule's subject is `lineLimit(1)`
    /// and truncates on screen by itself, but `RecentAction.accessibilityAnnouncement` SPEAKS the
    /// subject whole — and the journal composer is the one whose text runs to paragraphs. Without
    /// a cut, filing a long entry would read the paragraph aloud as an interruption.
    static let subjectLimit = 80

    /// Whether closing a composer on this text should file it rather than discard it.
    ///
    /// **Whitespace is not text.** A stray space is an untouched composer as far as the user is
    /// concerned, and `CaptureValidation` would refuse it anyway — deciding here means no doomed
    /// write whose error would have to be swallowed silently.
    static func shouldFile(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// What the capsule says it kept: the draft's first non-empty line, trimmed, cut at
    /// `subjectLimit`.
    ///
    /// The FIRST LINE rather than the first N characters, because the capsule draws one line and a
    /// character count would cut mid-sentence where a line break is the author's own boundary.
    static func subject(for text: String) -> String {
        let firstLine = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty }) ?? ""

        guard firstLine.count > subjectLimit else { return firstLine }
        return String(firstLine.prefix(subjectLimit - 1)) + "…"
    }
}

/// Files a composer's unsent text and offers the way back to it.
///
/// **A value the composer builds, not a service it holds.** Each composer already owns its own
/// service for the thing it was actually for; this is one call on the way out, so it takes its
/// three collaborators at the call site and keeps no state. That also means a test can drive it
/// with a recording fake and no view at all — which matters, because every one of its call sites
/// is inside a `.onDisappear` that nothing can reach.
@MainActor
struct ComposerDraftFiler {
    let client: any CaptureClientAdapting
    let record: any RecentActionRecording
    /// Takes the user to a capture in the inbox — E's Step 0 answer 1, *"Open it in the inbox"*.
    let openCapture: (UUID) -> Void

    /// Files `text` as a `.note` capture and offers "Kept in your inbox · Reopen".
    ///
    /// Returns whether anything was filed, so a caller that must clear its own field afterwards
    /// (the journal composer, whose text outlives its view) knows whether the words are safe
    /// somewhere else first.
    ///
    /// **A failed write records NOTHING, and that is the important half.** The one outcome worse
    /// than the silent discard this block replaces is a capsule reading "Kept in your inbox" over
    /// text that was never written: the user stops worrying and the words are gone. Failing quietly
    /// leaves the composer's own text where it was.
    @discardableResult
    func fileIfNeeded(_ text: String) async -> Bool {
        guard ComposerDraftFiling.shouldFile(text) else { return false }

        let normalized: NormalizedCreateCaptureInput
        switch CaptureValidation.normalizeCreateCaptureInput(
            content: text, kind: .note
        ) {
        case .success(let value):
            normalized = value
        case .failure:
            return false
        }

        guard let capture = try? await client.createCapture(normalized) else { return false }

        let openCapture = openCapture
        record.record(
            RecentAction(
                kind: .draftKeptInInbox,
                subject: ComposerDraftFiling.subject(for: text),
                undo: {
                    openCapture(capture.id)
                    return true
                }
            )
        )
        return true
    }
}
