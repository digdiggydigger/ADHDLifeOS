//
//  AWSHomeClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class AWSHomeClientAdapterTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(authClient: AuthClientAdapting) -> AWSHomeClientAdapter {
        AWSHomeClientAdapter(
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
                    ["id": areaID.uuidString, "name": "Work", "colour": "💼", "sortOrder": 1]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let lifeAreas = try await sut.fetchLifeAreas()

        XCTAssertEqual(lifeAreas, [LifeArea(id: areaID, name: "Work", colour: "💼", sortOrder: 1)])
    }

    func testFetchLifeAreas_carriesArchivedThroughRatherThanFiltering() async throws {
        // The adapter no longer filters archived areas — it carries the flag through so the Capture
        // triage picker (fed from Home) can grey them. The Home grid applies its active-only filter
        // at the view layer, proven separately in HomeServiceTests.
        let liveID = UUID()
        let archivedID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "lifeAreas": [
                    ["id": liveID.uuidString, "name": "Work", "colour": "💼", "sortOrder": 1, "archived": false],
                    ["id": archivedID.uuidString, "name": "Old", "colour": "🗂️", "sortOrder": 2, "archived": true]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let lifeAreas = try await sut.fetchLifeAreas()

        XCTAssertEqual(lifeAreas.map(\.id), [liveID, archivedID], "both areas carried through")
        XCTAssertEqual(lifeAreas.first(where: { $0.id == archivedID })?.archived, true)
        XCTAssertEqual(lifeAreas.first(where: { $0.id == liveID })?.archived, false)
    }

    func testFetchLifeAreas_missingArchivedField_treatedAsNotArchived() async throws {
        // The nine seeded rows predate `archived`; a missing field must read as not-archived (shown).
        let id = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "lifeAreas": [["id": id.uuidString, "name": "Work", "colour": "💼", "sortOrder": 1]]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let lifeAreas = try await sut.fetchLifeAreas()

        XCTAssertEqual(lifeAreas.map(\.id), [id])
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
        } catch let HomeServiceError.fetchFailed(message) {
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("Expected HomeServiceError.fetchFailed, got \(error)")
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
        } catch is HomeServiceError {
            // expected
        } catch {
            XCTFail("Expected HomeServiceError.fetchFailed, got \(error)")
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
        } catch is HomeServiceError {
            // expected
        } catch {
            XCTFail("Expected HomeServiceError.fetchFailed, got \(error)")
        }
    }

    // MARK: - reorder

    func testReorder_sendsOnePatchToReorderRouteWithLowercaseCompleteOrder() async throws {
        let idOne = UUID()
        let idTwo = UUID()
        var capturedMethod: String?
        var capturedPath: String?
        var capturedBody: [String: [String]]?
        MockURLProtocol.requestHandler = { [self] request in
            capturedMethod = request.httpMethod
            capturedPath = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.path
            // URLProtocol strips httpBody into httpBodyStream — read whichever is populated.
            let bodyData = request.httpBody ?? request.httpBodyStream.map(Self.readStream)
            capturedBody = bodyData.flatMap { try? JSONDecoder().decode([String: [String]].self, from: $0) }
            return try jsonResponse(200, url: request.url!, ["lifeAreas": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        try await sut.reorder(order: [idOne, idTwo])

        XCTAssertEqual(capturedMethod, "PATCH")
        XCTAssertEqual(capturedPath, "/prod/life-areas/reorder", "one bulk route, never PATCH /life-areas/{id}")
        XCTAssertEqual(capturedBody, ["order": [idOne.uuidString.lowercased(), idTwo.uuidString.lowercased()]])
    }

    func testReorder_nonSuccess_surfacesBackendErrorMessage() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(400, url: request.url!, ["error": "order is missing id(s): abc"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            try await sut.reorder(order: [UUID()])
            XCTFail("Expected reorder to throw")
        } catch let HomeServiceError.fetchFailed(message) {
            XCTAssertEqual(message, "order is missing id(s): abc", "surfaces the backend's readable reason")
        }
    }

    private static func readStream(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    // MARK: - fetchOpenTasks

    func testFetchOpenTasks_success_decodesLambdaShapeIntoTaskSummary() async throws {
        let lifeAreaID = UUID()
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(200, url: request.url!, [
                "tasks": [
                    ["lifeAreaId": lifeAreaID.uuidString, "status": "open"]
                ]
            ])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        let tasks = try await sut.fetchOpenTasks()

        XCTAssertEqual(tasks, [TaskSummary(lifeAreaId: lifeAreaID, status: .open)])
    }

    func testFetchOpenTasks_appendsStatusOpenQueryItem() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { [self] request in
            capturedURL = request.url
            return try jsonResponse(200, url: request.url!, ["tasks": []])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        _ = try await sut.fetchOpenTasks()

        let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.path, "/prod/tasks")
        XCTAssertEqual(components?.queryItems, [URLQueryItem(name: "status", value: "open")])
    }

    func testFetchOpenTasks_nonSuccessStatus_surfacesFetchFailed() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            try jsonResponse(401, url: request.url!, ["error": "unauthorized"])
        }
        let sut = makeAdapter(authClient: FakeAuthClientAdapting())

        do {
            _ = try await sut.fetchOpenTasks()
            XCTFail("Expected fetchOpenTasks to throw")
        } catch is HomeServiceError {
            // expected
        } catch {
            XCTFail("Expected HomeServiceError.fetchFailed, got \(error)")
        }
    }

    func testFetchOpenTasks_tokenThrows_shortCircuitsBeforeNetworkCallAndSurfacesFetchFailed() async throws {
        let fakeAuth = FakeAuthClientAdapting()
        fakeAuth.validIDTokenResult = .failure(AuthServiceError.sessionExpired("signed out"))
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network when validIDToken() throws")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(authClient: fakeAuth)

        do {
            _ = try await sut.fetchOpenTasks()
            XCTFail("Expected fetchOpenTasks to throw")
        } catch is HomeServiceError {
            // expected
        } catch {
            XCTFail("Expected HomeServiceError.fetchFailed, got \(error)")
        }
    }
}

final class LifeAreaCardMetricsTests: XCTestCase {
    func testEmojiFontSize_isSeventyPercentOfCardWidth() {
        XCTAssertEqual(LifeAreaCardMetrics.emojiFontSize(forCardWidth: 200), 140)
        XCTAssertEqual(LifeAreaCardMetrics.emojiFontSize(forCardWidth: 150), 105)
    }

    func testEmojiFontSize_zeroWidth_returnsZero() {
        XCTAssertEqual(LifeAreaCardMetrics.emojiFontSize(forCardWidth: 0), 0)
    }
}
