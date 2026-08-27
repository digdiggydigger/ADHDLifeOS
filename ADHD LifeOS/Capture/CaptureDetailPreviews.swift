//
//  CaptureDetailPreviews.swift
//  ADHD LifeOS
//
//  Light/Dark previews for the detail screen and its promote sheet (§6). Its stub client follows
//  the per-file private-preview-client house pattern (`CaptureInboxPreviews`, `HomeViewPreviews`).
//

#if DEBUG
import SwiftUI

private struct DetailPreviewCaptureClient: CaptureClientAdapting {
    static let sample = Capture(
        id: UUID(),
        content: "https://www.swiftpackageindex.com/migration",
        kind: .link,
        processed: false,
        createdAt: Date(),
        title: "Swift concurrency: migrating at your own pace",
        lifeAreaId: nil,
        mediaURL: nil,
        mediaContentType: nil,
        thumbnailURL: nil,
        linkPreview: CaptureLinkPreview(
            url: "https://www.swiftpackageindex.com/migration",
            title: "Swift concurrency: migrating at your own pace",
            description: "Read before the Thursday architecture review.",
            thumbnailURL: nil
        ),
        aiAssessment: "Reference material, no action implied."
    )

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        fatalError("unused in preview")
    }
    func fetchUnprocessedCaptures() async throws -> [Capture] { [Self.sample] }
    func fetchProcessedCaptures() async throws -> [Capture] { [] }
    func fetchSeenCaptures() async throws -> [Capture] { [] }
    func fetchCaptures() async throws -> [Capture] { [] }
    func fetchCapture(id: UUID) async throws -> Capture { Self.sample }
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        fatalError("unused in preview")
    }
    func markProcessed(captureId: UUID) async throws {}
    func deleteCapture(id: UUID) async throws {}
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture { Self.sample }
    func fetchAllTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { Tag(id: UUID(), name: name) }
    func fetchTags(captureId: UUID) async throws -> [Tag] { [Tag(id: UUID(), name: "reading")] }
    func addTag(captureId: UUID, tagId: UUID) async throws {}
    func removeTag(captureId: UUID, tagId: UUID) async throws {}
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        fatalError("unused in preview")
    }
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}
}

private struct CaptureDetailPreviewHost: View {
    @StateObject private var service = CaptureInboxService(client: DetailPreviewCaptureClient())

    var body: some View {
        NavigationStack {
            CaptureDetailView(
                captureId: DetailPreviewCaptureClient.sample.id,
                lifeAreas: [LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)],
                service: service
            )
        }
    }
}

#Preview("Detail Light") {
    CaptureDetailPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Detail Dark") {
    CaptureDetailPreviewHost()
        .preferredColorScheme(.dark)
}

private struct CapturePromoteSheetPreviewHost: View {
    @StateObject private var service = CaptureInboxService(client: DetailPreviewCaptureClient())

    var body: some View {
        Color.pageBackground
            .sheet(isPresented: .constant(true)) {
                CapturePromoteSheet(
                    capture: DetailPreviewCaptureClient.sample,
                    lifeAreaId: nil,
                    service: service,
                    onPromoted: {}
                )
            }
    }
}

#Preview("Promote sheet Light") {
    CapturePromoteSheetPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Promote sheet Dark") {
    CapturePromoteSheetPreviewHost()
        .preferredColorScheme(.dark)
}
#endif
