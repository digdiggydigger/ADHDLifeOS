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

    // MARK: - Caption

    // The caption led with the kind until the 2026-08-20 Inbox parity pass, when it moved to the
    // web original's "Captured 14:32 · voice note": the glyph beside it already says the kind, and
    // WHEN a thought was dumped is the fact you actually scan a backlog for. The shape itself is
    // covered in `CaptureRowDetailTests`; what stays here is the invariant every row shares.

    func testCaption_hasTheSameShapeForEveryKind() {
        let captions = CaptureKind.allCases.map { kind in
            CaptureRowPresentation.caption(
                for: Capture(id: UUID(), content: "x", kind: kind, processed: false, createdAt: Date())
            )
        }

        XCTAssertTrue(captions.allSatisfy { $0.contains(" · ") }, "one separator, every row")
    }

    // MARK: - Tags resolution

    // The chips under a row's meta line resolve against the ONE already-fetched tag list — never a
    // per-row fetch. Semantics mirror `FirebaseManager.fetchTags(for:parentId:)`: renamed tags show
    // their current name because resolution happens by id, and dangling ids are silently dropped.

    func testTags_resolveInTheCapturesAttachOrder() {
        let errands = Tag(id: UUID(), name: "errands")
        let deep = Tag(id: UUID(), name: "deep-work")
        let waiting = Tag(id: UUID(), name: "waiting-on")
        let capture = Capture(
            id: UUID(), content: "x", kind: .note, processed: false, createdAt: Date(),
            tagIds: [waiting.id, errands.id]
        )

        XCTAssertEqual(
            CaptureRowPresentation.tags(for: capture, from: [errands, deep, waiting]),
            [waiting, errands],
            "chip order is the tag_ids array order (attach order), not the fetched list's order"
        )
    }

    func testTags_dropDanglingIdsSilently() {
        let kept = Tag(id: UUID(), name: "kept")
        let capture = Capture(
            id: UUID(), content: "x", kind: .note, processed: false, createdAt: Date(),
            tagIds: [UUID(), kept.id]
        )

        XCTAssertEqual(CaptureRowPresentation.tags(for: capture, from: [kept]), [kept])
    }

    func testTags_emptyWhenTheCaptureHasNoMembership() {
        let tag = Tag(id: UUID(), name: "unused")
        let noField = Capture(id: UUID(), content: "x", kind: .note, processed: false, createdAt: Date())
        let emptyField = Capture(
            id: UUID(), content: "x", kind: .note, processed: false, createdAt: Date(), tagIds: []
        )

        XCTAssertEqual(CaptureRowPresentation.tags(for: noField, from: [tag]), [])
        XCTAssertEqual(CaptureRowPresentation.tags(for: emptyField, from: [tag]), [])
    }
}
