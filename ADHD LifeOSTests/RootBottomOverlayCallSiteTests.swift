//
//  RootBottomOverlayCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-LandscapeFabOverlap's reachability guards, in the `FocusBarCollapseCallSiteTests` mould and
//  for the same reason: this repo's most repeated defect (seven instances) is a pure rule that is
//  written, documented and unit-tested while no view calls it. A perfect
//  `RootBottomOverlayLayout` that `RootBottomOverlay` never consults passes every assertion in
//  `RootBottomOverlayLayoutTests` and leaves the disc exactly where E photographed it. Tests
//  prove correctness, never reachability — except these, which read the source.
//

import XCTest
@testable import ADHD_LifeOS

final class RootBottomOverlayCallSiteTests: XCTestCase {

    private static let overlay = "RootBottomOverlay.swift"
    private static let layout = "RootBottomOverlayLayout.swift"

    // MARK: - The rule reaches the view

    func testTheOverlayReadsTheVerticalSizeClass() throws {
        XCTAssertTrue(
            try Self.appCode(Self.overlay).contains("@Environment(\\.verticalSizeClass)"),
            "`RootBottomOverlay` never reads `verticalSizeClass`, so it cannot know it is in"
                + " landscape and the arrangement rule has nothing to decide on."
        )
    }

    func testTheOverlayAsksTheRuleWhichArrangementApplies() throws {
        XCTAssertTrue(
            try Self.appCode(Self.overlay).contains("RootBottomOverlayLayout.arrangement("),
            "The arrangement rule is never called. Whatever the overlay does in landscape is"
                + " untested code written inline at the call site."
        )
    }

    /// The container is the custom `Layout`, and its two children are the disc row THEN the
    /// cards — subview 0 is the disc row, which is the Layout's whole contract. Swap them and
    /// every geometry test still passes while the disc is placed where the cards should be.
    func testTheContainerIsTheArrangementLayoutWithTheDiscRowFirst() throws {
        let source = try Self.flattened(Self.overlay)
        guard let container = source.range(of: "RootBottomOverlayArrangement(arrangement:") else {
            return XCTFail(
                "`RootBottomOverlay` does not lay its pieces out with `RootBottomOverlayArrangement`,"
                    + " so the tested geometry is not the geometry on screen."
            )
        }
        let body = source[container.upperBound...]
        guard let disc = body.range(of: "discRow"), let cards = body.range(of: "cards") else {
            return XCTFail("The container's body does not name both `discRow` and `cards`.")
        }
        XCTAssertLessThan(
            disc.lowerBound, cards.lowerBound,
            "The cards come before the disc row inside the container, so the Layout places the"
                + " disc where the cards belong."
        )
    }

    /// **Why a `Layout` and not a `switch` between a `VStack` and an `HStack`.** Changing the
    /// container TYPE gives every child a new identity, and `FocusTimerBar` owns the sprint
    /// detail sheet's `@State` — so a rotation with that sheet open would dismiss it. A `Layout`
    /// whose arrangement is a property keeps the children through the change.
    func testTheOverlayDoesNotSwitchContainerTypesOnTheArrangement() throws {
        let source = try Self.appCode(Self.overlay)
        XCTAssertFalse(
            source.contains("case .besideTheDisc") || source.contains("case .stacked"),
            "`RootBottomOverlay` switches on the arrangement itself. Two container types means"
                + " two identities for the timer bar, and its detail sheet dies on rotation."
        )
    }

    // MARK: - The fan fade reaches the view (F-FanCardsFade)

    /// The cards fade by OPACITY and drop out of hit-testing, fed by the pure rule — never by an
    /// `if` that removes them.
    ///
    /// **The reason REVERSED on 2026-09-17 (`F-FanXAtRest`); the guard did not.** It used to say
    /// removal would drop the × into its corner, moving it from under the thumb. E then chose
    /// exactly that drop — shape B, *"× drops to its corner"* — so it is no longer the reason. The
    /// honest reasons now: removing the cards would destroy `FocusTimerBar`'s `@State` (the sprint
    /// detail sheet, the Stop confirmation) every time the fan opened, and swap the fade E passed
    /// on device for a removal transition. The × now moves by the Layout, not by the cards leaving.
    func testTheCardsFadeUnderTheFanByOpacityAndKeepTheirLayout() throws {
        let source = try Self.flattened(Self.overlay)
        XCTAssertTrue(
            source.contains("RootBottomOverlayLayout.cardsPresence(fanIsOpen: isFabOpen)"),
            "The overlay never asks the fan rule, so the cards stay above the fan."
        )
        guard let container = source.range(of: "RootBottomOverlayArrangement(arrangement:") else {
            return XCTFail("No arrangement container — see the test above.")
        }
        let body = source[container.upperBound...]
        for anchor in [".opacity(", ".allowsHitTesting("] {
            XCTAssertTrue(body.contains(anchor), "The cards are not modified with `\(anchor)` inside the container.")
        }
        XCTAssertFalse(
            source.contains("if isFabOpen") || source.contains("if !isFabOpen"),
            "The overlay gates the cards' EXISTENCE on the fan. That tears down the timer bar's"
                + " detail sheet and Stop confirmation, and replaces the fade with a removal."
        )
    }

