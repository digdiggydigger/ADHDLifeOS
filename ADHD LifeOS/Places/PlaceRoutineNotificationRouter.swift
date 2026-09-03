//
//  PlaceRoutineNotificationRouter.swift
//  ADHD LifeOS
//
//  The third pending-door replay (F-Routines-3-Screen), the `PlaceActionNotificationRouter`
//  shape: a tap on a routine notification can land in a cold launch while auth is still
//  restoring, before the tabs exist — the router holds the run key as pending and replays it
//  the moment `RootView` connects. The tap carries ONLY the minted run UUID; resolving it
//  against the store (and the stale-tap rule that falls out of a mismatch) is the door's job,
//  not this router's.
//

import Foundation

@MainActor
final class PlaceRoutineNotificationRouter {
    static let shared = PlaceRoutineNotificationRouter()

    private var openDoor: ((UUID?) -> Void)?
    private var pendingRunKey: UUID?

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
    @discardableResult
    func handle(notificationIdentifier: String, userInfo: [AnyHashable: Any]) -> Bool {
        guard notificationIdentifier.hasPrefix(PlaceRoutineNotificationContent.identifierPrefix)
        else { return false }
        let runKey = (userInfo[PlaceRoutineNotificationContent.runIdUserInfoKey] as? String)
            .flatMap(UUID.init(uuidString:))
        deliver(runKey)
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
