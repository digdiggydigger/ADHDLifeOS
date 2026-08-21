//
//  FirebaseDailySummaryGeneratorTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The response contract with the `dailySummary` Cloud Function, and the request encoding it
/// depends on. Both are testable without a network or a signed-in user, and both are where a
/// mismatch would be silent rather than loud.
@MainActor
final class FirebaseDailySummaryGeneratorTests: XCTestCase {
    private let url = URL(string: "https://example.invalid/dailySummary")!

    // MARK: - Request encoding

    /// The function reads `date` as a string. Swift's default strategy would encode it as seconds
    /// since the 2001 reference date — a bare number the function cannot interpret as a day.
    func testDateEncodesAsISO8601StringNotAReferenceInterval() throws {
        let request = DailySummaryRequest(
            date: Date(timeIntervalSince1970: 1_787_000_000), tone: .gentle,
            tasks: [], focusSessions: [], journalEntries: [], capturesCount: 0,
            lifeAreaNames: [:], calendar: Calendar(identifier: .gregorian)
        )
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: FirebaseDailySummaryGenerator.encoder.encode(request)
            ) as? [String: Any]
        )
        let date = try XCTUnwrap(json["date"] as? String)
        XCTAssertTrue(date.contains("T"), "expected ISO-8601, got \(date)")
        XCTAssertTrue(date.hasSuffix("Z"), "expected UTC designator, got \(date)")
    }

    // MARK: - Response decoding

    func testASuccessfulEnvelopeDecodesToContent() throws {
        let content = try FirebaseDailySummaryGenerator.decode(
            data: Data("""
            {"success":true,"source":"claude-opus-5","summary":{
              "headline":"One finished today.",
              "dopamineWins":["Shipped the fix."],
              "journalReflections":"You noted feeling scattered.",
              "focusStaminaInsight":"26 minutes of focus.",
              "gentleTomorrowKickstart":["Start small."]
            }}
            """.utf8),
            response: http(200)
        )
        XCTAssertEqual(content.headline, "One finished today.")
        XCTAssertEqual(content.dopamineWins, ["Shipped the fix."])
        XCTAssertEqual(content.gentleTomorrowKickstart, ["Start small."])
    }

    /// 401 is its own case because the fix is specific — re-authenticate — and a generic
    /// "something went wrong" would send the user looking in the wrong place.
    func testUnauthorizedIsDistinctFromOtherServerErrors() {
        XCTAssertThrowsError(
            try FirebaseDailySummaryGenerator.decode(
                data: Data(#"{"error":"unauthorized"}"#.utf8), response: http(401)
            )
        ) { error in
            XCTAssertEqual(error as? DailySummaryEndpointError, .unauthorized)
        }
    }

    /// The server writes its errors for the user; passing them through beats inventing a generic
    /// one on the client.
    func testServerErrorMessageIsSurfacedVerbatim() {
        XCTAssertThrowsError(
            try FirebaseDailySummaryGenerator.decode(
                data: Data(#"{"error":"the model declined to write this summary"}"#.utf8),
                response: http(502)
            )
        ) { error in
            XCTAssertEqual(
                error as? DailySummaryEndpointError,
                .server("the model declined to write this summary")
            )
        }
    }

    func testAnErrorStatusWithNoBodyStillProducesAReadableMessage() {
        XCTAssertThrowsError(
            try FirebaseDailySummaryGenerator.decode(data: Data(), response: http(500))
        ) { error in
            let described = (error as? DailySummaryEndpointError)?.errorDescription ?? ""
            XCTAssertTrue(described.contains("500"), "unhelpful message: \(described)")
        }
    }

    /// A 200 whose body is missing or malformed must not be rendered as a half-empty summary.
    func testAMalformedSuccessBodyIsRejected() {
        for body in ["", "{}", #"{"success":true}"#, #"{"success":false,"summary":null}"#, "not json"] {
            XCTAssertThrowsError(
                try FirebaseDailySummaryGenerator.decode(data: Data(body.utf8), response: http(200)),
                "accepted \(body)"
            ) { error in
                XCTAssertEqual(error as? DailySummaryEndpointError, .badResponse)
            }
        }
    }

    // MARK: - Configuration

    /// Until the deployed URL is filled in, generating must fail with a clear message rather than
    /// crash or silently do nothing.
    func testAnUnconfiguredEndpointFailsWithAClearMessage() async {
        let generator = FirebaseDailySummaryGenerator(endpoint: nil)
        let request = DailySummaryRequest(
            date: .now, tone: .energizing, tasks: [], focusSessions: [], journalEntries: [],
            capturesCount: 0, lifeAreaNames: [:], calendar: Calendar(identifier: .gregorian)
        )
        do {
            _ = try await generator.generate(request)
            XCTFail("expected a configuration failure")
        } catch {
            XCTAssertEqual(error as? DailySummaryEndpointError, .notConfigured)
        }
    }

    func testEveryErrorCaseHasAUserReadableDescription() {
        let cases: [DailySummaryEndpointError] = [
            .notSignedIn, .notConfigured, .unauthorized, .server("x"), .badResponse
        ]
        for error in cases {
            XCTAssertFalse(
                (error.errorDescription ?? "").isEmpty, "\(error) has no description"
            )
        }
    }

    // MARK: - Helpers

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
