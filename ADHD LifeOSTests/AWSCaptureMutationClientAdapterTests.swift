//
//  AWSCaptureMutationClientAdapterTests.swift
//  ADHD LifeOSTests
//
//  Covers createTask/markProcessed/requestUploadURL/uploadMedia. createCapture/
//  fetchUnprocessedCaptures/fetchCapture coverage lives in AWSCaptureClientAdapterTests.swift,
//  split out to keep both files under SwiftLint's type_body_length ceiling (same precedent as
//  Stage C.5's AWSTaskDetailTagsTests split).
//

import XCTest
@testable import ADHD_LifeOS

final class AWSCaptureMutationClientAdapterTests: XCTestCase {

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

    // MARK: - createTask

    func testCreateTask_sendsSourceCaptureLiterally() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": UUID().uuidString, "title": "Buy milk", "status": "open", "priority": "p4"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedPromoteToTaskInput(
            title: "Buy milk", lifeAreaId: nil, priority: .p4, dueDate: nil
        )

        _ = try await sut.createTask(input)

        XCTAssertEqual(capturedBody["source"] as? String, "capture")
    }

    func testCreateTask_success_decodesTaskItem() async throws {
        let taskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(201, url: request.url!, [
                "id": taskID.uuidString, "title": "Buy milk", "status": "open", "priority": "p2"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedPromoteToTaskInput(
            title: "Buy milk", lifeAreaId: nil, priority: .p2, dueDate: nil
        )

        let task = try await sut.createTask(input)

        XCTAssertEqual(task.id, taskID)
        XCTAssertEqual(task.title, "Buy milk")
        XCTAssertEqual(task.priority, .p2)
    }

    func testCreateTask_dueDate_sentAsFractionalISO8601() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": UUID().uuidString, "title": "x", "status": "open", "priority": "p4"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedPromoteToTaskInput(
            title: "x", lifeAreaId: nil, priority: .p4, dueDate: Date(timeIntervalSince1970: 1_785_000_000)
        )

        _ = try await sut.createTask(input)

        let sentDueDate = try XCTUnwrap(capturedBody["dueDate"] as? String)
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNotNil(fractionalFormatter.date(from: sentDueDate))
    }

    func testCreateTask_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "title cannot be empty"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedPromoteToTaskInput(title: "", lifeAreaId: nil, priority: .p4, dueDate: nil)

        do {
            _ = try await sut.createTask(input)
            XCTFail("Expected createTask to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - markProcessed

    func testMarkProcessed_sendsStatusProcessedBody() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, [
                "id": UUID().uuidString, "content": "x", "kind": "note",
                "processed": true, "createdAt": "2026-07-23T04:47:46", "status": "processed"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.markProcessed(captureId: UUID())

        XCTAssertEqual(capturedBody["status"] as? String, "processed")
    }

    func testMarkProcessed_sendsLowercaseIdInURLPath() async throws {
        let uppercaseID = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            return try jsonResponse(200, url: request.url!, [
                "id": uppercaseID.uuidString, "content": "x", "kind": "note",
                "processed": true, "createdAt": "2026-07-23T04:47:46", "status": "processed"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.markProcessed(captureId: uppercaseID)

        XCTAssertEqual(capturedPath, "/prod/captures/1c4c7551-3f3c-4e2f-b02d-e6095be570c6")
    }

    func testMarkProcessed_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(404, url: request.url!, ["error": "not found"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.markProcessed(captureId: UUID())
            XCTFail("Expected markProcessed to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - requestUploadURL

    func testRequestUploadURL_success_decodesTarget() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "uploadUrl": "https://s3.example.com/put?sig=abc",
                "mediaKey": "captures/u/1/original.jpg",
                "thumbnailKey": "captures/u/1/thumb.jpg"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let target = try await sut.requestUploadURL(kind: .photo, contentType: "image/jpeg")

        XCTAssertEqual(target.uploadURL, URL(string: "https://s3.example.com/put?sig=abc"))
        XCTAssertEqual(target.mediaKey, "captures/u/1/original.jpg")
        XCTAssertEqual(target.thumbnailKey, "captures/u/1/thumb.jpg")
    }

    func testRequestUploadURL_voiceKind_noThumbnailKey() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "uploadUrl": "https://s3.example.com/put?sig=abc",
                "mediaKey": "captures/u/1/audio.m4a"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let target = try await sut.requestUploadURL(kind: .voice, contentType: "audio/m4a")

        XCTAssertNil(target.thumbnailKey)
    }

    func testRequestUploadURL_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "bad kind"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.requestUploadURL(kind: .photo, contentType: "image/jpeg")
            XCTFail("Expected requestUploadURL to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - uploadMedia

    func testUploadMedia_sendsPUTWithContentTypeAndNoAuthorizationHeader() async throws {
        var capturedMethod: String?
        var capturedHeaders: [String: String] = [:]
        var capturedBody: Data?
        MockURLProtocol.requestHandler = { request in
            capturedMethod = request.httpMethod
            capturedHeaders = request.allHTTPHeaderFields ?? [:]
            capturedBody = MockURLProtocol.body(of: request)
            guard
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            else {
                throw URLError(.badServerResponse)
            }
            return (response, Data())
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let payload = Data("hello".utf8)

        try await sut.uploadMedia(
            to: URL(string: "https://s3.example.com/put?sig=abc")!, data: payload, contentType: "image/jpeg"
        )

        XCTAssertEqual(capturedMethod, "PUT")
        XCTAssertEqual(capturedHeaders["Content-Type"], "image/jpeg")
        XCTAssertNil(capturedHeaders["Authorization"])
        XCTAssertEqual(capturedBody, payload)
    }

    func testUploadMedia_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { request in
            guard
                let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)
            else {
                throw URLError(.badServerResponse)
            }
            return (response, Data())
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.uploadMedia(
                to: URL(string: "https://s3.example.com/put?sig=abc")!,
                data: Data("hello".utf8), contentType: "image/jpeg"
            )
            XCTFail("Expected uploadMedia to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }
}
