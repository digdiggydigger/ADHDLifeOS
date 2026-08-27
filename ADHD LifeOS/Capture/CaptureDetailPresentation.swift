//
//  CaptureDetailPresentation.swift
//  ADHD LifeOS
//

import Foundation

/// Pure presentation logic for the full-screen capture detail (design frame B6), sibling of
/// `CaptureRowPresentation`: what strings the screen shows, never how they are laid out. The
/// title and notes themselves reuse `CaptureRowPresentation.primaryText`/`secondaryText`, so the
/// detail can never disagree with the row that opened it.
enum CaptureDetailPresentation {
    /// The detail card's headline. Voice captures stop borrowing their TRANSCRIPT as a title —
    /// with no explicit title they read "Voice note", and the transcript gets its own labelled
    /// block below (E's review directive, 2026-08-25).
    static func headline(for capture: Capture) -> String {
        if capture.kind == .voice,
           capture.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            return "Voice note"
        }
        return CaptureRowPresentation.primaryText(for: capture)
    }

    /// The full transcription, voice captures only — `content` IS the transcript there
    /// (an empty transcription is rejected at creation, so this is never a hollow block).
    static func transcript(for capture: Capture) -> String? {
        guard capture.kind == .voice else { return nil }
        let trimmed = capture.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The nav bar's principal label — the capture's kind, worn as identity ("🌐 Link"), matching
    /// the B6 frame. Exhaustive so a sixth kind fails the build here rather than shipping a blank
    /// bar. `.task` has no mockup frame; it follows the same emoji-plus-name pattern.
    static func navTitle(for kind: CaptureKind) -> String {
        switch kind {
        case .note: return "📝 Note"
        case .task: return "✅ Task"
        case .link: return "🌐 Link"
        case .voice: return "🗣️ Voice"
        case .photo: return "📸 Photo"
        }
    }

    /// "14 August 2026 at 07:33" — absolute, unlike the row's relative caption, because a detail
    /// screen (and especially the Captures archive) gets read long after "2 hr ago" stops meaning
    /// anything. Locale and zone injectable so tests don't depend on the machine running them.
    static func timestamp(
        for date: Date,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        date.formatted(Date.FormatStyle(date: .long, time: .shortened, locale: locale, timeZone: timeZone))
    }

    /// Whether this screen's **Sorted** button can fire — the same requirement the triage card
    /// puts on its own Sorted button, delegated rather than restated.
    ///
    /// This screen used to carry an `archivebox` button that called `markSeen` outright: one tap,
    /// no life area, straight into the slice the app calls **Sorted** (the audit's A3). A capture
    /// could therefore be "sorted" having never been sorted anywhere, and the rule E set in round
    /// 1 — dealt with always also means "and I know where it lives" — held on exactly one of the
    /// two paths into that state. Delegating to `CaptureTriage.canSort` is the point: two copies
    /// of the rule is how they drifted apart the first time.
    static func canSort(selectedLifeAreaId: UUID?) -> Bool {
        CaptureTriage.canSort(area: selectedLifeAreaId)
    }

    /// What the Sorted button promises, or what it is still waiting for. A disabled control that
    /// never names what is missing is the dead end the triage card's own button had before it
    /// learned to light up only when ready.
    static func sortHint(canSort: Bool) -> String {
        canSort
            ? "Files this capture in the chosen area and clears it from your inbox."
            : "Choose a life area above first."
    }

    /// Whether the overflow menu offers "Move back to Inbox". Seen alone is not enough: a
    /// capture archived and LATER promoted is `processed`, and the Inbox query (`processed ==
    /// false`) can never show it again — offering the action there wrote `seen = false`, changed
    /// nothing the user could see, and wrongly removed the row from the Promoted list (found
    /// on-device, 2026-08-24).
    static func canReturnToInbox(_ capture: Capture) -> Bool {
        capture.seen == true && !capture.processed
    }

    /// The link the capture points at, preferring the unfurl's canonical URL over the raw captured
    /// string — the preview is what the server resolved the link TO, redirects followed.
    static func sourceURL(for capture: Capture) -> URL? {
        guard capture.kind == .link else { return nil }
        let raw = (capture.linkPreview?.url ?? capture.content)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // `URL(string:)` accepts nearly anything; only a parse that yields a host counts as a
        // source worth naming.
        guard let url = URL(string: raw), url.host != nil else { return nil }
        return url
    }

    /// The accent-coloured source line under a link capture's title ("swiftpackageindex.com"),
    /// "www." stripped the way every browser's address bar does.
    static func sourceDomain(for capture: Capture) -> String? {
        guard let host = sourceURL(for: capture)?.host else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst("www.".count)) : host
    }
}
