//
//  FocusBarCollapseCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-1's reachability guards, in the `CaptureDiscPillCallSiteTests` mould and for the
//  same reason: this repo's most repeated defect (six instances) is a helper that is written,
//  documented and unit-tested while no view uses it. A perfect `FocusBarCollapseSwipe` that
//  `FocusTimerBar` never calls passes every assertion in `FocusBarCollapseTests` and leaves the
//  card exactly as tall as it was. Tests prove correctness, never reachability — except these,
//  which read the source, the layer the wiring claim actually lives in.
//

import XCTest
@testable import ADHD_LifeOS

final class FocusBarCollapseCallSiteTests: XCTestCase {

    // MARK: - The state reaches the view

    func testTheBarReadsTheServicesCollapseFlag() throws {
        XCTAssertTrue(
            try Self.appSource("Focus/FocusTimerBar.swift").contains("service.isCardCollapsed"),
            "`FocusTimerBar` never reads `isCardCollapsed`, so the service can persist and restore"
                + " it all day and the card renders one fixed size — F-FocusCard-1 as dead code."
        )
    }

    func testTheSwipeIsWiredToTheGesture() throws {
        XCTAssertTrue(
            try Self.appSource("Focus/FocusTimerBar.swift").contains("FocusBarCollapseSwipe.outcome"),
            "The direction-aware swipe rule is never called. Whatever the card does on a drag is"
                + " untested code written inline at the call site."
        )
    }

    /// **The trap the block is most likely to ship.** A plain `.gesture(DragGesture(...))` on the
    /// card wins the hit test over its children, so Pause — the collapsed card's ONLY remaining
    /// control — stops responding. `.simultaneousGesture` lets both live.
    func testTheDragIsSimultaneousSoPauseStillWorks() throws {
        let source = try Self.appCode("Focus/FocusTimerBar.swift")
        XCTAssertTrue(
            source.contains("simultaneousGesture"),
            "The card's drag is attached with `.gesture`, which swallows the Pause button's taps."
                + " Collapsed, that leaves a card whose only control is dead."
        )
        XCTAssertFalse(
            source.contains(".gesture(DragGesture"),
            "A plain `.gesture(DragGesture(...))` is back on the card. Use `.simultaneousGesture`."
        )
    }

    // MARK: - The shape reaches the view

    func testTheCardDrawsTheBranchingShape() throws {
        let source = try Self.appCode("Focus/FocusTimerBar.swift")
        XCTAssertTrue(
            source.contains("FocusBarCardShape("),
            "The card is not drawn with `FocusBarCardShape`, so its bottom corners cannot round"
                + " conditionally and the collapsed state is a floating rounded rectangle again."
        )
        XCTAssertFalse(
            source.contains("RoundedRectangle(cornerRadius: 24"),
            "The old always-rounded rectangle is still here. It must be gone from BOTH the"
                + " `.background` and the `.overlay`, or one of the two ignores the collapse."
        )
    }

    /// **Full-bleed was REVERSED by E on 2026-09-09**, after seeing it on device: the collapsed
    /// card must *"become smaller than the nav bar below it"*. It now takes its own, larger inset
    /// rather than zero — the earlier requirement (*"the full-screen-width card sizing is
    /// important"*) no longer holds and this guard would have kept enforcing it.
    func testTheCollapsedCardTakesItsOwnInsetNotFullBleed() throws {
        let source = try Self.appCode("Focus/FocusTimerBar.swift")
        XCTAssertTrue(
            source.contains("isCollapsed ? FocusBarMetrics.collapsedInset : FocusBarMetrics.expandedInset"),
            "The collapsed card is not taking `collapsedInset`. If this reverted to `? 0 :` the"
                + " card is full-bleed again, which E rejected on device."
        )
        XCTAssertFalse(
            source.contains("isCollapsed ? 0 :"),
            "The collapsed card is full-bleed again."
        )
    }

    func testTheFlushDropUsesAnOffsetNotNegativePadding() throws {
        let source = try Self.appCode("Focus/FocusTimerBar.swift")
        XCTAssertTrue(
            source.contains("FocusBarMetrics.collapsedOffsetY"),
            "Nothing drops the collapsed card onto the tab bar, so its square bottom corners hang"
                + " 32pt above the bar in mid-air."
        )
        XCTAssertTrue(
            source.contains(".offset(y:"),
            "`FocusTimerBar` is the LAST child of `RootBottomOverlay`'s VStack, which pads its own"
                + " bottom by `bottomFurnitureLift`. Negative bottom padding here SHRINKS that"
                + " stack and drags the search row and the capture disc down 32pt with it."
                + " `.offset` moves rendering and hit-testing without touching layout."
        )
        XCTAssertFalse(
            source.contains(".padding(.bottom, -"),
            "Negative bottom padding is back — see above; it moves the search row and the disc too."
        )
    }

