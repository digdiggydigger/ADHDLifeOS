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

    // MARK: - Browse split

    func testBrowseSplit_popularKeepsRankOrder_restIsAlphabetical() {
        let ranked = [
            entry("Spotify", scheme: "spotify", rank: 1),
            entry("WhatsApp", scheme: "whatsapp", rank: 2),
            entry("Zoom", scheme: "zoomus", rank: 3),
            entry("Deliveroo", scheme: "deliveroo", rank: 4)
        ]

        let split = PlaceAppPickerPresentation.browseSplit(ranked, popularCount: 2)

        XCTAssertEqual(split.popular.map(\.name), ["Spotify", "WhatsApp"])
        XCTAssertEqual(
            split.rest.map(\.name), ["Deliveroo", "Zoom"],
            "The long tail reads alphabetically — rank stops meaning anything down there"
        )
    }

    func testBrowseSplit_shortListIsAllPopular() {
        let ranked = [entry("Spotify", scheme: "spotify", rank: 1)]

        let split = PlaceAppPickerPresentation.browseSplit(ranked, popularCount: 8)

        XCTAssertEqual(split.popular.map(\.name), ["Spotify"])
        XCTAssertTrue(split.rest.isEmpty)
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
