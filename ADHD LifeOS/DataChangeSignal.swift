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

    /// Where the debounce actually lives, and it is deliberately NOT in the subscriber's chain.
    ///
    /// This used to be a factory returning a fresh `NotificationCenter → debounce` chain per
    /// call, which meant every SwiftUI body evaluation built a new one and `onReceive`
    /// resubscribed. A body evaluation inside the 600ms window — a tab switch is one — tore the
    /// pending chain down before it could fire, and the change was simply lost. That is the
    /// round-2 field-walk defect: Today kept a stale routine card after a departure crossing,
    /// while an arrival looked fine only because its journal auto-step writes to Firestore and
    /// posts a SECOND signal once the switch has settled.
    ///
    /// A `let` on an enum is lazy and initialised exactly once, so this subscription is created
    /// on first use and then retained for the process's life. Views subscribe to the SUBJECT,
    /// downstream of the debounce, so a resubscribe rejoins a stream that is already running
    /// instead of restarting a timer.
    private static let pipeline: AnyCancellable = NotificationCenter.default
        .publisher(for: name)
        .map { _ in () }
        .debounce(for: refetchInterval, scheduler: RunLoop.main)
        .sink { relay.send() }

    private static let relay = PassthroughSubject<Void, Never>()

    /// One debounced stream for every listener, so no screen invents its own cadence. Delivered
    /// on the main run loop — subscribers kick straight into `@MainActor` reloads.
    static let changes: AnyPublisher<Void, Never> = {
        _ = pipeline                       // force the subscription before anyone can miss it
        return relay.eraseToAnyPublisher()
    }()

    /// TEST ONLY — a private cadence, for pinning the debounce itself. Production screens use
    /// `changes`; a factory here cannot exhibit the resubscribe fault because the test holds its
    /// cancellable for the whole assertion.
    static func debouncedPublisher(
        interval: RunLoop.SchedulerTimeType.Stride = refetchInterval
    ) -> AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: name)
            .map { _ in () }
            .debounce(for: interval, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
