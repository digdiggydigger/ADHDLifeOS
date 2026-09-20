//
//  TaskDetailAutosaveCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C2-DraftsToInbox`, the autosave half, asserted by reading the tree.
//
//  **The discard gate's removal cannot be caught any other way.** Nothing in either test target
//  ever referenced `showDiscardAlert`, `taskDetailDiscardChangesButton` or
//  `taskDetailKeepEditingButton` — a repo-wide sweep found them in `TaskDetailView.swift` and
//  nowhere else — so the alert could be reinstated tomorrow with the whole suite green. The same
//  is true of `.navigationBarBackButtonHidden(true)`: swipe-back is a system gesture, and no unit
//  test can feel it. What CAN be read is whether the modifier that suppresses it is still there.
//

import XCTest
@testable import ADHD_LifeOS

final class TaskDetailAutosaveCallSiteTests: XCTestCase {

    /// **E, round 2: the blocking "Discard changes?" becomes autosave.** All five pieces of the
    /// gate go together — the flag, the alert, both of its buttons and the dirty check that raised
    /// it. Listed individually rather than as one search so a half-removal names which half.
    func testTheDiscardGateIsGoneEntirely() throws {
        let view = try Self.appCode("Tasks/TaskDetailView.swift")
        let gate = [
            "showDiscardAlert": "the flag that raised the blocking alert",
            "Discard changes?": "the alert itself",
            "taskDetailDiscardChangesButton": "its destructive button",
            "taskDetailKeepEditingButton": "its cancel button",
            "func attemptBack()": "the dirty check that decided whether to block"
        ]
        for (needle, what) in gate {
            XCTAssertFalse(
                view.contains(needle),
                "`\(needle)` — \(what) — survives. E replaced this gate with autosave; leaving the"
                    + " screen must never block."
            )
        }
    }

    /// **Swipe-back is restored, and this is the only test that can see it.** The gesture is the
    /// system's, so no unit test feels it and the UI tests are skipped in the standard run; what a
    /// call-site read CAN prove is that nothing suppresses it any more.
    /// `.navigationBarBackButtonHidden(true)` was what hid the system control, and hiding it is
    /// what disabled the gesture — the view's own comment called that "an accepted outcome".
    /// It is not accepted any more.
    func testNothingSuppressesTheSystemBackButtonOrItsSwipeGesture() throws {
        let view = try Self.appCode("Tasks/TaskDetailView.swift")
        XCTAssertFalse(
            view.contains("navigationBarBackButtonHidden"),
            "The system back button is hidden again, which also kills interactive swipe-back —"
                + " the gesture E asked to have restored."
        )
        XCTAssertFalse(
            view.contains("taskDetailBackButton"),
            "The custom back control is back. It exists only to intercept the gate that is gone,"
                + " and having it means the system control is hidden again."
        )
    }

    /// **The autosave has to be WIRED, and a correct rule proves nothing about that.**
    /// `TaskDetailAutosaveTests` proves `shouldSave` answers correctly; only this proves anything
    /// ever asks it. `.onDisappear` is the trigger because it is the one hook that catches every
    /// way off this screen — the system back button, the swipe gesture and a tab switch alike.
    func testLeavingTheScreenIsWhatCommitsTheStagedEdits() throws {
        let view = try Self.appCode("Tasks/TaskDetailView.swift")
        XCTAssertTrue(
            view.contains(".onDisappear"),
            "Nothing runs when the screen goes away, so backing out discards the staged edits —"
                + " silently now, because the dialog that used to warn about it is gone."
        )
        XCTAssertTrue(
            view.contains("autosaveOnLeaving()"),
            "The disappear hook does not autosave."
        )
        XCTAssertTrue(
            try Self.appCode("Tasks/TaskDetailFormSections.swift").contains("TaskDetailAutosave.shouldSave("),
            "The autosave path does not consult the shared rule, so it can drift from the Save"
                + " button's own enabled condition."
        )
    }

    /// **The explicit Save button STAYS, and that is a decision rather than an oversight.**
    /// Autosave fires as the screen leaves, where nothing can be drawn; the button is what gives a
    /// visible, confirmed save — the existing "Saved" toast and its haptic — to a user who wants
    /// to know the edit landed before they walk away. `feedback.md`: feedback belongs in the
    /// interface.
    func testTheExplicitSaveButtonAndItsConfirmationSurvive() throws {
        let sections = try Self.appCode("Tasks/TaskDetailFormSections.swift")
        XCTAssertTrue(sections.contains("taskDetailSaveButton"), "The explicit Save button is gone.")
        XCTAssertTrue(
            sections.contains("showSavedConfirmation = true"),
            "The \"Saved\" confirmation no longer fires, so a deliberate save says nothing."
        )
    }

    // MARK: - Reading the tree

    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw AutosaveSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum AutosaveSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
