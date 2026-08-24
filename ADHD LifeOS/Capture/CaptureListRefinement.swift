//
//  CaptureListRefinement.swift
//  ADHD LifeOS
//
//  The sort and kind-filter rule behind the refinement menu on the Capture Inbox and the
//  Captures tab (E's direction, 2026-08-24). Pure, and applied at DISPLAY time over the
//  service's loaded slice — the loaded state stays the untouched truth, so counts and summaries
//  keep describing the whole slice while the rows obey the menu.
//

import Foundation

enum CaptureListRefinement {
    static func apply(captures: [Capture], newestFirst: Bool, kind: CaptureKind?) -> [Capture] {
        captures
            .filter { kind == nil || $0.kind == kind }
            .sorted { newestFirst ? $0.createdAt > $1.createdAt : $0.createdAt < $1.createdAt }
    }
}
