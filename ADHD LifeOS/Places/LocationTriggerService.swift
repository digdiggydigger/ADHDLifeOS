//
//  LocationTriggerService.swift
//  ADHD LifeOS
//

import Foundation

/// The slice of CLLocationManager's region machinery the trigger engine drives — a protocol so
/// the registration rules are testable without CoreLocation, per the house seam pattern.
@MainActor
protocol RegionMonitoring: AnyObject {
    var monitoredPlaceIds: Set<UUID> { get }
    var onEvent: ((PlaceTriggerEvent) -> Void)? { get set }
    /// Fires on a significant-change wake, with the new coordinate when the OS supplied one.
    var onSignificantChange: ((PlaceCoordinate?) -> Void)? { get set }
    func startMonitoring(_ region: PlaceRegion)
    func stopMonitoring(placeId: UUID)
    func setSignificantChangeMonitoring(enabled: Bool)
}

/// Keeps iOS's monitored regions agreeing with the places E has asked to be nudged about
/// (block 4b), and fans fence crossings out to the surfacings built on top.
///
/// Replanned on launch, on foregrounding, on any data change (a place edit posts
/// `DataChangeSignal` through the shared write plumbing), on the Settings master switch, and on
/// every significant-change wake — the wake being the whole point of the fallback: moving across
/// the country swaps in the fences that now matter.
@MainActor
final class LocationTriggerService {
    /// The production instance, created at App init so a background relaunch (a region crossing
    /// resurrects the app with no UI) rebuilds the delegate wiring before iOS delivers the event
    /// — the `CoreLocationFixProvider.shared` precedent.
    static let shared = LocationTriggerService()

    private let monitor: RegionMonitoring
    private let placesClient: PlacesClientAdapting
    private let isEnabled: () -> Bool
    private let authorization: () -> LocationAuthorizationState
    /// Feeds the wake-time snapshot (variation A): the open tasks a background crossing will be
    /// told about. A closure so tests hand over a fixed list.
    private let fetchTasks: () async throws -> [TaskItem]
    private let store: ArrivalNudgeStateStoring

    /// The surfacings (4c) hang off this — notification nudges, the silent event log. One fan-out
    /// point so the monitor never learns who is listening.
    var onEvent: ((PlaceTriggerEvent) -> Void)?

    init(
        monitor: RegionMonitoring? = nil,
        placesClient: PlacesClientAdapting? = nil,
        isEnabled: @escaping () -> Bool = { AppFeedback.arrivalNudgesEnabled() },
        authorization: @escaping () -> LocationAuthorizationState = {
            CoreLocationFixProvider.shared.authorizationState
        },
        fetchTasks: (() async throws -> [TaskItem])? = nil,
        store: ArrivalNudgeStateStoring? = nil
    ) {
        self.monitor = monitor ?? CoreLocationTriggerMonitor()
        self.placesClient = placesClient ?? FirebasePlacesClientAdapter()
        self.isEnabled = isEnabled
        self.authorization = authorization
        self.fetchTasks = fetchTasks ?? { try await FirebaseTasksClientAdapter().fetchAllTasks() }
        self.store = store ?? UserDefaultsArrivalNudgeStateStore()
        self.monitor.onEvent = { [weak self] event in
            self?.onEvent?(event)
        }
        self.monitor.onSignificantChange = { [weak self] coordinate in
            Task { await self?.refreshRegistrations(around: coordinate) }
        }
    }

    /// Re-derives the whole registration set and hands the difference to iOS.
    ///
    /// Two deliberate asymmetries:
    /// - Gates closed (master switch off, grant revoked) tears everything down NOW, without even
    ///   a places fetch — "off" must not cost a Firestore read.
    /// - A FAILED fetch keeps the current fences untouched: a fence wrongly torn down on a flaky
    ///   background wake is an arrival nudge that silently never fires again.
    func refreshRegistrations(around coordinate: PlaceCoordinate? = nil) async {
        let plan: [PlaceRegion]
        var knownPlaces: [Place] = []
        if isEnabled(), authorization().allowsTriggering {
            do {
                knownPlaces = try await placesClient.fetchPlaces()
            } catch {
                return
            }
            plan = LocationTriggerPlan.regions(
                places: knownPlaces,
                around: coordinate,
                authorization: authorization(),
                isEnabled: isEnabled()
            )
        } else {
            plan = []
        }

        let actions = LocationTriggerPlan.reconcile(
            currentIds: monitor.monitoredPlaceIds, planned: plan
        )
        for placeId in actions.stopIds {
            monitor.stopMonitoring(placeId: placeId)
        }
        for region in actions.start {
            monitor.startMonitoring(region)
        }
        // The fallback rides with the fences: armed while any exist, quiet when none do.
        monitor.setSignificantChangeMonitoring(enabled: !plan.isEmpty)
        await refreshSnapshot(for: plan, among: knownPlaces)
    }

    /// Rebuilds the wake-time snapshot (variation A) for exactly the fences that can fire. A
    /// failed tasks fetch keeps the previous snapshot — slightly stale content beats a nudge
    /// with nothing to say.
    private func refreshSnapshot(for plan: [PlaceRegion], among places: [Place]) async {
        guard !plan.isEmpty else { return }
        guard let tasks = try? await fetchTasks() else { return }
        let plannedIds = Set(plan.map(\.placeId))
        store.writeSnapshot(AtPlaceSnapshot.build(
            places: places.filter { plannedIds.contains($0.id) },
            tasks: tasks
        ))
    }
}
