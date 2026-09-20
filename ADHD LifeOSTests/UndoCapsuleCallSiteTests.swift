//
//  UndoCapsuleCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C1-UndoCapsule`: the wiring, asserted by reading the tree.
//
//  **These exist because the failure mode of this block is silence.** A close surface that records
//  nothing still closes the task, still buzzes, still pops its confetti and still passes every
//  behaviour test in the suite — it just never offers the undo. Nothing but a call-site sweep can
//  catch that, which is the same reasoning `CelebrationMountCallSiteTests` records for its own
//  four mounts, and the reason the spec calls for a NEW test per surface rather than a reversed
//  one: grepping the tree found no existing test asserting no-undo at any of the four sites.
//

import XCTest
@testable import ADHD_LifeOS

final class UndoCapsuleCallSiteTests: XCTestCase {

    // MARK: - The app's own wiring

    /// Both keys, on the App rather than in `RootView`. A site that cannot see the centre records
    /// into `InertRecentActionRecorder` and says nothing about it, so this is the one thing no
    /// behaviour test can notice.
    func testTheAppOwnsTheCentreAndInjectsBothEnvironmentKeys() throws {
        let app = try Self.appCode("ADHD_LifeOSApp.swift")
        XCTAssertTrue(
            app.contains("@StateObject private var recentActionCenter = RecentActionCenter()"),
            "The App does not own the centre, so it is rebuilt on every auth-state swap and drops"
                + " whatever undo was pending."
        )
        XCTAssertTrue(
            app.contains(".environment(\\.recordAction, recentActionCenter)"),
            "Nothing injects the recorder, so every one of the five sites records into the inert"
                + " default and no capsule ever appears."
        )
        XCTAssertTrue(
            app.contains(".environment(\\.recentActionCenter, recentActionCenter)"),
            "Nothing injects the object, so the capsule slot draws nothing however many actions"
                + " are recorded."
        )
    }

    /// The capsule is the disc row's occupant, wrapping the band rather than joining it — which is
    /// what makes it stand IN FOR the search row and the Journal's pencil (E's round 2b and her
    /// Step 0 answer 4) instead of pushing the capture disc along.
    func testTheCapsuleSlotWrapsTheDiscRowsLeadingBand() throws {
        let overlay = try Self.appCode("RootBottomOverlay.swift")
        XCTAssertTrue(
            overlay.contains("UndoCapsuleSlot {"),
            "The disc row does not mount the capsule slot, so no close anywhere in the app shows"
                + " its undo."
        )
        XCTAssertTrue(
            overlay.contains("leadingBand"),
            "The slot has no fallback band, so the search row and the pencil disc are gone for good"
                + " rather than displaced while a capsule is up."
        )
        XCTAssertFalse(
            overlay.contains("if let placeholder = searchScope.placeholder {\n                AppSearchRow"),
            "The search row is still a sibling of the capsule in the `HStack`, so both would show"
                + " at once and the capture disc would be pushed off the row."
        )
    }

    /// `voiceover.md › Best practices`: *"Inform VoiceOver when visible content or layout changes
    /// occur."* Two things change when a close lands — the capsule arrives and, on Tasks, the
    /// search row leaves — and both are out of a VoiceOver user's way unless announced. A silent
    /// capsule passes every other test in this file, which is why this one exists.
    func testTheCapsulesArrivalIsAnnouncedToVoiceOver() throws {
        let capsule = try Self.appCode("Undo/UndoCapsule.swift")
        XCTAssertTrue(
            capsule.contains("UIAccessibility.post(notification: .announcement"),
            "The capsule arrives silently, so the one affordance this block adds is invisible to"
                + " VoiceOver."
        )
        XCTAssertTrue(
            capsule.contains("action.accessibilityAnnouncement"),
            "The announcement does not use the recorded action's own words, so it can drift from"
                + " what the capsule draws."
        )
    }

    /// **Found by LOOKING, not by a test** — the first simulator render showed the Undo button as
    /// "Un…". In a tight `HStack` SwiftUI compresses whichever child will give, and beside a
    /// two-line subject the child that gave was the one control in the capsule that must never be
    /// ambiguous. Truncation is not a property a unit test can see, so the two modifiers that fix
    /// it are pinned by name here instead — §1's Layout Safety rule names `.layoutPriority(1)` for
    /// exactly this case.
    func testTheUndoControlCannotBeSqueezedOrTruncated() throws {
        let capsule = try Self.appCode("Undo/UndoCapsule.swift")
        XCTAssertTrue(
            capsule.contains(".fixedSize(horizontal: true, vertical: false)"),
            "The Undo label may compress again, which is how \"Undo\" became \"Un…\"."
        )
        XCTAssertTrue(
            capsule.contains(".layoutPriority(1)"),
            "The Undo button has no layout priority, so a long subject takes its width."
        )
        XCTAssertTrue(
            capsule.contains(".minimumScaleFactor(0.8)"),
            "Nothing lets the SUBJECT give instead, so the row has no slack anywhere."
        )
    }

