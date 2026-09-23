//
//  ComposerBothDoorsCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-D1-ComposerBothDoors`: the wiring, asserted by reading the tree.
//
//  E, round 6: *"One composer, both doors"* — the Tasks "+" and the capture disc's Task tile open
//  the SAME composer, whose content is *"a title field; four tappable 'when' chips (Not yet ·
//  Today · Tomorrow · Pick a date); and C1's area and time pop-up chips (menus, not sheets). The
//  next step — tags, place and notes — live on the task."*
//
//  **Almost none of this is visible to a behaviour test.** Which view a `.fullScreenCover`
//  presents, which arguments a call site threads, and whether a deleted section's identifier is
//  really gone are all facts about the source — and every one of them fails SILENTLY: a door that
//  still opens the old composer, or opens the new one without `captureClient:`, compiles, runs,
//  and passes every other test in the suite.
//

import XCTest
@testable import ADHD_LifeOS

final class ComposerBothDoorsCallSiteTests: XCTestCase {

    // MARK: - Both doors

    /// **The disc's Task tile opens the task composer**, and hands it every seam it needs.
    ///
    /// Scoped to the cover's own body, deliberately: `RootView.swift` already contains
    /// `captureClient: captureClient` and `taskDetailClient: taskDetailClient` where it builds the
    /// TABS, so a whole-file `contains` would pass on a branch that forgot either — which is the
    /// hole `ComposerDraftCallSiteTests.testEveryScreenThatPresentsAComposerHandsItTheCaptureSeam`
    /// has for this one site.
    func testTheDiscsTaskTileOpensTheTaskComposerWithEverySeam() throws {
        let cover = try Self.slice(
            of: "RootView.swift", from: ".fullScreenCover(item: $composerKind)", to: "restorePersistedSprint"
        )
        XCTAssertTrue(cover.contains("if kind == .task {"), "The composer cover does not branch on the Task kind")
        XCTAssertTrue(cover.contains("TaskCreateView("), "The disc's Task tile still opens Quick Capture")
        XCTAssertTrue(
            cover.contains("QuickCaptureView("),
            "Note, voice, photo and link lost their composer — only .task was meant to move"
        )
        for seam in [
            "captureClient: captureClient",     // an abandoned title files into the inbox (F-C2)
            "taskDetailClient: taskDetailClient", // the Time menu's write
            "homeClient: homeClient"            // the Area menu's list — RootView holds no array
        ] {
            XCTAssertTrue(cover.contains(seam), "The disc's task composer is presented without `\(seam)`")
        }
        XCTAssertEqual(
            cover.components(separatedBy: ".keyboardDismissal()").count - 1, 2,
            "Each of the cover's two composers must keep the keyboard's dismissal gesture"
        )
    }

    /// **The Tasks "+" and "Add to <area>" hand the composer the Time menu's write seam.** Both
    /// already held a `TaskDetailClientAdapting` for task detail; this block threads it through.
    /// "Add to <area>" must also keep landing pre-filed.
    func testTheTwoSheetDoorsThreadTheTimeWriteSeam() throws {
        for file in ["Tasks/TaskListView.swift", "LifeAreaDetail/LifeAreaDetailView.swift"] {
            let call = try Self.slice(of: file, from: "TaskCreateView(", to: ".keyboardDismissal()")
            XCTAssertTrue(
                call.contains("taskDetailClient: taskDetailClient"),
                "\(file) opens the composer without the seam its Time menu writes through"
            )
            XCTAssertTrue(call.contains("captureClient: captureClient"), "\(file) lost the draft seam")
        }
        XCTAssertTrue(
            try Self.slice(
                of: "LifeAreaDetail/LifeAreaDetailView.swift", from: "TaskCreateView(", to: ".keyboardDismissal()"
            ).contains("preselectedLifeAreaId: lifeArea.id"),
            "\"Add to <area>\" no longer opens the composer filed to that area"
        )
    }

    // MARK: - The settled content

    /// **Area is a Menu reading "None"** — the shared `LifeAreaPicker`, which IS a `Menu`, rather
    /// than `ComposerAreaChips`' chip flow; and round 10b's rename (*"'Decide later' and 'No life
    /// area' → 'None', as in the round 7b composer"*) lands here directly.
    func testTheAreaControlIsTheSharedMenuDefaultingToNone() throws {
        let view = try Self.appCode("Tasks/TaskCreateView.swift")
        XCTAssertTrue(view.contains("LifeAreaPicker("), "The composer's Area is not the shared Menu picker")
        XCTAssertTrue(view.contains("noSelectionLabel: \"None\""), "The Area menu's empty choice is not \"None\"")
        XCTAssertFalse(view.contains("ComposerAreaChips("), "The Area control is still a chip flow")
        XCTAssertFalse(view.contains("Decide later"), "\"Decide later\" survived round 10b's rename")
    }

