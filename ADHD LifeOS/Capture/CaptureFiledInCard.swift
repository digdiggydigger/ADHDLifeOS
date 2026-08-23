//
//  CaptureFiledInCard.swift
//  ADHD LifeOS
//
//  B6's "Filed in" card: the life area a capture belongs to, and its tags. The life-area PATCH
//  race machinery here moved VERBATIM from `CaptureRowView` when the inline accordion was retired
//  (2026-08-23) — the revert rollback, echo suppression and superseded-task cancellation are
//  hard-won (the 345233b race) and `CaptureInboxLifeAreaRaceTests` pins the service-level contract
//  they rely on. Do not simplify them in a design pass.
//

import SwiftUI

struct CaptureFiledInCard: View {
    let capture: Capture
    let lifeAreas: [LifeArea]
    /// Owned by the detail screen, not here, because the promote sheet inherits it — the picker's
    /// current value IS the life area a new task will be filed under.
    @Binding var selectedLifeAreaId: UUID?
    let triageErrorMessage: String?
    let onSetLifeArea: (UUID?) async -> Bool
    let onLoadTags: () async -> [Tag]
    let onLoadAllTags: () async -> [Tag]
    let onAddExistingTag: (UUID) async -> Void
    let onCreateTag: (String) async -> Void
    let onRemoveTag: (UUID) async -> Void

    /// The last life-area value the server accepted, used to roll `selectedLifeAreaId` back when a
    /// PATCH fails. Seeded from the capture so the first change has a real "previous" to revert to.
    @State private var lastCommittedLifeAreaId: UUID?
    /// Suppresses the echo PATCH that a programmatic revert of `selectedLifeAreaId` would
    /// otherwise trigger through `.onChange`.
    @State private var isRevertingLifeArea = false
    /// The in-flight life-area PATCH task, held so a newer pick can cancel a superseded one before
    /// it gets a chance to write stale `@State` (the 345233b revert race).
    @State private var lifeAreaTask: Task<Void, Never>?

    init(
        capture: Capture,
        lifeAreas: [LifeArea],
        selectedLifeAreaId: Binding<UUID?>,
        triageErrorMessage: String?,
        onSetLifeArea: @escaping (UUID?) async -> Bool,
        onLoadTags: @escaping () async -> [Tag],
        onLoadAllTags: @escaping () async -> [Tag],
        onAddExistingTag: @escaping (UUID) async -> Void,
        onCreateTag: @escaping (String) async -> Void,
        onRemoveTag: @escaping (UUID) async -> Void
    ) {
        self.capture = capture
        self.lifeAreas = lifeAreas
        self._selectedLifeAreaId = selectedLifeAreaId
        self.triageErrorMessage = triageErrorMessage
        self.onSetLifeArea = onSetLifeArea
        self.onLoadTags = onLoadTags
        self.onLoadAllTags = onLoadAllTags
        self.onAddExistingTag = onAddExistingTag
        self.onCreateTag = onCreateTag
        self.onRemoveTag = onRemoveTag
        _lastCommittedLifeAreaId = State(initialValue: capture.lifeAreaId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LifeAreaPicker(
                title: "Life Area",
                noSelectionLabel: "None",
                lifeAreas: lifeAreas,
                selection: $selectedLifeAreaId,
                accessibilityID: "captureTriageLifeAreaPicker"
            )
            .onChange(of: selectedLifeAreaId, perform: handleLifeAreaChange)

            Text("Applies to this capture and any task made from it.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("captureLifeAreaScopeNote")

            Divider()

            CaptureRowTagEditor(
                onLoadTags: onLoadTags,
                onLoadAllTags: onLoadAllTags,
                onAddExistingTag: onAddExistingTag,
                onCreateTag: onCreateTag,
                onRemoveTag: onRemoveTag
            )

            if let triageErrorMessage {
                Label(triageErrorMessage, systemImage: "exclamationmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("captureTriageErrorMessage")
            }
        }
        .bentoCard()
    }

    /// Persists the newly-picked life area to the capture. On a failed PATCH the picker rolls back
    /// to the last server-accepted value, so Make a Task (which inherits this value) can never
    /// file a task under an area the server rejected. `isRevertingLifeArea` swallows the echo
    /// change the rollback assignment would otherwise feed back through this same handler.
    ///
    /// Each pick cancels the previous in-flight PATCH task and, on return, bails before touching
    /// any `@State` if it was superseded — otherwise a slow, older PATCH that fails could revert
    /// the picker back off a newer value the server has since accepted (the 345233b race). The
    /// HTTP request itself is deliberately *not* cancelled: a superseded PATCH may complete
    /// server-side, last-write-wins; this only stops a stale UI revert from firing.
    private func handleLifeAreaChange(_ newValue: UUID?) {
        if isRevertingLifeArea {
            isRevertingLifeArea = false
            return
        }
        lifeAreaTask?.cancel()
        let previous = lastCommittedLifeAreaId
        lifeAreaTask = Task {
            let succeeded = await onSetLifeArea(newValue)
            guard !Task.isCancelled else { return }
            if succeeded {
                lastCommittedLifeAreaId = newValue
            } else {
                isRevertingLifeArea = true
                selectedLifeAreaId = previous
            }
        }
    }
}

#if DEBUG
private struct CaptureFiledInCardPreviewHost: View {
    @State private var selection: UUID?

    var body: some View {
        CaptureFiledInCard(
            capture: Capture(id: UUID(), content: "A thought", kind: .note, processed: false, createdAt: Date()),
            lifeAreas: [LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)],
            selectedLifeAreaId: $selection,
            triageErrorMessage: nil,
            onSetLifeArea: { _ in true },
            onLoadTags: { [Tag(id: UUID(), name: "reading")] },
            onLoadAllTags: { [] },
            onAddExistingTag: { _ in },
            onCreateTag: { _ in },
            onRemoveTag: { _ in }
        )
        .padding(16)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    CaptureFiledInCardPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CaptureFiledInCardPreviewHost()
        .preferredColorScheme(.dark)
}
#endif
