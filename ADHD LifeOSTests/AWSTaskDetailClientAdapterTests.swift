//
//  AWSTaskDetailClientAdapterTests.swift
//  ADHD LifeOSTests
//
//  Covers fetchTask/updateTask/updateStatus. Tag-route coverage lives in
//  AWSTaskDetailTagsTests.swift, split out to keep both files under SwiftLint's
//  type_body_length ceiling (same precedent as Stage C.4's AttachTagsTests split).
//

import XCTest
@testable import ADHD_LifeOS

final class AWSTaskDetailClientAdapterTests: XCTestCase {

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

    // MARK: - fetchTask

    func testFetchTask_success_decodesBareCreatedAtAndFractionalDueDate() async throws {
        let taskID = UUID()
        let lifeAreaID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString,
                "lifeAreaId": lifeAreaID.uuidString,
                "title": "Speak to Jacob",
                "notes": "call about the roof",
                "status": "open",
                "priority": "p2",
                "dueDate": "2026-08-01T09:30:00.000Z",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let task = try await sut.fetchTask(id: taskID)

        XCTAssertEqual(task.id, taskID)
        XCTAssertEqual(task.lifeAreaId, lifeAreaID)
        XCTAssertEqual(task.title, "Speak to Jacob")
        XCTAssertEqual(task.notes, "call about the roof")
        XCTAssertEqual(task.status, .open)
        XCTAssertEqual(task.priority, .p2)
        XCTAssertNotNil(task.dueDate)

        var expectedComponents = DateComponents()
        expectedComponents.year = 2026; expectedComponents.month = 7; expectedComponents.day = 23
        expectedComponents.hour = 4; expectedComponents.minute = 47; expectedComponents.second = 46
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(task.createdAt, utcCalendar.date(from: expectedComponents))
    }

    func testFetchTask_missingDueDate_decodesNil() async throws {
        let taskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString, "title": "No due date", "status": "open", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let task = try await sut.fetchTask(id: taskID)

        XCTAssertNil(task.dueDate)
        XCTAssertNil(task.lifeAreaId)
        XCTAssertNil(task.notes)
    }

    func testFetchTask_unparseableCreatedAt_throws() async throws {
        let taskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString, "title": "Bad createdAt", "status": "open", "priority": "p4",
                "createdAt": "not-a-real-date"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchTask(id: taskID)
            XCTFail("Expected fetchTask to throw when createdAt is unparseable")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchTask_404_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(404, url: request.url!, ["error": "Task not found"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchTask(id: UUID())
            XCTFail("Expected fetchTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchTask_tokenThrows_shortCircuitsBeforeNetworkCall() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            _ = try await sut.fetchTask(id: UUID())
            XCTFail("Expected fetchTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchTask_sendsNoHeaderBeyondAuthorization() async throws {
        let taskID = UUID()
        var capturedHeaders: [String: String] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedHeaders = request.allHTTPHeaderFields ?? [:]
            return try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString, "title": "x", "status": "open", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchTask(id: taskID)

        XCTAssertEqual(Set(capturedHeaders.keys), ["Authorization"])
    }

    // MARK: - updateTask

    func testUpdateTask_partialPayload_onlyChangedKeysPresent() async throws {
        let taskID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString, "title": "New title", "status": "open", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let payload = TaskUpdatePayload(title: "New title")

        _ = try await sut.updateTask(id: taskID, payload: payload)

        XCTAssertEqual(capturedBody["title"] as? String, "New title")
        XCTAssertEqual(capturedBody.keys.count, 1)
    }

    func testUpdateTask_explicitNullField_sendsJSONNull() async throws {
        let taskID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString, "title": "x", "status": "open", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let payload = TaskUpdatePayload(notes: .some(nil))

        _ = try await sut.updateTask(id: taskID, payload: payload)

        XCTAssertTrue(capturedBody.keys.contains("notes"))
        XCTAssertTrue(capturedBody["notes"] is NSNull)
    }

    func testUpdateTask_dueDate_sentAsFractionalISO8601() async throws {
        let taskID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString, "title": "x", "status": "open", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let payload = TaskUpdatePayload(dueDate: .some(Date(timeIntervalSince1970: 1_785_000_000)))

        _ = try await sut.updateTask(id: taskID, payload: payload)

        let sentDueDate = try XCTUnwrap(capturedBody["dueDate"] as? String)
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNotNil(fractionalFormatter.date(from: sentDueDate))
    }

    func testUpdateTask_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "title cannot be empty"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.updateTask(id: UUID(), payload: TaskUpdatePayload(title: ""))
            XCTFail("Expected updateTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testUpdateTask_tokenThrows_shortCircuitsBeforeNetworkCall() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            _ = try await sut.updateTask(id: UUID(), payload: TaskUpdatePayload(title: "x"))
            XCTFail("Expected updateTask to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - updateStatus

    func testUpdateStatus_sendsExactBody() async throws {
        let taskID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(200, url: request.url!, [
                "id": taskID.uuidString, "title": "x", "status": "done", "priority": "p4",
                "createdAt": "2026-07-23T04:47:46"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let task = try await sut.updateStatus(id: taskID, status: .done)

        XCTAssertEqual(capturedBody.keys.count, 1)
        XCTAssertEqual(capturedBody["status"] as? String, "done")
        XCTAssertEqual(task.status, .done)
    }

    func testUpdateStatus_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(404, url: request.url!, ["error": "Task not found"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.updateStatus(id: UUID(), status: .done)
            XCTFail("Expected updateStatus to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }
}
