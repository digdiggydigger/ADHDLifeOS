//
//  CaptureInboxPreviews.swift
//  ADHD LifeOS
//
//  Preview scaffolding for `CaptureInboxView`, extracted to keep `CaptureInboxView.swift` from
//  growing further (it already trips the file-length lint) — same split as `HomeViewPreviews.swift`.
//

#if DEBUG
import SwiftUI

private struct PreviewCaptureClientAdapting: CaptureClientAdapting {
    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        fatalError("unused in preview")
    }

    func fetchUnprocessedCaptures() async throws -> [Capture] {
        [
            Capture(id: UUID(), content: "Buy groceries", kind: .note, processed: false, createdAt: Date()),
            Capture(id: UUID(), content: "Call the dentist", kind: .task, processed: false, createdAt: Date())
        ]
    }

    func fetchCapture(id: UUID) async throws -> Capture { fatalError("unused in preview") }
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        fatalError("unused in preview")
    }
    func markProcessed(captureId: UUID) async throws {}
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        fatalError("unused in preview")
    }
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}

    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        Capture(id: id, content: "Buy groceries", kind: .note, processed: false, createdAt: Date())
    }
    func fetchAllTags() async throws -> [Tag] {
        [Tag(id: UUID(), name: "urgent"), Tag(id: UUID(), name: "focus")]
    }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func fetchTags(captureId: UUID) async throws -> [Tag] { [] }
    func addTag(captureId: UUID, tagId: UUID) async throws {}
    func removeTag(captureId: UUID, tagId: UUID) async throws {}
}

#Preview("Light") {
    NavigationStack {
        CaptureInboxView(
            client: PreviewCaptureClientAdapting(),
            lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)]
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        CaptureInboxView(
            client: PreviewCaptureClientAdapting(),
            lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)]
        )
    }
    .preferredColorScheme(.dark)
}

/// Returns nothing, so the empty state — the one a user with a healthy triage habit sees most —
/// can be previewed rather than only ever reached at runtime.
private struct EmptyInboxPreviewClient: CaptureClientAdapting {
    private let backing = PreviewCaptureClientAdapting()

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        try await backing.createCapture(input)
    }
    func fetchUnprocessedCaptures() async throws -> [Capture] { [] }
    func fetchCapture(id: UUID) async throws -> Capture { try await backing.fetchCapture(id: id) }
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        try await backing.createTask(input)
    }
    func markProcessed(captureId: UUID) async throws {}
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        try await backing.requestUploadURL(kind: kind, contentType: contentType)
    }
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        try await backing.updateCapture(id: id, changes: changes)
    }
    func fetchAllTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func fetchTags(captureId: UUID) async throws -> [Tag] { [] }
    func addTag(captureId: UUID, tagId: UUID) async throws {}
    func removeTag(captureId: UUID, tagId: UUID) async throws {}
}

#Preview("Empty — Light") {
    NavigationStack {
        CaptureInboxView(client: EmptyInboxPreviewClient(), lifeAreas: [])
    }
    .preferredColorScheme(.light)
}

#Preview("Empty — Dark") {
    NavigationStack {
        CaptureInboxView(client: EmptyInboxPreviewClient(), lifeAreas: [])
    }
    .preferredColorScheme(.dark)
}
#endif
