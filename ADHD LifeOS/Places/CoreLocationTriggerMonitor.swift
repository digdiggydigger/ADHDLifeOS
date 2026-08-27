//
//  CoreLocationTriggerMonitor.swift
//  ADHD LifeOS
//

import CoreLocation

/// The real `RegionMonitoring`, over CoreLocation. The only type in the app that registers
/// geofences — deliberately separate from `CoreLocationFixProvider`, whose one-shot fix has
/// nothing to do with region lifecycles.
///
/// Region identifiers are the place's UPPERCASE `uuidString`, matching document ids everywhere
/// else. Registrations OUTLIVE the process — iOS keeps them and relaunches the app for a
/// crossing — which is why this type is created at App init: the delegate must exist before the
/// event is delivered.
@MainActor
final class CoreLocationTriggerMonitor: NSObject, RegionMonitoring {
    private let manager = CLLocationManager()
    private var significantChangeOn = false

    var onEvent: ((PlaceTriggerEvent) -> Void)?
    var onSignificantChange: ((PlaceCoordinate?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    var monitoredPlaceIds: Set<UUID> {
        Set(manager.monitoredRegions.compactMap { UUID(uuidString: $0.identifier) })
    }

    func startMonitoring(_ region: PlaceRegion) {
        let circular = CLCircularRegion(
            center: CLLocationCoordinate2D(
                latitude: region.center.latitude, longitude: region.center.longitude
            ),
            radius: region.radiusMetres,
            identifier: region.placeId.uuidString
        )
        circular.notifyOnEntry = region.notifyOnEntry
        circular.notifyOnExit = region.notifyOnExit
        manager.startMonitoring(for: circular)
    }

    func stopMonitoring(placeId: UUID) {
        for monitored in manager.monitoredRegions where monitored.identifier == placeId.uuidString {
            manager.stopMonitoring(for: monitored)
        }
    }

    func setSignificantChangeMonitoring(enabled: Bool) {
        guard enabled != significantChangeOn else { return }
        significantChangeOn = enabled
        if enabled {
            manager.startMonitoringSignificantLocationChanges()
        } else {
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
}

extension CoreLocationTriggerMonitor: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        deliver(region, kind: .arrival)
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        deliver(region, kind: .departure)
    }

    private nonisolated func deliver(_ region: CLRegion, kind: PlaceTriggerEvent.Kind) {
        guard let placeId = UUID(uuidString: region.identifier) else { return }
        Task { @MainActor [weak self] in
            self?.onEvent?(PlaceTriggerEvent(placeId: placeId, kind: kind, occurredAt: .now))
        }
    }

    /// Significant-change deliveries land here (this manager never calls `requestLocation`), and
    /// each one re-runs the nearest-20 selection around wherever the device now is.
    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor [weak self] in
            self?.onSignificantChange?(coordinate.map {
                PlaceCoordinate(latitude: $0.latitude, longitude: $0.longitude)
            })
        }
    }

    /// Quiet on purpose: a region that failed to register has no user-facing recovery beyond the
    /// next replan, and `didFailWithError` here is routinely transient.
    nonisolated func locationManager(
        _ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error
    ) {}

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
