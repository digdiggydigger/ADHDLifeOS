//
//  PromoteRaceCaptureClientFake.swift
//  ADHD LifeOSTests
//
//  A controllable `CaptureClientAdapting` fake purpose-built for the promote double-tap race:
//  it gates `fetchCapture` (the first suspension point on `promoteToTask`'s create path) so a test
//  can park one promote genuinely in-flight and fire a second overlapping tap, proving the
//  in-flight guard collapses the double-tap to a single `createTask`. Mirrors
//  `SequencedCaptureClientFake`'s gate, which does the same for the Life-Area PATCH race.
//
//  Every method not on the promote path returns a trivial default.
//

import Foundation
@testable import ADHD_LifeOS

final class PromoteRaceCaptureClientFake: CaptureClientAdapting, @unchecked Sendable {
    private let lock = NSLock()
    private let capture: Capture

    private(set) var fetchCaptureCallCount = 0
    private(set) var createTaskCallCount = 0
    private(set) var markProcessedCallCount = 0

    // Gate machinery for `fetchCapture`, keyed by a call's 1-based ordinal.
    private var heldOrdinals: Set<Int> = []
    private var gateContinuations: [Int: CheckedContinuation<Void, Never>] = [:]
    private var arrivalWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var startedOrdinals: Set<Int> = []

    init(capture: Capture) {
        self.capture = capture
    }

    // MARK: - Test controls

    /// Marks the Nth `fetchCapture` call (1-based) to suspend until `releaseFetchCapture`.
    func hold(fetchCaptureOrdinal ordinal: Int) {
        lock.lock(); defer { lock.unlock() }
        heldOrdinals.insert(ordinal)
    }

    /// Suspends until the given `fetchCapture` call has started (and, if held, parked on its gate),
    /// so a test can fire a second overlapping promote knowing the first is genuinely in-flight.
    func waitUntilFetchCaptureStarted(ordinal: Int) async {
        await withCheckedContinuation { cont in
            lock.lock()
            if startedOrdinals.contains(ordinal) {
                lock.unlock()
                cont.resume()
            } else {
                arrivalWaiters[ordinal] = cont
                lock.unlock()
            }
        }
    }

    /// Resumes a held `fetchCapture` call so it can return.
    func releaseFetchCapture(ordinal: Int) {
        lock.lock()
        let cont = gateContinuations.removeValue(forKey: ordinal)
        heldOrdinals.remove(ordinal)
        lock.unlock()
        cont?.resume()
    }

    // MARK: - CaptureClientAdapting

    func fetchCapture(id: UUID) async throws -> Capture {
        lock.lock()
        fetchCaptureCallCount += 1
        let ordinal = fetchCaptureCallCount
        let isHeld = heldOrdinals.contains(ordinal)
        lock.unlock()

        if isHeld {
            // Register the gate continuation and signal arrival atomically, so a `release` racing
            // in right after `waitUntilFetchCaptureStarted` can never miss the continuation.
            await withCheckedContinuation { cont in
                lock.lock()
                gateContinuations[ordinal] = cont
                startedOrdinals.insert(ordinal)
                let waiter = arrivalWaiters.removeValue(forKey: ordinal)
                lock.unlock()
                waiter?.resume()
            }
        } else {
            lock.lock()
            startedOrdinals.insert(ordinal)
            let waiter = arrivalWaiters.removeValue(forKey: ordinal)
            lock.unlock()
            waiter?.resume()
        }

        return capture
    }

    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        lock.lock(); createTaskCallCount += 1; lock.unlock()
        return TaskItem(
            id: UUID(), lifeAreaId: input.lifeAreaId, title: input.title,
            status: .open, priority: input.priority, dueDate: input.dueDate
        )
    }

    func markProcessed(captureId: UUID) async throws {
        lock.lock(); markProcessedCallCount += 1; lock.unlock()
    }

    func fetchProcessedCaptures() async throws -> [Capture] { [] }
    func deleteCapture(id: UUID) async throws {}

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture { capture }
    func fetchUnprocessedCaptures() async throws -> [Capture] { [capture] }
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        CaptureUploadTarget(uploadURL: URL(string: "https://example.com/upload")!, mediaKey: "key", thumbnailKey: nil)
    }
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture { capture }
    func fetchAllTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func fetchTags(captureId: UUID) async throws -> [Tag] { [] }
    func addTag(captureId: UUID, tagId: UUID) async throws {}
    func removeTag(captureId: UUID, tagId: UUID) async throws {}
}
