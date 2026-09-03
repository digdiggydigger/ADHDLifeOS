//
//  CaptureSearchRefinement.swift
//  ADHD LifeOS
//

import Foundation

/// Search over the capture inbox — `TaskListRefinement`'s shape, deliberately, so the two search
/// fields in this app cannot come to mean different things.
///
/// **It matches what the ROW SHOWS, not what the model stores, and that is the whole design.**
/// A capture may have no title and no content at all — a photo dropped in with nothing typed is
/// the ordinary case, not an edge one — and `CaptureRowPresentation.primaryText` is what decides
/// the words that appear in its place ("Photo capture", "Untitled capture", a link's preview
/// title). Filtering on `title` and `content` would leave those captures **visible in the inbox
/// and impossible to find**, with nothing looking broken.
///
/// That is not hypothetical here. The inbox triage card hand-rolled its own title fallback rather
/// than calling `primaryText`, and photo captures shipped as a BLANK card (`eddef9b`). This is the
/// same defect one turn quieter, so the fix is the same: go through the presentation rule.
///
/// The contract, in one line: **you can find what you can see.**
enum CaptureSearchRefinement {

    /// Filters, and only filters — the inbox's own ordering is not this type's business.
    static func apply(captures: [Capture], searchText: String) -> [Capture] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return captures }
        return captures.filter { matches($0, query: query) }
    }

    /// The two lines a collapsed row draws. `secondaryText` is `nil` exactly when the content has
    /// already been used as the primary line, so between them every word on screen is covered
    /// once and none is missed.
    ///
    /// `localizedCaseInsensitiveContains` because that is what `TaskListRefinement` uses. It is
    /// **not** diacritic-insensitive, and that is deliberate rather than an oversight: two search
    /// fields in one app that disagree about whether "cafe" finds "café" is worse than either
    /// answer alone. `CaptureSearchRefinementTests` pins the two to the same behaviour, so folding
    /// becomes one decision taken in both places rather than a drift discovered later.
    private static func matches(_ capture: Capture, query: String) -> Bool {
        if CaptureRowPresentation.primaryText(for: capture).localizedCaseInsensitiveContains(query) {
            return true
        }
        if let secondary = CaptureRowPresentation.secondaryText(for: capture) {
            return secondary.localizedCaseInsensitiveContains(query)
        }
        return false
    }
}
