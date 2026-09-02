//
//  PlaceAppPickerPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure presentation helpers behind the app-directory design pass (E's 2026-09-02 device
/// verdict: "ugly and plain"): the monogram initial each row's avatar disc shows, the
/// Popular / All-apps browse split, and the kind glyphs the editor's Action picker carries.
final class PlaceAppPickerPresentationTests: XCTestCase {

    private func entry(_ name: String, scheme: String, rank: Int) -> PlaceAppDirectoryEntry {
        PlaceAppDirectoryEntry(
            scheme: scheme, name: name, keywords: [], universalLinkHosts: [],
            destinations: [], rank: rank, hidden: false
        )
    }

    // MARK: - Monogram

    func testMonogram_isTheFirstCharacterUppercased() {
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: "spotify"), "S")
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: "WhatsApp"), "W")
    }

    func testMonogram_survivesLeadingWhitespaceAndEmpty() {
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: "  uber"), "U")
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: ""), "")
    }

    // MARK: - Popular head

    func testPopular_keepsRankOrderAndStopsAtTheCount() {
        let ranked = [
            entry("Spotify", scheme: "spotify", rank: 4),
            entry("WhatsApp", scheme: "whatsapp", rank: 3),
            entry("Zoom", scheme: "zoomus", rank: 2),
            entry("Deliveroo", scheme: "deliveroo", rank: 1)
        ]

        XCTAssertEqual(
            PlaceAppPickerPresentation.popular(ranked, count: 2).map(\.name),
            ["Spotify", "WhatsApp"],
            "The head is taken in the order given — rank order, straight off the search"
        )
    }

    func testPopular_shortListIsReturnedWhole() {
        let ranked = [entry("Spotify", scheme: "spotify", rank: 1)]

        XCTAssertEqual(PlaceAppPickerPresentation.popular(ranked, count: 8).map(\.name), ["Spotify"])
    }

    // MARK: - Category browse

    private func categorised(
        _ name: String, _ scheme: String, _ category: PlaceAppCategory, hidden: Bool = false
    ) -> PlaceAppDirectoryEntry {
        PlaceAppDirectoryEntry(
            scheme: scheme, name: name, keywords: [], universalLinkHosts: [],
            destinations: [], rank: 0, hidden: hidden, category: category
        )
    }

    func testCategoryBrowse_ordersCategoriesByDeclaration_andEntriesAlphabetically() {
        let entries = [
            categorised("Zoom", "zoomus", .social),
            categorised("Strava", "strava", .health),
            categorised("Discord", "discord", .social),
            categorised("Notes", "mobilenotes", .apple)
        ]

        let sections = PlaceAppPickerPresentation.categoryBrowse(entries)

        XCTAssertEqual(
            sections.map(\.category), [.apple, .social, .health],
            "Declaration order IS browse order — Apple, then Social, then Health"
        )
        XCTAssertEqual(
            sections[1].entries.map(\.name), ["Discord", "Zoom"],
            "Inside a category the eye needs A-Z, not rank"
        )
    }

    func testCategoryBrowse_dropsEmptyCategoriesAndHiddenEntries() {
        let entries = [
            categorised("Discord", "discord", .social),
            categorised("Retired", "retired", .money, hidden: true)
        ]

        let sections = PlaceAppPickerPresentation.categoryBrowse(entries)

        XCTAssertEqual(sections.map(\.category), [.social])
        XCTAssertEqual(
            sections.first?.count, 1,
            "A category whose only entry is hidden must not show as an empty row"
        )
    }

    /// The categories are COMPLETE, not a partition against the popular head: an app in the
    /// top eight still appears under its own category, because a category that quietly omits
    /// the most obvious app in it reads as broken.
    func testCategoryBrowse_coversEveryVisibleEntryExactlyOnce() {
        let all = PlaceAppDirectoryBundled.entries
        let sections = PlaceAppPickerPresentation.categoryBrowse(all)

        let browsed = sections.flatMap(\.entries).map(\.scheme)
        XCTAssertEqual(
            Set(browsed), Set(all.filter { !$0.hidden }.map(\.scheme)),
            "Every visible bundled app must be reachable by browsing"
        )
        XCTAssertEqual(browsed.count, Set(browsed).count, "No app listed under two categories")
    }

    // MARK: - Row metrics (E's density verdict, 2026-09-02)

    /// §3 is not negotiable: the row got tighter, the TOUCH TARGET did not.
    func testRowMetrics_keepTheFortyFourPointTouchTarget() {
        XCTAssertGreaterThanOrEqual(PlaceAppPickerPresentation.RowMetrics.minimumHeight, 44)
    }

    /// The tightening has to come out of PADDING. If the disc plus its padding ever grew past
    /// the minimum height, the row would expand again and the change would achieve nothing —
    /// which is exactly the shape of the bug E photographed (10 of 22 apps on screen).
    func testRowMetrics_discAndPaddingFitInsideTheMinimumHeight() {
        let disc = PlaceAppPickerPresentation.RowMetrics.discSize
        let padding = PlaceAppPickerPresentation.RowMetrics.verticalPadding

        XCTAssertLessThanOrEqual(
            disc + 2 * padding, PlaceAppPickerPresentation.RowMetrics.minimumHeight,
            "The row's own content is taller than the 44pt floor, so the floor stopped governing"
        )
    }

    // MARK: - Destination control

    /// E's 2026-09-02 call: the row TAP now always picks the app, so deep destinations need
    /// their own hit area. Only entries that HAVE destinations show the control — a control
    /// leading to an empty step would be a promise of nothing.
    func testDestinationControl_showsOnlyForEntriesThatHaveDestinations() {
        let plain = entry("Gmail", scheme: "googlegmail", rank: 0)
        let deep = PlaceAppDirectoryEntry(
            scheme: "maps", name: "Apple Maps",
            destinations: [
                PlaceAppDestinationTemplate(name: "Directions", template: "maps://?daddr={value}")
            ]
        )

        XCTAssertFalse(PlaceAppPickerPresentation.showsDestinationControl(for: plain))
        XCTAssertTrue(PlaceAppPickerPresentation.showsDestinationControl(for: deep))
    }

    // MARK: - Kind glyphs

    func testEveryKindChoice_carriesAGlyph() {
        for choice in PlaceActionDraft.KindChoice.allCases {
            XCTAssertFalse(
                PlaceAppPickerPresentation.kindGlyph(for: choice).isEmpty,
                "\(choice) has no glyph"
            )
        }
    }

    // MARK: - Installed tick — E's display switch (2026-09-02)

    /// E: "do not display the tick icon … this means we don't have to deal with this at the
    /// minute". With the switch off NO verdict draws a tick — including `.looksInstalled`,
    /// the only one that ever could. These assertions are expected to flip WITH the switch;
    /// the positive-only rule below is what must survive it.
    func testInstalledCheck_isSuppressedForEveryVerdict_whileTheSwitchIsOff() {
        XCTAssertFalse(
            PlaceAppPickerPresentation.showsInstalledBadge,
            "E switched the directory tick off on 2026-09-02 — flip it back only on E's word"
        )

        for verdict in [
            PlaceAppInstallVerdict.looksInstalled, .doesNotLookInstalled, .cannotCheck
        ] {
            XCTAssertFalse(
                PlaceAppPickerPresentation.showsInstalledCheck(verdict: verdict),
                "\(verdict) drew a tick with the switch off"
            )
        }
    }

    /// The switch is the ONLY thing holding the tick back — re-enabling must not also bring
    /// back a negative mark on 150 rows, which is the noise F-AppDirectory-3 set out to
    /// avoid. Pinned now so turning it on again stays a one-line change, not a redesign.
    func testInstalledCheck_staysPositiveOnly_whenTheSwitchIsOn() {
        XCTAssertTrue(
            PlaceAppPickerPresentation.showsInstalledCheck(
                enabled: true, verdict: .looksInstalled
            )
        )
        XCTAssertFalse(
            PlaceAppPickerPresentation.showsInstalledCheck(
                enabled: true, verdict: .doesNotLookInstalled
            )
        )
        XCTAssertFalse(
            PlaceAppPickerPresentation.showsInstalledCheck(
                enabled: true, verdict: .cannotCheck
            )
        )
    }

    /// The verdict is not merely ignored, it is never ASKED for — so a switched-off tick
    /// costs the picker zero `canOpenURL` calls rather than 45 discarded ones per open.
    func testInstalledCheck_neverEvaluatesTheVerdict_whileTheSwitchIsOff() {
        var asked = 0

        _ = PlaceAppPickerPresentation.showsInstalledCheck(
            verdict: { () -> PlaceAppInstallVerdict in asked += 1; return .looksInstalled }()
        )

        XCTAssertEqual(asked, 0, "The verdict was computed for a tick that cannot be drawn")
    }
}
