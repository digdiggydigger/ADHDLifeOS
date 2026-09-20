//
//  ComposerDraftFilerTests.swift
//  ADHD LifeOSTests
//
//  `F-C2-DraftsToInbox`: the act of filing, as opposed to the rule about whether to
//  (`ComposerDraftFilingTests`).
//
//  **The failure mode of this block is silence**, exactly as `F-C1`'s was: a composer that files
//  nothing still closes, still looks right, and still passes every test about the composer. What
//  has to be asserted is that the write HAPPENED, that it carried the user's words, and that the
//  capsule was told — and that a failed write does NOT claim it was kept.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ComposerDraftFilerTests: XCTestCase {

    private func makeFiler(
        client: FakeCaptureClientAdapting,
        recorder: RecordingRecentActionRecorder = RecordingRecentActionRecorder(),
        openCapture: @escaping (UUID) -> Void = { _ in }
    ) -> (ComposerDraftFiler, RecordingRecentActionRecorder) {
        (ComposerDraftFiler(client: client, record: recorder, openCapture: openCapture), recorder)
    }

    func testTypedTextIsWrittenAsANoteCarryingTheUsersOwnWords() async {
        let client = FakeCaptureClientAdapting()
        let (filer, _) = makeFiler(client: client)

        let filed = await filer.fileIfNeeded("Book the dentist before Friday")

        XCTAssertTrue(filed)
        XCTAssertEqual(client.createCaptureCallCount, 1)
        XCTAssertEqual(client.lastCreateCaptureInput?.content, "Book the dentist before Friday")
        XCTAssertEqual(
            client.lastCreateCaptureInput?.kind, .note,
            "A filed draft must be an ordinary note — the spec's accepted cost is that it is not a"
                + " richer draft type, and a new kind would need its own rules everywhere."
        )
    }

    /// **The inbox must not fill with empty notes.** Every opened-and-closed composer runs this
    /// path, so an untouched one writing anything would make the feature a nuisance.
    func testAnUntouchedComposerWritesNothingAndSaysNothing() async {
        let client = FakeCaptureClientAdapting()
        let (filer, recorder) = makeFiler(client: client)

        let filed = await filer.fileIfNeeded("   \n ")

        XCTAssertFalse(filed)
        XCTAssertEqual(client.createCaptureCallCount, 0, "An untouched composer wrote to the server.")
        XCTAssertNil(recorder.recorded, "An untouched composer showed a capsule claiming it kept something.")
    }

    /// The capsule names what was kept, in E's own words, and offers Reopen rather than Undo.
    func testTheCapsuleIsToldWhatWasKeptAndOffersToReopenIt() async throws {
        let client = FakeCaptureClientAdapting()
        let (filer, recorder) = makeFiler(client: client)

        _ = await filer.fileIfNeeded("Ask Sam about the spare key")

        let action = try XCTUnwrap(recorder.recorded)
        XCTAssertEqual(action.kind, .draftKeptInInbox)
        XCTAssertEqual(action.subject, "Ask Sam about the spare key")
        XCTAssertEqual(action.kind.verb, "Kept in your inbox")
        XCTAssertEqual(action.kind.actionLabel, "Reopen")
    }

    /// The capsule's subject is the shared rule's, not the raw text — so a long journal entry is
    /// cut for the announcement rather than spoken whole.
    func testTheCapsuleNamesTheDraftByItsFirstLine() async throws {
        let client = FakeCaptureClientAdapting()
        let (filer, recorder) = makeFiler(client: client)

        _ = await filer.fileIfNeeded("Book the dentist\nand the optician")

        XCTAssertEqual(try XCTUnwrap(recorder.recorded).subject, "Book the dentist")
        XCTAssertEqual(
            client.lastCreateCaptureInput?.content, "Book the dentist\nand the optician",
            "The CAPTURE must keep the whole draft — only the capsule's label is shortened."
        )
    }

    /// **A failed write must never claim the text was kept.** This is the one outcome worse than
    /// the old silent discard: the user reads "Kept in your inbox", stops worrying, and the words
    /// are gone. Nothing is recorded, so no capsule appears and nothing lies.
    func testAFailedWriteShowsNoCapsuleRatherThanPromisingSomethingIsKept() async {
        let client = FakeCaptureClientAdapting()
        client.createCaptureResult = .failure(CaptureServiceError.fetchFailed("offline"))
        let (filer, recorder) = makeFiler(client: client)

        let filed = await filer.fileIfNeeded("Book the dentist before Friday")

        XCTAssertFalse(filed)
        XCTAssertNil(
            recorder.recorded,
            "A capsule claimed the draft was kept after the write failed — the user would stop"
                + " worrying about words that are gone."
        )
    }

    /// Reopen takes the user to the capture that was just written, by its own id — E's Step 0
    /// answer 1, *"Open it in the inbox"*. The id has to be the SERVER's, not one minted here.
    func testReopenOpensTheCaptureThatWasJustWritten() async throws {
        let client = FakeCaptureClientAdapting()
        let written = try client.createCaptureResult.get()
        var opened: UUID?
        let (filer, recorder) = makeFiler(client: client, openCapture: { opened = $0 })

        _ = await filer.fileIfNeeded("Ask Sam about the spare key")
        let landed = await (try XCTUnwrap(recorder.recorded)).undo()

        XCTAssertTrue(landed, "Reopen reported that it could not take the user anywhere.")
        XCTAssertEqual(opened, written.id)
    }
}

/// Records the one action a filer offers, so the test can read it and run it.
final class RecordingRecentActionRecorder: RecentActionRecording {
    private(set) var recorded: RecentAction?
    private(set) var clearCount = 0

    func record(_ action: RecentAction) { recorded = action }
    func clear() { clearCount += 1 }
}
