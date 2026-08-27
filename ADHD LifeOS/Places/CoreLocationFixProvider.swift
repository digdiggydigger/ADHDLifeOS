//
//  CoreLocationFixProvider.swift
//  ADHD LifeOS
//

import Combine
import CoreLocation

/// The real one-shot location fix, over CoreLocation. The only type in the app that owns a
/// `CLLocationManager` for tagging.
///
/// `requestLocation()` is deliberately used rather than `startUpdatingLocation()`: it delivers one
/// fix and stops the hardware itself, which is exactly the shape of "where am I, right now, for
/// this capture" and avoids leaving GPS running behind a screen nobody is looking at.
///
/// The bridge from delegate callbacks to `async` is a continuation, and the thing that makes it
/// safe is resuming EXACTLY once: CoreLocation can call back more than once, or never, and a
/// continuation resumed twice traps while one never resumed hangs the caller forever. Hence the
/// `pending` nil-out on every path, plus a timeout.
@MainActor
final class CoreLocationFixProvider: NSObject, ObservableObject, LocationFixProviding {
    static let shared = CoreLocationFixProvider()

    /// Long enough for a cold GPS indoors, short enough that a capture never feels stuck. The
    /// capture is saved regardless — the stamp is a bonus, never a blocker.
    static let fixTimeout: Duration = .seconds(8)

    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<PlaceCoordinate?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        // Neighbourhood-level is plenty: places have a 100m floor, so a tighter accuracy would
        // spend battery to answer a question nobody asked.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationState: LocationAuthorizationState {
        LocationAuthorizationState(status: manager.authorizationStatus)
    }

    /// Published so a banner can react the moment the user answers the system sheet — the
    /// delegate callback is the ONLY signal that the answer arrived.
    @Published private(set) var authorizationChanges = 0

    /// Raise the system prompt.
    ///
    /// Deliberately no completion: iOS answers through the delegate, and a caller that awaited a
    /// result would hang whenever the user swipes the sheet away without choosing. Callers watch
    /// `authorizationState` instead.
    ///
    /// Asking for Always is only legal AFTER When In Use has been granted — requesting it from
    /// `notDetermined` shows a weaker prompt, so `LocationPermissionPrompt` never offers that
    /// order and this method does not second-guess it.
    func request(_ request: LocationAuthorizationRequest) {
        switch request {
        case .whenInUse:
            manager.requestWhenInUseAuthorization()
        case .always:
            manager.requestAlwaysAuthorization()
        }
    }

    func currentCoordinate() async -> PlaceCoordinate? {
        guard authorizationState.allowsTagging else { return nil }
        // A second request while one is in flight resolves to nothing rather than stamping on the
        // first one's continuation.
        guard pending == nil else { return nil }

        return await withTaskGroup(of: PlaceCoordinate?.self) { group in
            group.addTask { @MainActor [weak self] in
                guard let self else { return nil }
                return await withCheckedContinuation { continuation in
                    self.pending = continuation
                    self.manager.requestLocation()
                }
            }
            group.addTask { @MainActor [weak self] in
                try? await Task.sleep(for: Self.fixTimeout)
                // Timed out: resume the waiter with nothing, exactly once.
                self?.finish(nil)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    /// The single resume point. Nil-ing `pending` first is what guarantees exactly-once.
    private func finish(_ coordinate: PlaceCoordinate?) {
        guard let continuation = pending else { return }
        pending = nil
        continuation.resume(returning: coordinate)
    }
}

extension CoreLocationFixProvider: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor [weak self] in
            guard let coordinate else {
                self?.finish(nil)
                return
            }
            self?.finish(
                PlaceCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.authorizationChanges += 1
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // No stamp rather than a wrong one — the caller treats nil as "didn't happen".
        Task { @MainActor [weak self] in
            self?.finish(nil)
        }
    }
}
