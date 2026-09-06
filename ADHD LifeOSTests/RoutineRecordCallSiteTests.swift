//
//  RoutineRecordCallSiteTests.swift
//  ADHD LifeOSTests
//
//  REACHABILITY for the routine record (F-RoutineRecord-1) — this repo's most repeated
//  defect, six instances: a seam written, tested and called by nothing. The recorder's own
//  tests prove it writes the right fields; these read the SOURCE to prove the six sites
//  actually call it, that the dismiss branch sits where a swipe can reach it and never where
//  a tap would start the routine, and that the rules admit the collection at all.
//

import XCTest

final class RoutineRecordCallSiteTests: XCTestCase {

    // MARK: - Site 3: the swipe

    func testTheRoutineCategoryAsksIOSToReportDismissals() throws {
        let app = try Self.code("ADHD_LifeOSApp.swift")

        XCTAssertTrue(
            app.contains(".customDismissAction"),
            "Without the custom-dismiss option iOS never reports a swipe, and every cleared"
                + " banner reads as ignored. The option goes on the ONE category registration —"
                + " setNotificationCategories replaces the whole set."
        )
    }

    func testTheDismissBranchRunsBeforeEveryTapRouter() throws {
        let app = try Self.code("ADHD_LifeOSApp.swift")
        let dismiss = try XCTUnwrap(
            app.range(of: "RoutineDismissRecorder.shared.handle("),
            "the delegate must hand a dismiss response to the dismiss recorder"
        )
        let placeActionRouter = try XCTUnwrap(app.range(of: "PlaceActionNotificationRouter.shared.handle("))
        let routineRouter = try XCTUnwrap(app.range(of: "PlaceRoutineNotificationRouter.shared.handle("))

        XCTAssertLessThan(
            dismiss.lowerBound, placeActionRouter.lowerBound,
            "a dismiss must be claimed BEFORE the tap routers see it — the routine router would"
                + " otherwise START the routine the user just cleared"
        )
        XCTAssertLessThan(dismiss.lowerBound, routineRouter.lowerBound)
    }

    // MARK: - Site 4 and 5: the screen

    func testEveryStepChangeOnTheScreenIsRecorded() throws {
        let screen = try Self.code("Places/PlaceRoutineScreen.swift")

        XCTAssertTrue(
            Self.collapsed(screen).contains(
                "_ = store.updateMatching(updated) record { try await recorder.progressed(updated"
            ),
            "the step write-through and the record must be the SAME moment: a step the local"
                + " store knows and Firestore does not is a run whose Journal row lies"
        )
    }

    func testLeavingAFinishedScreenRecordsCompletion() throws {
        let screen = try Self.code("Places/PlaceRoutineScreen.swift")

        XCTAssertTrue(
            Self.collapsed(screen).contains(
                "store.end(runId: run.id) record { try await recorder.ended(runId: run.id, reason: .completed"
            ),
            "ending the local run and recording `completed` must sit together, inside the"
                + " fully-resolved branch — leaving an unfinished screen is not completion"
        )
    }

    func testTheDoorHandsTheScreenARealRecorder() throws {
        let doors = try Self.code("RootView+Doors.swift")

        XCTAssertTrue(
            doors.contains("recorder: FirebaseRoutineRunRecorder()"),
            "the screen's recorder is injected, never defaulted (a default argument would"
                + " touch FirebaseManager.shared in previews) — so the door must pass the real one"
        )
    }

    // MARK: - Site 1 and 5: the crossing

    func testTheOfferIsRecordedInsideThePostPath() throws {
        let handler = try Self.code("Places/PlaceTriggerEventHandler.swift")

        XCTAssertTrue(
            Self.collapsed(handler).contains(
                "categoryIdentifier: PlaceRoutineNotificationContent.categoryIdentifier )"
                    + " await recordOffer(routineRun"
            ),
            "the offer is recorded right after the routine banner POSTS — a suppressed crossing"
                + " (cooldown, kill-switch, threshold) offered nothing and must record nothing"
        )
    }

    func testTheDepartureEndRecordsLeftPlace() throws {
        let handler = try Self.code("Places/PlaceTriggerEventHandler.swift")

        XCTAssertTrue(
            Self.collapsed(handler).contains("runStore.endLiveRun() await recordEnd(liveRun.id, reason: .leftPlace"),
            "the one run write a crossing still makes — ending — must also record WHY"
        )
    }

    // MARK: - Site 6: the reconciler runs after the Journal load

    func testTheJournalLoadReconciles() throws {
        let service = try Self.code("Journal/JournalService.swift")

        XCTAssertTrue(
            service.contains("RoutineRunReconciliation.updates("),
            "the passive endings are DERIVED on the Journal load; nothing else in the arc looks"
        )
    }

    // MARK: - The leak fix reaches the session

    func testTheAuthServiceDefaultsToClearingTheRunStore() throws {
        let auth = try Self.code("Auth/AuthService.swift")

        XCTAssertTrue(
            auth.contains("UserDefaultsRoutineRunStore().clearEveryUser()"),
            "the hook's DEFAULT must clear the run store — an injected hook nobody injects in"
                + " production is the dead-shared-component pattern again"
        )
    }

    // MARK: - The rules admit the collection

    func testTheRulesGrantOwnerCRUDOnRoutineRuns() throws {
        let rules = try Self.repoFile("firestore.rules")
        let generic = try XCTUnwrap(rules.range(of: "collection in ["))

        XCTAssertTrue(
            rules[generic.lowerBound...].contains("'routine_runs'"),
            "routine_runs is UPDATED in place, so it belongs in the generic owner-CRUD list —"
                + " an append-only match would reject every transition after the offer"
        )
    }

    // MARK: - Reading the tree

    private static func code(_ relativePath: String) throws -> String {
        let source = try appSource(relativePath)
        var output = ""
        var index = source.startIndex
        while index < source.endIndex {
            if source[index...].hasPrefix("//") {
                while index < source.endIndex, source[index] != "\n" {
                    index = source.index(after: index)
                }
            } else {
                output.append(source[index])
                index = source.index(after: index)
            }
        }
        return output
    }

    private static func collapsed(_ source: String) -> String {
        source.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func appSource(_ relativePath: String) throws -> String {
        try repoFile("ADHD LifeOS/\(relativePath)")
    }

    private static func repoFile(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.unreadable(url.path)
        }
        return text
    }

    private enum SourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
