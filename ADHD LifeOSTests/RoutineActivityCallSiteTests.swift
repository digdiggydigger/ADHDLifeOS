//
//  RoutineActivityCallSiteTests.swift
//  ADHD LifeOSTests
//
//  Source-read pins for the routine Live Activity (F-Routines-5). The claims here are about
//  WIRING and about two platform constraints that no unit test over values can see — and the
//  widget extension has no test bundle at all, so this target is the only place they can live.
//

import XCTest

final class RoutineActivityCallSiteTests: XCTestCase {

    /// ActivityKit cannot START an Activity from the background, and a crossing arrives with
    /// the app backgrounded. The Activity therefore begins when the SCREEN opens. This is a
    /// platform floor — a future reader "fixing" it by starting at the crossing would ship an
    /// Activity that silently never appears.
    func testTheActivityStartsWithTheScreen_neverAtTheCrossing() throws {
        let screen = try Self.source("ADHD LifeOS/Places/PlaceRoutineScreen.swift")
        let handler = try Self.source("ADHD LifeOS/Places/PlaceTriggerEventHandler.swift")

        XCTAssertTrue(
            screen.contains(".task { activity.started(run) }"),
            "the routine screen is the only foreground moment the Activity can begin in"
        )
        XCTAssertFalse(
            handler.contains("Activity") || handler.contains("activity"),
            "the crossing handler runs in the BACKGROUND — ActivityKit cannot start there"
        )
    }

    func testTheActivityFollowsTheRunAndEndsWithIt() throws {
        let screen = try Self.source("ADHD LifeOS/Places/PlaceRoutineScreen.swift")

        XCTAssertTrue(screen.contains("activity.updated(updated)"), "steps must move the card")
        XCTAssertTrue(
            screen.contains("activity.ended()"),
            "leaving must end it: the Activity belongs to the SCREEN, and nothing can restart"
                + " it from the background"
        )
    }

    /// A Live Activity IGNORES the widget target's global accent — `.tint` and
    /// `Color.accentColor` both render system blue there. The colour must be read from the
    /// extension's OWN catalog by name.
    func testTheActivityReadsTheAccentByName() throws {
        let activity = try Self.source("FocusTimerWidget/RoutineLiveActivity.swift")

        XCTAssertTrue(activity.contains("Color(\"AccentColor\")"))
        XCTAssertFalse(
            Self.code(of: activity).contains("Color.accentColor"),
            "the generated accent symbol renders system blue inside a Live Activity"
        )
    }

