//
//  ComposerDraftCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C2-DraftsToInbox`: the wiring, asserted by reading the tree.
//
//  **The failure mode of this block is silence, exactly as `F-C1`'s was.** A composer that files
//  nothing still closes, still looks right, and still passes every test about the composer — it
//  just loses the user's words, which is the one thing this arc exists to stop. Worse, the
//  `captureClient` argument is OPTIONAL by design (so previews build unchanged), so a call site
//  that forgets it compiles, runs, and quietly does nothing. That is the
//  `dead-shared-component-pattern` shape this repo has hit seven times, and only a call-site sweep
//  catches it.
//

import XCTest
@testable import ADHD_LifeOS

final class ComposerDraftCallSiteTests: XCTestCase {

    /// Every composer files on the way out, and every one of them uses the same hook.
    ///
    /// **`.onDisappear` is the mechanism the spec's Step 0 answer 2 asked for**: file once the
    /// sheet has ACTUALLY gone, so a swipe keeps dismissing exactly as it does today and a
    /// half-swipe that springs back files nothing by construction rather than by a guard. It is
    /// also the only hook that covers Quick Capture's two presentations at once — a
    /// `.fullScreenCover` from the capture disc and a `.sheet` from the Capture Inbox.
    func testAllThreeComposersFileWhateverWasTypedWhenTheyClose() throws {
        let composers = [
            "Capture/QuickCaptureView.swift": "Quick Capture",
            "Tasks/TaskCreateView.swift": "the task composer",
            "Journal/LogComposerView.swift": "the journal composer"
        ]
        for (file, what) in composers {
            let source = try Self.appCode(file)
            XCTAssertTrue(
                source.contains(".onDisappear { fileDraftIfNeeded() }"),
                "\(what) does not file on the way out, so closing it still loses the user's words."
            )
        }
    }

    /// **The submit path must not double-file.** After a successful create the text is still in
    /// the service when the sheet dismisses, so `.onDisappear` would file the just-saved words a
    /// second time as an abandoned draft — the user would find a duplicate note in the inbox every
    /// time they used a composer properly.
    func testASuccessfulSubmitFilesNothing() throws {
        let composers = [
            "Capture/QuickCaptureView.swift", "Tasks/TaskCreateView.swift",
            "Journal/LogComposerView.swift"
        ]
        for file in composers {
            XCTAssertTrue(
                try Self.appCode(file).contains("didSubmit = true"),
                "\(file) never marks a successful submit, so submitting would ALSO file a draft."
            )
        }
        for file in ["Capture/QuickCaptureView.swift", "Tasks/TaskCreateView+Drafts.swift",
                     "Journal/LogComposerView+Drafts.swift"] {
            XCTAssertTrue(
                try Self.appCode(file).contains("guard !didSubmit"),
                "\(file) files without checking whether the composer had already submitted."
            )
        }
    }

    /// **The four real call sites, and the argument is optional so a missed one is SILENT.**
    /// `captureClient:` defaults to `nil` so every preview builds unchanged; the cost is that a
    /// composer presented without it files nothing and says nothing about it. These are the only
    /// four places in the app that present a composer.
    func testEveryScreenThatPresentsAComposerHandsItTheCaptureSeam() throws {
        let sites: [(file: String, what: String)] = [
            ("Tasks/TaskListView.swift", "the Tasks list's + button"),
            ("LifeAreaDetail/LifeAreaDetailView.swift", "a life area's \"Add to area\""),
            ("Journal/JournalView.swift", "the Journal's pencil"),
            ("RootView.swift", "the capture disc's full-screen composer")
        ]
        for site in sites {
            XCTAssertTrue(
                try Self.appCode(site.file).contains("captureClient: captureClient"),
                "\(site.file) presents a composer without the capture seam, so a draft abandoned"
                    + " from \(site.what) is lost silently."
            )
        }
    }

    /// **"Close", not "Cancel", on all three** — E, round 2, carried by every option she was shown.
    /// `sheets.md › Best practices` is the reason she gave: Cancel means *without saving*, and
    /// these controls no longer discard.
    func testAllThreeComposersSayCloseRatherThanCancel() throws {
        let composers = [
            "Capture/QuickCaptureView.swift", "Tasks/TaskCreateView.swift",
            "Journal/LogComposerView.swift"
        ]
        for file in composers {
            let source = try Self.appCode(file)
            XCTAssertTrue(source.contains("Button(\"Close\") { dismiss() }"), "\(file) still says Cancel.")
            XCTAssertFalse(
                source.contains("Button(\"Cancel\") { dismiss() }"),
                "\(file) still carries the old Cancel button beside the new Close."
            )
        }
    }

    /// The three dismiss controls had **no accessibility identifier at all** before this block —
    /// the only interactive controls on any of the three composers without one, so no test could
    /// address them and nothing would have noticed the relabel either way. Added with the rename
    /// so the next change to them is catchable.
    func testTheThreeCloseControlsAreAddressable() throws {
        let identifiers = [
            "Capture/QuickCaptureView.swift": "quickCaptureCloseButton",
            "Tasks/TaskCreateView.swift": "taskCreateCloseButton",
            "Journal/LogComposerView.swift": "logComposerCloseButton"
        ]
        for (file, identifier) in identifiers {
            XCTAssertTrue(
                try Self.appCode(file).contains(identifier),
                "\(file)'s Close control is still unaddressable by any test."
            )
        }
    }

    /// **The journal composer must CLEAR its body once the draft is safe** — the spec's named
    /// trap. `composerBody` lives on `JournalService`, which outlives the view, so filing without
    /// clearing leaves the same words in two places: a capture in the inbox, and text waiting in
    /// the service for the next time the composer opens.
    ///
    /// **Cleared only when the write LANDED**, which is why the call is inside the `if`. Clearing
    /// after a failed write would destroy the only copy of the thought.
    func testTheJournalComposerClearsItsBodyOnlyOnceTheDraftIsSafelyFiled() throws {
        let drafts = try Self.appCode("Journal/LogComposerView+Drafts.swift")
        XCTAssertTrue(
            drafts.contains("if await filer.fileIfNeeded(text) {")
                && drafts.contains("journalService.composerBody = \"\""),
            "The journal composer either does not clear its body, or clears it without checking"
                + " that the draft was actually written."
        )
    }

    /// **The Reopen door is wired end to end**, and none of its three pieces can be seen by a
    /// behaviour test: the environment value a composer reads, the door `RootView` answers it
    /// with, and the drain on the far side that turns a parked id into an open capture.
    func testTheReopenDoorIsWiredFromTheComposerToTheInbox() throws {
        XCTAssertTrue(
            try Self.appCode("RootView.swift").contains(".environment(\\.openCapture, openCaptureDoor)"),
            "`RootView` injects no way to open a capture, so every filed draft's Reopen does nothing."
        )
        XCTAssertTrue(
            try Self.appCode("RootView+Doors.swift").contains("selectedTab = .captures"),
            "The Reopen door never switches to the Captures tab."
        )
        XCTAssertTrue(
            try Self.appCode("Capture/CaptureInboxUndoSections.swift").contains("func drainReopenDoor()"),
            "Nothing on the Captures tab takes the parked capture id, so Reopen switches tab and"
                + " then does nothing visible."
        )
        XCTAssertTrue(
            try Self.appCode("Capture/CaptureInboxView.swift").contains("await drainReopenDoor()"),
            "The inbox never calls its own drain."
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
            throw ComposerDraftSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum ComposerDraftSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
