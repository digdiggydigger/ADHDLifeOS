//
//  DataChangeSignal.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// The app-wide "user data changed" pulse (BUG-b7/b1, SUGG-b4: screens went stale because nothing
/// told them a write happened elsewhere — a task added over the list, an area recoloured in
/// Settings, a capture taken through the global fan). Every successful Firestore write posts it
/// from `FirebaseManager`'s write plumbing — the one choke point all adapters share — and each
/// screen root refetches through `debouncedPublisher`, so a burst of writes (create + attach
/// tags, a reorder batch) coalesces into a single reload instead of one per write.
///
/// Foundation + Combine only, deliberately: the unit-test target cannot link the Firebase SDK,
/// and this type must be testable there.
enum DataChangeSignal {
    static let name = Notification.Name("lifeOSUserDataDidChange")

    /// The shared refetch cadence. Long enough to swallow one logical action's write burst,
    /// short enough that the reload still reads as "instant" on the screen behind a dismissing
    /// sheet.
    static let refetchInterval = RunLoop.SchedulerTimeType.Stride.milliseconds(600)

    static func post() {
        NotificationCenter.default.post(name: name, object: nil)
    }

    /// One debounced stream for every listener, so no screen invents its own cadence. Delivered
    /// on the main run loop — subscribers kick straight into `@MainActor` reloads.
    static func debouncedPublisher(
        interval: RunLoop.SchedulerTimeType.Stride = refetchInterval
    ) -> AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: name)
            .map { _ in () }
            .debounce(for: interval, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
