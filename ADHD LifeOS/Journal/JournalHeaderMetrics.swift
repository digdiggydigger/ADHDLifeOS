//
//  JournalHeaderMetrics.swift
//  ADHD LifeOS
//
//  The Journal header's two circles — the "All activity" eye and the new-entry pencil — share
//  one size, so the header reads as one family. Its own file so the size outlives any rewrite of
//  the views that read it (`JournalHeaderControlsTests` holds both the value and the readers).
//

import CoreGraphics

enum JournalHeaderMetrics {
    /// **44 since `F-JournalDoorUnpinned` (2026-09-18), up from 40.** E chose option 04 — the
    /// pinned "One line about today…" bar goes and the header pencil is the door — which made the
    /// pencil the Journal's ONLY way to write an entry while it sat under §3's 44pt floor. A real
    /// frame rather than `AppTabBarMetrics.slotHitOverflow`'s negative-padding trick: that exists
    /// so a target does not grow a CONSTRAINED container, and this row's height is already set by
    /// the caption and the `.largeTitle` beside it, so the 4pt costs no layout.
    static let controlSize: CGFloat = AppTabBarPresentation.minimumTouchTarget
}
