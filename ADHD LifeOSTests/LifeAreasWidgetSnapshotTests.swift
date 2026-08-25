//
//  LifeAreasWidgetSnapshotTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Life Areas medium widget's payload (E's 2026-08-25 note) — the same two-process contract
/// discipline as `FocusWidgetSnapshot`: versioned, resolved app-side, decode-only in the widget.
final class LifeAreasWidgetSnapshotTests: XCTestCase {
    private func area(
        _ name: String, emoji: String, sortOrder: Int,
        archived: Bool = false, palette: String? = nil, id: UUID = UUID()
    ) -> LifeArea {
        LifeArea(id: id, name: name, colour: emoji, sortOrder: sortOrder, archived: archived, palette: palette)
    }

    // MARK: - Builder

    func testBuilder_ordersBySortOrderAndDropsArchived() {
        let snapshot = LifeAreasWidgetSnapshotBuilder.snapshot(
            lifeAreas: [
                area("Second", emoji: "🌱", sortOrder: 1),
                area("Hidden", emoji: "🗄", sortOrder: 2, archived: true),
                area("First", emoji: "💼", sortOrder: 0)
            ],
            openTasks: []
        )

        XCTAssertEqual(snapshot.areas.map(\.name), ["First", "Second"])
    }

    func testBuilder_capsAtTheMediumGridsSixSlots() {
        let many = (0..<9).map { area("Area \($0)", emoji: "💼", sortOrder: $0) }

        let snapshot = LifeAreasWidgetSnapshotBuilder.snapshot(lifeAreas: many, openTasks: [])

        XCTAssertEqual(snapshot.areas.count, 6)
        XCTAssertEqual(snapshot.areas.last?.name, "Area 5")
    }

    func testBuilder_countsEachAreasOpenTasks() {
        let health = area("Health", emoji: "🫀", sortOrder: 0)
        let work = area("Work", emoji: "💼", sortOrder: 1)
        let openTasks = [
            TaskSummary(id: UUID(), lifeAreaId: health.id, status: .open, title: "a"),
            TaskSummary(id: UUID(), lifeAreaId: health.id, status: .open, title: "b"),
            TaskSummary(id: UUID(), lifeAreaId: nil, status: .open, title: "unfiled")
        ]

        let snapshot = LifeAreasWidgetSnapshotBuilder.snapshot(
            lifeAreas: [health, work], openTasks: openTasks
        )

        XCTAssertEqual(snapshot.areas.map(\.openCount), [2, 0])
    }

    /// The stem is resolved app-side through `AreaPalette.family(for:)`, so the assigned colour
    /// override (F-V3-AreaColour) reaches the Home Screen too — the widget never sees a `LifeArea`.
    func testBuilder_resolvesThePaletteStemIncludingTheOverride() {
        let automatic = area("Work", emoji: "💼", sortOrder: 0)
        let overridden = area("Money", emoji: "💰", sortOrder: 1, palette: "hobby")

        let snapshot = LifeAreasWidgetSnapshotBuilder.snapshot(
            lifeAreas: [automatic, overridden], openTasks: []
        )

        XCTAssertEqual(snapshot.areas.map(\.paletteAssetStem), ["AreaWork", "AreaHobby"])
    }

    // MARK: - Store contract

    func testStore_roundTripsThroughTheSharedDefaults() {
        let suiteName = "LifeAreasWidgetSnapshotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = LifeAreasWidgetStore(defaults: defaults)
        let snapshot = LifeAreasWidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            areas: [.init(name: "Work", emoji: "💼", paletteAssetStem: "AreaWork", openCount: 3)]
        )

        store.write(snapshot)

        XCTAssertEqual(store.read(), snapshot)
    }

    /// A payload stamped with a version this build doesn't know is discarded, never half-decoded.
    func testStore_discardsAForeignVersion() throws {
        let suiteName = "LifeAreasWidgetSnapshotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = LifeAreasWidgetStore(defaults: defaults)
        let snapshot = LifeAreasWidgetSnapshot(generatedAt: Date(), areas: [])
        var object = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(snapshot)
        ) as? [String: Any] ?? [:]
        object["version"] = LifeAreasWidgetSnapshot.currentVersion + 1
        defaults.set(
            try JSONSerialization.data(withJSONObject: object), forKey: LifeAreasWidgetStore.snapshotKey
        )

        XCTAssertNil(store.read())
    }
}
