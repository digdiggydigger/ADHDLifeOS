//
//  LifeAreaTaskCountsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class LifeAreaTaskCountsTests: XCTestCase {

    private func makeLifeArea(name: String, sortOrder: Int) -> LifeArea {
        LifeArea(id: UUID(), name: name, colour: "#123456", sortOrder: sortOrder)
    }

    func testCountOpenTasksByLifeArea_withEmptyTasks_returnsZeroForEveryArea() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let personal = makeLifeArea(name: "Personal", sortOrder: 1)

        let result = LifeAreaTaskCounts.countOpenTasksByLifeArea(lifeAreas: [work, personal], tasks: [])

        XCTAssertEqual(result.map(\.openTaskCount), [0, 0])
    }

    func testCountOpenTasksByLifeArea_sortsByLifeAreaSortOrder() {
        let personal = makeLifeArea(name: "Personal", sortOrder: 1)
        let work = makeLifeArea(name: "Work", sortOrder: 0)

        let result = LifeAreaTaskCounts.countOpenTasksByLifeArea(lifeAreas: [personal, work], tasks: [])

        XCTAssertEqual(result.map(\.lifeArea.name), ["Work", "Personal"])
    }

    func testCountOpenTasksByLifeArea_countsOnlyOpenTasksPerMatchingArea() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let personal = makeLifeArea(name: "Personal", sortOrder: 1)
        let tasks = [
            TaskSummary(lifeAreaId: work.id, status: .open),
            TaskSummary(lifeAreaId: work.id, status: .open),
            TaskSummary(lifeAreaId: personal.id, status: .open),
            TaskSummary(lifeAreaId: work.id, status: .done)
        ]

        let result = LifeAreaTaskCounts.countOpenTasksByLifeArea(lifeAreas: [work, personal], tasks: tasks)

        XCTAssertEqual(result.first(where: { $0.lifeArea.id == work.id })?.openTaskCount, 2)
        XCTAssertEqual(result.first(where: { $0.lifeArea.id == personal.id })?.openTaskCount, 1)
    }

    func testCountOpenTasksByLifeArea_taskWithNilLifeAreaId_countsTowardNothing() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let tasks = [TaskSummary(lifeAreaId: nil, status: .open)]

        let result = LifeAreaTaskCounts.countOpenTasksByLifeArea(lifeAreas: [work], tasks: tasks)

        XCTAssertEqual(result.first?.openTaskCount, 0)
    }

    func testCountOpenTasksByLifeArea_areaWithNoMatchingTasks_returnsZero() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let health = makeLifeArea(name: "Health", sortOrder: 1)
        let tasks = [TaskSummary(lifeAreaId: work.id, status: .open)]

        let result = LifeAreaTaskCounts.countOpenTasksByLifeArea(lifeAreas: [work, health], tasks: tasks)

        XCTAssertEqual(result.first(where: { $0.lifeArea.id == health.id })?.openTaskCount, 0)
    }
}
