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
    ///
    /// **Each assertion here is a whole line of Swift, not a bare name, and that is a scar.** The
    /// first cut of this test read `source.contains("settingsLifeAreasRow")`, and the red-check
    /// found it inert twice over: the identifier survives as a PREFIX of anything longer
    /// (`…RowX` still "contains" it), and this file's own doc comment names it in prose, so the
    /// assertion held even with the row deleted outright. A guard that passes on a broken tree is
    /// worse than none — it is the failure mode this whole file exists to prevent.
    func testLifeAreasKeptItsSettingsDoor() throws {
        let source = try Self.appSource("Settings/SettingsView.swift")
        XCTAssertTrue(
            source.contains(".accessibilityIdentifier(\"settingsLifeAreasRow\")"),
            "The Life Areas row was removed from Settings, or its identifier changed. That is not"
                + " the split E asked for: Places left, Life Areas STAYED and gained a second"
                + " door. Do not make this symmetrical."
        )
        XCTAssertTrue(
            source.contains("LifeAreaEditorListView(client: lifeAreaEditorClient)"),
            "Settings' Life Areas row no longer pushes the editor."
        )
        XCTAssertTrue(
            source.contains("                lifeAreasSection\n"),
            "`lifeAreasSection` is no longer rendered by Settings' `Form`. The section can be"
                + " perfectly written and simply not built — the gated-off variant of this"
                + " repo's most repeated defect."
        )
    }

    // MARK: - The Routines section is REACHED (F-Routines-B)

    /// The whole block is a reachability feature, so this is its acceptance test. A perfect
    /// `ToolsRoutinesCatalog` that no view renders is the seventh instance of this repo's most
    /// repeated defect, and it would pass all sixteen of its own unit tests while doing it.
    func testToolsPageRendersTheRoutinesSection() throws {
        let source = try Self.code("Tools/ToolsView.swift")
        XCTAssertTrue(
            source.contains("ToolsRoutinesSection(client: placesClient)"),
            "The Tools page no longer builds the Routines section. E asked for Routines to have"
                + " its own section here; a section nothing renders is the feature not existing."
        )
    }

    /// The section is iOS 17+ because the editor a row opens is. `placesSupported` is a `Bool`
    /// and cannot narrow availability, so this needs a real `if #available` — and every
    /// simulator on this machine is 26.5, so nothing else would ever notice.
    func testTheRoutinesSectionIsBehindTheSameFloorAsPlaces() throws {
        let source = try Self.code("Tools/ToolsView.swift")
        XCTAssertTrue(
            Self.collapsed(source).contains("if #available(iOS 17.0, *) { ToolsRoutinesSection("),
            "The Routines section is no longer directly inside an availability check. It pushes"
                + " `PlaceEditorView`, which is iOS 17+, and the app floor is 16.0 — and every"
                + " simulator on this machine is 26.5, so nothing else here would ever notice."
        )
    }

    func testTheSectionAsksTheCatalogRatherThanBuildingItsOwnList() throws {
        let source = try Self.code("Tools/ToolsRoutinesSection.swift")
        XCTAssertTrue(
            source.contains("ToolsRoutinesCatalog.content("),
            "`ToolsRoutinesSection` no longer asks `ToolsRoutinesCatalog` what to draw, so the"
                + " catalog can be correct and tested while the view hand-rolls a drifting copy."
        )
    }

    /// **The two-truths guard.** Membership and the step count belong to `PlaceRoutinePlan`;
    /// a second spelling in the Tools layer is free to drift from the notification's and the
    /// Today card's, which is how this repo produced its last three counting bugs.
    func testNeitherToolsFileReimplementsTheRoutineRule() throws {
        for file in ["Tools/ToolsRoutinesSection.swift", "Tools/ToolsView.swift"] {
            let source = try Self.code(file)
            for spelling in ["stepThreshold", "tapSteps", "autoRunSteps"] {
                XCTAssertFalse(
                    source.contains(spelling),
                    "\(file) reaches for `\(spelling)` itself. Membership and the count are"
                        + " `PlaceRoutinePlan`'s answers, reached only through"
                        + " `ToolsRoutinesCatalog` — two truths about one routine is the defect"
                        + " this repo produces most."
                )
            }
        }
        let catalog = try Self.code("Tools/ToolsRoutinesCatalog.swift")
        XCTAssertTrue(
            catalog.contains("plan.qualifiesAsRoutine"),
            "The catalog no longer asks `PlaceRoutinePlan` whether a crossing is a routine."
                + " A literal `>= 2` here would be a second copy of E's settled threshold."
        )
        XCTAssertTrue(
            catalog.contains("PlacesService.sorted("),
            "The catalog no longer reuses the Places list's comparator, so the two screens can"
                + " list the same places in different orders."
        )
    }

    /// A routine's editor IS the place's Actions section — E's settled Option A. There is no
    /// separate routine object to edit, and inventing a second editor would create one.
    func testARoutineRowOpensThePlaceEditor() throws {
        let source = try Self.code("Tools/ToolsRoutinesSection.swift")
        XCTAssertTrue(
            source.contains("PlaceEditorView(existing: place"),
            "A routine row no longer opens the place editor, whose Actions section with its"
                + " drag-to-reorder is the routine editor under E's Option A call."
        )
    }

    /// The empty state's way out pushes Places INSIDE the Tools stack, so it lands under the
    /// capture disc exactly as the Places card's push does and must ask for the same room.
    func testTheEmptyStatePushClearsTheCaptureDisc() throws {
        let source = try Self.code("Tools/ToolsRoutinesSection.swift")
        XCTAssertTrue(
            Self.collapsed(source).contains("PlacesListView(client: client) .captureDiscClearance()"),
            "The Routines empty state pushes `PlacesListView` without the capture-disc"
                + " clearance, so that screen's last row sits under an opaque 60pt circle."
        )
    }

    // MARK: - The permission footer reaches the section (E's 2026-09-07 ruling)

    func testTheSectionRendersTheLocationBannerForTheAlwaysGrant() throws {
        let source = try Self.code("Tools/ToolsRoutinesSection.swift")
        XCTAssertTrue(
            source.contains("LocationPermissionBanner(wantsTriggering: true)"),
            "the exact spelling matters: `wantsTriggering: false` would render happily and"
                + " teach the WEAKER grant, and routines fire only on Always — a listed routine"
                + " with no banner and no Always is the silent dormancy this footer exists to end"
        )
    }

    func testTheNudgesOffButtonMirrorsTheSettingsToggleExactly() throws {
        let source = try Self.code("Tools/ToolsRoutinesSection.swift")
        XCTAssertTrue(
            Self.collapsed(source).contains(
                "preferences.arrivalNudgesEnabled = true preferencesStore.write(preferences)"
            ),
            "the fix must go through MomentumPreferencesStoring — the same truth the wake path"
                + " reads via AppFeedback.arrivalNudgesEnabled() — never a raw defaults key"
        )
        XCTAssertTrue(
            source.contains("LocationTriggerService.shared.refreshRegistrations()"),
            "the fences must follow the switch NOW (the Settings toggle's own rule): without"
                + " the refresh the switch reads on but nothing is registered until the next"
                + " app lifecycle event, and the banner's promise is a lie for that whole window"
        )
    }

    // MARK: - Reading the tree

    /// Source with comments removed — the form every NEGATIVE assertion must read. A bare
    /// `contains("Foo()")` matches `// Foo()` just as happily, which is how a bundle-registration
    /// guard in the Routines arc slept through its own red-check.
    private static func code(_ relativePath: String) throws -> String {
        let source = try appSource(relativePath)
        var output = ""
        var index = source.startIndex
        while index < source.endIndex {
            if source[index...].hasPrefix("//") {
                while index < source.endIndex, source[index] != "\n" {
                    index = source.index(after: index)
                }
            } else {
                output.append(source[index])
                index = source.index(after: index)
            }
        }
        return output
    }

    /// Comment-free source with every whitespace run flattened to one space, so a structural
    /// claim ("this call sits directly inside that check") can be asserted without pinning the
    /// indentation a later edit is free to change.
    private static func collapsed(_ source: String) -> String {
        source.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

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
