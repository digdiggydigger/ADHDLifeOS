//
//  PlaceRoutineNotificationRouter.swift
//  ADHD LifeOS
//
//  The third pending-door replay (F-Routines-3-Screen), the `PlaceActionNotificationRouter`
//  shape: a tap on a routine notification can land in a cold launch while auth is still
//  restoring, before the tabs exist — the router holds the run key as pending and replays it
//  the moment `RootView` connects.
//
//  Block A moved one thing in here and only one: the tap is now where the routine is CREATED
//  (nothing is written at the crossing), so `handle` hands the payload to an activator before
//  delivering a key. The routing rules themselves — prefix greed, pending, replay-once — are
//  untouched, and the activator is injected so tests of those rules never create anything.
//

import Foundation

@MainActor
final class PlaceRoutineNotificationRouter {
    static let shared = PlaceRoutineNotificationRouter()

    private let activator: RoutineActivating
    private var openDoor: ((UUID?) -> Void)?
    private var pendingRunKey: UUID?

    init(activator: RoutineActivating? = nil) {
        self.activator = activator ?? PlaceRoutineActivator()
    }

    func connect(openDoor: @escaping (UUID?) -> Void) {
        self.openDoor = openDoor
        guard let pendingRunKey else { return }
        self.pendingRunKey = nil
        openDoor(pendingRunKey)
    }

    /// `true` when the notification was ours — the delegate uses this to leave every other
    /// identifier for the focus router. Our OWN prefix is claimed even when the payload is
    /// broken (the placeAction greed rule, applied to our own species): a broken tap delivers
    /// a nil key, which the door resolves to Today — never a blank routine screen.
    ///
    /// The tap is also the moment the routine starts existing (Block A), which is the
    /// activator's job — and it is synchronous for a reason: the key handed to the door is
    /// resolved against the run store immediately, so a run written asynchronously would race
    /// its own screen.
    @discardableResult
    func handle(notificationIdentifier: String, userInfo: [AnyHashable: Any]) -> Bool {
        guard notificationIdentifier.hasPrefix(PlaceRoutineNotificationContent.identifierPrefix)
        else { return false }
        deliver(activator.activate(userInfo: userInfo, now: .now))
        return true
    }

    /// The second way IN (F-Routines-4): Today's routine card hands its run key here
    /// directly — no notification involved, but the same pending/replay rules apply, so the
    /// card cannot open a door the notification tap could not.
    func open(_ runKey: UUID) {
        deliver(runKey)
    }

    private func deliver(_ runKey: UUID?) {
        if let openDoor {
            openDoor(runKey)
        } else if let runKey {
            // A broken tap with nothing connected has nothing worth replaying — the app is
            // launching anyway, and Today is already the landing.
            pendingRunKey = runKey
        }
    }
}
