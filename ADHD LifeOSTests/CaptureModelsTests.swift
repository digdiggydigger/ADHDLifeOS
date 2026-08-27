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

    // MARK: - Triage state

    /// The audit's A4. `processed` and `seen` are the two orthogonal facts triage actually turns
    /// on — "was it dealt with" and "was it filed away". `status` was a third field encoding the
    /// same thing, written at create and on promotion and read by NOTHING, so Sorted never
    /// updated it and every sorted capture's `status` still claimed `inbox`. Encoding must not
    /// mint it again.
    func testEncoding_carriesProcessedButNoStatusField() throws {
        let capture = Capture(id: UUID(), content: "Note", kind: .note, processed: false, createdAt: Date())

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(capture)) as? [String: Any]
        )

        XCTAssertNotNil(json["processed"])
        XCTAssertNil(json["status"], "processed + seen are the only triage state a capture carries")
    }
}
