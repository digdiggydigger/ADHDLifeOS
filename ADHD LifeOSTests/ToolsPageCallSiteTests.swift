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
            source.contains("ToolsCatalog.entries"),
            "`ToolsView` no longer asks `ToolsCatalog` what to draw. The catalog can then be"
                + " perfectly correct and perfectly tested while the page hand-rolls a second,"
                + " drifting copy of the list — this repo's most repeated defect."
        )
    }

    /// **REVERSED by `F-Floor18`** (E, 2026-09-23: *"iOS 18, before F-D2"*). Until then this was
    /// `testPlacesSupportIsAskedOfTheSystemAndNotHardcoded`: `ToolsView` HAD to carry a real
    /// `if #available(iOS 17.0, *)` because Places sat above the old 16.0 floor and a hardcoded
    /// `placesSupported: true` would have shipped a dead card to a phone no simulator here could
    /// show. At the 18 floor the gate is dead code the compiler never flags, so the pin inverts:
    /// no availability check and no support flag anywhere on the page. Comment-stripped, because
    /// this very history names both.
    func testPlacesIsUngatedAndTheSupportFlagIsGone() throws {
        let source = try Self.code("Tools/ToolsView.swift")
        XCTAssertFalse(
            source.contains("#available(iOS 17"),
            "`ToolsView` checks for iOS 17 again. The minimum is 18 (F-Floor18); the check can"
                + " never be false and the branch under it can never run."
        )
        XCTAssertFalse(
            source.contains("placesSupported"),
            "`placesSupported` is back. Places is universal at the 18 floor; a flag here reopens"
                + " the one case nothing on this machine can see."
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

    /// Every push lands under the capture disc, so every one asks for the room where it is
    /// pushed — the presentation owns the clearance, exactly as `AreasView` does for its own copy
    /// of the Life Areas editor. See `CaptureDiscClearanceCallSiteTests` for why these screens are
    /// not on that file's list.
    ///
    /// **Was "both" and a count of 3; `F-C3-RecentlyDeleted` made it three pushes and 4.** Updated
    /// deliberately, which is this test working: a third destination added WITHOUT its clearance
    /// would have left the count at 3 and passed.
    func testEveryPushedScreenAsksForCaptureDiscClearance() throws {
        let source = try Self.appSource("Tools/ToolsView.swift")
        XCTAssertEqual(
            source.components(separatedBy: ".captureDiscClearance()").count - 1, 4,
            "The Tools page should call `.captureDiscClearance()` four times: once on its own"
                + " scroll, and once at each of the three pushes. A missing one puts that"
                + " screen's last row under an opaque 60pt circle with nothing below it to"
                + " scroll to."
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

    /// **REVERSED by `F-Floor18`.** This was `testTheRoutinesSectionIsBehindTheSameFloorAsPlaces`,
    /// pinning `if #available(iOS 17.0, *) { ToolsRoutinesSection(` because the editor a row
    /// opens sat above the old floor. At 18 the section is drawn unconditionally and carries no
    /// annotation of its own.
    func testTheRoutinesSectionIsDrawnWithNoAvailabilityGate() throws {
        let tools = Self.collapsed(try Self.code("Tools/ToolsView.swift"))
        XCTAssertFalse(
            tools.contains("#available(iOS 17.0, *) { ToolsRoutinesSection("),
            "The Routines section is back inside an iOS 17 check, which can never be false at"
                + " the 18 floor (F-Floor18)."
        )
        let section = try Self.code("Tools/ToolsRoutinesSection.swift")
        XCTAssertFalse(
            section.contains("@available(iOS"),
            "`ToolsRoutinesSection` carries an availability annotation again."
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
    ///
    /// Since F-TabDepth-1 (2026-09-08) the section no longer pushes anything itself: its button
    /// calls `onOpenPlaces`, `ToolsView` turns that into its one flag push, and the clearance
    /// lives on `ToolsView`'s `.places` destination — so all three links of that chain are read,
    /// because any one of them broken puts the last row back under the disc.
    func testTheEmptyStatePushClearsTheCaptureDisc() throws {
        let section = try Self.code("Tools/ToolsRoutinesSection.swift")
        let tools = Self.collapsed(try Self.code("Tools/ToolsView.swift"))
        XCTAssertTrue(
            section.contains("onOpenPlaces()"),
            "The Routines empty state no longer routes its push through `onOpenPlaces`."
        )
        XCTAssertTrue(
            tools.contains("ToolsRoutinesSection(client: placesClient) { pushedDestination = .places }"),
            "`ToolsView` no longer turns the empty state's `onOpenPlaces` into its Places push."
        )
        XCTAssertTrue(
            tools.contains("PlacesListView(client: placesClient) .captureDiscClearance()"),
            "`ToolsView` pushes `PlacesListView` without the capture-disc clearance, so that"
                + " screen's last row sits under an opaque 60pt circle."
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
