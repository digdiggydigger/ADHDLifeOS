//
//  AWSTaskDetailLowercaseUUIDTests.swift
//  ADHD LifeOSTests
//
//  Regression coverage for the uppercase-UUID-vs-case-sensitive-DynamoDB-key FIX. Split out from
//  AWSTaskDetailClientAdapterTests.swift to keep that file under SwiftLint's type_body_length
//  ceiling (same precedent as Stage C.4's AttachTagsTests split). Each test constructs its UUID
//  from an uppercase string literal (matching how a real decoded id could look in memory) and
//  asserts the captured request's URL path is the literal lowercase form, not merely
//  case-insensitively equal.
//

import XCTest
@testable import ADHD_LifeOS

final class AWSTaskDetailLowercaseUUIDTests: XCTestCase {

    private let uppercaseID = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!
    private let lowercasePathSegment = "1c4c7551-3f3c-4e2f-b02d-e6095be570c6"

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

    func testFetchTask_sendsLowercaseIdInURLPath() async throws {
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            return try jsonResponse(200, url: request.url!, [
                "id": uppercaseID.uuidString, "title": "x", "status": "open", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchTask(id: uppercaseID)

        XCTAssertEqual(capturedPath, "/prod/tasks/\(lowercasePathSegment)")
    }

    func testUpdateTask_sendsLowercaseIdInURLPath() async throws {
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            return try jsonResponse(200, url: request.url!, [
                "id": uppercaseID.uuidString, "title": "x", "status": "open", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.updateTask(id: uppercaseID, payload: TaskUpdatePayload(title: "x"))

        XCTAssertEqual(capturedPath, "/prod/tasks/\(lowercasePathSegment)")
    }

    func testUpdateStatus_sendsLowercaseIdInURLPath() async throws {
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedPath = request.url!.path
            return try jsonResponse(200, url: request.url!, [
                "id": uppercaseID.uuidString, "title": "x", "status": "done", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.updateStatus(id: uppercaseID, status: .done)

        XCTAssertEqual(capturedPath, "/prod/tasks/\(lowercasePathSegment)")
    }
}
