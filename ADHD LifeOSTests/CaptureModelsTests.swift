//
//  CaptureModelsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class CaptureModelsTests: XCTestCase {

    func testPhotoDisplayURL_prefersThumbnailURLOverMediaURL() {
        let thumbnailURL = URL(string: "https://example.com/thumb.jpg")!
        let mediaURL = URL(string: "https://example.com/original.jpg")!
        let capture = Capture(
            id: UUID(), content: "", kind: .photo, processed: false, createdAt: Date(),
            mediaURL: mediaURL, thumbnailURL: thumbnailURL
        )

        XCTAssertEqual(capture.photoDisplayURL, thumbnailURL)
    }

    func testPhotoDisplayURL_fallsBackToMediaURL_whenThumbnailAbsent() {
        let mediaURL = URL(string: "https://example.com/original.jpg")!
        let capture = Capture(
            id: UUID(), content: "", kind: .photo, processed: false, createdAt: Date(),
            mediaURL: mediaURL, thumbnailURL: nil
        )

        XCTAssertEqual(capture.photoDisplayURL, mediaURL)
    }

    func testPhotoDisplayURL_nil_whenNeitherPresent() {
        let capture = Capture(id: UUID(), content: "Note", kind: .note, processed: false, createdAt: Date())

        XCTAssertNil(capture.photoDisplayURL)
    }
}
