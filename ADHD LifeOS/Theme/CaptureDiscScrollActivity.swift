//
//  CaptureDiscScrollActivity.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// F-DiscPill's state: is the user mid-scroll, so the capture disc should be a pill?
///
/// E's report, twice (2026-08-30): the disc sits over real content throughout the app — a nudge
/// row's time, a capture's subtitle, the "Week review" card. F-DiscClearance fixed the END of
/// every scroll with the 84pt inset; this fixes the MIDDLE, per E's chosen design: *shrink the
/// disc to a small pill while scrolling.*
///
/// The shrink is immediate — a pill that arrives late spends the whole scroll as a disc. The
/// restore is debounced by `settleDelay`, so stop-and-go scrolling (drag, read, drag again)
/// reads as one continuous pill rather than a disc flapping between sizes. A new drag inside
/// the window cancels the pending restore: it is the SAME scroll, continued.
@MainActor
final class CaptureDiscScrollActivity: ObservableObject {
    @Published private(set) var isScrolling = false

    /// How long the finger must stay up before the disc STARTS growing back. Long enough to
    /// bridge a thumb repositioning between drags — and deliberately unhurried: E's device
    /// verdict on the first cut (0.7s) was "needs to regrow EVEN slower" (F-PillTune), so the
    /// beat is now 1.2s, and the regrow animation itself is a slow expanding fade on top of it.
    nonisolated static let settleDelay: TimeInterval = 1.2

    private let settleDelay: TimeInterval
    private var pendingRestore: Task<Void, Never>?

    /// Tests inject a short delay; the app uses the default.
    init(settleDelay: TimeInterval = CaptureDiscScrollActivity.settleDelay) {
        self.settleDelay = settleDelay
    }

    func dragBegan() {
        pendingRestore?.cancel()
        pendingRestore = nil
        isScrolling = true
    }

    func dragEnded() {
        pendingRestore?.cancel()
        pendingRestore = Task { [weak self, settleDelay] in
            try? await Task.sleep(nanoseconds: UInt64(settleDelay * 1_000_000_000))
            // A drag that started during the sleep cancelled this task; the check is on the
            // main actor alongside `dragBegan`, so there is no window between them.
            guard !Task.isCancelled else { return }
            self?.isScrolling = false
        }
    }
}
