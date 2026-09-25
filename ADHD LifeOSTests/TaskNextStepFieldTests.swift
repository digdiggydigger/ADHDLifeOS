//
//  TaskNextStepFieldTests.swift
//  ADHD LifeOSTests
//
//  `F-E2-NextStepField` — E's round 5a: *"Next step → 'A "Next step" field.' One optional line on a
//  task, editable from the card and from task detail. Time comes from the task's stored sprint
//  length (`focus_duration_seconds`)."*
//
//  The field is new surface, so nothing is reversed here; what these pin is the wire contract,
//  because a wrong key raises nothing — it writes a field nothing reads (CLAUDE.md, "Hand-written
//  Firestore field dictionaries"). Tasks are fully snake_cased, so the key is `next_step`, and the
//  camelCase spelling must be ABSENT as well as the right one present.
//

import XCTest
@testable import ADHD_LifeOS

final class TaskNextStepFieldTests: XCTestCase {

    private func detail(nextStep: String? = nil) -> TaskDetail {
        TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Book the MOT", notes: nil, status: .open,
            priority: .p3, dueDate: nil, createdAt: Date(timeIntervalSince1970: 0),
            nextStep: nextStep
        )
    }

    private func edited(from task: TaskDetail, nextStep: String?) -> TaskEditedFields {
        TaskEditedFields(
            title: task.title, notes: task.notes ?? "", lifeAreaId: task.lifeAreaId,
            priority: task.priority, dueDate: task.dueDate, atPlaceId: task.atPlaceId,
            nextStep: nextStep
        )
    }

    private func payload(_ task: TaskDetail, staging nextStep: String?) throws -> TaskUpdatePayload {
        try TaskUpdateValidation.normalizeUpdateTaskInput(
            original: task, edited: edited(from: task, nextStep: nextStep)
        ).get()
    }

    // MARK: - The wire: one snake_cased key on every task document

    func testTaskUpdate_nextStepIsSnakeCased() {
        let fields = FirestoreFieldPayloads.taskUpdate(TaskUpdatePayload(nextStep: .some("Find the V5C")))

        XCTAssertEqual(fields["next_step"] as? String, "Find the V5C")
        XCTAssertNil(fields["nextStep"], "that spelling belongs to captures, not tasks")
    }

    /// Clearing the line is a write (`FieldValue.delete()`), and an untouched line is none — the
    /// house nested-optional contract `notes` already keeps.
    func testTaskUpdate_nextStepClearedIsADeleteAndUntouchedIsNothing() {
        let cleared = FirestoreFieldPayloads.taskUpdate(TaskUpdatePayload(nextStep: .some(nil)))
        XCTAssertTrue(
            FirestoreDocumentCoder.isFieldDelete(cleared["next_step"]),
            "a cleared line must reach the document as a delete, not an empty string"
        )

        let untouched = FirestoreFieldPayloads.taskUpdate(TaskUpdatePayload())
        XCTAssertNil(untouched["next_step"])
    }

    func testPayload_withOnlyANextStepIsNotEmpty() {
        XCTAssertTrue(TaskUpdatePayload().isEmpty)
        XCTAssertFalse(TaskUpdatePayload(nextStep: .some("Find the V5C")).isEmpty)
        XCTAssertFalse(TaskUpdatePayload(nextStep: .some(nil)).isEmpty, "clearing is a change too")
    }

    // MARK: - Decoding: every document written before E2 has no key

    func testTaskSummaryDecodesANextStep_andToleratesItsAbsence() throws {
        let decoder = JSONDecoder()
        let with = Data("""
        {"id": "\(UUID().uuidString)", "title": "MOT", "status": "open", "priority": "p2",
         "next_step": "Find the V5C"}
        """.utf8)
        let legacy = Data("""
        {"id": "\(UUID().uuidString)", "title": "MOT", "status": "open", "priority": "p2"}
        """.utf8)

        XCTAssertEqual(try decoder.decode(TaskSummary.self, from: with).nextStep, "Find the V5C")
        XCTAssertNil(try decoder.decode(TaskSummary.self, from: legacy).nextStep)
    }

    /// `TaskItem` is what Tasks and Home's `allTasks` decode, and `TaskDetail` what the detail
    /// screen stages from — all three must read the one key, or the card and the detail disagree.
    func testTaskItemAndTaskDetailDecodeTheSameKey() throws {
        let item = try JSONDecoder().decode(TaskItem.self, from: Data("""
        {"id": "\(UUID().uuidString)", "title": "MOT", "status": "open", "priority": "p2",
         "next_step": "Find the V5C"}
        """.utf8))
        XCTAssertEqual(item.nextStep, "Find the V5C")

        let encoded = try JSONEncoder().encode(detail(nextStep: "Ring the garage"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(json["next_step"] as? String, "Ring the garage")
        XCTAssertNil(json["nextStep"])
    }

    // MARK: - Staging: the detail screen's Save diff

    /// A staged line is trimmed, and an empty one is "no next step" — the `notes` rule.
    func testANewLineIsSavedTrimmed() throws {
        XCTAssertEqual(try payload(detail(), staging: "  Find the V5C \n").nextStep, .some("Find the V5C"))
    }

    func testClearingTheLineSavesADelete() throws {
        XCTAssertEqual(try payload(detail(nextStep: "Find the V5C"), staging: "   ").nextStep, .some(nil))
    }

    /// The control pair for the two above: the same line, or a line never staged at all, is not an
    /// edit — otherwise merely OPENING a task with a next step would read as unsaved.
    func testAnUnchangedOrUnstagedLineIsNotAnEdit() throws {
        let task = detail(nextStep: "Find the V5C")
        XCTAssertNil(try payload(task, staging: "Find the V5C").nextStep)
        XCTAssertNil(try payload(task, staging: nil).nextStep)
        XCTAssertFalse(
            TaskDetailDirtyState(original: task, edited: edited(from: task, nextStep: "Find the V5C"))
                .hasUnsavedChanges
        )
        XCTAssertTrue(
            TaskDetailDirtyState(original: task, edited: edited(from: task, nextStep: "Ring the garage"))
                .hasUnsavedChanges
        )
    }

    // MARK: - Reachability: the screen stages, seeds and draws the line

    /// Every assertion above is about the model, and each would pass with no row on screen — the
    /// `dead-shared-component-pattern`. The row is drawn, seeded from the stored task, and handed to
    /// Save and autosave through `currentEditedFields`.
    func testTaskDetailDrawsSeedsAndStagesTheLine() throws {
        let form = try flattened("Tasks/TaskDetailFormSections.swift")
        XCTAssertTrue(form.contains("TextField(\"Next Step\", text: $nextStep, axis: .vertical)"))
        XCTAssertTrue(form.contains("nextStep = task.nextStep ?? \"\""), "the stored line never seeds the field")
        let view = try flattened("Tasks/TaskDetailView.swift")
        XCTAssertTrue(view.contains("atPlaceId: atPlaceId, nextStep: nextStep"), "Save never sees the line")
    }

    private func flattened(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS").appendingPathComponent(relativePath)
        let text = try String(contentsOf: url, encoding: .utf8)
        return text.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }
}
