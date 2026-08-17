//
//  AWSCaptureTriageTests.swift
//  ADHD LifeOSTests
//
//  Covers Stage C.6b-triage's adapter additions: updateCapture/fetchAllTags/createTag/fetchTags/
//  addTag/removeTag. Split out to keep AWSCaptureClientAdapterTests.swift under SwiftLint's
//  type_body_length ceiling — same precedent as AWSTaskDetailTagsTests.swift.
//

import XCTest
@testable import ADHD_LifeOS

final class AWSCaptureTriageTests: XCTestCase {

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

    private func captureJSON(id: UUID) -> [String: Any] {
        [
            "id": id.uuidString, "content": "Buy milk", "kind": "note",
            "processed": false, "createdAt": "2026-07-23T04:47:46"
        ]
    }

    // MARK: - updateCapture

    func testUpdateCapture_sendsOnlyPresentFieldsAndLowercasePath() async throws {
        let captureId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        let lifeAreaId = UUID(uuidString: "AB2C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, captureJSON(id: captureId))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.updateCapture(id: captureId, changes: CaptureUpdate(lifeAreaId: .some(lifeAreaId)))

        XCTAssertEqual(capturedPath, "/prod/captures/1c4c7551-3f3c-4e2f-b02d-e6095be570c6")
        XCTAssertEqual(Set(capturedBody.keys), ["lifeAreaId"])
        XCTAssertEqual(capturedBody["lifeAreaId"] as? String, lifeAreaId.uuidString)
    }

    func testUpdateCapture_clearedLifeArea_sendsExplicitNull() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, captureJSON(id: UUID()))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.updateCapture(id: UUID(), changes: CaptureUpdate(lifeAreaId: .some(nil)))

        XCTAssertEqual(Set(capturedBody.keys), ["lifeAreaId"])
        XCTAssertTrue(capturedBody["lifeAreaId"] is NSNull)
    }

    func testUpdateCapture_noChanges_sendsEmptyBody() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, captureJSON(id: UUID()))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.updateCapture(id: UUID(), changes: CaptureUpdate())

        XCTAssertTrue(capturedBody.isEmpty)
    }

    func testUpdateCapture_decodesReturnedCapture() async throws {
        let captureId = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, captureJSON(id: captureId))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let capture = try await sut.updateCapture(id: captureId, changes: CaptureUpdate(status: .inbox))

        XCTAssertEqual(capture.id, captureId)
    }

    func testUpdateCapture_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.updateCapture(id: UUID(), changes: CaptureUpdate())
            XCTFail("Expected updateCapture to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - fetchAllTags / createTag

    func testFetchAllTags_success_decodesTagList() async throws {
        let tagID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, ["tags": [["id": tagID.uuidString, "name": "focus"]]])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tags = try await sut.fetchAllTags()

        XCTAssertEqual(tags, [Tag(id: tagID, name: "focus")])
    }

    func testCreateTag_success_sendsNameAndDecodesResponse() async throws {
        let tagID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, ["id": tagID.uuidString, "name": "focus"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tag = try await sut.createTag(name: "focus")

        XCTAssertEqual(tag, Tag(id: tagID, name: "focus"))
        XCTAssertEqual(capturedBody["name"] as? String, "focus")
    }

    // MARK: - fetchTags

    func testFetchTags_success_decodesTagList() async throws {
        let captureId = UUID()
        let tagId = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, ["tags": [["id": tagId.uuidString, "name": "urgent"]]])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tags = try await sut.fetchTags(captureId: captureId)

        XCTAssertEqual(tags, [Tag(id: tagId, name: "urgent")])
    }

    func testFetchTags_sendsLowercaseIdInURLPath() async throws {
        let captureId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            return try jsonResponse(200, url: request.url!, ["tags": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchTags(captureId: captureId)

        XCTAssertEqual(capturedPath, "/prod/captures/1c4c7551-3f3c-4e2f-b02d-e6095be570c6/tags")
    }

    func testFetchTags_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchTags(captureId: UUID())
            XCTFail("Expected fetchTags to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - addTag

    func testAddTag_sendsLowercaseIdsInPathAndBody() async throws {
        let captureId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        let tagId = UUID(uuidString: "AB2C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            capturedBody = decodedBody(of: request)
            return try jsonResponse(
                201, url: request.url!, ["captureId": captureId.uuidString, "tagId": tagId.uuidString]
            )
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.addTag(captureId: captureId, tagId: tagId)

        XCTAssertEqual(capturedPath, "/prod/captures/1c4c7551-3f3c-4e2f-b02d-e6095be570c6/tags")
        XCTAssertEqual(capturedBody["tagId"] as? String, "ab2c7551-3f3c-4e2f-b02d-e6095be570c6")
    }

    func testAddTag_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "tagId is required"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.addTag(captureId: UUID(), tagId: UUID())
            XCTFail("Expected addTag to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - removeTag

    func testRemoveTag_sendsCorrectDeletePathWithLowercaseIds() async throws {
        let captureId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        let tagId = UUID(uuidString: "AB2C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        var capturedMethod: String?
        MockURLProtocol.requestHandler = { request in
            capturedPath = request.url!.path
            capturedMethod = request.httpMethod
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.removeTag(captureId: captureId, tagId: tagId)

        XCTAssertEqual(
            capturedPath,
            "/prod/captures/1c4c7551-3f3c-4e2f-b02d-e6095be570c6/tags/ab2c7551-3f3c-4e2f-b02d-e6095be570c6"
        )
        XCTAssertEqual(capturedMethod, "DELETE")
    }

    func testRemoveTag_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.removeTag(captureId: UUID(), tagId: UUID())
            XCTFail("Expected removeTag to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }

    func testRemoveTag_tokenThrows_shortCircuitsBeforeNetworkCall() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            try await sut.removeTag(captureId: UUID(), tagId: UUID())
            XCTFail("Expected removeTag to throw")
        } catch is CaptureServiceError {
            // expected
        } catch {
            XCTFail("Expected CaptureServiceError.fetchFailed, got \(error)")
        }
    }
}
