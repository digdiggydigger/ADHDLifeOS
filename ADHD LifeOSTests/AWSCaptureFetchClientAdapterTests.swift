//
//  AWSCaptureFetchClientAdapterTests.swift
//  ADHD LifeOSTests
//
//  Covers fetchCapture. createCapture/fetchUnprocessedCaptures coverage lives in
//  AWSCaptureClientAdapterTests.swift; createTask/markProcessed/requestUploadURL/uploadMedia
//  coverage lives in AWSCaptureMutationClientAdapterTests.swift — split out to keep all three
//  files under SwiftLint's type_body_length ceiling (same precedent as Stage C.5's
//  AWSTaskDetailTagsTests split).
//

import XCTest
@testable import ADHD_LifeOS

final class AWSCaptureFetchClientAdapterTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(authClient: AuthClientAdapting) -> AWSCaptureClientAdapter {
        AWSCaptureClientAdapter(
            authClient: authClient,
            session: MockURLProtocol.makeSession(),
            baseURL: URL(string: "https://life-os-api-gw.example.com/prod")!
        )
    }

    private func jsonResponse(_ statusCode: Int, url: URL, _ body: [String: Any]) throws -> (HTTPURLResponse, Data) {
        let data = try JSONSerialization.data(withJSONObject: body)
        guard
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        else {
            throw URLError(.badServerResponse)
        }
        return (response, data)
    }

    func testFetchCapture_success_decodesFullItem() async throws {
        let captureID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": captureID.uuidString, "content": "A link", "kind": "link",
                "processed": false, "createdAt": "2026-07-23T04:47:46",
                "status": "needs-review",
                "mediaUrl": "https://media.example.com/original.jpg",
                "thumbnailUrl": "https://media.example.com/thumb.jpg",
                "linkPreview": [
                    "url": "https://example.com",
                    "title": "Example",
                    "description": "An example site",
                    "thumbnailUrl": "https://media.example.com/link-thumb.jpg"
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let capture = try await sut.fetchCapture(id: captureID)

        XCTAssertEqual(capture.status, .needsReview)
        XCTAssertEqual(capture.mediaURL, URL(string: "https://media.example.com/original.jpg"))
        XCTAssertEqual(capture.thumbnailURL, URL(string: "https://media.example.com/thumb.jpg"))
        XCTAssertEqual(capture.linkPreview?.url, "https://example.com")
        XCTAssertEqual(capture.linkPreview?.title, "Example")
        XCTAssertEqual(capture.linkPreview?.description, "An example site")
        XCTAssertEqual(
            capture.linkPreview?.thumbnailURL, URL(string: "https://media.example.com/link-thumb.jpg")
        )
    }

    func testFetchCapture_absentOptionalFields_decodeNil() async throws {
        let captureID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": captureID.uuidString, "content": "Plain", "kind": "note",
                "processed": false, "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let capture = try await sut.fetchCapture(id: captureID)

        XCTAssertNil(capture.status)
        XCTAssertNil(capture.mediaURL)
        XCTAssertNil(capture.thumbnailURL)
        XCTAssertNil(capture.linkPreview)
        XCTAssertNil(capture.title)
        XCTAssertNil(capture.lifeAreaId)
        XCTAssertNil(capture.aiAssessment)
    }

    func testFetchCapture_bareCreatedAt_decodes() async throws {
        let captureID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": captureID.uuidString, "content": "x", "kind": "note",
                "processed": false, "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let capture = try await sut.fetchCapture(id: captureID)

        var expectedComponents = DateComponents()
        expectedComponents.year = 2026; expectedComponents.month = 7; expectedComponents.day = 23
        expectedComponents.hour = 4; expectedComponents.minute = 47; expectedComponents.second = 46
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(capture.createdAt, utcCalendar.date(from: expectedComponents))
    }

    func testFetchCapture_unparseableCreatedAt_throws() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": UUID().uuidString, "content": "x", "kind": "note",
                "processed": false, "createdAt": "not-a-real-date"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchCapture(id: UUID())
            XCTFail("Expected fetchCapture to throw when createdAt is unparseable")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchCapture_sendsLowercaseIdInURLPath() async throws {
        let uppercaseID = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            return try jsonResponse(200, url: request.url!, [
                "id": uppercaseID.uuidString, "content": "x", "kind": "note",
                "processed": false, "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchCapture(id: uppercaseID)

        XCTAssertEqual(capturedPath, "/prod/captures/1c4c7551-3f3c-4e2f-b02d-e6095be570c6")
    }
}
