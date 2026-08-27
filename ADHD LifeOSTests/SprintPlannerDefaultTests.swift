//
//  SprintPlannerDefaultTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Task Detail planner's opening values (E's 2026-08-28 fix). The one-tap starts have honoured
/// `MomentumPreferences.defaultSprintMinutes` since the 2026-08-25 Settings audit, but the detail
/// screen's planner still seeded from `FocusSprintConfiguration`'s hardcoded standard — so a task
/// with no stored config opened at 15 minutes however the setting was configured, and starting
/// from there ran the wrong sprint.
///
/// Seeding is only half of the fix. The dirty-state engine diffs the staged config against the
/// RESOLVED original, so unless the same default reaches that comparison, merely OPENING an
/// untuned task would light Save up and arm the discard alert on a screen nobody edited — and a
/// save for some unrelated field would quietly pin the default onto the task forever. Both halves
/// are pinned here.
final class SprintPlannerDefaultTests: XCTestCase {

    private final class FakePlacesClient: PlacesClientAdapting {
        func fetchPlaces() async throws -> [Place] { [] }
        func savePlace(_ place: Place) async throws {}
        func deletePlace(id: UUID) async throws {}
    }

    /// Test double for the preferences seam — the real store reads `UserDefaults.standard`, which
    /// would leak the running simulator's own settings into the assertions below.
    private final class FakePreferencesStore: MomentumPreferencesStoring {
        private var preferences: MomentumPreferences

        init(defaultSprintMinutes: Int) {
            preferences = MomentumPreferences(
                dailyGoal: 5, showStreaks: true, defaultSprintMinutes: defaultSprintMinutes
            )
        }

        func read() -> MomentumPreferences { preferences.normalized() }
        func write(_ preferences: MomentumPreferences) { self.preferences = preferences.normalized() }
    }

    /// A deliberately non-standard setting, so a value resolving to 900 is unambiguously the old
    /// hardcoded default rather than a coincidence.
    private let pomodoroDefaultSeconds = 25 * 60

