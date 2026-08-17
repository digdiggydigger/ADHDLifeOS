//
//  CaptureRowPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class CaptureRowPresentationTests: XCTestCase {

    // MARK: - primaryText

    func testPrimaryText_titleWinsOverContent() {
        let capture = Capture(
            id: UUID(), content: "the content body", kind: .note, processed: false,
            createdAt: Date(), title: "A Real Title"
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "A Real Title")
    }

    func testPrimaryText_whitespaceOnlyTitleFallsThroughToContent() {
        let capture = Capture(
            id: UUID(), content: "the content body", kind: .note, processed: false,
            createdAt: Date(), title: "   \n  "
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "the content body")
    }

    func testPrimaryText_linkPrefersPreviewTitleOverRawURL() {
        let preview = CaptureLinkPreview(
            url: "https://example.com/article",
            title: "Example Article Headline",
            description: nil,
            thumbnailURL: nil
        )
        let capture = Capture(
            id: UUID(), content: "https://example.com/article", kind: .link, processed: false,
            createdAt: Date(), linkPreview: preview
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "Example Article Headline")
    }

    func testPrimaryText_linkWithWhitespaceOnlyPreviewTitleFallsThroughToContent() {
        let preview = CaptureLinkPreview(
            url: "https://example.com/article",
            title: "   ",
            description: nil,
            thumbnailURL: nil
        )
        let capture = Capture(
            id: UUID(), content: "https://example.com/article", kind: .link, processed: false,
            createdAt: Date(), linkPreview: preview
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "https://example.com/article")
    }

    func testPrimaryText_previewTitleIgnoredForNonLinkKind() {
        let preview = CaptureLinkPreview(
            url: "https://example.com",
            title: "Preview Title",
            description: nil,
            thumbnailURL: nil
        )
        // A note that somehow carries a linkPreview must NOT use it — (b) is link-only.
        let capture = Capture(
            id: UUID(), content: "note body", kind: .note, processed: false,
            createdAt: Date(), linkPreview: preview
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "note body")
    }

    func testPrimaryText_photoWithEmptyContentAndNoTitleReturnsPhotoCapture() {
        let capture = Capture(
            id: UUID(), content: "", kind: .photo, processed: false, createdAt: Date()
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "Photo capture")
    }

    func testPrimaryText_photoWithWhitespaceContentAndNoTitleReturnsPhotoCapture() {
        let capture = Capture(
            id: UUID(), content: "  \n ", kind: .photo, processed: false, createdAt: Date()
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "Photo capture")
    }

    func testPrimaryText_nonPhotoWithAllFieldsEmptyReturnsUntitledCapture() {
        let capture = Capture(
            id: UUID(), content: "", kind: .note, processed: false, createdAt: Date()
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "Untitled capture")
    }

    func testPrimaryText_contentUsedWhenNoTitle() {
        let capture = Capture(
            id: UUID(), content: "Just the body", kind: .task, processed: false, createdAt: Date()
        )
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: capture), "Just the body")
    }

    // MARK: - glyphSystemImageName

    func testGlyphSystemImageName_note() {
        XCTAssertEqual(CaptureRowPresentation.glyphSystemImageName(for: .note), "note.text")
    }

    func testGlyphSystemImageName_task() {
        XCTAssertEqual(CaptureRowPresentation.glyphSystemImageName(for: .task), "checkmark.circle")
    }

    func testGlyphSystemImageName_link() {
        XCTAssertEqual(CaptureRowPresentation.glyphSystemImageName(for: .link), "link")
    }

    func testGlyphSystemImageName_photo() {
        XCTAssertEqual(CaptureRowPresentation.glyphSystemImageName(for: .photo), "photo")
    }

    func testGlyphSystemImageName_voice() {
        XCTAssertEqual(CaptureRowPresentation.glyphSystemImageName(for: .voice), "waveform")
    }

    // MARK: - kindLabel

    func testKindLabel_allFiveKinds() {
        XCTAssertEqual(CaptureRowPresentation.kindLabel(for: .note), "Note")
        XCTAssertEqual(CaptureRowPresentation.kindLabel(for: .task), "Task")
        XCTAssertEqual(CaptureRowPresentation.kindLabel(for: .link), "Link")
        XCTAssertEqual(CaptureRowPresentation.kindLabel(for: .photo), "Photo")
        XCTAssertEqual(CaptureRowPresentation.kindLabel(for: .voice), "Voice")
    }
}
