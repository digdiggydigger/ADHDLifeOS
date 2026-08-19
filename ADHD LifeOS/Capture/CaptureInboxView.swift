//
//  CaptureInboxView.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

struct CaptureInboxView: View {
    @StateObject private var service: CaptureInboxService
    let lifeAreas: [LifeArea]
    @State private var expandedCaptureId: UUID?

    init(client: CaptureClientAdapting, lifeAreas: [LifeArea]) {
        _service = StateObject(wrappedValue: CaptureInboxService(client: client))
        self.lifeAreas = lifeAreas
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("captureInboxLoadingIndicator")
            case .failed(let message):
                VStack(spacing: 16) {
                    Text("Couldn't load your inbox")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .accessibilityIdentifier("captureInboxErrorMessage")
            case .loaded(let captures):
                if captures.isEmpty {
                    Text("Inbox is empty")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("captureInboxEmptyState")
                } else {
                    List(captures) { capture in
                        CaptureRowView(
                            capture: capture,
                            lifeAreas: lifeAreas,
                            isExpanded: expandedCaptureId == capture.id,
                            warningMessage: service.warningMessage,
                            errorMessage: service.errorMessage,
                            triageErrorMessage: service.triageErrorMessage,
                            onToggleExpanded: {
                                expandedCaptureId = expandedCaptureId == capture.id ? nil : capture.id
                            },
                            onCreateTask: { lifeAreaId, priority, dueDate in
                                let succeeded = await service.promoteToTask(
                                    capture: capture, lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate
                                )
                                if succeeded {
                                    expandedCaptureId = nil
                                }
                                return succeeded
                            },
                            onSetLifeArea: { lifeAreaId in
                                await service.updateLifeArea(capture: capture, lifeAreaId: lifeAreaId)
                            },
                            onLoadTags: {
                                await service.fetchTags(for: capture)
                            },
                            onLoadAllTags: {
                                await service.fetchAllTags()
                            },
                            onAddExistingTag: { tagId in
                                await service.addExistingTag(capture: capture, tagId: tagId)
                            },
                            onCreateTag: { name in
                                await service.createAndAddTag(capture: capture, name: name)
                            },
                            onRemoveTag: { tagId in
                                await service.removeTag(capture: capture, tagId: tagId)
                            }
                        )
                        .listRowBackground(Color.cardSurface)
                    }
                    // Token alignment (2026-08-19 bento pass): rows on the CardSurface cream,
                    // page behind them on PageBackground. Deliberately still a `List`, not
                    // floating bento cards — rebuilding this heavily-tested triage screen's
                    // container was judged out of scope for a styling pass; flagged in report.
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await service.refresh()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle("Inbox")
        .task {
            await service.load()
        }
    }
}

private struct CaptureRowView: View {
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
    @State private var currentTags: [Tag] = []
    @State private var allTags: [Tag] = []
    @State private var tagQuery = ""

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
        onRemoveTag: @escaping (UUID) async -> Void
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
        .task(id: isExpanded) {
            guard isExpanded else { return }
            currentTags = await onLoadTags()
            allTags = await onLoadAllTags()
        }
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
            CaptureRowLeadingSlot(capture: capture)
            VStack(alignment: .leading, spacing: 4) {
                Text(CaptureRowPresentation.primaryText(for: capture))
                    .lineLimit(isExpanded ? nil : 1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                if isExpanded, capture.kind == .link {
                    expandedLinkContent
                }
                Text(captionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(1)
        }
    }

    private var promoteButton: some View {
        Button(isExpanded ? "Cancel" : "Promote") {
            onToggleExpanded()
        }
        .buttonStyle(.plain)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityIdentifier("capturePromoteButton")
    }

    /// One caption line reading "Kind · time ago" — identical shape on every row so the collapsed
    /// list has a consistent second line.
    private var captionText: String {
        let kind = CaptureRowPresentation.kindLabel(for: capture.kind)
        let when = capture.createdAt.formatted(.relative(presentation: .named))
        return "\(kind) · \(when)"
    }

    /// The rich link preview, shown only once the row is expanded so collapsed link rows share the
    /// uniform slot + single-line layout of every other kind. Renders a preview card once the
    /// server-side unfurl has landed on `capture.linkPreview`; until then (or if the unfurl failed)
    /// it degrades to a bare tappable URL — never an error, since an unfurled preview is
    /// best-effort, not guaranteed.
    @ViewBuilder
    private var expandedLinkContent: some View {
        if let preview = capture.linkPreview {
            linkPreviewCard(preview)
        } else if let url = URL(string: capture.content) {
            Link(capture.content, destination: url)
                .font(.subheadline)
                .lineLimit(1)
                .accessibilityIdentifier("captureLinkBareURL")
        }
    }

    private func linkPreviewCard(_ preview: CaptureLinkPreview) -> some View {
        HStack(alignment: .top, spacing: 8) {
            AsyncImage(url: preview.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .overlay(
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("captureLinkThumbnail")

            VStack(alignment: .leading, spacing: 4) {
                Text(preview.title ?? capture.content)
                    .font(.subheadline)
                    .lineLimit(1)
                if let description = preview.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .accessibilityIdentifier("captureLinkPreviewCard")
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

            tagEditor

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

    private var tagEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !currentTags.isEmpty {
                currentTagsRow
            }

            TextField("Add a tag", text: $tagQuery)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("captureTagSearchField")

            if !trimmedTagQuery.isEmpty {
                ForEach(filteredTagSuggestions) { tag in
                    Button(tag.name) {
                        let tagId = tag.id
                        Task {
                            await onAddExistingTag(tagId)
                            tagQuery = ""
                            currentTags = await onLoadTags()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("captureTagSuggestion-\(tag.name)")
                }
                if !tagQueryMatchesExistingTag {
                    Button("Create \"\(trimmedTagQuery)\"") {
                        let name = trimmedTagQuery
                        Task {
                            await onCreateTag(name)
                            tagQuery = ""
                            currentTags = await onLoadTags()
                            allTags = await onLoadAllTags()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("captureCreateTagButton")
                }
            }
        }
    }

    private var currentTagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(currentTags) { tag in
                    HStack(spacing: 4) {
                        Text(tag.name)
                            .font(.caption)
                        Button {
                            let tagId = tag.id
                            Task {
                                await onRemoveTag(tagId)
                                currentTags = await onLoadTags()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .accessibilityIdentifier("captureRemoveTagButton-\(tag.name)")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                }
            }
        }
        .accessibilityIdentifier("captureCurrentTagsRow")
    }

    private var trimmedTagQuery: String {
        tagQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredTagSuggestions: [Tag] {
        let currentTagIds = Set(currentTags.map(\.id))
        return allTags.filter {
            !currentTagIds.contains($0.id) && $0.name.localizedCaseInsensitiveContains(trimmedTagQuery)
        }
    }

    private var tagQueryMatchesExistingTag: Bool {
        allTags.contains { $0.name.localizedCaseInsensitiveCompare(trimmedTagQuery) == .orderedSame }
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
        }
    }
}

/// The Inbox promote form's primary action, extracted so its in-flight `@State` lives here rather
/// than swelling `CaptureRowView`. Full-width filled `PrimaryActionButtonStyle` (§3/§5); while a
/// promote is in flight the label becomes a progress indicator and the button disables, so a second
/// tap is a no-op at the UI layer (the service's in-flight guard is the concurrency backstop). A
/// successful create fires an `#available`-gated haptic; a failure does not.
private struct CreateTaskButton: View {
    let lifeAreaId: UUID?
    let priority: TaskPriority
    let dueDate: Date?
    let onCreateTask: (UUID?, TaskPriority, Date?) async -> Bool

    @State private var isCreatingTask = false
    @State private var successHapticTrigger = false

    var body: some View {
        Button {
            Task { await create() }
        } label: {
            if isCreatingTask {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.secondary)
                    Text("Creating Task…")
                }
            } else {
                Text("Create Task")
            }
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(isCreatingTask)
        .promoteSuccessHaptic(trigger: successHapticTrigger)
        .accessibilityIdentifier("captureCreateTaskButton")
    }

    private func create() async {
        isCreatingTask = true
        let succeeded = await onCreateTask(lifeAreaId, priority, dueDate)
        isCreatingTask = false
        if succeeded {
            successHapticTrigger.toggle()
        }
    }
}

/// The single, always-present 44×44 leading element every collapsed row gets. Extracted into its
/// own view so `CaptureRowView` stays within its type-body budget. Media rows keep their existing
/// thumbnail/playback control; link rows with a landed preview thumbnail render it; every other
/// kind gets a centred SF Symbol placeholder in a matching 10pt-radius tile.
private struct CaptureRowLeadingSlot: View {
    let capture: Capture

    var body: some View {
        switch capture.kind {
        case .photo:
            photoThumbnail
        case .voice:
            VoicePlaybackButton(url: capture.mediaURL)
        case .link where capture.linkPreview?.thumbnailURL != nil:
            linkThumbnail
        default:
            glyphSlot
        }
    }

    private var glyphSlot: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: CaptureRowPresentation.glyphSystemImageName(for: capture.kind))
                    .foregroundStyle(.secondary)
            )
    }

    private var photoThumbnail: some View {
        AsyncImage(url: capture.photoDisplayURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("capturePhotoThumbnail")
    }

    private var linkThumbnail: some View {
        AsyncImage(url: capture.linkPreview?.thumbnailURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private extension View {
    /// Tactile confirmation when a row expands/collapses (`CLAUDE.md` §3). `sensoryFeedback` is
    /// iOS 17+, while the app's deployment target is iOS 16, so it is applied only where available;
    /// on iOS 16 the row simply renders without the haptic rather than failing to build.
    @ViewBuilder
    func expandCollapseHaptic(trigger: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .solid), trigger: trigger)
        } else {
            self
        }
    }

    /// Success confirmation when a capture is promoted to a task (`CLAUDE.md` §3). `sensoryFeedback`
    /// is iOS 17+, so on iOS 16 the same `trigger` drives a `UIImpactFeedbackGenerator` via
    /// `.onChange` instead — the deployment target stays iOS 16.0 (§7). Fired only on success by the
    /// caller, so a failed create never buzzes as if it confirmed.
    @ViewBuilder
    func promoteSuccessHaptic(trigger: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .solid), trigger: trigger)
        } else {
            self.onChange(of: trigger) { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}

private struct VoicePlaybackButton: View {
    let url: URL?
    @StateObject private var player = VoiceCapturePlayer()

    var body: some View {
        Button {
            player.toggle(url: url)
        } label: {
            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .accessibilityIdentifier("captureVoicePlaybackButton")
    }
}
