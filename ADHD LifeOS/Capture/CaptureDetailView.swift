//
//  CaptureDetailView.swift
//  ADHD LifeOS
//
//  The full-screen capture detail (design frame B6, 2026-08-23), replacing the Inbox row's inline
//  accordion: a dedicated place where one capture's content, filing and exits all fit without
//  fighting a list for room. Pushed with an ID and re-fetching (`TaskDetailView` precedent), so it
//  always shows the server's document rather than a possibly stale row.
//

import SwiftUI

struct CaptureDetailView: View {
    let captureId: UUID
    let lifeAreas: [LifeArea]
    /// The pushing screen's own service instance, shared so every action here (promote with its
    /// concurrency and retry guards, archive, discard) mutates the list the user pops back to.
    @ObservedObject var service: CaptureInboxService

    enum ViewState {
        case loading
        case loaded(Capture)
        case failed(String)
    }

    @State private var state: ViewState = .loading
    /// The Filed-in card's picker value, owned here because the promote sheet inherits it.
    @State private var selectedLifeAreaId: UUID?
    @State private var isPresentingPromoteSheet = false
    @State private var isConfirmingDiscard = false
    @State private var isPresentingPhoto = false
    @State private var isSorting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("captureDetailLoadingIndicator")
            case .failed(let message):
                failedState(message)
            case .loaded(let capture):
                loadedContent(capture)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await load() }
    }

    // MARK: - States

    private func load() async {
        state = .loading
        do {
            let capture = try await service.fetchCaptureDetail(id: captureId)
            selectedLifeAreaId = capture.lifeAreaId
            state = .loaded(capture)
        } catch {
            state = .failed(CaptureInboxService.message(for: error))
        }
    }

    private func loadedContent(_ capture: Capture) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                contentCard(capture)
                CaptureDetailNotesEditor(capture: capture) { text in
                    guard let updated = await service.saveNotes(capture: capture, notes: text) else {
                        return nil
                    }
                    state = .loaded(updated)
                    return updated
                }
                filedInSection(capture)
                actionsRow(capture)
            }
            .padding(16)
        }
        .sheet(isPresented: $isPresentingPromoteSheet) {
            CapturePromoteSheet(
                capture: capture,
                lifeAreaId: selectedLifeAreaId,
                service: service,
                onPromoted: { dismiss() }
            )
            .keyboardDismissal()
        }
        .fullScreenCover(isPresented: $isPresentingPhoto) {
            CapturePhotoLightbox(
                url: capture.photoDisplayURL,
                title: CaptureRowPresentation.primaryText(for: capture)
            )
        }
        .confirmationDialog(
            "Discard this capture?",
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                Task {
                    if await service.discard(capture: capture) { dismiss() }
                }
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("It won't become a task or a journal entry. This can't be undone.")
        }
        .accessibilityIdentifier("captureDetailView")
    }

    /// Extracted for the same reason `contentCard` was — the loaded body's 50-line budget. The
    /// Sorted button's availability is resolved here, one place, from the Filed-in card's picker.
    private func actionsRow(_ capture: Capture) -> some View {
        CaptureDetailActions(
            capture: capture,
            canSort: CaptureDetailPresentation.canSort(selectedLifeAreaId: selectedLifeAreaId),
            isSorting: isSorting,
            onMakeTask: { isPresentingPromoteSheet = true },
            onSort: { Task { await sortCapture(capture) } }
        )
    }

    private func filedInSection(_ capture: Capture) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filed in")
                .sectionLabel()
                .foregroundStyle(.secondary)
            CaptureFiledInCard(
                capture: capture,
                lifeAreas: lifeAreas,
                selectedLifeAreaId: $selectedLifeAreaId,
                triageErrorMessage: service.triageErrorMessage,
                onSetLifeArea: { lifeAreaId in
                    let committed = await service.updateLifeArea(capture: capture, lifeAreaId: lifeAreaId)
                    if committed {
                        // This screen holds its own re-fetched copy, and `sort` reads its
                        // `lifeAreaId` to record what undo should put back. Left stale, undoing a
                        // sort would restore the area the picker had ALREADY replaced.
                        var updated = capture
                        updated.lifeAreaId = lifeAreaId
                        state = .loaded(updated)
                    }
                    return committed
                },
                onLoadTags: { await service.fetchTags(for: capture) },
                onLoadAllTags: { await service.fetchAllTags() },
                onAddExistingTag: { tagId in _ = await service.addExistingTag(capture: capture, tagId: tagId) },
                onCreateTag: { name in _ = await service.createAndAddTag(capture: capture, name: name) },
                onRemoveTag: { tagId in _ = await service.removeTag(capture: capture, tagId: tagId) }
            )
        }
    }

    private func failedState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Couldn't load this capture", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color("StateWarn"))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again") {
                Task { await load() }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("captureDetailRetryButton")
        }
        .bentoCard()
        .padding(16)
        .accessibilityIdentifier("captureDetailErrorMessage")
    }

    // MARK: - Actions

    /// **Sorted**, from the detail screen — the same one write the triage card makes, through the
    /// same `sort(capture:into:)`, so the area, the `seen` flag and the exit stamp land together
    /// and this screen cannot mint a sorted-but-unfiled capture (A3). Routing through it rather
    /// than keeping a second writer also means an accidental tap here is now undoable, like one
    /// on the card.
    private func sortCapture(_ capture: Capture) async {
        guard !isSorting, let lifeAreaId = selectedLifeAreaId else { return }
        isSorting = true
        defer { isSorting = false }
        if await service.sort(capture: capture, into: lifeAreaId) {
            dismiss()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if case .loaded(let capture) = state {
            ToolbarItem(placement: .principal) {
                Text(CaptureDetailPresentation.navTitle(for: capture.kind))
                    .font(.headline)
                    .accessibilityIdentifier("captureDetailKindLabel")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                overflowMenu(capture)
            }
        }
    }

    /// The exits that aren't the screen's primary pair. "Log to journal" keeps the one-tap
    /// behaviour with the composer's default energy/mood — the accordion's adjustable strip has no
    /// home in the B6 layout, dropped deliberately and flagged in the block report.
    private func overflowMenu(_ capture: Capture) -> some View {
        Menu {
            Button {
                Task {
                    if await service.logToJournal(
                        capture: capture, energyLevel: .medium, moodEmoji: JournalMood.defaultEmoji
                    ) {
                        dismiss()
                    }
                }
            } label: {
                Label("Log to journal", systemImage: "book")
            }
            if CaptureDetailPresentation.canReturnToInbox(capture) {
                Button {
                    Task {
                        if await service.undoSeen(capture: capture) { dismiss() }
                    }
                } label: {
                    Label("Move back to Inbox", systemImage: "tray.and.arrow.up")
                }
            }
            Divider()
            Button(role: .destructive) {
                isConfirmingDiscard = true
            } label: {
                Label("Discard", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("More actions")
        .accessibilityIdentifier("captureDetailMenuButton")
    }

    /// Extracted only to keep the loaded body inside its 50-line budget — passing `places`
    /// three-lines-wide was what tipped it over.
    private func contentCard(_ capture: Capture) -> some View {
        CaptureDetailContentCard(
            capture: capture,
            places: service.places,
            onOpenPhoto: { isPresentingPhoto = true }
        )
    }

}