    /// Comments talk ABOUT the wrong spellings; only the code may not contain them. Without
    /// this the file's own "do not use Color.accentColor" note fails the check it documents.
    private static func code(of source: String) -> String {
        source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    /// The shared attributes type must compile into BOTH targets or the extension cannot match
    /// the Activity. The mechanism is the pbxproj membership exception, not an Xcode GUI step —
    /// a "cannot find type" error in the extension means this line went missing.
    func testTheSharedAttributesAreInBothTargets() throws {
        let project = try Self.source("ADHD LifeOS.xcodeproj/project.pbxproj")

        XCTAssertTrue(
            project.contains("RoutineActivityAttributes.swift,"),
            "the attributes file must be listed in the app target's membershipExceptions,"
                + " beside FocusActivityAttributes.swift"
        )
    }

    func testTheBundleRegistersTheSecondActivity() throws {
        let bundle = try Self.source("FocusTimerWidget/FocusTimerWidgetBundle.swift")

        XCTAssertTrue(
            // CODE, not prose: commenting the line out left `contains` matching the comment,
            // which is how this guard slept through its own red-check.
            Self.code(of: bundle).contains("RoutineLiveActivity()"),
            "an unregistered ActivityConfiguration never renders — the dead-component shape,"
                + " at the widget layer"
        )
        XCTAssertFalse(
            Self.code(of: bundle).contains("if #available"),
            "a conditional inside a WidgetBundle body can silently drop the widget from the"
                + " bundle; the extension's floor is already 16.1, so it buys nothing"
        )
    }

    /// No buttons in this block: interactive App Intents are the settled fast-follow, and they
    /// are iOS 17+ against the widget target's 16.1 floor.
    func testTheActivityCarriesNoButtons() throws {
        let activity = try Self.source("FocusTimerWidget/RoutineLiveActivity.swift")

        XCTAssertFalse(activity.contains("Button("), "display only, by design")
        XCTAssertTrue(
            activity.contains("widgetURL(URL(string: RoutineActivityAttributes.deepLink))"),
            "tap-to-return is the ONE interaction this block ships"
        )
    }

    /// The presenter is handed to the screen from a `@ViewBuilder`, so a per-call instance
    /// would be replaced on every re-render — dropping the handle to the running Activity with
    /// it, and leaving a Lock Screen card nothing could update or dismiss.
    func testThePresenterOutlivesBodyReevaluation() throws {
        let presenter = try Self.source("ADHD LifeOS/Places/RoutineActivityKitPresenter.swift")
        let doors = try Self.source("ADHD LifeOS/RootView+Doors.swift")

        XCTAssertTrue(presenter.contains("static let shared = RoutineActivityKitPresenter()"))
        XCTAssertTrue(
            presenter.contains("private init()"),
            "a second instance would own a second Activity handle"
        )
        XCTAssertTrue(doors.contains("RoutineActivityKitPresenter.shared"))
    }

    /// E's field-walk asks: a definitive border around the island, and no truncated count.
    /// `keylineTint` is ActivityKit's supported way to draw that border — the island's outline
    /// is not otherwise styleable — and the trailing slot takes the short form because it is
    /// the region that clipped.
    ///
    /// The tint is AMBER, not the accent (E, 2026-09-04 round 2): a mid-blue hairline on a
    /// true-black island is barely visible in dark mode.
    func testTheIslandHasAKeylineAndAnUntruncatedCount() throws {
        let activity = try Self.source("FocusTimerWidget/RoutineLiveActivity.swift")
        let code = Self.code(of: activity)

        XCTAssertTrue(
            code.contains(".keylineTint(Color(\"IslandKeyline\"))"),
            "the island needs a definitive outline, tinted from the extension's own catalog"
        )
        XCTAssertTrue(
            code.contains("context.state.shortStatusLine"),
            "the expanded trailing region must use the short count — the full sentence"
                + " truncated to \"1 of 2…\" on device"
        )
    }

    /// The half the name-check cannot see. `Color("…")` resolves at RUNTIME: a missing colorset
    /// does not fail the build and does not fail the assertion above — it renders a fallback,
    /// so the border E asked for would simply be invisible again, in the one presentation no
    /// simulator can show. Assert the asset exists, in the EXTENSION's catalog (a Live Activity
    /// ignores the widget target's global accent and reads its own), with a dark variant, since
    /// the island is always dark whatever the system theme is doing.
    func testTheKeylineColourAssetExistsInTheExtensionCatalog() throws {
        let colorset = try Self.source(
            "FocusTimerWidget/Assets.xcassets/IslandKeyline.colorset/Contents.json"
        )

        XCTAssertTrue(
            colorset.contains("\"luminosity\"") && colorset.contains("\"dark\""),
            "the keyline needs a dark-appearance variant — the island is always dark"
        )
        let components = try XCTUnwrap(
            try? JSONSerialization.jsonObject(with: Data(colorset.utf8)) as? [String: Any]
        )
        let colors = try XCTUnwrap(components["colors"] as? [[String: Any]])
        XCTAssertEqual(colors.count, 2, "expected a light and a dark entry")
    }

    private static func source(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw NSError(domain: "RoutineActivityCallSiteTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not read \(url.path)."
            ])
        }
        return text
    }
}
