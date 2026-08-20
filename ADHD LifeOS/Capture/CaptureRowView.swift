//
//  CaptureRowView.swift
//  ADHD LifeOS
//
//  One Inbox row and its triage affordances, split out of `CaptureInboxView.swift` in the 2026-08-20
//  Inbox design pass — that file carried the screen AND the row and had been over the file-length
//  and type-body lint budgets for months. The row's behaviour is deliberately untouched here: its
//  life-area revert race, superseded-PATCH cancellation and accessibility-size reflow are all
//  hard-won and covered by `CaptureInboxLifeAreaRaceTests` / `CaptureInboxPromoteRaceTests`.
//

import SwiftUI
import UIKit

struct CaptureRowView: View {
    let capture: Capture
    let lifeAreas: [LifeArea]
    let isExpanded: Bool
    let warningMessage: String?
    let errorMessage: String?
    let triageErrorMessage: String?
    let onToggleExpanded: () -> Void
    let onCreateTask: (UUID?, TaskPriority, Date?) async -> Bool
    let onSetLifeArea: (UUID?) async -> Bool
    let onLoadTags: () async -> [Tag]
    let onLoadAllTags: () async -> [Tag]
    let onAddExistingTag: (UUID) async -> Void
    let onCreateTag: (String) async -> Void
    let onRemoveTag: (UUID) async -> Void
    /// Writes the capture into the journal and retires it — the triage exit for a thought that
    /// is worth keeping but isn't a task.
    let onLogToJournal: () async -> Bool
    /// Deletes the capture outright. Confirmed before it fires: this is the one irreversible
    /// action on the screen.
    let onDiscard: () async -> Bool

    @State private var priority: TaskPriority = .p4
    @State private var dueDate: Date?
    @State private var hasDueDate = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var triageLifeAreaId: UUID?
    /// The last life-area value the server accepted, used to roll `triageLifeAreaId` back when a
    /// PATCH fails. Seeded from the capture so the first change has a real "previous" to revert to.
    @State private var lastCommittedLifeAreaId: UUID?
    /// Suppresses the echo PATCH that a programmatic revert of `triageLifeAreaId` would otherwise
    /// trigger through `.onChange`.
    @State private var isRevertingLifeArea = false
    /// The in-flight life-area PATCH task, held so a newer pick can cancel a superseded one before
    /// it gets a chance to write stale `@State` (the 345233b revert race).
    @State private var lifeAreaTask: Task<Void, Never>?
    @State private var isConfirmingDiscard = false
    @State private var isLoggingToJournal = false
    @State private var isPresentingPhoto = false

