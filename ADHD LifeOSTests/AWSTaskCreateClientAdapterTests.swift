//
//  AWSTaskCreateClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class AWSTaskCreateClientAdapterTests: XCTestCase {

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

    // MARK: - fetchTags

    func testFetchTags_success_decodesLambdaShapeIntoTag() async throws {
        let tagID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tags": [["id": tagID.uuidString, "name": "urgent"]]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tags = try await sut.fetchTags()

        XCTAssertEqual(tags, [Tag(id: tagID, name: "urgent")])
    }

    func testFetchTags_emptyList_decodesAsEmpty() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, ["tags": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tags = try await sut.fetchTags()

        XCTAssertEqual(tags, [])
    }

    func testFetchTags_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchTags()
            XCTFail("Expected fetchTags to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchTags_tokenThrows_shortCircuitsBeforeNetworkCall() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            _ = try await sut.fetchTags()
            XCTFail("Expected fetchTags to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - createTag

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

    func testCreateTag_dedupedExistingTag_decodesIdenticallyToNewTag() async throws {
        let tagID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, ["id": tagID.uuidString, "name": "focus"])
        }
        let tag = try await makeAdapter(authClient: FakeAuthClientAdapting()).createTag(name: "focus")
        XCTAssertEqual(tag, Tag(id: tagID, name: "focus"))
    }

    func testCreateTag_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "name is required"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.createTag(name: "")
            XCTFail("Expected createTag to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - createTask

    func testCreateTask_success_sendsCorrectBodyAndDecodesResponse() async throws {
        let taskID = UUID()
        let lifeAreaID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": taskID.uuidString,
                "lifeAreaId": lifeAreaID.uuidString,
                "title": "Speak to Jacob",
                "status": "open",
                "priority": "p2",
                "dueDate": "2026-08-01T09:30:00.000Z"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedCreateTaskInput(
            title: "Speak to Jacob",
            notes: "call about the roof",
            lifeAreaId: lifeAreaID,
            dueDate: Date(timeIntervalSince1970: 1_785_000_000),
            priority: .p2
        )

        let task = try await sut.createTask(input)

        XCTAssertEqual(task.id, taskID)
        XCTAssertEqual(task.lifeAreaId, lifeAreaID)
        XCTAssertEqual(task.title, "Speak to Jacob")
        XCTAssertEqual(task.status, .open)
        XCTAssertEqual(task.priority, .p2)
        XCTAssertNotNil(task.dueDate)

        XCTAssertEqual(capturedBody["title"] as? String, "Speak to Jacob")
        XCTAssertEqual(capturedBody["notes"] as? String, "call about the roof")
        XCTAssertEqual(capturedBody["lifeAreaId"] as? String, lifeAreaID.uuidString)
        XCTAssertEqual(capturedBody["priority"] as? String, "p2")

        let sentDueDate = try XCTUnwrap(capturedBody["dueDate"] as? String)
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNotNil(
            fractionalFormatter.date(from: sentDueDate),
            "dueDate should be encoded as fractional-seconds ISO8601, got \(sentDueDate)"
        )
    }

    func testCreateTask_nilDueDate_omitsFieldFromBody() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": UUID().uuidString,
                "title": "No due date task",
                "status": "open",
                "priority": "p4"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedCreateTaskInput(
            title: "No due date task", notes: nil, lifeAreaId: nil, dueDate: nil, priority: .p4
        )

        _ = try await sut.createTask(input)

        XCTAssertNil(capturedBody["dueDate"])
    }

    func testCreateTask_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "title is required"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedCreateTaskInput(title: "x", notes: nil, lifeAreaId: nil, dueDate: nil, priority: .p4)

        do {
            _ = try await sut.createTask(input)
            XCTFail("Expected createTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testCreateTask_tokenThrows_shortCircuitsBeforeNetworkCall() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)
        let input = NormalizedCreateTaskInput(title: "x", notes: nil, lifeAreaId: nil, dueDate: nil, priority: .p4)

        do {
            _ = try await sut.createTask(input)
            XCTFail("Expected createTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

}
