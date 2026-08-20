//
//  CaptureRowPresentation.swift
//  ADHD LifeOS
//

import Foundation

/// Pure, unit-testable presentation logic for a single collapsed Inbox row. No SwiftUI import:
/// this decides *what strings/glyphs* a `CaptureRowView` shows, never *how* they are laid out.
///
/// The `primaryText` resolution order deliberately mirrors the existing precedent in
/// `CaptureInboxService.taskTitle(for:)` (link-preview title preference, `"Photo capture"`
/// fallback) so the collapsed row and the promoted task read consistently. The two are kept in
/// sync by hand — this does not call into `taskTitle(for:)`, which owns a different job.
enum CaptureRowPresentation {

    /// The single line shown as a collapsed row's primary text. Resolution order — first value
    /// that is non-empty after trimming whitespace/newlines wins:
    /// (a) `capture.title`; (b) for `.link` only, `capture.linkPreview?.title`; (c) `capture.content`;
    /// (d) final fallback — `"Photo capture"` for `.photo`, otherwise `"Untitled capture"`.
    static func primaryText(for capture: Capture) -> String {
        if let title = capture.title, isNonEmpty(title) {
            return title
        }
        if capture.kind == .link, let previewTitle = capture.linkPreview?.title, isNonEmpty(previewTitle) {
            return previewTitle
        }
        if isNonEmpty(capture.content) {
            return capture.content
        }
        return capture.kind == .photo ? "Photo capture" : "Untitled capture"
    }

    /// The SF Symbol shown in a text/placeholder row's 44×44 leading slot. Exhaustive switch, no
    /// `default`: adding a sixth `CaptureKind` must fail the build loudly rather than silently
    /// falling back to a wrong glyph.
    static func glyphSystemImageName(for kind: CaptureKind) -> String {
        switch kind {
        case .note: return "note.text"
        case .task: return "checkmark.circle"
        case .link: return "link"
        case .photo: return "photo"
        case .voice: return "waveform"
        }
    }

    /// The human-readable kind name shown wherever a kind is named on its own.
    static func kindLabel(for kind: CaptureKind) -> String {
        kind.rawValue.capitalized
    }

    /// The capture's own words, quoted beneath the title — the web card's italic note/transcript
    /// block.
    ///
    /// `nil` when there is nothing to add: either the capture has no content, or `primaryText`
    /// already fell through to that same content because there was no title. Without the second
    /// guard an untitled note printed the identical sentence twice, once as headline and once as
    /// quote.
    static func secondaryText(for capture: Capture) -> String? {
        let trimmed = capture.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != primaryText(for: capture) else { return nil }
        return trimmed
    }

    /// "Captured 14:32 · voice note" — the web's caption, which says WHEN the thought was dumped.
    /// That is the useful fact when scanning a backlog; the previous "Note · 2 minutes ago" led
    /// with the kind, which the glyph beside it already says.
    ///
    /// One deliberate improvement on the web, which prints a bare clock time and is therefore
    /// useless on anything older than today: a capture from another day carries its date too.
    static func caption(for capture: Capture, now: Date = Date(), calendar: Calendar = .current) -> String {
        // Against the CALLER's `now`, not the real clock — an injected `now` that the body then
        // ignored would make this untestable and quietly wrong under a fixed date.
        let when: String = calendar.isDate(capture.createdAt, inSameDayAs: now)
            ? capture.createdAt.formatted(date: .omitted, time: .shortened)
            : capture.createdAt.formatted(date: .abbreviated, time: .shortened)
        return "Captured \(when) · \(kindNoun(for: capture.kind))"
    }

    /// Lower-case, because it sits mid-sentence in the caption.
    ///
    /// The web appends a bare " note" to every kind, which reads "note note" for the commonest kind
    /// of all (seen in-simulator, 2026-08-20). Each kind names itself properly instead: `voice` and
    /// `photo` are adjectives and take the noun, the rest already are nouns.
    private static func kindNoun(for kind: CaptureKind) -> String {
        switch kind {
        case .note: return "note"
        case .task: return "task"
        case .link: return "link"
        case .photo: return "photo note"
        case .voice: return "voice note"
        }
    }

    private static func isNonEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
