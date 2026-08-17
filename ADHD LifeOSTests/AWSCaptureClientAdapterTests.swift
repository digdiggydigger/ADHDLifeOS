//
//  AWSCaptureClientAdapterTests.swift
//  ADHD LifeOSTests
//
//  Covers createCapture/fetchUnprocessedCaptures. fetchCapture coverage lives in
//  AWSCaptureFetchClientAdapterTests.swift; createTask/markProcessed/requestUploadURL/
//  uploadMedia coverage lives in AWSCaptureMutationClientAdapterTests.swift — split out to keep
//  all three files under SwiftLint's type_body_length ceiling (same precedent as Stage C.5's
//  AWSTaskDetailTagsTests split).
//

import XCTest
@testable import ADHD_LifeOS

final class AWSCaptureClientAdapterTests: XCTestCase {

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

    private func decodedBody(of request: URLRequest) -> [String: Any] {
        guard
            let data = MockURLProtocol.body(of: request),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return json
    }

    private func normalizedInput(
        content: String = "Buy milk",
        kind: CaptureKind = .note,
        title: String? = nil,
        lifeAreaId: UUID? = nil,
        mediaKey: String? = nil,
        mediaContentType: String? = nil,
        thumbnailKey: String? = nil
    ) -> NormalizedCreateCaptureInput {
        guard case .success(let normalized) = CaptureValidation.normalizeCreateCaptureInput(
            content: content, kind: kind, title: title, lifeAreaId: lifeAreaId,
            mediaKey: mediaKey, mediaContentType: mediaContentType, thumbnailKey: thumbnailKey
        ) else {
            fatalError("expected valid input")
        }
        return normalized
    }

    // MARK: - createCapture

    func testCreateCapture_success_decodesCapture() async throws {
        let captureID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": captureID.uuidString, "content": "Buy milk", "kind": "note",
                "processed": false, "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let capture = try await sut.createCapture(normalizedInput())

        XCTAssertEqual(capture.id, captureID)
        XCTAssertEqual(capture.content, "Buy milk")
        XCTAssertEqual(capture.kind, .note)
        XCTAssertFalse(capture.processed)
    }

    func testCreateCapture_mediaFieldsPresent_allKeysOnWire() async throws {
        let lifeAreaID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": UUID().uuidString, "content": "", "kind": "photo",
                "processed": false, "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = normalizedInput(
            content: "", kind: .photo, title: "Sunset", lifeAreaId: lifeAreaID,
            mediaKey: "captures/u/1/original.jpg", mediaContentType: "image/jpeg",
            thumbnailKey: "captures/u/1/thumb.jpg"
        )

        _ = try await sut.createCapture(input)

        XCTAssertEqual(capturedBody["title"] as? String, "Sunset")
        XCTAssertEqual(capturedBody["lifeAreaId"] as? String, lifeAreaID.uuidString)
        XCTAssertEqual(capturedBody["mediaKey"] as? String, "captures/u/1/original.jpg")
        XCTAssertEqual(capturedBody["mediaContentType"] as? String, "image/jpeg")
        XCTAssertEqual(capturedBody["thumbnailKey"] as? String, "captures/u/1/thumb.jpg")
    }

    func testCreateCapture_mediaFieldsAbsent_keysOmittedNotNull() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": UUID().uuidString, "content": "Buy milk", "kind": "note",
                "processed": false, "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.createCapture(normalizedInput())

        XCTAssertEqual(Set(capturedBody.keys), ["content", "kind"])
    }

    func testCreateCapture_photoWithEmptyContent_succeedsPreFlight() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "", kind: .photo)

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.content, "")
            XCTAssertEqual(normalized.kind, .photo)
        case .failure:
            XCTFail("Expected photo capture with empty content to be valid")
        }
    }

    func testCreateCapture_noteWithEmptyContent_rejectedPreFlight() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "   ", kind: .note)

        XCTAssertEqual(result, .failure(.emptyContent))
    }

    func testCreateCapture_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "bad request"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.createCapture(normalizedInput())
            XCTFail("Expected createCapture to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - fetchUnprocessedCaptures

    func testFetchUnprocessedCaptures_success_decodesList() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "captures": [
                    ["id": UUID().uuidString, "content": "First", "kind": "note",
                     "processed": false, "createdAt": "2026-07-23T04:47:46"],
                    ["id": UUID().uuidString, "content": "Second", "kind": "task",
                     "processed": false, "createdAt": "2026-07-23T04:48:00"]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let captures = try await sut.fetchUnprocessedCaptures()

        XCTAssertEqual(captures.count, 2)
        XCTAssertEqual(captures[0].content, "First")
        XCTAssertEqual(captures[1].content, "Second")
    }

    func testFetchUnprocessedCaptures_empty_decodesEmptyList() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, ["captures": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let captures = try await sut.fetchUnprocessedCaptures()

        XCTAssertTrue(captures.isEmpty)
    }

    func testFetchUnprocessedCaptures_sendsProcessedFalseQueryItem() async throws {
        var capturedQuery: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedQuery = request.url!.query
            return try jsonResponse(200, url: request.url!, ["captures": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchUnprocessedCaptures()

        XCTAssertEqual(capturedQuery, "processed=false")
    }

    func testFetchUnprocessedCaptures_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchUnprocessedCaptures()
            XCTFail("Expected fetchUnprocessedCaptures to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

}
