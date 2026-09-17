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
