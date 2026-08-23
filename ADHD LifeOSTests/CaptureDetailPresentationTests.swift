//
//  CaptureDetailPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Pure presentation logic for the full-screen capture detail (design frame B6): the nav-bar kind
/// label, the absolute timestamp, and a link capture's source domain. Layout stays in the view;
/// every string decision lives here where a unit test can reach it.
final class CaptureDetailPresentationTests: XCTestCase {

    // MARK: - Nav title

    /// Exhaustive over `CaptureKind` so a sixth kind fails here rather than shipping a blank nav
    /// bar. The mockup names four; `.task` has no frame, so it pairs the checkmark with its name
    /// by the same pattern (flagged in the block report).
    func testNavTitle_pairsEmojiAndKindName_forEveryKind() {
        let expected: [CaptureKind: String] = [
            .note: "📝 Note",
            .task: "✅ Task",
            .link: "🌐 Link",
            .voice: "🗣️ Voice",
            .photo: "📸 Photo"
        ]
        for kind in CaptureKind.allCases {
            XCTAssertEqual(CaptureDetailPresentation.navTitle(for: kind), expected[kind])
        }
    }

    // MARK: - Timestamp

    /// "14 August 2026 at 07:33" — absolute, because an archive gets read long after relative
    /// times ("2 hr ago") stop meaning anything. Locale and zone injected so the test doesn't
    /// depend on the machine running it.
    func testTimestamp_rendersLongDateWithShortTime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 7, minute: 33))!

        let rendered = CaptureDetailPresentation.timestamp(
            for: date, locale: Locale(identifier: "en_GB"), timeZone: TimeZone(identifier: "UTC")!
        )

        // Substring assertions rather than one exact string: ICU pads the hour ("07:33" vs
        // "7:33") differently across toolchains, and that rendering is the locale's business.
        // What this test pins is the SHAPE — absolute long date, joined to a wall-clock time.
        // ("07:33".contains("7:33") is true, so both paddings pass.)
        XCTAssertTrue(rendered.contains("14 August 2026"), "got: \(rendered)")
        XCTAssertTrue(rendered.contains("7:33"), "got: \(rendered)")
    }

    // MARK: - Source domain

    private func linkCapture(content: String, previewURL: String? = nil) -> Capture {
        Capture(
            id: UUID(), content: content, kind: .link, processed: false, createdAt: Date(),
            linkPreview: previewURL.map {
                CaptureLinkPreview(url: $0, title: nil, description: nil, thumbnailURL: nil)
            }
        )
    }

    func testSourceDomain_linkCapture_returnsHost() {
        let capture = linkCapture(content: "https://swiftpackageindex.com/apple/swift-async-algorithms")

        XCTAssertEqual(CaptureDetailPresentation.sourceDomain(for: capture), "swiftpackageindex.com")
    }

    func testSourceDomain_stripsWWWPrefix() {
        let capture = linkCapture(content: "https://www.example.com/article")

        XCTAssertEqual(CaptureDetailPresentation.sourceDomain(for: capture), "example.com")
    }

    /// The unfurl's canonical URL beats the raw captured string — the preview is what the server
    /// resolved the link TO, redirects followed.
    func testSourceDomain_prefersTheUnfurledPreviewURL() {
        let capture = linkCapture(content: "https://t.co/abc123", previewURL: "https://example.com/real")

        XCTAssertEqual(CaptureDetailPresentation.sourceDomain(for: capture), "example.com")
    }

    func testSourceDomain_nonLinkCapture_returnsNil() {
        let note = Capture(id: UUID(), content: "https://example.com", kind: .note, processed: false, createdAt: Date())

        XCTAssertNil(CaptureDetailPresentation.sourceDomain(for: note))
    }

    /// `URL(string:)` accepts almost anything; only a parse that yields a HOST counts as a source.
    func testSourceDomain_hostlessContent_returnsNil() {
        let capture = linkCapture(content: "just some words")

        XCTAssertNil(CaptureDetailPresentation.sourceDomain(for: capture))
    }
}