    // MARK: - The × drops to its corner (F-FanXAtRest)

    /// A perfect `frames(…fanIsOpen:)` that the view never feeds leaves the × on the tile E
    /// photographed. Both hops are pinned: the overlay hands the fan's state to the Layout, and
    /// the Layout hands it to the pure geometry.
    func testTheFansStateReachesTheGeometry() throws {
        XCTAssertTrue(
            try Self.flattened(Self.overlay).contains(
                "RootBottomOverlayArrangement(arrangement: arrangement, fanIsOpen: isFabOpen)"
            ),
            "The overlay never tells the Layout the fan is open, so the × stays pushed up over the tiles."
        )
        XCTAssertTrue(
            try Self.flattened(Self.layout).contains("fanIsOpen: fanIsOpen"),
            "The Layout never passes the fan's state into `frames`, so the tested rule is not the one on screen."
        )
    }

    /// **Every way the fan closes moves the × the same way.** The disc's own button toggles inside
    /// a `withAnimation`, but the scrim's tap and a tile's pick set `isFabOpen` bare in `RootView`
    /// — so without an animation keyed on the state itself, dismissing by the scrim would SNAP
    /// the × 68–194pt back up. `nil` under Reduce Motion: this is §7.2's continuous re-layout,
    /// the same reading as the disc's existing push when a sprint starts.
    func testTheXMovesOnTheSameSpringWhicheverWayTheFanCloses() throws {
        XCTAssertTrue(
            try Self.flattened(Self.overlay).contains(
                ".animation( reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: isFabOpen )"
            ),
            "Nothing animates the × on a scrim or tile dismissal, so it jumps back up above the cards."
        )
    }

    /// The disc row is subview 0, so the cards column draws OVER it. While the fan opens, the ×
    /// travels down into the cards' space as they fade; with the default order it passes behind a
    /// half-faded card — and under Reduce Motion it jumps there at once and sits behind the fading
    /// card for the whole fade. `zIndex` puts the × on top without touching the subview order the
    /// Layout's contract depends on. `RootBottomOverlayDrawOrderTests` proves the Layout honours it.
    func testTheDiscRowDrawsAboveTheCards() throws {
        let source = try Self.flattened(Self.overlay)
        guard let container = source.range(of: "RootBottomOverlayArrangement(arrangement:") else {
            return XCTFail("No arrangement container — see the tests above.")
        }
        XCTAssertTrue(
            source[container.upperBound...].contains("discRow .zIndex(1)"),
            "The disc row is not raised above the cards, so the × passes behind a fading card."
        )
    }

    // MARK: - The Journal's pencil disc (F-JournalPencilDisc)

    /// E, 2026-09-18: *"move the filled pencil icon disc down to the left-hand side of the FAB Icon.
    /// make the filled pencil disc inline with the FAB icon"*. Inline means the SAME `HStack` as the
    /// +, so the shared centre line is by construction — and to its LEFT means after the search
    /// slot and before the disc. A pencil disc drawn anywhere else passes every value test.
    ///
    /// **Reversed by `F-C1-UndoCapsule` (2026-09-20), not deleted, and the property is unchanged.**
    /// The search row and the pencil moved into `leadingBand`, which `UndoCapsuleSlot` wraps so the
    /// capsule can stand IN FOR them — so the row's source is now `UndoCapsuleSlot { leadingBand }`
    /// then the +, and the band's own source is search → pencil. Both halves are asserted, because
    /// a pencil that left the band, or a + that fell inside it, would each pass one of them alone.
    func testThePencilDiscSitsInTheDiscRowBetweenTheSearchSlotAndThePlus() throws {
        let source = try Self.flattened(Self.overlay)
        guard let row = source.range(of: "private var discRow: some View {"),
              let band = source.range(of: "private var leadingBand: some View {")
        else {
            return XCTFail("`RootBottomOverlay` has no `discRow`/`leadingBand` pair.")
        }
        // The row: the capsule slot wrapping the band, then the + — and nothing between them.
        let rowBody = source[row.upperBound..<band.lowerBound]
        let rowOrder = ["UndoCapsuleSlot {", "leadingBand", "CaptureDiscLabel("]
        let rowPositions = rowOrder.compactMap { rowBody.range(of: $0)?.lowerBound }
        XCTAssertEqual(rowPositions.count, rowOrder.count, "The disc row is missing one of \(rowOrder).")
        XCTAssertEqual(rowPositions, rowPositions.sorted(), "The row's order is not slot → band → +.")
        // The band: the search row, then the pencil. The + is deliberately NOT here — it must never
        // be displaced by the capsule.
        let bandBody = source[band.upperBound...]
        let bandOrder = ["AppSearchRow(", "if showsJournalCompose {", "JournalComposeDisc("]
        let bandPositions = bandOrder.compactMap { bandBody.range(of: $0)?.lowerBound }
        XCTAssertEqual(bandPositions.count, bandOrder.count, "The band is missing one of \(bandOrder).")
        XCTAssertEqual(bandPositions, bandPositions.sorted(), "The band's order is not search → pencil.")
        XCTAssertFalse(
            bandBody.contains("CaptureDiscLabel("),
            "The + disc is inside the band the capsule displaces, so a pending undo would take the"
                + " capture disc off the screen with it."
        )
    }

