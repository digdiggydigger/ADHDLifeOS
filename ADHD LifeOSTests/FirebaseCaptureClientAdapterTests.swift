//
//  FirebaseCaptureClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The widest of the Firebase adapters, and the one carrying the most real logic: the blank-slate
/// backend has no server-side jobs, so this adapter assembles the capture document itself, sorts
/// what the query cannot, and projects a promoted capture into a task.
final class FirebaseCaptureClientAdapterTests: XCTestCase {
    private var store: FakeCaptureBackingStore!
    private var adapter: FirebaseCaptureClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeCaptureBackingStore()
        adapter = FirebaseCaptureClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Creating a capture

    /// Everything the deleted backend used to fill in server-side is now the adapter's job, and the
    /// defaults it picks are load-bearing: `processed: false` + `status: .inbox` is what puts a new
    /// capture in the triage inbox at all.
    func testCreateCapture_landsInTheInboxUnprocessed() async throws {
        let capture = try await adapter.createCapture(Self.input(content: "Ring the dentist"))

        XCTAssertEqual(capture.content, "Ring the dentist")
        XCTAssertEqual(capture.status, .inbox)
        XCTAssertFalse(capture.processed)
        XCTAssertEqual(store.savedCaptures, [capture], "the returned capture must be the one persisted")
    }

    /// There is no enrichment Lambda and no thumbnailer on the blank slate. These stay `nil` rather
    /// than being invented — `photoDisplayURL` already falls back to the full-size image.
    func testCreateCapture_leavesServerEnrichedFieldsEmpty() async throws {
        let capture = try await adapter.createCapture(Self.input(content: "Ring the dentist"))

        XCTAssertNil(capture.thumbnailURL)
        XCTAssertNil(capture.linkPreview)
        XCTAssertNil(capture.aiAssessment)
    }

    func testCreateCapture_withoutMedia_neverResolvesADownloadURL() async throws {
        let capture = try await adapter.createCapture(Self.input(content: "Ring the dentist"))

        XCTAssertTrue(store.downloadURLKeys.isEmpty)
        XCTAssertNil(capture.mediaURL)
        XCTAssertNil(capture.mediaContentType)
    }

    /// Upload happens before this call, so the object exists and its stable download URL resolves
    /// here. The URL is hand-built rather than signed — a signed Admin SDK URL would expire and rot
    /// the image.
    func testCreateCapture_withMedia_resolvesAndStoresTheDownloadURL() async throws {
        store.resolvedDownloadURL = URL(string: "https://example.com/audio.m4a")!
        let input = Self.input(
            content: "Voice note",
            kind: .voice,
            mediaKey: "users/uid/captures/object.m4a",
            mediaContentType: "audio/m4a"
        )

        let capture = try await adapter.createCapture(input)

        XCTAssertEqual(store.downloadURLKeys, ["users/uid/captures/object.m4a"])
        XCTAssertEqual(capture.mediaURL, URL(string: "https://example.com/audio.m4a"))
        XCTAssertEqual(capture.mediaContentType, "audio/m4a")
    }

    /// If the URL cannot be resolved the capture must not be written half-formed — a document with
    /// no `mediaURL` would render as a caption with a permanently missing image.
    func testCreateCapture_whenTheDownloadURLFails_writesNothing() async {
        store.downloadURLError = FirebaseManagerError.storageUnavailable
        let input = Self.input(content: "Voice note", kind: .voice, mediaKey: "users/uid/captures/object.m4a")

        await XCTAssertThrowsErrorAsync(try await adapter.createCapture(input)) { _ in }

        XCTAssertTrue(store.savedCaptures.isEmpty)
    }

    // MARK: - Listing

    /// `fetchWhere` deliberately has no `order(by:)` — combining a `whereField` with an order on a
    /// different field would need a composite index, so newest-first is the adapter's job.
    func testFetchUnprocessedCaptures_sortsNewestFirst() async throws {
        let old = Self.capture(content: "Older", createdAt: Date(timeIntervalSince1970: 1_000))
        let new = Self.capture(content: "Newer", createdAt: Date(timeIntervalSince1970: 2_000))
        store.unprocessedCaptures = [old, new]

        let captures = try await adapter.fetchUnprocessedCaptures()

        XCTAssertEqual(captures.map(\.content), ["Newer", "Older"])
    }

    func testFetchProcessedCaptures_sortsNewestFirst() async throws {
        let old = Self.capture(content: "Older", createdAt: Date(timeIntervalSince1970: 1_000))
        let new = Self.capture(content: "Newer", createdAt: Date(timeIntervalSince1970: 2_000))
        store.processedCaptures = [old, new]

        let captures = try await adapter.fetchProcessedCaptures()

        XCTAssertEqual(captures.map(\.content), ["Newer", "Older"])
    }

