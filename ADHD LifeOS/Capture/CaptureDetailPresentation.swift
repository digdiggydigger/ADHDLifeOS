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
