//
//  PlaceAppDirectoryRemote.swift
//  ADHD LifeOS
//
//  The directory's remote top-up (F-AppDirectory-4-Remote): a read-only Firestore document
//  lets the curated list grow — or retire a rotted scheme — without an app release. Every
//  failure mode (offline, rules-unpublished permission-denied, malformed doc, corrupted
//  cache) degrades to bundled + last good entries, never a broken picker.
//

import Foundation

/// The remote fetch, as the provider sees it — a recording fake in tests, the Firebase
/// adapter in the app.
protocol AppDirectoryClientAdapting {
    func fetchRemoteEntryObjects() async throws -> [[String: Any]]
}

/// Two methods, nothing else: the cache is a JSON blob and a stamp, deliberately too dumb
/// to have failure modes of its own.
protocol AppDirectoryCacheStoring {
    func load() -> (data: Data, fetchedAt: Date)?
    func save(data: Data, fetchedAt: Date)
}

struct UserDefaultsAppDirectoryCache: AppDirectoryCacheStoring {
    static let dataKey = "place_app_directory_cache_json"
    static let fetchedAtKey = "place_app_directory_cache_fetched_at"

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> (data: Data, fetchedAt: Date)? {
        guard let data = defaults.data(forKey: Self.dataKey),
              let stamp = defaults.object(forKey: Self.fetchedAtKey) as? Date else { return nil }
        return (data, stamp)
    }

    func save(data: Data, fetchedAt: Date) {
        defaults.set(data, forKey: Self.dataKey)
        defaults.set(fetchedAt, forKey: Self.fetchedAtKey)
    }
}

/// Pure throttle: one fetch a day is plenty for a catalogue.
enum PlaceAppDirectoryCachePolicy {
    static let timeToLive: TimeInterval = 24 * 60 * 60

    static func isFetchDue(lastFetchedAt: Date?, now: Date) -> Bool {
        guard let lastFetchedAt else { return true }
        return now.timeIntervalSince(lastFetchedAt) >= timeToLive
    }
}

/// The composition the picker leans on. `snapshot()` is SYNCHRONOUS — bundled + the last
/// good cached entries, decoded leniently — so the sheet always renders instantly, and the
/// no-reshuffle contract is structural: the sheet holds the value it was given, and a
/// completed refresh only changes what the NEXT `snapshot()` returns.
@MainActor
final class PlaceAppDirectoryProvider {
    static let shared = PlaceAppDirectoryProvider(
        client: FirebaseAppDirectoryClientAdapter(),
        cache: UserDefaultsAppDirectoryCache()
    )

    private let client: AppDirectoryClientAdapting
    private let cache: AppDirectoryCacheStoring
    private let bundled: [PlaceAppDirectoryEntry]
    private let now: () -> Date

    init(
        client: AppDirectoryClientAdapting,
        cache: AppDirectoryCacheStoring,
        bundled: [PlaceAppDirectoryEntry] = PlaceAppDirectoryBundled.entries,
        now: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.cache = cache
        self.bundled = bundled
        self.now = now
    }

    func snapshot() -> [PlaceAppDirectoryEntry] {
        guard let cached = cache.load() else { return bundled }
        // The lenient decode carries the whole degradation story: unparseable data yields
        // zero entries (merge identity → bundled), a bad row costs only itself.
        let remote = PlaceAppDirectory.entries(fromJSONArray: cached.data)
        return PlaceAppDirectory.merge(bundled: bundled, remote: remote)
    }

    /// Fetch at most once per TTL; swallow every failure — offline and rules-unpublished are
    /// indistinguishable out here and both mean "keep what we have". A payload that can't
    /// round-trip through JSON is not cached, so the old good cache survives it.
    func refreshIfDue() async {
        guard PlaceAppDirectoryCachePolicy.isFetchDue(
            lastFetchedAt: cache.load()?.fetchedAt, now: now()
        ) else { return }
        guard let objects = try? await client.fetchRemoteEntryObjects(),
              JSONSerialization.isValidJSONObject(objects),
              let data = try? JSONSerialization.data(withJSONObject: objects) else { return }
        cache.save(data: data, fetchedAt: now())
    }
}