    /// A capture archived as "seen" leaves the inbox but is NOT processed — and the query cannot
    /// say `processed == false AND seen != true` (`fetchWhere` is single-field equality, no
    /// composite indexes), so the adapter subtracts seen captures client-side. This same filter is
    /// what keeps Home's inbox badge honest — it counts through this method.
    func testFetchUnprocessedCaptures_excludesSeenCaptures() async throws {
        var archived = Self.capture(content: "Archived")
        archived.seen = true
        store.unprocessedCaptures = [archived, Self.capture(content: "Waiting")]

        let captures = try await adapter.fetchUnprocessedCaptures()

        XCTAssertEqual(captures.map(\.content), ["Waiting"])
    }

    /// Only an explicit `true` means archived: pre-`seen` documents decode `nil`, and an
    /// un-archived capture carries an explicit `false` — both belong in the inbox.
    func testFetchUnprocessedCaptures_keepsSeenNilAndSeenFalse() async throws {
        var unarchived = Self.capture(content: "Sent back")
        unarchived.seen = false
        store.unprocessedCaptures = [Self.capture(content: "Legacy"), unarchived]

        let captures = try await adapter.fetchUnprocessedCaptures()

        XCTAssertEqual(captures.count, 2)
    }

    func testFetchSeenCaptures_sortsNewestFirst() async throws {
        var old = Self.capture(content: "Older", createdAt: Date(timeIntervalSince1970: 1_000))
        old.seen = true
        var new = Self.capture(content: "Newer", createdAt: Date(timeIntervalSince1970: 2_000))
        new.seen = true
        store.seenCaptures = [old, new]

        let captures = try await adapter.fetchSeenCaptures()

        XCTAssertEqual(captures.map(\.content), ["Newer", "Older"])
    }

    /// A capture archived first and promoted later shows under Promoted, not Seen — every capture
    /// has exactly one home in the Captures tab.
    func testFetchSeenCaptures_excludesAlreadyPromoted() async throws {
        var promotedLater = Self.capture(content: "Promoted later")
        promotedLater.seen = true
        promotedLater.processed = true
        var justSeen = Self.capture(content: "Just seen")
        justSeen.seen = true
        store.seenCaptures = [promotedLater, justSeen]

        let captures = try await adapter.fetchSeenCaptures()

        XCTAssertEqual(captures.map(\.content), ["Just seen"])
    }

    // MARK: - Triage

    /// A partial update followed by a re-read. The returned capture must be the **server's**
    /// document, not a locally patched copy — the write is partial, so fields the adapter never
    /// touched (tag membership, media) are only correct if they come back from Firestore.
    func testUpdateCapture_returnsTheReReadDocumentNotALocalPatch() async throws {
        let id = UUID()
        let serverVersion = Self.capture(id: id, content: "Server wins", title: "From Firestore")
        store.capturesById[id] = serverVersion

        let updated = try await adapter.updateCapture(id: id, changes: CaptureUpdate(title: "Locally typed"))

        XCTAssertEqual(store.captureUpdates.count, 1)
        XCTAssertEqual(store.captureUpdates.first?.changes, CaptureUpdate(title: "Locally typed"))
        XCTAssertEqual(store.fetchedCaptureIds, [id], "the update must be followed by a read")
        XCTAssertEqual(updated, serverVersion)
    }

    func testMarkProcessed_forwardsTheId() async throws {
        let id = UUID()

        try await adapter.markProcessed(captureId: id)

        XCTAssertEqual(store.markedProcessedIds, [id])
    }

    func testDeleteCapture_forwardsTheId() async throws {
        let id = UUID()

        try await adapter.deleteCapture(id: id)

        XCTAssertEqual(store.deletedCaptureIds, [id])
    }

    // MARK: - Promotion to a task

    /// Promotion writes a `TaskDetail` but hands back the `TaskItem` list projection. The two must
    /// agree — the returned item is what the Tasks list renders immediately, before any refetch.
    func testCreateTask_writesAnOpenTaskAndReturnsTheMatchingProjection() async throws {
        let lifeAreaId = UUID()
        let dueDate = Date(timeIntervalSince1970: 1_755_000_000)
        let input = NormalizedPromoteToTaskInput(
            title: "Ring the dentist",
            notes: nil,
            lifeAreaId: lifeAreaId,
            priority: .p1,
            dueDate: dueDate
        )

        let item = try await adapter.createTask(input)

        let written = try XCTUnwrap(store.createdTasks.first)
        XCTAssertEqual(written.status, .open, "a promoted capture becomes an open task")
        XCTAssertEqual(written.title, "Ring the dentist")
        XCTAssertEqual(written.lifeAreaId, lifeAreaId)
        XCTAssertEqual(written.priority, .p1)
        XCTAssertEqual(written.dueDate, dueDate)
        XCTAssertNil(written.notes)

        XCTAssertEqual(item.id, written.id)
        XCTAssertEqual(item.title, written.title)
        XCTAssertEqual(item.lifeAreaId, written.lifeAreaId)
        XCTAssertEqual(item.status, written.status)
        XCTAssertEqual(item.priority, written.priority)
        XCTAssertEqual(item.dueDate, written.dueDate)
    }

    /// A brand-new task has never been completed, so it must carry no stamp — a task that is `done`
    /// with no `completed_at` belongs to no day's wins, and the inverse would be worse.
    func testCreateTask_carriesNoCompletionStamp() async throws {
        let item = try await adapter.createTask(Self.promoteInput())

        XCTAssertNil(item.completedAt)
    }

