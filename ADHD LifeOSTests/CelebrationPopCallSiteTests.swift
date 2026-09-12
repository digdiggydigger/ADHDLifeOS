//
//  CelebrationPopCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-4`'s reachability guards for E's F6 — the mini confetti pop, on the nine
//  in-place moments E chose ("celebrate DOING, not ADDING").
//
//  **These exist because `F-CTACelebrations-3` built `CelebrationPopSource`, `CelebrationKind.pop`
//  and `CelebrationRecipes.pop` and left them with NO production call site.** Every one of them was
//  unit-tested and correct, and a user could not have made a single piece of paper appear. Tests
//  prove correctness, never REACHABILITY, so this file greps the tree for the call.
//
//  **Each guard is scoped to its CLOSURE, not its file** — a pop somewhere else in the same view
//  is not the same feature. The rule E's design sets is that the pop line sits INSIDE the same
//  closure as the site's own haptic, so the feel and the paper can never drift apart, and that is
//  what is asserted. Source is read with comment lines stripped and, where a call is wrapped over
//  several lines, flattened to one — the `*CallSiteTests` house shape.
//
//  **Two shapes, and the difference is deliberate.** Eight controls are wrapped in
//  `CelebrationPopSource`, whose measured centre IS the control. `TaskRow` cannot be: its circle
//  and its swipe share one `close()` method, so the wrapper would have to enclose the whole row and
//  the paper would leave from the middle of it. It uses the same file's other half instead —
//  `.celebrationPopOrigin` on the circle, held in `@State`, requested in `close()` — so both close
//  paths pop from the circle, which is the origin E approved by looking.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationPopCallSiteTests: XCTestCase {

    // MARK: - The ten code sites (nine moments; Sorted lives in two files)

    func testTheTaskRowsCloseCirclePopsFromTheCircleItself() throws {
        try assertPops(
            in: "Tasks/TaskRow.swift", afterHaptic: "private func close() { Haptics.play(.taskClose)",
            upTo: "var body: some View", pop: "celebrate.request(.pop, at: popOrigin)",
            because: "closing a task from the Tasks list is E's first in-place moment"
        )
    }

    func testTheTaskDetailsCloseItButtonPops() throws {
        try assertPops(
            in: "Tasks/TaskDetailFormSections.swift", afterHaptic: "Button { Haptics.play(.taskClose)",
            upTo: "} label: {", pop: "handle.pop()",
            because: "the detail screen's Close it is the same moment as the row's circle"
        )
    }

    func testTheLifeAreaRowsTickPops() throws {
        try assertPops(
            in: "LifeAreaDetail/AreaTaskRow.swift", afterHaptic: "Button { Haptics.play(.taskClose)",
            upTo: "} label: {", pop: "handle.pop()",
            because: "a life-area row closes a task exactly as the Tasks list does"
        )
    }

    func testHomesBestNextMoveCloseItButtonPops() throws {
        try assertPops(
            in: "Home/MomentumScoreboardViews.swift", afterHaptic: "Button { Haptics.play(.taskClose)",
            upTo: "} label: {", pop: "handle.pop()",
            because: "Home's Best-next-move is the fourth way to close a task"
        )
    }

    func testTheTriageCardsSortedButtonPops() throws {
        try assertPops(
            in: "Capture/CaptureInboxSections.swift",
            afterHaptic: "guard let area else { return } Haptics.play(.success)",
            upTo: "} label: {", pop: "handle.pop()",
            because: "Sorted is one of E's three doing verbs on a capture"
        )
    }

    func testTheTriageCardsJournalItButtonPops() throws {
        try assertPops(
            in: "Capture/CaptureInboxSections.swift",
            afterHaptic: "Button(\"Journal it\") { Haptics.play(.success)",
            upTo: ".buttonStyle(MomentumBorderedButtonStyle())", pop: "handle.pop()",
            because: "Journal it is the second doing verb"
        )
    }

    func testTheCaptureDetailsSortedButtonPops() throws {
        try assertPops(
            in: "Capture/CaptureDetailComponents.swift",
            // Named all the way down from `sortedButton`, because `Button { Haptics.play(.success)`
            // on its own matches this file TWICE — the other one is "Make a task", which is an
            // ADDING verb and deliberately has no pop.
            afterHaptic: "private var sortedButton: some View { CelebrationPopSource { handle in"
                + " Button { Haptics.play(.success)",
            upTo: "} label: {", pop: "handle.pop()",
            because: "Sorted from the full capture is the same verb reached another way"
        )
    }

    /// The one site whose pop is not in the button's own closure: a create can FAIL, and E's rule
    /// is that a celebration marks something that happened. It goes where the success haptic
    /// already goes, after the await.
    func testTheCreateTaskButtonPopsOnlyAfterTheCreateSucceeded() throws {
        let create = try slice(
            in: "Capture/CaptureRowComponents.swift", from: "private func create(",
            to: "struct CaptureRowLeadingSlot"
        )
        let succeeded = try XCTUnwrap(
            create.range(of: "if succeeded {"),
            "CreateTaskButton no longer branches on success, so nothing can be hung off it."
        )
        let pop = try XCTUnwrap(
            create.range(of: "pop()"),
            "Create Task never pops, so E's third doing verb is the only one with no paper."
        )
        XCTAssertLessThan(
            succeeded.lowerBound, pop.lowerBound,
            "Create Task pops before it knows the create worked, so a failure celebrates."
        )
    }

    func testTheNudgesDoneForNowButtonPops() throws {
        try assertPops(
            in: "Nudges/NudgeDueCard.swift",
            afterHaptic: "Button(\"Done for now\") { Haptics.play(.success)",
            upTo: ".buttonStyle(", pop: "handle.pop()",
            because: "dismissing a due nudge is doing the thing, not adding it"
        )
    }

    func testEachRoutineStepsActionPops() throws {
        try assertPops(
            in: "Places/PlaceRoutineScreen.swift", afterHaptic: "Button(title) { Haptics.play(.solid)",
            upTo: ".buttonStyle(PrimaryActionButtonStyle())", pop: "handle.pop()",
            because: "a routine step's action is the ninth moment E chose"
        )
    }

    // MARK: - The two rules that no single site can carry

    /// E's design says the row's circle and its swipe pop from ONE point. They already share
    /// `close()`; what this pins is that nothing else in the row pops, so the swipe cannot acquire
    /// an origin of its own without this failing.
    func testTheSwipeAndTheCircleClosePopFromOneOrigin() throws {
        let row = try flattened("Tasks/TaskRow.swift")
        XCTAssertEqual(
            row.components(separatedBy: "celebrate.request(").count - 1, 1,
            "TaskRow requests a celebration in more than one place, so the swipe and the circle can"
                + " throw paper from two different points for the same close."
        )
        XCTAssertTrue(
            row.contains("if closes { close() }"),
            "The swipe no longer funnels through close(), so it pops from nowhere or from elsewhere."
        )
        XCTAssertTrue(
            row.contains("Button(action: close)"),
            "The circle no longer funnels through close()."
        )
        XCTAssertTrue(
            row.contains(".celebrationPopOrigin { popOrigin = $0 }"),
            "Nothing in TaskRow records an origin, so both close paths pop from the canvas centre."
        )
    }

    /// R-e. The sheet dismisses itself on a successful promote, so without a hold the pop is drawn
    /// on a layer that is already going. E's alternative was no pop there at all.
    func testTheCreateTaskSheetHoldsLongEnoughForItsPopToBeSeen() throws {
        let sheet = try flattened("Capture/CapturePromoteSheet.swift")
        XCTAssertTrue(
            sheet.contains("Task.sleep(nanoseconds: UInt64(Self.popHold"),
            "The promote sheet dismisses immediately, so the Create Task pop is cut off at birth (R-e)."
        )
        XCTAssertTrue(
            sheet.contains("static let popHold: TimeInterval = 0.45"),
            "R-e's hold is not the 0.45 s the design record settled."
        )
        // The USE, not the declaration — the declaration is at the top of the file and would sit
        // before `dismiss()` however the hold was written, which would make the order check vacuous.
        let hold = try XCTUnwrap(sheet.range(of: "Task.sleep(nanoseconds: UInt64(Self.popHold"))
        let dismiss = try XCTUnwrap(
            sheet.range(of: "dismiss()", range: hold.upperBound..<sheet.endIndex),
            "The hold does not come before the dismiss it is supposed to delay."
        )
        XCTAssertLessThan(hold.lowerBound, dismiss.lowerBound)
    }

    /// The count is what makes the enumeration above load-bearing. Eight wrappers, and `TaskRow`'s
    /// modifier — a tenth site added without a test would push this over.
    func testNoOtherControlInTheAppThrowsAPop() throws {
        let wrappers = try appTargetOccurrences(of: "CelebrationPopSource {")
        XCTAssertEqual(
            wrappers.count, 9,
            "The app wraps \(wrappers.count) controls in CelebrationPopSource, not 9."
                + " Wrapped in: \(wrappers.map(\.file).sorted().joined(separator: ", "))."
                + " E chose nine in-place moments; Sorted is two files, and TaskRow uses"
                + " .celebrationPopOrigin instead because its circle and swipe share one close()."
        )
        let origins = try appTargetOccurrences(of: ".celebrationPopOrigin {")
        XCTAssertEqual(
            origins.count, 2,
            "The app records \(origins.count) pop origins by hand, not 2 (the wrapper's own, and"
                + " TaskRow's circle). Recorded in: \(origins.map(\.file).sorted().joined(separator: ", "))."
        )
    }

    // MARK: - Reading the tree

    /// The one shape every site shares: the pop line lives INSIDE the same closure as the haptic.
    ///
    /// **The haptic is in the ANCHOR, not in a second assertion, and that is the fix for a defect
    /// this file shipped red with.** Three guards originally opened on `Button { Haptics.play(…)`
    /// and then asserted the haptic was inside the slice — but a slice starts AFTER its anchor, so
    /// those three could not have gone green however correctly the site was wired. Anchoring on the
    /// haptic makes the adjacency structural: the slice IS "what follows this haptic, in this
    /// closure", and `assertAnchorIsUnique` stops it silently pointing at a different button.
    private func assertPops(
        in file: String, afterHaptic opening: String, upTo closing: String,
        pop: String, because reason: String,
        line: UInt = #line
    ) throws {
        try assertAnchorIsUnique(opening, in: file, line: line)
        let closure = try slice(in: file, from: opening, to: closing)
        XCTAssertTrue(
            closure.contains(pop),
            "\(file) never throws a pop beside its haptic — \(reason), and it is silent.",
            line: line
        )
    }

    /// A guard anchored on a string that appears twice is a guard on whichever comes first.
    private func assertAnchorIsUnique(_ anchor: String, in file: String, line: UInt = #line) throws {
        let occurrences = try flattened(file).components(separatedBy: anchor).count - 1
        XCTAssertEqual(
            occurrences, 1,
            "`\(anchor)` appears \(occurrences) times in \(file); this guard would be reading"
                + " whichever one comes first.",
            line: line
        )
    }

    private func slice(in relativePath: String, from opening: String, to closing: String) throws -> String {
        let source = try flattened(relativePath)
        guard let start = source.range(of: opening) else {
            throw PopSourceError.anchorMissing(relativePath, opening)
        }
        guard let end = source.range(of: closing, range: start.upperBound..<source.endIndex) else {
            throw PopSourceError.anchorMissing(relativePath, closing)
        }
        return String(source[start.upperBound..<end.lowerBound])
    }

    /// The source on one line, so an anchor does not have to know how a call was wrapped —
    /// adding an argument to a modifier re-flows it and would otherwise break the guard.
    private func flattened(_ relativePath: String) throws -> String {
        try appCode(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private func appCode(_ relativePath: String) throws -> String {
        let url = Self.appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw PopSourceError.unreadable(url.path)
        }
        return stripped(text)
    }

    private func appTargetOccurrences(of needle: String) throws -> [(file: String, count: Int)] {
        guard let walker = FileManager.default.enumerator(at: Self.appRoot, includingPropertiesForKeys: nil) else {
            throw PopSourceError.unreadable(Self.appRoot.path)
        }
        var found: [(file: String, count: Int)] = []
        for case let url as URL in walker where url.pathExtension == "swift" {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let count = stripped(text).components(separatedBy: needle).count - 1
            if count > 0 { found.append((url.lastPathComponent, count)) }
        }
        return found.flatMap { entry in Array(repeating: entry, count: entry.count) }
    }

    private func stripped(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static let appRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ADHD LifeOS")

    private enum PopSourceError: Error, CustomStringConvertible {
        case unreadable(String)
        case anchorMissing(String, String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            case .anchorMissing(let file, let anchor):
                return "\(file) does not contain `\(anchor)` — this guard's anchor is stale, or the"
                    + " site has moved. Re-read the file rather than deleting the assertion."
            }
        }
    }
}
