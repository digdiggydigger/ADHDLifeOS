//
//  AWSJournalClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class AWSJournalClientAdapterTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(authClient: AuthClientAdapting) -> AWSJournalClientAdapter {
        AWSJournalClientAdapter(
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

    func testFetchLifeAreas_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchLifeAreas()
            XCTFail("Expected fetchLifeAreas to throw")
        } catch let JournalServiceError.fetchFailed(message) {
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("Expected JournalServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - fetchLogs

    func testFetchLogs_success_decodesCamelCaseShapeIntoLog() async throws {
        let logID = UUID()
        let lifeAreaID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "logs": [
                    [
                        "id": logID.uuidString,
                        "lifeAreaId": lifeAreaID.uuidString,
                        "type": "journal",
                        "body": "Had a good session today.",
                        "entryDate": "2026-07-24T09:15:00",
                        "createdAt": "2026-07-24T09:15:00"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let logs = try await sut.fetchLogs()

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.id, logID)
        XCTAssertEqual(logs.first?.lifeAreaId, lifeAreaID)
        XCTAssertEqual(logs.first?.type, .journal)
        XCTAssertEqual(logs.first?.body, "Had a good session today.")

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

    func testFetchLogs_missingLifeAreaId_decodesAsNil() async throws {
        let logID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "logs": [
                    [
                        "id": logID.uuidString,
                        "type": "log",
                        "body": "Unassigned log entry.",
                        "entryDate": "2026-07-24T09:15:00",
                        "createdAt": "2026-07-24T09:15:00"
                    ]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let logs = try await sut.fetchLogs()

        XCTAssertEqual(logs.first?.lifeAreaId, nil)
    }

    func testFetchLogs_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(401, url: request.url!, ["error": "unauthorized"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchLogs()
            XCTFail("Expected fetchLogs to throw")
        } catch is JournalServiceError {
            // expected
        } catch {
            XCTFail("Expected JournalServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - createLog

    func testCreateLog_lifeAreaIdPresent_sendsAllThreeKeys() async throws {
        let lifeAreaID = UUID()
        let logID = UUID()
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": logID.uuidString,
                "lifeAreaId": lifeAreaID.uuidString,
                "type": "log",
                "body": "Finished the report.",
                "entryDate": "2026-07-24T09:15:00",
                "createdAt": "2026-07-24T09:15:00"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedCreateLogInput(body: "Finished the report.", type: .log, lifeAreaId: lifeAreaID)

        let created = try await sut.createLog(input)

        XCTAssertEqual(capturedBody["body"] as? String, "Finished the report.")
        XCTAssertEqual(capturedBody["type"] as? String, "log")
        XCTAssertEqual(capturedBody["lifeAreaId"] as? String, lifeAreaID.uuidString)
        XCTAssertNil(capturedBody["entryDate"])
        XCTAssertNil(capturedBody["userId"])
        XCTAssertEqual(created.id, logID)
        XCTAssertEqual(created.lifeAreaId, lifeAreaID)
    }

    func testCreateLog_lifeAreaIdNil_keyOmittedNotNull() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.requestHandler = { [self] request in
            capturedBody = decodedBody(of: request)
            return try jsonResponse(201, url: request.url!, [
                "id": UUID().uuidString,
                "type": "journal",
                "body": "No area for this one.",
                "entryDate": "2026-07-24T09:15:00",
                "createdAt": "2026-07-24T09:15:00"
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedCreateLogInput(body: "No area for this one.", type: .journal, lifeAreaId: nil)

        _ = try await sut.createLog(input)

        XCTAssertFalse(capturedBody.keys.contains("lifeAreaId"))
    }

    func testCreateLog_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(500, url: request.url!, ["error": "boom"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())
        let input = NormalizedCreateLogInput(body: "Whatever", type: .log, lifeAreaId: nil)

        do {
            _ = try await sut.createLog(input)
            XCTFail("Expected createLog to throw")
        } catch is JournalServiceError {
            // expected
        } catch {
            XCTFail("Expected JournalServiceError.fetchFailed, got \(error)")
        }
    }

    func testCreateLog_tokenThrows_shortCircuitsBeforeNetworkCallAndSurfacesFetchFailed() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)
        let input = NormalizedCreateLogInput(body: "Whatever", type: .log, lifeAreaId: nil)

        do {
            _ = try await sut.createLog(input)
            XCTFail("Expected createLog to throw")
        } catch is JournalServiceError {
            // expected
        } catch {
            XCTFail("Expected JournalServiceError.fetchFailed, got \(error)")
        }
    }
}
