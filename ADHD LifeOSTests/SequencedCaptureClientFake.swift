//
//  SequencedCaptureClientFake.swift
//  ADHD LifeOSTests
//
//  A controllable `CaptureClientAdapting` fake purpose-built for the Life-Area PATCH race:
//    • `enqueueUpdateOutcomes` — a FIFO queue of results so successive `updateCapture` calls can be
//      made to fail-then-succeed (or any order) deterministically.
//    • `hold(callOrdinal:)` + `waitUntilStarted` + `release(callOrdinal:)` — a gate that parks a
//      chosen `updateCapture` call in-flight so two calls can genuinely overlap, letting a test pin
//      the "first fails, second succeeds, first resolves last" ordering at the service boundary.
//
//  Every other protocol method returns a trivial default — this fake only exists to drive
//  `updateLifeArea`. Separate from the general-purpose `FakeCaptureClientAdapting` so its single
//  shared `updateCaptureResult` semantics stay untouched.
//

import Foundation
@testable import ADHD_LifeOS

final class SequencedCaptureClientFake: CaptureClientAdapting, @unchecked Sendable {
    private let lock = NSLock()

    // FIFO outcomes for `updateCapture`; when exhausted, `defaultUpdateOutcome` is used.
    private var updateOutcomes: [Result<Capture, Error>] = []
    private let defaultUpdateOutcome: Result<Capture, Error>

    /// The capture ids passed to `updateCapture`, in call-start order.
    private(set) var updateStartOrder: [UUID] = []
    private(set) var updateCaptureCallCount = 0

    // Gate machinery, all keyed by a call's 1-based ordinal.
    private var heldOrdinals: Set<Int> = []
    private var gateContinuations: [Int: CheckedContinuation<Void, Never>] = [:]
    private var arrivalWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var startedOrdinals: Set<Int> = []

    init(defaultUpdateOutcome: Result<Capture, Error>) {
        self.defaultUpdateOutcome = defaultUpdateOutcome
    }

    // MARK: - Test controls

    func enqueueUpdateOutcomes(_ outcomes: [Result<Capture, Error>]) {
        lock.lock(); defer { lock.unlock() }
        updateOutcomes = outcomes
    }

    /// Marks the Nth `updateCapture` call (1-based) to suspend until `release(callOrdinal:)`.
    func hold(callOrdinal: Int) {
        lock.lock(); defer { lock.unlock() }
        heldOrdinals.insert(callOrdinal)
    }

    /// Suspends until the given call has started and (if held) parked on its gate — so a test can
    /// launch a second overlapping call knowing the first is genuinely in-flight.
    func waitUntilStarted(callOrdinal: Int) async {
        await withCheckedContinuation { cont in
            lock.lock()
            if startedOrdinals.contains(callOrdinal) {
                lock.unlock()
                cont.resume()
            } else {
                arrivalWaiters[callOrdinal] = cont
                lock.unlock()
            }
        }
    }

    /// Resumes a held call so it can return its queued outcome.
    func release(callOrdinal: Int) {
        lock.lock()
        let cont = gateContinuations.removeValue(forKey: callOrdinal)
        heldOrdinals.remove(callOrdinal)
        lock.unlock()
        cont?.resume()
    }

    // MARK: - CaptureClientAdapting

    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        lock.lock()
        updateCaptureCallCount += 1
        let ordinal = updateCaptureCallCount
        updateStartOrder.append(id)
        let outcome = updateOutcomes.isEmpty ? defaultUpdateOutcome : updateOutcomes.removeFirst()
        let isHeld = heldOrdinals.contains(ordinal)
        lock.unlock()

        if isHeld {
            // Register the gate continuation and signal arrival atomically, so a `release` that
            // races in right after `waitUntilStarted` can never miss the continuation.
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

        return try outcome.get()
    }

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        defaultCapture
    }

    func fetchUnprocessedCaptures() async throws -> [Capture] { [] }
    func fetchCapture(id: UUID) async throws -> Capture { defaultCapture }
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
    }
    func markProcessed(captureId: UUID) async throws {}
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        CaptureUploadTarget(uploadURL: URL(string: "https://example.com/upload")!, mediaKey: "key", thumbnailKey: nil)
    }
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}
    func fetchAllTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func fetchTags(captureId: UUID) async throws -> [Tag] { [] }
    func addTag(captureId: UUID, tagId: UUID) async throws {}
    func removeTag(captureId: UUID, tagId: UUID) async throws {}

    private var defaultCapture: Capture {
        Capture(id: UUID(), content: "note", kind: .note, processed: false, createdAt: Date())
    }
}