    // MARK: - Tags

    func testFetchTags_forACapture_scopesToTheCaptureCollection() async throws {
        let captureId = UUID()
        let tag = Tag(id: UUID(), name: "errand")
        store.tagsByParent[captureId] = [tag]

        let tags = try await adapter.fetchTags(captureId: captureId)

        XCTAssertEqual(tags, [tag])
        XCTAssertEqual(store.tagLookups.first?.parent, .capture, "never .task — that would read the wrong document")
        XCTAssertEqual(store.tagLookups.first?.parentId, captureId)
    }

    func testAddTag_attachesToTheCaptureNotTheTask() async throws {
        let captureId = UUID()
        let tagId = UUID()

        try await adapter.addTag(captureId: captureId, tagId: tagId)

        XCTAssertEqual(store.addedTags.first?.parent, .capture)
        XCTAssertEqual(store.addedTags.first?.parentId, captureId)
        XCTAssertEqual(store.addedTags.first?.tagId, tagId)
    }

    func testRemoveTag_detachesFromTheCaptureNotTheTask() async throws {
        let captureId = UUID()
        let tagId = UUID()

        try await adapter.removeTag(captureId: captureId, tagId: tagId)

        XCTAssertEqual(store.removedTags.first?.parent, .capture)
        XCTAssertEqual(store.removedTags.first?.parentId, captureId)
        XCTAssertEqual(store.removedTags.first?.tagId, tagId)
    }

    /// Creating a tag dedups by name server-side rather than making a duplicate.
    func testCreateTag_returnsTheExistingTagWhenTheNameAlreadyExists() async throws {
        let existing = Tag(id: UUID(), name: "Errand")
        store.tags = [existing]

        let tag = try await adapter.createTag(name: "errand")

        XCTAssertEqual(tag, existing)
    }

    // MARK: - Media upload

    func testRequestUploadURL_forwardsKindAndContentType() async throws {
        let target = try await adapter.requestUploadURL(kind: .photo, contentType: "image/jpeg")

        XCTAssertEqual(store.uploadTargetRequests.first?.kind, .photo)
        XCTAssertEqual(store.uploadTargetRequests.first?.contentType, "image/jpeg")
        XCTAssertEqual(target, store.uploadTarget)
    }

    func testUploadMedia_forwardsTheBytesAndContentType() async throws {
        let url = URL(string: "gs://bucket/users/uid/captures/object.jpg")!
        let data = Data("bytes".utf8)

        try await adapter.uploadMedia(to: url, data: data, contentType: "image/jpeg")

        XCTAssertEqual(store.uploads.count, 1)
        XCTAssertEqual(store.uploads.first?.url, url)
        XCTAssertEqual(store.uploads.first?.data, data)
        XCTAssertEqual(store.uploads.first?.contentType, "image/jpeg")
    }

    // MARK: - Fixtures

    private static func input(
        content: String,
        kind: CaptureKind = .note,
        mediaKey: String? = nil,
        mediaContentType: String? = nil
    ) -> NormalizedCreateCaptureInput {
        NormalizedCreateCaptureInput(
            content: content,
            kind: kind,
            title: nil,
            lifeAreaId: nil,
            mediaKey: mediaKey,
            mediaContentType: mediaContentType,
            thumbnailKey: nil
        )
    }

    private static func promoteInput(
        notes: String? = nil,
        focusDurationSeconds: Int? = nil
    ) -> NormalizedPromoteToTaskInput {
        NormalizedPromoteToTaskInput(
            title: "Ring the dentist", notes: notes, lifeAreaId: nil, priority: .p2, dueDate: nil,
            focusDurationSeconds: focusDurationSeconds
        )
    }

    /// S2's effort chips land on the task's own sprint config — the field every seeded task
    /// already carries, no new schema.
    func testCreateTask_carriesTheChosenEffortIntoTheTaskDocument() async throws {
        _ = try await adapter.createTask(Self.promoteInput(focusDurationSeconds: 900))

        XCTAssertEqual(store.createdTasks.first?.focusDurationSeconds, 900)
    }

    /// The promotion promise now includes the annotation: "the new task inherits this capture's
    /// life area, tags and notes".
    func testCreateTask_carriesTheNotesIntoTheTaskDocument() async throws {
        _ = try await adapter.createTask(Self.promoteInput(notes: "Ask about the referral"))

        XCTAssertEqual(store.createdTasks.first?.notes, "Ask about the referral")
    }

    private static func capture(
        id: UUID = UUID(),
        content: String,
        title: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 1_755_000_000)
    ) -> Capture {
        Capture(
            id: id,
            content: content,
            kind: .note,
            processed: false,
            createdAt: createdAt,
            title: title,
            status: .inbox,
            lifeAreaId: nil,
            mediaURL: nil,
            mediaContentType: nil,
            thumbnailURL: nil,
            linkPreview: nil,
            aiAssessment: nil
        )
    }
}
