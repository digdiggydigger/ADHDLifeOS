//
//  ToolsPageCallSiteTests.swift
//  ADHD LifeOSTests
//
//  Reachability guards for the Tools page and the Settings split it completes, in the
//  `AppTabBarCallSiteTests` / `CaptureDiscClearanceCallSiteTests` mould.
//
//  `ToolsCatalogTests` proves the catalog returns the right entries. It cannot prove anything
//  RENDERS them, and it cannot prove the cards open the real screens — this repo's most repeated
//  defect (six instances) is exactly that gap: a helper written, documented and unit-tested while
//  no view calls it. So these read the source, which is the layer a wiring claim lives in.
//
//  The other half is the ASYMMETRY. E's split is deliberate and unusual — Places gets one door,
//  Life Areas keeps two — and a later tidy-up "fixing" it would look like an improvement. Both
//  halves are asserted here so that fix fails loudly instead.
//

import XCTest
@testable import ADHD_LifeOS

final class ToolsPageCallSiteTests: XCTestCase {

    // MARK: - The page actually consults the catalog

    func testToolsViewBuildsItsCardsFromTheCatalog() throws {
        let source = try Self.appSource("Tools/ToolsView.swift")
        XCTAssertTrue(
            source.contains("ToolsCatalog.available("),
            "`ToolsView` no longer asks `ToolsCatalog` what to draw. The catalog can then be"
                + " perfectly correct and perfectly tested while the page hand-rolls a second,"
                + " drifting copy of the list — this repo's most repeated defect."
        )
    }

    /// The gate that never shows up on this machine. Every simulator here is iOS 26.5, so a
    /// hardcoded `placesSupported: true` would look completely correct in every build, every
    /// test run and every screenshot, and ship a card that pushes nothing to a 16.x phone.
    func testPlacesSupportIsAskedOfTheSystemAndNotHardcoded() throws {
        let source = try Self.appSource("Tools/ToolsView.swift")
        XCTAssertTrue(
            source.contains("if #available(iOS 17.0, *)"),
            "`ToolsView` no longer checks availability. `PlacesListView` is iOS 17+ and the app"
                + " floor is 16.0."
        )
        XCTAssertFalse(
            source.contains("available(placesSupported: true)"),
            "`placesSupported` is hardcoded true. That compiles and runs perfectly on the 26.5"
                + " simulator and breaks the 16.0 floor — the one case nothing here can see."
        )
    }

    // MARK: - Both cards open something real

    func testBothCardsPushTheirRealDestinations() throws {
        let source = try Self.appSource("Tools/ToolsView.swift")
        XCTAssertTrue(
            source.contains("PlacesListView(client: placesClient)"),
            "The Places card does not push `PlacesListView`. Places left Settings this block, so"
                + " this is now the ONLY way into it — a dead card here means the feature is"
                + " unreachable, not merely inconvenient."
        )
        XCTAssertTrue(
            source.contains("LifeAreaEditorListView(client: lifeAreaEditorClient)"),
            "The Life Areas card does not push `LifeAreaEditorListView`."
        )
    }

    /// Both pushes land under the capture disc, so both ask for the room where they are pushed —
    /// the presentation owns the clearance, exactly as `AreasView` does for its own copy of the
    /// Life Areas editor. See `CaptureDiscClearanceCallSiteTests` for why neither screen is on
    /// that file's list.
    func testBothPushedScreensAskForCaptureDiscClearance() throws {
        let source = try Self.appSource("Tools/ToolsView.swift")
        XCTAssertEqual(
            source.components(separatedBy: ".captureDiscClearance()").count - 1, 3,
            "The Tools page should call `.captureDiscClearance()` three times: once on its own"
                + " scroll, and once at each push. A missing one puts that screen's last row"
                + " under an opaque 60pt circle with nothing below it to scroll to."
        )
    }

    // MARK: - The asymmetric Settings split (E's call, 2026-09-02)

    func testPlacesIsGoneFromSettings() throws {
        let source = try Self.appSource("Settings/SettingsView.swift")
        for trace in ["placesSection", "settingsPlacesRow", "PlacesListView"] {
            XCTAssertFalse(
                source.contains(trace),
                "`\(trace)` is back in Settings. Places has ONE door now, in Tools — two doors"
                    + " was the thing this block removed."
            )
        }
    }

    /// **The half that looks like a bug and is not.** Life Areas is reachable from Settings AND
    /// from Tools, deliberately, because it is genuinely both a setting and a tool. E chose this
    /// knowing it is the opposite of the Captures de-duplication.
    func testLifeAreasKeptItsSettingsDoor() throws {
        let source = try Self.appSource("Settings/SettingsView.swift")
        XCTAssertTrue(
            source.contains("settingsLifeAreasRow"),
            "The Life Areas row was removed from Settings. That is not the split E asked for:"
                + " Places left, Life Areas STAYED and gained a second door. Do not make this"
                + " symmetrical."
        )
        XCTAssertTrue(
            source.contains("LifeAreaEditorListView(client: lifeAreaEditorClient)"),
            "Settings' Life Areas row no longer pushes the editor."
        )
    }

    // MARK: - Reading the tree

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ToolsSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum ToolsSourceError: Error, CustomStringConvertible {
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