    init(
        capture: Capture,
        lifeAreas: [LifeArea],
        isExpanded: Bool,
        warningMessage: String?,
        errorMessage: String?,
        triageErrorMessage: String?,
        onToggleExpanded: @escaping () -> Void,
        onCreateTask: @escaping (UUID?, TaskPriority, Date?) async -> Bool,
        onSetLifeArea: @escaping (UUID?) async -> Bool,
        onLoadTags: @escaping () async -> [Tag],
        onLoadAllTags: @escaping () async -> [Tag],
        onAddExistingTag: @escaping (UUID) async -> Void,
        onCreateTag: @escaping (String) async -> Void,
        onRemoveTag: @escaping (UUID) async -> Void,
        onLogToJournal: @escaping () async -> Bool,
        onDiscard: @escaping () async -> Bool
    ) {
        self.capture = capture
        self.lifeAreas = lifeAreas
        self.isExpanded = isExpanded
        self.warningMessage = warningMessage
        self.errorMessage = errorMessage
        self.triageErrorMessage = triageErrorMessage
        self.onToggleExpanded = onToggleExpanded
        self.onCreateTask = onCreateTask
        self.onSetLifeArea = onSetLifeArea
        self.onLoadTags = onLoadTags
        self.onLoadAllTags = onLoadAllTags
        self.onAddExistingTag = onAddExistingTag
        self.onCreateTag = onCreateTag
        self.onRemoveTag = onRemoveTag
        self.onLogToJournal = onLogToJournal
        self.onDiscard = onDiscard
        _triageLifeAreaId = State(initialValue: capture.lifeAreaId)
        _lastCommittedLifeAreaId = State(initialValue: capture.lifeAreaId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if isExpanded {
                triageSection
                Divider()
                promoteForm
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .expandCollapseHaptic(trigger: isExpanded)
        .accessibilityIdentifier("captureRow-\(capture.id)")
        .captureRowPresentations(
            capture: capture,
            isPresentingPhoto: $isPresentingPhoto,
            isConfirmingDiscard: $isConfirmingDiscard,
            onDiscard: onDiscard
        )
    }

    /// At accessibility text sizes the "Promote" button and the row's primary text still cannot
    /// both stay legible on one line — even with the shorter label and `.minimumScaleFactor(0.8)`,
    /// forcing them side by side either shoves the text off-screen or shrinks the button to a stub.
    /// So at those sizes the button reflows beneath the content and each gets the full row width; at
    /// normal sizes they sit side by side exactly as before. `.minimumScaleFactor` then keeps the
    /// reflowed elements from truncating within their own full-width line. `CLAUDE.md` §1 (layout
    /// safety) / §3.
    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                headerContent
                promoteButton
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                headerContent
                Spacer()
                promoteButton
            }
        }
    }

    private var headerContent: some View {
        HStack(alignment: .top, spacing: 8) {
            CaptureRowLeadingSlot(capture: capture) { isPresentingPhoto = true }
            VStack(alignment: .leading, spacing: 4) {
                Text(CaptureRowPresentation.primaryText(for: capture))
                    .lineLimit(isExpanded ? nil : 1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                if isExpanded, capture.kind == .link {
                    expandedLinkContent
                }
                Text(CaptureRowPresentation.caption(for: capture))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(1)
        }
    }

    /// Now a real chip rather than bare text (2026-08-20 Inbox pass): on a flat `List` row plain
    /// text read as a label, and inside a bento card it read as part of the content. It also sat
    /// well under §3's 44pt target — the primary action on every row in the triage screen.
    @ViewBuilder
    private var promoteButton: some View {
        // An already-triaged capture (the Promoted tab) has nothing left to promote — offering the
        // button anyway invited a tap that could only ever be refused (found in-simulator,
        // 2026-08-20). It becomes a status chip instead.
        if capture.processed {
            CapturePromotedChip()
        } else {
            promoteToggle
        }
    }

    private var promoteToggle: some View {
        Button {
            onToggleExpanded()
        } label: {
            Text(isExpanded ? "Cancel" : "Promote")
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: false))
        .accessibilityIdentifier("capturePromoteButton")
    }

    /// The rich link preview, shown only once the row is expanded so collapsed link rows share the
    /// uniform slot + single-line layout of every other kind. Renders a preview card once the
    /// server-side unfurl has landed on `capture.linkPreview`; until then (or if the unfurl failed)
    /// it degrades to a bare tappable URL — never an error, since an unfurled preview is
    /// best-effort, not guaranteed.
    @ViewBuilder
    private var expandedLinkContent: some View {
        if let preview = capture.linkPreview {
            CaptureLinkPreviewCard(preview: preview, fallbackTitle: capture.content)
        } else if let url = URL(string: capture.content) {
            Link(capture.content, destination: url)
                .font(.subheadline)
                .lineLimit(1)
                .accessibilityIdentifier("captureLinkBareURL")
        }
    }

    /// Life Area + Tag editing, plus read-only Title/AI Assessment display when present — the
    /// triage screen. Distinct from `promoteForm` below, which edits the *task being created*,
    /// not the capture itself.
    private var triageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = capture.title, !title.isEmpty {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("captureTitleText")
            }
            if let aiAssessment = capture.aiAssessment, !aiAssessment.isEmpty {
                Text(aiAssessment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("captureAIAssessmentText")
            }

            LifeAreaPicker(
                title: "Life Area",
                noSelectionLabel: "None",
                lifeAreas: lifeAreas,
                selection: $triageLifeAreaId,
                accessibilityID: "captureTriageLifeAreaPicker"
            )
            .onChange(of: triageLifeAreaId, perform: handleLifeAreaChange)

            Text("Applies to this capture and any task made from it.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("captureLifeAreaScopeNote")

            CaptureRowTagEditor(
                onLoadTags: onLoadTags,
                onLoadAllTags: onLoadAllTags,
                onAddExistingTag: onAddExistingTag,
                onCreateTag: onCreateTag,
                onRemoveTag: onRemoveTag
            )

            if let triageErrorMessage {
                Text(triageErrorMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("captureTriageErrorMessage")
            }
        }
    }

    /// Persists the newly-picked life area to the capture. On a failed PATCH the picker rolls back
    /// to the last server-accepted value, so Create Task (which now inherits this value) can never
    /// file a task under an area the server rejected. `isRevertingLifeArea` swallows the echo change
    /// the rollback assignment would otherwise feed back through this same handler.
    ///
    /// Each pick cancels the previous in-flight PATCH task and, on return, bails before touching any
    /// `@State` if it was superseded — otherwise a slow, older PATCH that fails could revert the
    /// picker back off a newer value the server has since accepted (the 345233b race). The HTTP
    /// request itself is deliberately *not* cancelled: a superseded PATCH may complete server-side,
    /// last-write-wins; this only stops a stale UI revert from firing.
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
                triageLifeAreaId = previous
            }
        }
    }

    private var promoteForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { option in
                    Text(option.rawValue.uppercased()).tag(option)
                }
            }
            .accessibilityIdentifier("capturePromotePriorityPicker")

            Toggle("Due Date", isOn: $hasDueDate)
                .onChange(of: hasDueDate) { newValue in
                    dueDate = newValue ? (dueDate ?? Date()) : nil
                }
            if hasDueDate {
                DatePicker(
                    "Date",
                    selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }),
                    displayedComponents: .date
                )
            }

            if let warningMessage {
                // Icon + text via `Label` so warning-ness is conveyed structurally (not by colour
                // alone, §4) and VoiceOver reads the pair as one element (§7). Identifier verbatim.
                Label(warningMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("capturePromoteWarningMessage")
            }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("capturePromoteErrorMessage")
            }

            CreateTaskButton(
                lifeAreaId: triageLifeAreaId, priority: priority, dueDate: dueDate, onCreateTask: onCreateTask
            )

            CaptureSecondaryTriageActions(
                isLoggingToJournal: $isLoggingToJournal,
                onLogToJournal: onLogToJournal,
                onRequestDiscard: { isConfirmingDiscard = true }
            )
        }
    }
}
