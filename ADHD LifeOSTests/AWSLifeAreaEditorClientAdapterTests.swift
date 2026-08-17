//
//  AWSLifeAreaEditorClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class AWSLifeAreaEditorClientAdapterTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAdapter(
        authClient: AuthClientAdapting = FakeAuthClientAdapting()
    ) -> AWSLifeAreaEditorClientAdapter {
        AWSLifeAreaEditorClientAdapter(
            authClient: authClient,
            session: MockURLProtocol.makeSession(),
            baseURL: URL(string: "https://life-os-api-gw.example.com/prod")!
        )
    }

    private func response(_ status: Int, url: URL, _ body: [String: Any]) throws -> (HTTPURLResponse, Data) {
        let data = try JSONSerialization.data(withJSONObject: body)
        let http = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (http, data)
    }

    // MARK: fetch — archived flag decodes

    func test_fetch_decodesArchivedFlag() async throws {
        let id = UUID()
        MockURLProtocol.requestHandler = { [self] req in
            try response(200, url: req.url!, ["lifeAreas": [
                ["id": id.uuidString, "name": "Work", "colour": "💼", "sortOrder": 1, "archived": true]
            ]])
        }

        let areas = try await makeAdapter().fetchLifeAreas()

        XCTAssertEqual(areas, [EditableLifeArea(id: id, name: "Work", colour: "💼", sortOrder: 1, archived: true)])
    }

    // MARK: update — 200 vs 409, and the lowercase-UUID path (trap a)

    func test_update_200_returnsUpdated_andPatchesLowercasedId() async throws {
        let id = UUID()
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] req in
            capturedPath = req.url!.path
            return try response(200, url: req.url!, [:])
        }

        let outcome = try await makeAdapter().update(id: id, name: "Career", colour: nil)

        XCTAssertEqual(outcome, .updated)
        XCTAssertEqual(
            capturedPath, "/prod/life-areas/\(id.uuidString.lowercased())",
            "the PATCH path must use the LOWERCASE uuid or DynamoDB 404s (trap a)"
        )
        XCTAssertFalse(capturedPath!.contains(id.uuidString), "must NOT contain the uppercase uuidString")
    }

    func test_update_409_decodesTypedConflictWithArchivedTrue() async throws {
        let conflictID = UUID()
        MockURLProtocol.requestHandler = { [self] req in
            try response(409, url: req.url!, [
                "error": "name already in use",
                "conflict": ["id": conflictID.uuidString, "name": "Health", "archived": true]
            ])
        }

        let outcome = try await makeAdapter().update(id: UUID(), name: "Health", colour: nil)

        XCTAssertEqual(outcome, .nameConflict(LifeAreaNameConflict(id: conflictID, name: "Health", archived: true)))
    }

    func test_update_400_throwsReadableError() async throws {
        MockURLProtocol.requestHandler = { [self] req in
            try response(400, url: req.url!, ["error": "Unknown field(s): sortOrder"])
        }

        do {
            _ = try await makeAdapter().update(id: UUID(), name: nil, colour: "🏠")
            XCTFail("expected a throw on 400")
        } catch let LifeAreaEditorServiceError.failed(message) {
            XCTAssertEqual(message, "Unknown field(s): sortOrder", "the backend error body must be surfaced verbatim")
        }
    }

    // MARK: create — 201 vs 409 (both archived branches)

    func test_create_201_returnsCreatedArea() async throws {
        let newID = UUID()
        MockURLProtocol.requestHandler = { [self] req in
            try response(201, url: req.url!, [
                "id": newID.uuidString, "name": "Garden", "colour": "🌱", "sortOrder": 10, "archived": false
            ])
        }

        let outcome = try await makeAdapter().create(name: "Garden", colour: "🌱")

        XCTAssertEqual(
            outcome,
            .created(EditableLifeArea(id: newID, name: "Garden", colour: "🌱", sortOrder: 10, archived: false))
        )
    }

    func test_create_409_archivedFalse_decodesLiveConflict() async throws {
        let conflictID = UUID()
        MockURLProtocol.requestHandler = { [self] req in
            try response(409, url: req.url!, [
                "error": "name already in use",
                "conflict": ["id": conflictID.uuidString, "name": "Work", "archived": false]
            ])
        }

        let outcome = try await makeAdapter().create(name: "Work", colour: "💼")

        XCTAssertEqual(outcome, .nameConflict(LifeAreaNameConflict(id: conflictID, name: "Work", archived: false)))
    }

    func test_create_409_archivedTrue_decodesArchivedConflict() async throws {
        let conflictID = UUID()
        MockURLProtocol.requestHandler = { [self] req in
            try response(409, url: req.url!, [
                "error": "name already in use",
                "conflict": ["id": conflictID.uuidString, "name": "OldProject", "archived": true]
            ])
        }

        let outcome = try await makeAdapter().create(name: "OldProject", colour: "🗂️")

        XCTAssertEqual(outcome, .nameConflict(LifeAreaNameConflict(id: conflictID, name: "OldProject", archived: true)))
    }

    // MARK: setArchived — body + lowercase path

    func test_setArchived_sendsArchivedBody_toLowercasedPath() async throws {
        let id = UUID()
        var capturedBody: [String: Any]?
        var capturedPath: String?
        MockURLProtocol.requestHandler = { [self] req in
            capturedPath = req.url!.path
            if let data = MockURLProtocol.body(of: req) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return try response(200, url: req.url!, [:])
        }

        try await makeAdapter().setArchived(id: id, archived: true)

        XCTAssertEqual(capturedPath, "/prod/life-areas/\(id.uuidString.lowercased())")
        XCTAssertEqual(capturedBody?["archived"] as? Bool, true)
    }

    func test_setArchived_500_throwsReadableError() async {
        MockURLProtocol.requestHandler = { [self] req in
            try response(500, url: req.url!, ["error": "boom"])
        }

        do {
            try await makeAdapter().setArchived(id: UUID(), archived: false)
            XCTFail("expected a throw on 500")
        } catch let LifeAreaEditorServiceError.failed(message) {
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("expected LifeAreaEditorServiceError.failed, got \(error)")
        }
    }
}
