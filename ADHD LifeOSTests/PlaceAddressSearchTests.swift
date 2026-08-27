//
//  PlaceAddressSearchTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Typing an address instead of hunting for it on the map (E's 2026-08-27 critique: the map-only
/// picker is fine for "somewhere near here" and useless for "14 Bridge Street").
///
/// MapKit's completer is delegate-based and needs a network, so it sits behind `AddressCompleting`
/// / `AddressResolving` and everything below runs against a fake. What is actually being pinned
/// down is the state machine — when to search, when not to, and what the screen shows in each
/// case — because those are the behaviours a user notices and MapKit does not define for us.
@MainActor
final class PlaceAddressSearchTests: XCTestCase {

    private func suggestion(_ title: String, _ subtitle: String = "") -> AddressSuggestion {
        AddressSuggestion(id: UUID(), title: title, subtitle: subtitle)
    }

    private final class FakeAddressProvider: AddressCompleting, AddressResolving {
        var onResults: (([AddressSuggestion]) -> Void)?
        var onFailure: ((Error) -> Void)?
        private(set) var queries: [String] = []
        private(set) var cancelCount = 0
        var resolution: PlaceCoordinate?
        var resolutionError: Error?
        private(set) var resolvedSuggestions: [AddressSuggestion] = []

        func updateQuery(_ query: String) { queries.append(query) }
        func cancel() { cancelCount += 1 }

        func resolve(_ suggestion: AddressSuggestion) async throws -> PlaceCoordinate {
            resolvedSuggestions.append(suggestion)
            if let resolutionError { throw resolutionError }
            guard let resolution else { throw TestError.boom }
            return resolution
        }

        /// Drive the delegate callback the way MapKit would.
        func deliver(_ suggestions: [AddressSuggestion]) { onResults?(suggestions) }
        func fail(_ error: Error) { onFailure?(error) }
    }

    private enum TestError: LocalizedError {
        case boom
        var errorDescription: String? { "Couldn't find that address." }
    }

    // MARK: - When to search at all

    /// One or two characters match half the country — searching there burns requests and shows
    /// noise. The floor is deliberate, not incidental.
    func testQuery_shorterThanTheMinimum_doesNotSearch() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)

        service.updateQuery("14")

        XCTAssertTrue(provider.queries.isEmpty)
        XCTAssertEqual(service.state, .idle)
    }

    func testQuery_atOrAboveTheMinimum_searches() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)

        service.updateQuery("14 Bridge Street")

        XCTAssertEqual(provider.queries, ["14 Bridge Street"])
        XCTAssertEqual(service.state, .searching)
    }

    func testQuery_isTrimmedBeforeSearching() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)

        service.updateQuery("   Bridge Street  ")

        XCTAssertEqual(provider.queries, ["Bridge Street"])
    }

    /// Whitespace alone is not a query — and clearing the field must cancel the in-flight search
    /// rather than leaving stale results under an empty box.
    func testQuery_clearedToEmpty_cancelsAndResets() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)
        service.updateQuery("Bridge Street")
        provider.deliver([suggestion("Bridge Street")])

        service.updateQuery("")

        XCTAssertEqual(provider.cancelCount, 1)
        XCTAssertEqual(service.state, .idle)
        XCTAssertTrue(service.suggestions.isEmpty)
    }

    // MARK: - Results

    func testResults_arePublishedAndMarkTheStateLoaded() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)
        service.updateQuery("Bridge Street")

        provider.deliver([suggestion("14 Bridge Street", "Bath"), suggestion("14 Bridge Road", "Bristol")])

        XCTAssertEqual(service.state, .results)
        XCTAssertEqual(service.suggestions.count, 2)
        XCTAssertEqual(service.suggestions.first?.title, "14 Bridge Street")
    }

    /// An empty result set is its own state — "no matches" is information, and showing a blank
    /// area instead reads as a broken screen.
    func testResults_thatAreEmpty_reportNoMatchesRatherThanLoaded() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)
        service.updateQuery("asdfghjkl qwertyuiop")

        provider.deliver([])

        XCTAssertEqual(service.state, .noMatches)
    }

    func testFailure_surfacesAReadableMessage() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)
        service.updateQuery("Bridge Street")

        provider.fail(TestError.boom)

        XCTAssertEqual(service.state, .failed("Couldn't find that address."))
    }

    /// MapKit's completer fires repeatedly as it refines. A late delivery for a query E has
    /// already replaced must not repopulate the list under them.
    func testResults_arrivingAfterTheQueryChanged_areIgnored() {
        let provider = FakeAddressProvider()
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)
        service.updateQuery("Bridge Street")
        service.updateQuery("")

        provider.deliver([suggestion("14 Bridge Street")])

        XCTAssertTrue(service.suggestions.isEmpty, "a stale delivery must not repopulate the list")
        XCTAssertEqual(service.state, .idle)
    }

    // MARK: - Choosing one

    func testSelecting_resolvesToACoordinate() async {
        let provider = FakeAddressProvider()
        provider.resolution = PlaceCoordinate(latitude: 51.38, longitude: -2.36)
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)
        let chosen = suggestion("14 Bridge Street", "Bath")

        let coordinate = await service.resolve(chosen)

        XCTAssertEqual(coordinate, PlaceCoordinate(latitude: 51.38, longitude: -2.36))
        XCTAssertEqual(provider.resolvedSuggestions.map(\.id), [chosen.id])
    }

    func testSelecting_whenResolutionFails_returnsNilAndSaysSo() async {
        let provider = FakeAddressProvider()
        provider.resolutionError = TestError.boom
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)

        let coordinate = await service.resolve(suggestion("Nowhere"))

        XCTAssertNil(coordinate)
        XCTAssertEqual(service.state, .failed("Couldn't find that address."))
    }

    /// After a successful pick the list must collapse — leaving suggestions on screen next to a
    /// dropped pin invites tapping a second one by accident.
    func testSelecting_successfully_clearsTheSuggestions() async {
        let provider = FakeAddressProvider()
        provider.resolution = PlaceCoordinate(latitude: 51.38, longitude: -2.36)
        let service = PlaceAddressSearchService(completer: provider, resolver: provider)
        service.updateQuery("Bridge Street")
        provider.deliver([suggestion("14 Bridge Street")])

        _ = await service.resolve(suggestion("14 Bridge Street"))

        XCTAssertTrue(service.suggestions.isEmpty)
        XCTAssertEqual(service.state, .idle)
    }

    // MARK: - Display

    /// Title and subtitle are separate fields from MapKit; a suggestion with no subtitle must not
    /// render a dangling separator.
    func testDisplayLine_joinsTitleAndSubtitleOnlyWhenBothExist() {
        XCTAssertEqual(suggestion("14 Bridge Street", "Bath").displayLine, "14 Bridge Street, Bath")
        XCTAssertEqual(suggestion("14 Bridge Street", "").displayLine, "14 Bridge Street")
        XCTAssertEqual(suggestion("14 Bridge Street", "   ").displayLine, "14 Bridge Street")
    }
}