    /// **Time is a Menu**, the fan's three effort chips ported rather than re-drawn as chips.
    func testTheTimeControlIsAMenu() throws {
        let view = try Self.appCode("Tasks/TaskCreateView.swift")
        XCTAssertTrue(view.contains("taskCreateTimeMenu"), "The composer has no Time control")
        let time = try Self.slice(of: "Tasks/TaskCreateView.swift", from: "private var timeMenu", to: "taskCreateTimeMenu")
        XCTAssertTrue(time.contains("Menu {"), "The Time control is not a Menu")
        XCTAssertTrue(time.contains("TaskEffortChoice.allCases"), "The Time menu does not offer the shared choices")
    }

    /// **Tags, place and notes left the composer** — the view renders none of them and the service
    /// holds no state for them. Round 6: *"The next step — tags, place and notes — live on the
    /// task"*, where `TaskDetailFormSections` already edits all three.
    func testTagsPlaceAndNotesLeftTheComposer() throws {
        let view = try Self.appCode("Tasks/TaskCreateView.swift")
        for gone in [
            "taskCreateNotesField", "taskCreateAtPlacePicker", "taskCreateTagChip", "taskCreateNewTagField",
            "taskCreateAddTagButton", "TaskAtPlacePicker(", "notesSection", "tagsSection", "placeSection"
        ] {
            XCTAssertFalse(view.contains(gone), "The composer still renders `\(gone)`")
        }
        let service = try Self.appCode("Tasks/TaskCreateService.swift")
        for gone in [
            "var notes", "atPlaceId", "places", "tagsState", "selectedTagIds", "newTagName",
            "func loadTags", "func loadPlaces", "func addNewTag", "func toggleTagSelection", "attachTags"
        ] {
            XCTAssertFalse(service.contains(gone), "`TaskCreateService` still carries `\(gone)`")
        }
    }

    /// **Pruned, not left dead** — the spec's prune-or-keep call, made. `TaskCreateService` was the
    /// ONLY caller of these three in the app, so keeping them would have left
    /// `FirebaseTaskCreateClientAdapter`'s implementations reachable only from their own tests:
    /// the `dead-shared-component-pattern` this repo has hit seven times. The backing store
    /// narrows with them; `FirebaseManager` keeps the methods, which other seams still use.
    func testTheCreateSeamNoLongerCarriesTags() throws {
        for file in [
            "Tasks/TaskCreateClientAdapting.swift", "Tasks/FirebaseTaskCreateClientAdapter.swift",
            "Tasks/TaskCreateBackingStore.swift"
        ] {
            let source = try Self.appCode(file)
            for gone in ["fetchTags", "createTag", "attachTags", "addTagId"] {
                XCTAssertFalse(source.contains(gone), "\(file) still declares `\(gone)`")
            }
        }
    }

    // MARK: - Quick Capture's dead Task path

    /// **Deleted once no door can reach it.** `RootView` branches `.task` away and the inbox's own
    /// composer never passed it, so the fast-task path — and the two clients only it used — would
    /// otherwise be code no user can run. `CaptureComposerCopy`'s `.task` arms stay: the kind
    /// still exists and the inbox still labels a stored `.task` capture with it.
    func testQuickCaptureNoLongerHasATaskPath() throws {
        for file in ["Capture/QuickCaptureView.swift", "Capture/QuickCaptureComponents.swift"] {
            let source = try Self.appCode(file)
            for gone in [
                "saveTask", "isTaskKind", "effortSection", "effortChip", "taskEffortSeconds",
                "taskErrorMessage", "taskCreateClient", "taskDetailClient", "quickCaptureEffort-"
            ] {
                XCTAssertFalse(source.contains(gone), "\(file) still carries the Task path's `\(gone)`")
            }
        }
    }

    // MARK: - Reading the tree

    private static func slice(of file: String, from start: String, to end: String) throws -> String {
        let source = try appCode(file)
        guard let lower = source.range(of: start) else {
            throw SourceError.missing("`\(start)` in \(file)")
        }
        guard let upper = source.range(of: end, range: lower.upperBound..<source.endIndex) else {
            throw SourceError.missing("`\(end)` after `\(start)` in \(file)")
        }
        return String(source[lower.lowerBound..<upper.upperBound])
    }

    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.missing(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum SourceError: Error, CustomStringConvertible {
        case missing(String)

        var description: String {
            switch self {
            case .missing(let what): return "Could not find \(what) in the tree this test was compiled from."
            }
        }
    }
}
