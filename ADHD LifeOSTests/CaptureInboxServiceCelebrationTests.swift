//
//  CaptureInboxServiceCelebrationTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-5`, the first of E's four full-screen milestones: **inbox zero**.
//
//  E named the three DOING verbs — Sorted, Journal it, Create Task — and the principle behind the
//  whole arc is "celebrate doing, not adding" (#5). **R-a** draws the line the other way too: a
//  discard is tidying, not doing, so binning the last capture empties the inbox and celebrates
//  nothing. That is the single most important assertion in this file, because it is the one a
//  reasonable implementation gets wrong — every exit funnels through the same `removeCapture`.
//
//  The listener lives in the SERVICE rather than in the five screens that host it: all five call
//  the same three methods, and a per-screen listener would be five copies of one rule and a silent
//  gap wherever a sixth door appeared.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CaptureInboxServiceCelebrationTests: XCTestCase {

    private func waiting(_ content: String) -> Capture {
        Capture(id: UUID(), content: content, kind: .note, processed: false, createdAt: Date())
    }

    /// The inbox screen's shape: a service whose `.unprocessed` list is loaded and on screen.
    private func loadedInbox(
        holding captures: [Capture], celebrate: RecordingCelebrationRequester,
        journal: FakeJournalClientAdapting? = nil
    ) async -> (CaptureInboxService, FakeCaptureClientAdapting) {
        let fake = FakeCaptureClientAdapting()
        fake.fetchUnprocessedCapturesResult = .success(captures)
        let service = CaptureInboxService(client: fake, journalClient: journal, celebrate: celebrate)
        await service.load()
        return (service, fake)
    }

    // MARK: - The three doing verbs

    func testSortingTheLastWaitingCaptureCelebratesInboxZero() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("the last one")
        let (service, _) = await loadedInbox(holding: [capture], celebrate: celebrate)

        await service.sort(capture: capture, into: UUID())

        XCTAssertEqual(celebrate.milestones, [.inboxZero])
    }

    func testJournallingTheLastWaitingCaptureCelebratesInboxZero() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("the last one")
        let journal = FakeJournalClientAdapting()
        let (service, _) = await loadedInbox(holding: [capture], celebrate: celebrate, journal: journal)

        await service.logToJournal(capture: capture)

        XCTAssertEqual(celebrate.milestones, [.inboxZero])
    }

    func testPromotingTheLastWaitingCaptureCelebratesInboxZero() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("the last one")
        let (service, fake) = await loadedInbox(holding: [capture], celebrate: celebrate)
        fake.fetchCaptureResult = .success(capture)

        await service.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertEqual(celebrate.milestones, [.inboxZero])
    }

    /// The milestone is the inbox reaching zero, not a capture leaving it.
    func testClearingOneOfTwoCapturesCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let first = waiting("first")
        let second = waiting("second")
        let (service, _) = await loadedInbox(holding: [first, second], celebrate: celebrate)

        await service.sort(capture: first, into: UUID())

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    // MARK: - R-a: the verbs that empty the inbox without doing anything

    /// **E named three verbs and R-a says why the fourth is not one of them.** Every exit removes
    /// the capture through the same `removeCapture`, so a listener placed one level down would
    /// celebrate a binned inbox exactly as loudly as a cleared one.
    func testDiscardingTheLastCaptureCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("not worth keeping")
        let (service, _) = await loadedInbox(holding: [capture], celebrate: celebrate)

        await service.discard(capture: capture)

        XCTAssertTrue(
            service.captures.isEmpty, "The discard did not happen, so the test proves nothing."
        )
        XCTAssertTrue(
            celebrate.requested.isEmpty,
            "Binning the last capture celebrated inbox zero. R-a: a discard is tidying, not doing."
        )
    }

    /// Sending a sorted capture back the other way empties the SORTED list, and puts something
    /// back into the inbox. Nothing about that is a milestone.
    func testSendingASortedCaptureBackToTheInboxCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let sorted = Capture(
            id: UUID(), content: "sorted earlier", kind: .note, processed: false,
            createdAt: Date(), seen: true
        )
        let fake = FakeCaptureClientAdapting()
        fake.fetchSeenCapturesResult = .success([sorted])
        let service = CaptureInboxService(
            client: fake, availableFilters: [.seen, .promoted], celebrate: celebrate
        )
        await service.load()

        await service.undoSeen(capture: sorted)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    /// A capture that was already sorted was never in the to-triage queue, so promoting it from
    /// the Captures tab cannot be what emptied it.
    func testPromotingACaptureThatWasAlreadySortedCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let sorted = Capture(
            id: UUID(), content: "sorted earlier", kind: .note, processed: false,
            createdAt: Date(), seen: true
        )
        let fake = FakeCaptureClientAdapting()
        fake.fetchSeenCapturesResult = .success([sorted])
        fake.fetchCaptureResult = .success(sorted)
        let service = CaptureInboxService(
            client: fake, availableFilters: [.seen, .promoted], celebrate: celebrate
        )
        await service.load()

        await service.promoteToTask(capture: sorted, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    // MARK: - A verb that failed did not clear anything

    func testASortThatFailedCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("the last one")
        let (service, fake) = await loadedInbox(holding: [capture], celebrate: celebrate)
        fake.updateCaptureResult = .failure(CaptureServiceError.alreadyProcessed)

        await service.sort(capture: capture, into: UUID())

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    // MARK: - The doors that hold no list

    /// **Home's inbox peek and the Journal timeline push a capture detail whose service never
    /// loaded a list** (`JournalCaptureDoor`), so "is the inbox empty now" cannot be read off
    /// `state` — there is nothing in it. One fetch is the answer.
    func testAServiceWithNoLoadedListAsksTheServerWhetherTheInboxIsEmpty() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("the last one")
        let fake = FakeCaptureClientAdapting()
        fake.fetchCaptureResult = .success(capture)
        fake.fetchUnprocessedCapturesResult = .success([])
        let service = CaptureInboxService(client: fake, celebrate: celebrate)

        await service.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertEqual(fake.fetchUnprocessedCapturesCallCount, 1, "The door fetched more than once.")
        XCTAssertEqual(celebrate.milestones, [.inboxZero])
    }

    func testADoorWhoseInboxStillHoldsSomethingCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("the one being promoted")
        let fake = FakeCaptureClientAdapting()
        fake.fetchCaptureResult = .success(capture)
        fake.fetchUnprocessedCapturesResult = .success([waiting("still waiting")])
        let service = CaptureInboxService(client: fake, celebrate: celebrate)

        await service.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    /// **A fetch that failed is not an empty inbox.** `?? []` would read a dropped connection as
    /// "you cleared everything" and throw a full-screen celebration at it — the same class of
    /// mistake `HomeService.allTasks` records for the arrival card, where an emptied list is not
    /// "don't know" but the positive claim "there is nothing".
    func testADoorWhoseInboxFetchFailedCelebratesNothing() async {
        let celebrate = RecordingCelebrationRequester()
        let capture = waiting("the last one")
        let fake = FakeCaptureClientAdapting()
        fake.fetchCaptureResult = .success(capture)
        fake.fetchUnprocessedCapturesResult = .failure(CaptureServiceError.alreadyProcessed)
        let service = CaptureInboxService(client: fake, celebrate: celebrate)

        await service.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(celebrate.requested.isEmpty)
    }

    // MARK: - The default

    /// Every other host builds the service without one. The default has to be inert rather than
    /// optional so no `init` in the app has to care, and so a preview draws nothing.
    func testAServiceBuiltWithoutARequesterCelebratesNothingAndDoesNotTrap() async {
        let capture = waiting("the last one")
        let fake = FakeCaptureClientAdapting()
        fake.fetchUnprocessedCapturesResult = .success([capture])
        let service = CaptureInboxService(client: fake)
        await service.load()

        await service.sort(capture: capture, into: UUID())

        XCTAssertTrue(service.captures.isEmpty)
    }
}