    private func untunedTask() -> TaskDetail {
        TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Untuned task", notes: nil,
            status: .open, priority: .p4, dueDate: nil, createdAt: Date()
        )
    }

    private func tunedTask(durationSeconds: Int, nudges: Int? = nil) -> TaskDetail {
        TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Tuned task", notes: nil,
            status: .open, priority: .p4, dueDate: nil, createdAt: Date(),
            focusDurationSeconds: durationSeconds, nudgesCount: nudges
        )
    }

    /// What `TaskDetailView.onAppear` stages: the resolved config plus every other field left at
    /// the original's value, i.e. a screen that has been opened and not touched.
    private func seededFields(
        for task: TaskDetail, defaultSprintSeconds: Int
    ) -> TaskEditedFields {
        let duration = FocusSprintConfiguration.resolvedDuration(
            explicit: task.focusDurationSeconds, defaultSeconds: defaultSprintSeconds
        )
        return TaskEditedFields(
            title: task.title, notes: task.notes ?? "", lifeAreaId: task.lifeAreaId,
            priority: task.priority, dueDate: task.dueDate,
            focusDurationSeconds: duration,
            nudgesCount: FocusSprintConfiguration.resolvedNudgeCount(
                explicit: task.nudgesCount, durationSeconds: duration
            ),
            atPlaceId: task.atPlaceId
        )
    }

    // MARK: - The seed itself

    func testPlannerSeed_untunedTask_opensAtTheSettingsDefault() {
        let seeded = seededFields(for: untunedTask(), defaultSprintSeconds: pomodoroDefaultSeconds)

        XCTAssertEqual(
            seeded.focusDurationSeconds, pomodoroDefaultSeconds,
            "the planner opens at the user's chosen default, not the hardcoded 15-minute standard"
        )
    }

    func testPlannerSeed_tunedTask_opensAtItsOwnStoredConfig() {
        let seeded = seededFields(
            for: tunedTask(durationSeconds: 600), defaultSprintSeconds: pomodoroDefaultSeconds
        )

        XCTAssertEqual(
            seeded.focusDurationSeconds, 600,
            "a task's own stored config always wins over the setting"
        )
    }

    // MARK: - Opening a screen is not an edit

    func testUpdateDiff_untunedTaskSeededFromTheSetting_writesNothing() throws {
        let original = untunedTask()

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original,
            edited: seededFields(for: original, defaultSprintSeconds: pomodoroDefaultSeconds),
            defaultSprintSeconds: pomodoroDefaultSeconds
        )

        let payload = try XCTUnwrap(try? result.get())
        XCTAssertNil(
            payload.focusDurationSeconds,
            "seeding from the setting is not an edit — it must not manufacture a write"
        )
        XCTAssertNil(payload.nudgesCount)
        XCTAssertTrue(payload.isEmpty, "an untouched screen sends nothing at all")
    }

    func testDirtyState_untunedTaskSeededFromTheSetting_isClean() {
        let original = untunedTask()

        let state = TaskDetailDirtyState(
            original: original,
            edited: seededFields(for: original, defaultSprintSeconds: pomodoroDefaultSeconds),
            defaultSprintSeconds: pomodoroDefaultSeconds
        )

        XCTAssertFalse(
            state.hasUnsavedChanges,
            "opening an untuned task must not light Save up or arm the discard alert"
        )
    }

    // MARK: - A real change still writes

    func testUpdateDiff_movingOffTheDefault_writesTheNewDuration() throws {
        let original = untunedTask()
        var edited = seededFields(for: original, defaultSprintSeconds: pomodoroDefaultSeconds)
        edited.focusDurationSeconds = 900

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: edited, defaultSprintSeconds: pomodoroDefaultSeconds
        )

        let payload = try XCTUnwrap(try? result.get())
        XCTAssertEqual(
            payload.focusDurationSeconds, 900,
            "the old standard is now a deliberate choice away from the default, so it must persist"
        )
    }

    func testUpdateDiff_changingNudgesOnASeededScreen_writesTheNewCount() throws {
        let original = untunedTask()
        var edited = seededFields(for: original, defaultSprintSeconds: pomodoroDefaultSeconds)
        edited.nudgesCount = 5

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: edited, defaultSprintSeconds: pomodoroDefaultSeconds
        )

        let payload = try XCTUnwrap(try? result.get())
        XCTAssertEqual(payload.nudgesCount, 5)
    }

    // MARK: - The default's own default (every legacy call site)

    func testUpdateDiff_omittedDefault_keepsTheHardcodedStandardSemantics() throws {
        let original = untunedTask()
        var edited = seededFields(for: original, defaultSprintSeconds: pomodoroDefaultSeconds)
        edited.focusDurationSeconds = FocusSprintConfiguration.defaultDurationSeconds

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        let payload = try XCTUnwrap(try? result.get())
        XCTAssertNil(
            payload.focusDurationSeconds,
            "call sites that pass no default still diff against the 15-minute standard"
        )
    }

    // MARK: - The service resolves the setting once, and the view seeds from it

    @MainActor
    func testService_readsTheDefaultSprintLengthFromPreferences() {
        let sut = TaskDetailService(
            taskId: UUID(), client: FakeTaskDetailClientAdapting(),
            placesClient: FakePlacesClient(),
            preferencesStore: FakePreferencesStore(defaultSprintMinutes: 25)
        )

        XCTAssertEqual(sut.defaultSprintSeconds, pomodoroDefaultSeconds)
    }

    @MainActor
    func testService_defaultSprintLengthIsClampedLikeEveryOtherDuration() {
        let sut = TaskDetailService(
            taskId: UUID(), client: FakeTaskDetailClientAdapting(),
            placesClient: FakePlacesClient(),
            preferencesStore: FakePreferencesStore(defaultSprintMinutes: 9_999)
        )

        XCTAssertEqual(
            sut.defaultSprintSeconds,
            MomentumPreferences.sprintMinutesRange.upperBound * 60,
            "the store normalizes on read, so an out-of-range setting can never reach the planner"
        )
    }
}
