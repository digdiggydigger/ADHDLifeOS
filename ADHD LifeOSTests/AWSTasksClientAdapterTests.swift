//
//  AWSTasksClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class AWSTasksClientAdapterTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(authClient: AuthClientAdapting) -> AWSTasksClientAdapter {
        AWSTasksClientAdapter(
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

    // MARK: - fetchLifeAreas

    func testFetchLifeAreas_success_decodesLambdaShapeIntoLifeArea() async throws {
        let areaID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "lifeAreas": [
                    ["id": areaID.uuidString, "name": "Family", "colour": "👪", "sortOrder": 3]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let lifeAreas = try await sut.fetchLifeAreas()

        XCTAssertEqual(lifeAreas, [LifeArea(id: areaID, name: "Family", colour: "👪", sortOrder: 3)])
    }

    func testFetchLifeAreas_sendsBearerToken() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .success("the-id-token")
        var capturedAuthorizationHeader: String?
        MockURLProtocol.requestHandler = { [self] request in
            capturedAuthorizationHeader = request.value(forHTTPHeaderField: "Authorization")
            return try jsonResponse(200, url: request.url!, ["lifeAreas": []])
        }
        let sut = makeAdapter(authClient: fakeAuth)

        _ = try await sut.fetchLifeAreas()

        XCTAssertEqual(capturedAuthorizationHeader, "Bearer the-id-token")
    }

    func testFetchLifeAreas_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchLifeAreas()
            XCTFail("Expected fetchLifeAreas to throw")
        } catch let TasksServiceError.fetchFailed(message) {
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchLifeAreas_malformedBody_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, Data("not json".utf8))
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchLifeAreas()
            XCTFail("Expected fetchLifeAreas to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchLifeAreas_tokenThrows_shortCircuitsBeforeNetworkCallAndSurfacesFetchFailed() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            _ = try await sut.fetchLifeAreas()
            XCTFail("Expected fetchLifeAreas to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - fetchAllTasks

    func testFetchAllTasks_success_decodesLambdaShapeIntoTaskItem() async throws {
        let taskID = UUID()
        let lifeAreaID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tasks": [
                    [
                        "id": taskID.uuidString,
                        "lifeAreaId": lifeAreaID.uuidString,
                        "title": "Speak to Jacob",
                        "status": "open",
                        "priority": "p2"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tasks = try await sut.fetchAllTasks()

        XCTAssertEqual(tasks, [
            TaskItem(
                id: taskID, lifeAreaId: lifeAreaID, title: "Speak to Jacob",
                status: .open, priority: .p2, dueDate: nil
            )
        ])
    }

    func testFetchAllTasks_noQueryParameters() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { [self] request in
            capturedURL = request.url
            return try jsonResponse(200, url: request.url!, ["tasks": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchAllTasks()

        let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.path, "/prod/tasks")
        XCTAssertNil(components?.queryItems)
    }

    func testFetchAllTasks_missingLifeAreaId_decodesAsNil() async throws {
        let taskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tasks": [
                    ["id": taskID.uuidString, "title": "Unassigned task", "status": "open", "priority": "p4"]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tasks = try await sut.fetchAllTasks()

        XCTAssertEqual(tasks.first?.lifeAreaId, nil)
    }

    func testFetchAllTasks_malformedDueDate_decodesAsNilNotThrowing() async throws {
        let taskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tasks": [
                    [
                        "id": taskID.uuidString,
                        "title": "Task with bad due date",
                        "status": "open",
                        "priority": "p3",
                        "dueDate": "not-a-real-date"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tasks = try await sut.fetchAllTasks()

        XCTAssertEqual(tasks.count, 1)
        XCTAssertNil(tasks.first?.dueDate)
    }

    func testFetchAllTasks_validDueDate_parsesWithNoTimezoneShift() async throws {
        let taskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tasks": [
                    [
                        "id": taskID.uuidString,
                        "title": "Task with real due date",
                        "status": "open",
                        "priority": "p1",
                        "dueDate": "2026-08-01T09:30:00Z"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tasks = try await sut.fetchAllTasks()

        var expectedComponents = DateComponents()
        expectedComponents.year = 2026
        expectedComponents.month = 8
        expectedComponents.day = 1
        expectedComponents.hour = 9
        expectedComponents.minute = 30
        expectedComponents.second = 0
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let expectedDate = utcCalendar.date(from: expectedComponents)!

        XCTAssertEqual(tasks.first?.dueDate, expectedDate)
    }

    func testFetchAllTasks_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(401, url: request.url!, ["error": "unauthorized"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchAllTasks()
            XCTFail("Expected fetchAllTasks to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchAllTasks_tokenThrows_shortCircuitsBeforeNetworkCallAndSurfacesFetchFailed() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            _ = try await sut.fetchAllTasks()
            XCTFail("Expected fetchAllTasks to throw")
        } catch is TasksServiceError {
            // expected
        } catch {
            XCTFail("Expected TasksServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchAllTasks_sendsNoHeaderBeyondAuthorization() async throws {
        var capturedHeaders: [String: String] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedHeaders = request.allHTTPHeaderFields ?? [:]
            return try jsonResponse(200, url: request.url!, ["tasks": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchAllTasks()

        XCTAssertEqual(Set(capturedHeaders.keys), ["Authorization"])
    }
}
