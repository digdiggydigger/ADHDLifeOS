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

    /// The human-readable kind name shown in the caption line, preserving the prior on-screen
    /// wording exactly (`kind.rawValue.capitalized`).
    static func kindLabel(for kind: CaptureKind) -> String {
        kind.rawValue.capitalized
    }

    private static func isNonEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