    // MARK: - The long-press door, and the orphan guard

    /// Tap now collapses, so the tap that used to open `FocusSprintDetailView` had to move. E
    /// chose the long-press over a Details button, over tapping the ring, and over orphaning the
    /// view (379 lines, plus `FocusCadenceEditorCard` and `FocusSprintTimelineCard`).
    func testTheDetailSheetIsStillReachable() throws {
        let source = try Self.appCode("Focus/FocusTimerBar.swift")
        XCTAssertTrue(
            source.contains("FocusSprintDetailView("),
            "`FocusSprintDetailView` has been orphaned — this bar is the app's ONLY door to it."
        )
        XCTAssertTrue(
            source.contains(".onTapGesture { openDetail() }"),
            "A single tap no longer opens the full sprint view. E's 2026-09-09 model: tap means"
                + " the same thing in BOTH states, and collapse moved onto the swipe and grabber."
        )
        XCTAssertFalse(
            source.contains("onLongPressGesture"),
            "The long-press is back. It was retired when the tap took over opening the detail"
                + " view — leaving it would be a hidden duplicate of a gesture that now has a"
                + " visible one."
        )
    }

    /// The swipe is the ONLY thing that changes the card's state now, apart from the grabber, so
    /// its wiring matters more than when a tap could also do it.
    func testCollapseIsReachableWithoutTheTap() throws {
        let source = try Self.appCode("Focus/FocusTimerBar.swift")
        XCTAssertTrue(source.contains("case .collapse: setCollapsed(true)"))
        XCTAssertTrue(source.contains("case .expand: setCollapsed(false)"))
        XCTAssertTrue(
            source.contains("focusBarGrabber"),
            "With the tap reassigned to the detail view and the chevron gone from the collapsed"
                + " card, the grabber is the only VISIBLE control that expands or collapses."
        )
    }

    /// The old task row was a `Button` whose action opened the sheet. Left in place it wins the
    /// hit test over the card's `.onTapGesture` across most of the card's area, so tapping the
    /// ring or the name opens the sheet instead of collapsing — the same failure family as the
    /// `.gesture`/Pause trap, in the opposite direction. The row is now a plain `HStack` in
    /// `FocusTimerBarContent`, and the ONLY writer of `isPresentingDetail` is the long-press.
    func testTheRowIsNoLongerItsOwnDoor() throws {
        let content = try Self.appCode("Focus/FocusTimerBarContent.swift")
        XCTAssertFalse(
            content.contains("isPresentingDetail"),
            "The content view still raises the detail sheet, so tapping the ring or the sprint"
                + " name opens it instead of collapsing the card."
        )
        let source = try Self.appCode("Focus/FocusTimerBar.swift")
        XCTAssertEqual(
            source.components(separatedBy: "isPresentingDetail = true").count - 1, 1,
            "There is more than one door to the detail sheet. Exactly one — the long-press —"
                + " may set `isPresentingDetail`, or a tap meant to collapse raises a sheet."
        )
    }

    // MARK: - The collapsed card carries exactly the three things E asked for

    func testTheExpandedOnlyControlsAreGatedOnTheFlag() throws {
        let content = try Self.appSource("Focus/FocusTimerBarContent.swift")
        for identifier in ["focusBarAdd30", "focusBarAdd5m", "focusBarStop"] {
            XCTAssertTrue(content.contains(identifier), "\(identifier) has been deleted, not gated.")
        }
        XCTAssertTrue(
            content.contains("if !isCollapsed"),
            "Nothing in the content view branches on `isCollapsed`, so either every control shows"
                + " when collapsed or `+30s` / `+5m` / `Stop` have been lost from BOTH states."
        )
        XCTAssertTrue(
            content.contains("focusBarPause"),
            "Pause is gone. It is one of the exactly three things E specified for the collapsed"
                + " card, alongside the progress ring and the sprint name."
        )
        // E, 2026-09-09: the chevron leaves the COLLAPSED card only. `collapsedBody` must not
        // render it; the expanded `titleColumn` still must.
        let collapsedBody = content[
            content.range(of: "private var collapsedBody")!.lowerBound
            ..< content.range(of: "private var expandedBody")!.lowerBound
        ]
        XCTAssertFalse(
            collapsedBody.contains("collapseChevron"),
            "The chevron is back on the collapsed card, where the grabber already says the same"
                + " thing 44pt away."
        )
        XCTAssertFalse(
            collapsedBody.contains("pausedBadge"),
            "The PAUSED badge is back on the collapsed card. The play/pause glyph conveys the"
                + " state by shape; the badge is what wrapped to two lines and crushed the title."
        )
        XCTAssertTrue(
            content.contains("collapseChevron"),
            "The chevron has been deleted outright — E kept it on the EXPANDED card."
        )
    }

