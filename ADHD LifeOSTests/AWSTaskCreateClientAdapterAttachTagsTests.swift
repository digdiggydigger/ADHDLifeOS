//
//  AWSTaskCreateClientAdapterAttachTagsTests.swift
//  ADHD LifeOSTests
//
//  Split out from AWSTaskCreateClientAdapterTests.swift to keep both files under the
//  type_body_length lint threshold.
//

import XCTest
@testable import ADHD_LifeOS

final class AWSTaskCreateAttachTagsTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(authClient: AuthClientAdapting) -> AWSTaskCreateClientAdapter {
        AWSTaskCreateClientAdapter(
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

    func testAttachTags_multipleTagIds_issuesOneRequestPerTag() async throws {
        let taskId = UUID()
        let tagIds = [UUID(), UUID(), UUID()]
        var capturedPaths: [String] = []
        var capturedTagIds: [String] = []
        MockURLProtocol.requestHandler = { [self] request in
            capturedPaths.append(request.url!.path)
            capturedTagIds.append(decodedBody(of: request)["tagId"] as? String ?? "")
            return try jsonResponse(201, url: request.url!, ["taskId": taskId.uuidString, "tagId": ""])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.attachTags(taskId: taskId, tagIds: tagIds)

        XCTAssertEqual(capturedPaths.count, 3)
        XCTAssertTrue(capturedPaths.allSatisfy { $0 == "/prod/tasks/\(taskId.lowercaseUUIDString)/tags" })
        XCTAssertEqual(Set(capturedTagIds), Set(tagIds.map(\.lowercaseUUIDString)))
    }

    func testAttachTags_oneRequestFails_stillAttemptsRemainingBeforeThrowing() async throws {
        let taskId = UUID()
        let tagIds = [UUID(), UUID(), UUID()]
        var attemptedTagIds: [String] = []
        MockURLProtocol.requestHandler = { [self] request in
            let tagId = decodedBody(of: request)["tagId"] as? String ?? ""
            attemptedTagIds.append(tagId)
            if tagId == tagIds[1].lowercaseUUIDString {
                return try jsonResponse(500, url: request.url!, ["error": "boom"])
            }
            return try jsonResponse(201, url: request.url!, ["taskId": taskId.uuidString, "tagId": tagId])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.attachTags(taskId: taskId, tagIds: tagIds)
            XCTFail("Expected attachTags to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }

        XCTAssertEqual(attemptedTagIds.count, 3, "All tags should be attempted even after a failure")
    }

    func testAttachTags_emptyTagIds_sendsNoRequests() async throws {
        var requestCount = 0
        MockURLProtocol.requestHandler = { [self] request in
            requestCount += 1
            return try jsonResponse(201, url: request.url!, [:])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.attachTags(taskId: UUID(), tagIds: [])

        XCTAssertEqual(requestCount, 0)
    }

    func testAttachTags_sendsLowercaseIdsInPathAndBody() async throws {
        let taskId = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        let tagId = UUID(uuidString: "AB2C7551-3F3C-4E2F-B02D-E6095BE570C6")!
        var capturedPath: String?
        var capturedTagId: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            capturedTagId = decodedBody(of: request)["tagId"] as? String
            return try jsonResponse(201, url: request.url!, ["taskId": taskId.uuidString, "tagId": tagId.uuidString])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.attachTags(taskId: taskId, tagIds: [tagId])

        XCTAssertEqual(capturedPath, "/prod/tasks/1c4c7551-3f3c-4e2f-b02d-e6095be570c6/tags")
        XCTAssertEqual(capturedTagId, "ab2c7551-3f3c-4e2f-b02d-e6095be570c6")
    }

    func testAttachTags_tokenThrows_surfacesFetchFailed() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            try await sut.attachTags(taskId: UUID(), tagIds: [UUID()])
            XCTFail("Expected attachTags to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }
}
