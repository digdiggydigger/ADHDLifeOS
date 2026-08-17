//
//  AWSLifeAreaDetailClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class AWSLifeAreaDetailClientAdapterTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(authClient: AuthClientAdapting) -> AWSLifeAreaDetailClientAdapter {
        AWSLifeAreaDetailClientAdapter(
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

    // MARK: - fetchTasks

    func testFetchTasks_success_returnsOnlyMatchingLifeAreaExcludingOtherAndNilArea() async throws {
        let targetAreaID = UUID()
        let otherAreaID = UUID()
        let matchingTaskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tasks": [
                    [
                        "id": matchingTaskID.uuidString, "lifeAreaId": targetAreaID.uuidString,
                        "title": "Matching task", "status": "open", "priority": "p2"
                    ],
                    [
                        "id": UUID().uuidString, "lifeAreaId": otherAreaID.uuidString,
                        "title": "Other area task", "status": "open", "priority": "p2"
                    ],
                    [
                        "id": UUID().uuidString,
                        "title": "Unassigned task", "status": "open", "priority": "p2"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tasks = try await sut.fetchTasks(lifeAreaId: targetAreaID)

        XCTAssertEqual(tasks.map(\.id), [matchingTaskID])
    }

    func testFetchTasks_validDueDate_decodesTolerantly() async throws {
        let targetAreaID = UUID()
        let taskID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tasks": [
                    [
                        "id": taskID.uuidString, "lifeAreaId": targetAreaID.uuidString,
                        "title": "Has due date", "status": "open", "priority": "p1",
                        "dueDate": "2026-08-01T09:30:00Z"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tasks = try await sut.fetchTasks(lifeAreaId: targetAreaID)

        XCTAssertNotNil(tasks.first?.dueDate)
    }

    func testFetchTasks_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchTasks(lifeAreaId: UUID())
            XCTFail("Expected fetchTasks to throw")
        } catch let LifeAreaDetailServiceError.fetchFailed(message) {
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("Expected LifeAreaDetailServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - fetchLogs

    func testFetchLogs_success_returnsOnlyMatchingLifeAreaExcludingOtherAndNilArea() async throws {
        let targetAreaID = UUID()
        let otherAreaID = UUID()
        let matchingLogID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "logs": [
                    [
                        "id": matchingLogID.uuidString, "lifeAreaId": targetAreaID.uuidString,
                        "type": "journal", "body": "Matching log",
                        "entryDate": "2026-07-24T09:15:00", "createdAt": "2026-07-24T09:15:00"
                    ],
                    [
                        "id": UUID().uuidString, "lifeAreaId": otherAreaID.uuidString,
                        "type": "log", "body": "Other area log",
                        "entryDate": "2026-07-24T09:15:00", "createdAt": "2026-07-24T09:15:00"
                    ],
                    [
                        "id": UUID().uuidString,
                        "type": "log", "body": "Unassigned log",
                        "entryDate": "2026-07-24T09:15:00", "createdAt": "2026-07-24T09:15:00"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let logs = try await sut.fetchLogs(lifeAreaId: targetAreaID)

        XCTAssertEqual(logs.map(\.id), [matchingLogID])
    }

    func testFetchLogs_bareTimezoneEntryDate_decodesTolerantly() async throws {
        let targetAreaID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "logs": [
                    [
                        "id": UUID().uuidString, "lifeAreaId": targetAreaID.uuidString,
                        "type": "log", "body": "Bare TZ",
                        "entryDate": "2026-07-24T09:15:00", "createdAt": "2026-07-24T09:15:00"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let logs = try await sut.fetchLogs(lifeAreaId: targetAreaID)

        var expectedComponents = DateComponents()
        expectedComponents.year = 2026
        expectedComponents.month = 7
        expectedComponents.day = 24
        expectedComponents.hour = 9
        expectedComponents.minute = 15
        expectedComponents.second = 0
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let expectedDate = utcCalendar.date(from: expectedComponents)!

        XCTAssertEqual(logs.first?.entryDate, expectedDate)
        XCTAssertEqual(logs.first?.createdAt, expectedDate)
    }

    func testFetchLogs_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(401, url: request.url!, ["error": "unauthorized"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchLogs(lifeAreaId: UUID())
            XCTFail("Expected fetchLogs to throw")
        } catch is LifeAreaDetailServiceError {
            // expected
        } catch {
            XCTFail("Expected LifeAreaDetailServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchLogs_tokenThrows_shortCircuitsBeforeNetworkCallAndSurfacesFetchFailed() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            _ = try await sut.fetchLogs(lifeAreaId: UUID())
            XCTFail("Expected fetchLogs to throw")
        } catch is LifeAreaDetailServiceError {
            // expected
        } catch {
            XCTFail("Expected LifeAreaDetailServiceError.fetchFailed, got \(error)")
        }
    }
}
