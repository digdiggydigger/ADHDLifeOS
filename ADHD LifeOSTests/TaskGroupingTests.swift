//
//  TaskGroupingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TaskGroupingTests: XCTestCase {

    private func makeLifeArea(name: String, sortOrder: Int, archived: Bool = false) -> LifeArea {
        LifeArea(id: UUID(), name: name, colour: "#123456", sortOrder: sortOrder, archived: archived)
    }

    private func makeTask(
        lifeAreaId: UUID?,
        title: String,
        status: TaskStatus = .open,
        priority: TaskPriority = .p4
    ) -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: lifeAreaId, title: title, status: status, priority: priority, dueDate: nil)
    }

    func testGroupTasksByLifeArea_groupsUnderLifeAreaOrderedBySortOrder() {
        let work = makeLifeArea(name: "Work", sortOrder: 1)
        let health = makeLifeArea(name: "Health", sortOrder: 2)
        let tasks = [
            makeTask(lifeAreaId: health.id, title: "Book checkup"),
            makeTask(lifeAreaId: work.id, title: "Finish report")
        ]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [health, work])

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Work", "Health"])
        XCTAssertEqual(groups[0].tasks.map(\.title), ["Finish report"])
        XCTAssertEqual(groups[1].tasks.map(\.title), ["Book checkup"])
    }

    func testGroupTasksByLifeArea_sortsTasksWithinGroupOpenBeforeDone() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let tasks = [
            makeTask(lifeAreaId: work.id, title: "Already done", status: .done),
            makeTask(lifeAreaId: work.id, title: "Still open", status: .open),
            makeTask(lifeAreaId: work.id, title: "Another open", status: .open)
        ]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [work])

        XCTAssertEqual(groups[0].tasks.map(\.title), ["Still open", "Another open", "Already done"])
    }

    func testGroupTasksByLifeArea_nilLifeAreaId_goesIntoTrailingUnassignedGroup() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let tasks = [
            makeTask(lifeAreaId: work.id, title: "Work task"),
            makeTask(lifeAreaId: nil, title: "Floating task")
        ]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [work])

        XCTAssertEqual(groups.count, 2)
        XCTAssertNil(groups[1].lifeAreaId)
        XCTAssertEqual(groups[1].lifeAreaName, TaskGrouping.unassignedLifeAreaName)
        XCTAssertEqual(groups[1].tasks.map(\.title), ["Floating task"])
    }

    func testGroupTasksByLifeArea_omitsLifeAreasWithNoTasks() {
        let work = makeLifeArea(name: "Work", sortOrder: 1)
        let health = makeLifeArea(name: "Health", sortOrder: 2)
        let tasks = [makeTask(lifeAreaId: work.id, title: "Finish report")]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [work, health])

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].lifeAreaName, "Work")
    }

    func testGroupTasksByLifeArea_noTasks_returnsEmptyArray() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: [], lifeAreas: [work])

        XCTAssertEqual(groups, [])
    }

    func testLifeAreaTaskGroup_id_forLifeAreaGroup_isLifeAreaIdString() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let tasks = [makeTask(lifeAreaId: work.id, title: "Finish report")]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [work])

        XCTAssertEqual(groups[0].id, work.id.uuidString)
    }

    func testLifeAreaTaskGroup_id_forUnassignedGroup_isUnassignedConstant() {
        let tasks = [makeTask(lifeAreaId: nil, title: "Floating task")]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [])

        XCTAssertEqual(groups[0].id, "unassigned")
    }

    // MARK: - Archived-aware routing (Home-reorder block)

    func testGroupTasksByLifeArea_archivedAreasTasks_routeToTrailingUnassigned() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let archived = makeLifeArea(name: "Old", sortOrder: 1, archived: true)
        let tasks = [
            makeTask(lifeAreaId: work.id, title: "Work task"),
            makeTask(lifeAreaId: archived.id, title: "Task in archived area")
        ]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [work, archived])

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Work", TaskGrouping.unassignedLifeAreaName],
                       "no group carries the archived area's name; it is the trailing group")
        XCTAssertNil(groups[1].lifeAreaId)
        XCTAssertEqual(groups[1].tasks.map(\.title), ["Task in archived area"])
    }

    func testGroupTasksByLifeArea_archivedAndNilTasks_shareTheOneUnassignedGroup_openBeforeDone() {
        let work = makeLifeArea(name: "Work", sortOrder: 0)
        let archived = makeLifeArea(name: "Old", sortOrder: 1, archived: true)
        let tasks = [
            makeTask(lifeAreaId: work.id, title: "Work task"),
            makeTask(lifeAreaId: archived.id, title: "Archived done", status: .done),
            makeTask(lifeAreaId: nil, title: "Floating open", status: .open),
            makeTask(lifeAreaId: archived.id, title: "Archived open", status: .open)
        ]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [work, archived])

        XCTAssertEqual(groups.count, 2)
        let unassigned = groups[1]
        XCTAssertEqual(unassigned.lifeAreaName, TaskGrouping.unassignedLifeAreaName)
        XCTAssertEqual(Set(unassigned.tasks.map(\.title)),
                       ["Archived done", "Floating open", "Archived open"])
        XCTAssertEqual(unassigned.tasks.last?.title, "Archived done", "done sorts after open within the group")
    }

    func testGroupTasksByLifeArea_activeBehaviourUnchangedWhenNothingArchived() {
        let work = makeLifeArea(name: "Work", sortOrder: 1)
        let health = makeLifeArea(name: "Health", sortOrder: 2)
        let tasks = [
            makeTask(lifeAreaId: health.id, title: "Book checkup"),
            makeTask(lifeAreaId: work.id, title: "Finish report")
        ]

        let groups = TaskGrouping.groupTasksByLifeArea(tasks: tasks, lifeAreas: [health, work])

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Work", "Health"])
    }
}
