//
//  AWSTaskDetailTagsTests.swift
//  ADHD LifeOSTests
//
//  Covers fetchTagsForTask/fetchAllTags/createTag/addTagToTask/removeTagFromTask. Split out from
//  AWSTaskDetailClientAdapterTests.swift to keep both files under SwiftLint's type_body_length
//  ceiling (same precedent as Stage C.4's AttachTagsTests split).
//

import XCTest
@testable import ADHD_LifeOS

final class AWSTaskDetailTagsTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(authClient: AuthClientAdapting) -> AWSTaskDetailClientAdapter {
        AWSTaskDetailClientAdapter(
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

    // MARK: - fetchTagsForTask

    func testFetchTagsForTask_success_decodesTagList() async throws {
        let taskID = UUID()
        let tagID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, ["tags": [["id": tagID.uuidString, "name": "urgent"]]])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tags = try await sut.fetchTagsForTask(taskId: taskID)

        XCTAssertEqual(tags, [Tag(id: tagID, name: "urgent")])
    }

    func testFetchTagsForTask_emptyList_decodesAsEmpty() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, ["tags": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tags = try await sut.fetchTagsForTask(taskId: UUID())

        XCTAssertEqual(tags, [])
    }

    func testFetchTagsForTask_sendsLowercaseIdInURLPath() async throws {
        let taskId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            return try jsonResponse(200, url: request.url!, ["tags": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchTagsForTask(taskId: taskId)

        XCTAssertEqual(capturedPath, "/prod/tasks/1c4c7551-3f3c-4e2f-b02d-e6095be570c6/tags")
    }

    func testFetchTagsForTask_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchTagsForTask(taskId: UUID())
            XCTFail("Expected fetchTagsForTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
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

    // MARK: - addTagToTask

    func testAddTagToTask_sendsCorrectPathAndBody() async throws {
        let taskId = UUID()
        let tagId = UUID()
        var capturedPath: String?
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, ["taskId": taskId.uuidString, "tagId": tagId.uuidString])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.addTagToTask(taskId: taskId, tagId: tagId)

        XCTAssertEqual(capturedPath, "/prod/tasks/\(taskId.lowercaseUUIDString)/tags")
        XCTAssertEqual(capturedBody["tagId"] as? String, tagId.lowercaseUUIDString)
    }

    func testAddTagToTask_sendsLowercaseIdsInPathAndBody() async throws {
        let taskId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        let tagId = UUID(uuidString: "AB2C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, ["taskId": taskId.uuidString, "tagId": tagId.uuidString])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.addTagToTask(taskId: taskId, tagId: tagId)

        XCTAssertEqual(capturedPath, "/prod/tasks/1c4c7551-3f3c-4e2f-b02d-e6095be570c6/tags")
        XCTAssertEqual(capturedBody["tagId"] as? String, "ab2c7551-3f3c-4e2f-b02d-e6095be570c6")
    }

    func testAddTagToTask_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "tagId is required"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.addTagToTask(taskId: UUID(), tagId: UUID())
            XCTFail("Expected addTagToTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - removeTagFromTask

    func testRemoveTagFromTask_sendsCorrectDeletePath() async throws {
        let taskId = UUID()
        let tagId = UUID()
        var capturedPath: String?
        var capturedMethod: String?
        MockURLProtocol.requestHandler = { request in
            capturedPath = request.url!.path
            capturedMethod = request.httpMethod
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.removeTagFromTask(taskId: taskId, tagId: tagId)

        XCTAssertEqual(capturedPath, "/prod/tasks/\(taskId.lowercaseUUIDString)/tags/\(tagId.lowercaseUUIDString)")
        XCTAssertEqual(capturedMethod, "DELETE")
    }

    func testRemoveTagFromTask_sendsLowercaseIdsInPath() async throws {
        let taskId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        let tagId = UUID(uuidString: "AB2C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        MockURLProtocol.requestHandler = { request in
            capturedPath = request.url!.path
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.removeTagFromTask(taskId: taskId, tagId: tagId)

        XCTAssertEqual(
            capturedPath,
            "/prod/tasks/1c4c7551-3f3c-4e2f-b02d-e6095be570c6/tags/ab2c7551-3f3c-4e2f-b02d-e6095be570c6"
        )
    }

    func testRemoveTagFromTask_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.removeTagFromTask(taskId: UUID(), tagId: UUID())
            XCTFail("Expected removeTagFromTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testRemoveTagFromTask_tokenThrows_shortCircuitsBeforeNetworkCall() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            try await sut.removeTagFromTask(taskId: UUID(), tagId: UUID())
            XCTFail("Expected removeTagFromTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }
}