    // MARK: - The five close surfaces (E, round 1 + Step 0 answers 1 and 3)

    /// One row per surface: the file, and the recording it must contain. A table rather than five
    /// near-identical methods, because the thing under test is the SET — a sixth close surface
    /// added without a recording is exactly what this is here to catch.
    private static let closeSurfaces: [(file: String, why: String)] = [
        ("Tasks/TaskListView.swift", "the Tasks list's tap-circle and swipe"),
        ("Tasks/TaskSearchSurface.swift", "the search surface's rows"),
        ("Tasks/TaskDetailFormSections.swift", "task detail's own Close button"),
        ("Home/HomeMomentumSections.swift", "Today's hero"),
        ("LifeAreaDetail/LifeAreaDetailView.swift", "a life area's task tick")
    ]

    func testEveryCloseSurfaceRecordsATaskClosedAction() throws {
        for surface in Self.closeSurfaces {
            let source = try Self.appCode(surface.file)
            XCTAssertTrue(
                source.contains("recordAction.record("),
                "\(surface.file) never records, so closing from \(surface.why) offers no undo."
            )
            XCTAssertTrue(
                source.contains("RecentAction(kind: .taskClosed, subject:"),
                "\(surface.file) records something other than a task close, so the capsule would"
                    + " name \(surface.why) wrongly."
            )
        }
    }

    /// The reversal is the site's own, because only the site knows its service. A recorded action
    /// whose closure does nothing would show a capsule whose Undo silently fails.
    func testEveryCloseSurfaceHandsOverAReversalThatReopensTheTask() throws {
        let reopeners: [(file: String, call: String)] = [
            ("Tasks/TaskListView.swift", "await tasksService.reopen(task)"),
            ("Tasks/TaskSearchSurface.swift", "await service.reopen(task)"),
            ("Tasks/TaskDetailFormSections.swift", "await service.reopen()"),
            ("Home/HomeMomentumSections.swift", "await undoClose(task)"),
            ("LifeAreaDetail/LifeAreaDetailView.swift", "await reopenTask(task)")
        ]
        for reopener in reopeners {
            let source = try Self.appCode(reopener.file)
            XCTAssertTrue(
                source.contains(reopener.call),
                "\(reopener.file) records an undo that never reopens anything."
            )
        }
    }

    /// E's Step 0 answer 3: *"Yes, a nudge dismiss gets the capsule"*. Held by the SERVICE, so
    /// both `NudgeDueCard` hosts are covered by one rule rather than two copies of it.
    func testTheNudgeDismissRecordsAndItsReversalUnmarksTheFiring() throws {
        let service = try Self.appCode("Nudges/NudgesService.swift")
        XCTAssertTrue(
            service.contains("RecentAction(kind: .nudgeDismissed, subject: nudge.label)"),
            "A \"Done for now\" records no undo, so E's fifth capsule kind never appears."
        )
        XCTAssertTrue(
            service.contains("await self?.restore(nudge)"),
            "The nudge's undo does not restore it."
        )
        XCTAssertTrue(
            service.contains("client.unmarkFired("),
            "`restore` does not write, so the stamps stay and the nudge is still dismissed."
        )
    }

    /// Both hosts wire the recorder in, and neither can do it in an `init`.
    func testBothServicesThatOwnTheirRuleAreWiredByTheirHost() throws {
        XCTAssertTrue(
            try Self.appCode("Home/HomeView.swift").contains("nudgesService.recordAction = recordAction"),
            "Home never hands the recorder to its nudges service, so every \"Done for now\""
                + " records into the inert default."
        )
        XCTAssertTrue(
            try Self.appCode("Capture/CaptureInboxView.swift").contains("service.recordAction = recordAction"),
            "The Capture Inbox never hands the recorder to its service, so no triage offers an undo."
        )
    }

    // MARK: - The Capture Inbox's migration (E, round 2 + Step 0 answer 2)

    /// The screen's own bar is gone; it does not sit BESIDE the capsule. The spec is explicit that
    /// `CaptureInboxUndoSections` is the pattern to migrate ONTO the capsule, not to leave beside
    /// it — two undo bars on one screen is the outcome this catches.
    func testTheInboxsOwnUndoBarIsGoneRatherThanLeftBesideTheCapsule() throws {
        let sections = try Self.appCode("Capture/CaptureInboxUndoSections.swift")
        XCTAssertFalse(
            sections.contains("var undoBar: some View"),
            "The inbox still draws its own undo bar, so a sorted capture offers two undos in two"
                + " places in two visual languages."
        )
        XCTAssertFalse(
            sections.contains("captureInboxUndoBar"),
            "The retired bar's identifier is still in the tree."
        )
        XCTAssertFalse(
            try Self.appCode("Capture/CaptureInboxService.swift").contains("var lastTriageAction"),
            "The service still holds its own slot beside the app's — the mirrored copy that goes"
                + " stale the moment a task is closed on another tab."
        )
    }

