//
//  TriageCallSequence.swift
//  ADHD LifeOSTests
//

import Foundation

/// A shared stamp two fakes can both write to, so a test can assert the ORDER of calls made
/// across them.
///
/// Undoing "Journal it" spans both seams — it restores the capture through
/// `CaptureClientAdapting` and deletes the entry through `JournalClientAdapting` — and the order
/// is the whole safety argument: restore first, so a failed delete leaves a stray entry rather
/// than erasing the thought from both places. Neither fake alone can see that.
///
/// Injected per-SUT rather than kept as a global, so nothing leaks between tests.
final class TriageCallSequence: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        defer { count += 1 }
        return count
    }
}