    func testTheGrabberAndChevronAreRealControls() throws {
        let source = try Self.appSource("Focus/FocusTimerBar.swift")
            + (try Self.appSource("Focus/FocusTimerBarContent.swift"))
        XCTAssertTrue(
            source.contains("focusBarGrabber"),
            "There is no grabber. E chose it as one of the four toggle affordances, and it is the"
                + " only one that ADVERTISES that the card moves."
        )
        XCTAssertTrue(
            source.contains("focusBarExpand"),
            "The chevron is gone. It was a decorative `Image` before this block and E chose to"
                + " make it a real control that flips direction with the state."
        )
        XCTAssertTrue(
            source.contains("FocusBarMetrics.grabberHitOverflow"),
            "The grabber is not using the negative-padding hit overflow, so its 44pt touch target"
                + " is setting the collapsed card's height and the card barely shrinks — the"
                + " `AppTabBarMetrics.slotHitOverflow` lesson, relearned."
        )
    }

    /// **A `layoutPriority` without a matching `fixedSize` on its siblings is a regression, not a
    /// fix.** Priority decides who is offered space FIRST, not who may shrink — so the title at
    /// priority 1 took what it wanted and SwiftUI compressed the emoji and the PAUSED badge to
    /// zero and 1pt respectively. Both vanished on E's device while every test stayed green,
    /// because nothing here asserts text layout.
    ///
    /// This guard is textual and coarse on purpose: a real assertion would need to measure the
    /// rendered width of a `Text` inside an `HStack`, which `sizeThatFits` cannot reach.
    func testTheRigidSiblingsCannotBeCompressedByTheTitlesPriority() throws {
        let content = try Self.appCode("Focus/FocusTimerBarContent.swift")
        XCTAssertEqual(
            content.components(separatedBy: ".fixedSize()").count - 1, 3,
            "There should be exactly three `.fixedSize()` calls — the life-area emoji in BOTH"
                + " states and the expanded card's PAUSED badge. Fewer means one of them can be"
                + " squeezed to nothing again by the title's `layoutPriority`; more means"
                + " something else has been frozen and should be checked."
        )
        XCTAssertTrue(
            content.contains(".layoutPriority(1)"),
            "The title lost its priority, so the trailing `Spacer` will absorb the width and the"
                + " title truncates early again — the \"9…\" E photographed."
        )
    }

    func testTheRingShrinksWithTheCard() throws {
        let content = try Self.appCode("Focus/FocusTimerBarContent.swift")
        XCTAssertTrue(
            content.contains("FocusBarMetrics.collapsedRingSize"),
            "The ring is drawn at one fixed size. At the expanded 64pt it alone is taller than"
                + " the collapsed card E asked for, so the card cannot reach 73pt."
        )
        XCTAssertFalse(
            content.contains("ringSize: CGFloat = 64"),
            "A literal 64 is back beside the metrics that also spell it — two spellings of one"
                + " measurement is the drift these tests exist to prevent."
        )
    }

    // MARK: - Still on screen at all

    func testTheBarIsStillRendered() throws {
        XCTAssertTrue(
            try Self.appSource("RootBottomOverlay.swift").contains("FocusTimerBar(service:"),
            "`RootBottomOverlay` no longer renders the timer bar, so every guard above is"
                + " asserting the shape of a view that is off screen on every tab."
        )
        XCTAssertTrue(
            try Self.appSource("Focus/FocusTimerBar.swift").contains("FocusTimerBarContent("),
            "The 400-line split left `FocusTimerBarContent` unrendered — the card would draw its"
                + " chrome and gestures around nothing at all."
        )
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed.
    ///
    /// **Every `XCTAssertFalse` below must read this, not `appSource`.** These files document the
    /// anti-patterns they ban — `FocusTimerBar.swift`'s own comment spells out
    /// "a plain .gesture(DragGesture(...)) swallows Pause's taps" — so a raw text search finds the
    /// banned string in the prose warning against it and fails a correct implementation. That is
    /// not hypothetical: it is what this file did on its first green run.
    private static func appCode(_ relativePath: String) throws -> String {
        try appSource(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw FocusBarSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum FocusBarSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`)."
            }
        }
    }
}