    /// E chose to KEEP the header ↶ over the recommendation to retire it, *as a second route
    /// reading the SAME undo*. So it reads the shared centre, and only for a REVERSIBLE capture
    /// action — an arrow in the Capture Inbox that reopened a task would be the wrong promise in
    /// the wrong place.
    ///
    /// **The exhaustive `switch` earned itself in `F-C2`.** Adding `draftKeptInInbox` failed the
    /// BUILD rather than silently inheriting a branch, which is what this test's own failure
    /// message predicted. A filed draft is a capture action and is still excluded: this glyph
    /// promises to take something back, and a draft is kept.
    func testTheHeaderArrowReadsTheSharedSlotAndOnlyForACaptureAction() throws {
        let sections = try Self.appCode("Capture/CaptureInboxUndoSections.swift")
        XCTAssertTrue(
            sections.contains("@ObservedObject var center: RecentActionCenter"),
            "The header arrow does not observe the centre, so it appears and vanishes only when"
                + " something else happens to redraw the screen."
        )
        XCTAssertTrue(
            sections.contains("case .captureSorted, .captureSkipped, .captureJournalled: return true"),
            "The header arrow does not restrict itself to capture actions."
        )
        XCTAssertTrue(
            sections.contains("case .taskClosed, .nudgeDismissed, .draftKeptInInbox, nil: return false"),
            "The header arrow's kind check is not exhaustive, so a sixth kind would silently"
                + " inherit whichever branch it fell into."
        )
    }

    /// **Reversed by `F-C2-DraftsToInbox`, not deleted — and what it protects is unchanged.** It
    /// used to pin the literal `Label("Undo", systemImage: "arrow.uturn.backward")`, because
    /// `SignedInJourneyUITests` addresses the control as `app.buttons["Undo"]` and UI tests are
    /// skipped in the standard run, so a relabel would break that journey with every gate green.
    ///
    /// E's *"Kept in your inbox · Reopen"* means the control's word is no longer always "Undo", so
    /// the literal had to go. **The protection moved rather than lapsed**, and it now takes two
    /// tests: this one reads that the view asks the KIND for its word, and
    /// `testOnlyTheFiledDraftOffersReopenAndEveryReversalStillSaysUndo` pins that every kind the
    /// journey can reach still answers "Undo". Split this way neither half can drift; pinned as a
    /// literal it could only have been deleted.
    func testTheUndoControlTakesItsWordFromTheActionRatherThanALiteral() throws {
        let capsule = try Self.appCode("Undo/UndoCapsule.swift")
        XCTAssertTrue(
            capsule.contains("Label(action.kind.actionLabel, systemImage: action.kind.actionSystemImage)"),
            "The control does not read its word and glyph from the action, so a filed draft would"
                + " offer to \"Undo\" something the app then keeps."
        )
        XCTAssertFalse(
            capsule.contains("accessibilityLabel(\"Undo \u{2014}"),
            "The Undo button took a richer accessibility label, which overrides the plain one the"
                + " capture journey addresses it by \u{2014} and that journey does not run in the standard suite."
        )
        XCTAssertTrue(
            try Self.appCode("../ADHD LifeOSUITests/SignedInJourneyUITests.swift").contains("undoCapsule"),
            "The capture journey still names the retired `captureInboxUndoBar` in its failure."
        )
    }

    // MARK: - What the block retired

    /// The `dead-shared-component-pattern` memory, applied: seven prior instances, always found by
    /// grep and never by the tests that were still passing on the dead code. These three went with
    /// the closure card, so the guard is that nothing is left holding them up.
    func testTheClosureCardAndItsTwoCopyHelpersAreGoneFromTheWholeTree() throws {
        let retired = ["ClosureCelebrationCard", "celebrationLine(", "nextButtonLabel(", "celebratedTask"]
        for file in try Self.everyAppSourceFile() {
            let source = try Self.appCode(file)
            for name in retired {
                XCTAssertFalse(
                    source.contains(name),
                    "`\(name)` survives in \(file). It was retired with Home's in-place close card;"
                        + " left behind it is dead code that every test still passes over."
                )
            }
        }
    }

    // MARK: - Reading the tree

    private static func everyAppSourceFile() throws -> [String] {
        let root = appRoot()
        guard let walker = FileManager.default.enumerator(atPath: root.path) else {
            throw UndoCapsuleSourceError.unreadable(root.path)
        }
        let files = walker.compactMap { $0 as? String }.filter { $0.hasSuffix(".swift") }
        guard files.count > 100 else {
            throw UndoCapsuleSourceError.unreadable("\(root.path) yielded only \(files.count) Swift files")
        }
        return files
    }

    private static func appRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    /// The same source with every comment line removed, because these files document the very
    /// names the assertions look for — the retirement notes above name `ClosureCelebrationCard`
    /// and `celebratedTask` on purpose, and a whole-file read would fail on its own history.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = appRoot().appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw UndoCapsuleSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum UndoCapsuleSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
