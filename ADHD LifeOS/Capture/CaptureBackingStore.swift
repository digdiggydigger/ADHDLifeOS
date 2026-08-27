//
//  CaptureBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore + Storage surface `FirebaseCaptureClientAdapter` uses. See
/// `LifeAreaEditorBackingStore` for why the seam exists and why it is one protocol per adapter.
///
/// Wider than the other stores because capture itself is: it owns media upload, triage, tag
/// membership and promotion to a task. That breadth is inherited from `CaptureClientAdapting`, not
/// added here — every method below backs exactly one adapter method.
protocol CaptureBackingStore {
    // Media
    func makeUploadTarget(kind: CaptureKind, contentType: String) throws -> CaptureUploadTarget
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws
    func downloadURL(forMediaKey key: String) async throws -> URL

    // Captures
    func saveCapture(_ capture: Capture) async throws
    func fetchUnprocessedCaptures() async throws -> [Capture]
    func fetchProcessedCaptures() async throws -> [Capture]
    func fetchSeenCaptures() async throws -> [Capture]
    func fetchCaptures() async throws -> [Capture]
    func fetchCapture(id: UUID) async throws -> Capture
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws
    func markCaptureProcessed(id: UUID) async throws
    func markCaptureUnprocessed(id: UUID) async throws
    func deleteCapture(id: UUID) async throws

    // Promotion
    func createTask(_ task: TaskDetail) async throws

    // Tags
    func fetchTags() async throws -> [Tag]
    func createTagDeduplicating(name: String) async throws -> Tag
    func fetchTags(for parent: FirebaseTagParent, parentId: UUID) async throws -> [Tag]
    func addTagId(_ tagId: UUID, to parent: FirebaseTagParent, parentId: UUID) async throws
    func removeTagId(_ tagId: UUID, from parent: FirebaseTagParent, parentId: UUID) async throws
}

extension FirebaseManager: CaptureBackingStore {}