    /// The pencil's arrangement, pinned hop by hop — each one missing is a pencil that does
    /// something E did not choose:
    /// - **the pill** (*"Follows the pill"*): it is handed the + disc's `showsPill`;
    /// - **the fan** (decision 6, `F-FanCardsFade`'s precedent): it fades and stops taking touches
    ///   WITH the cards, by the same rule — an opacity, never an `if`;
    /// - **appearing and leaving** is a reduced site (§7.2): a fade on both paths, never a `nil` cut.
    func testThePencilDiscFollowsThePillFadesWithTheFanAndArrivesOnAFade() throws {
        let source = try Self.flattened(Self.overlay)
        // Since `F-C1-UndoCapsule` the pencil is the last thing in `leadingBand`, so its modifier
        // chain runs to the end of that property rather than up to the + disc.
        guard let disc = source.range(of: "JournalComposeDisc(") else {
            return XCTFail("No pencil disc — see the test above.")
        }
        let chain = source[disc.lowerBound...]
        for anchor in [
            "JournalComposeDisc(showsPill: showsPill, action: onWriteEntry)",
            ".opacity(fanPresence.opacity)",
            ".allowsHitTesting(fanPresence.acceptsTouches)",
            // `allowsHitTesting` stops a finger, not VoiceOver's activate: without this a VoiceOver
            // user could open the composer from under the fan's scrim (the HIG review, 2026-09-18).
            ".accessibilityHidden(!fanPresence.acceptsTouches)",
            ".transition(.opacity.animation(JournalComposeDoor.appearAnimation(reduceMotion: reduceMotion)))"
        ] {
            XCTAssertTrue(chain.contains(anchor), "The pencil disc is not modified with `\(anchor)`.")
        }
    }

    /// The rule decides; `RootView` asks it with the selected tab AND that tab's depth, and hands
    /// the answer to the overlay. The depth is the search row's lesson (F-TabDepth-2): a row
    /// mounted once at the root that learns the tab but not the depth sits under a pushed screen.
    func testRootViewDecidesThePencilDiscFromTheSelectedTabAndItsDepth() throws {
        XCTAssertTrue(
            try Self.flattened("RootView+Furniture.swift").contains(
                "JournalComposeDoor.isShown(selectedTab: selectedTab, isAtRoot: tabNavigation.isAtRoot(selectedTab))"
            ),
            "RootView never asks the pencil's rule, or asks it without the tab's depth."
        )
        XCTAssertTrue(
            try Self.flattened("RootView.swift").contains("showsJournalCompose: showsJournalCompose"),
            "RootView computes whether the pencil shows and never tells the overlay."
        )
    }

    // MARK: - The geometry reaches the Layout

    /// `sizeThatFits` and `placeSubviews` cannot be unit-tested without real subviews, so they
    /// must DELEGATE to the pure functions that can be — otherwise the numbers in the tests and
    /// the numbers on screen are two different sets.
    func testTheLayoutDelegatesItsGeometryToThePureFunctions() throws {
        let source = try Self.appCode(Self.layout)
        let anchors = [
            "RootBottomOverlayLayout.size(",
            "RootBottomOverlayLayout.frames(",
            "RootBottomOverlayLayout.cardsWidth("
        ]
        for anchor in anchors {
            XCTAssertTrue(
                source.contains(anchor),
                "`RootBottomOverlayArrangement` never calls `\(anchor)`, so that half of the"
                    + " geometry is inline arithmetic nothing tests."
            )
        }
    }

    // MARK: - Source

    /// The same source on one line, each line trimmed and joined by a single space, so an anchor
    /// does not have to know how a call was wrapped.
    private static func flattened(_ relativePath: String) throws -> String {
        try appCode(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum SourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
