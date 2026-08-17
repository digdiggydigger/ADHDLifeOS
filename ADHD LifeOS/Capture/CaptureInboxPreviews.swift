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
#endif
