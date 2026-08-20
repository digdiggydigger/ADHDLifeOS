//
//  CaptureInboxView.swift
//  ADHD LifeOS
//

import SwiftUI

/// The capture triage screen.
///
/// Design pass, 2026-08-20 — this was the last screen still carrying its pre-token layout. The
/// 2026-08-19 bento pass had explicitly deferred it ("deliberately still a `List`… rebuilding this
/// heavily-tested triage screen's container was judged out of scope for a styling pass"), and this
/// closes that deferral:
/// - §2: the stock `List` becomes `ScrollView` + `LazyVStack` of floating `.bentoCard()` rows, so
///   the screen matches Home and Tasks instead of reading as a settings table.
/// - The empty state was one grey line of text on a blank screen. An empty inbox is the WIN state
///   for an ADHD user, so it now says so and offers the next action instead of describing a void.
/// - A header summarises what is waiting (`CaptureInboxSummary`) before the user reads a row.
///
/// `CaptureRowView` moved to its own file untouched: its life-area revert race, superseded-PATCH
/// cancellation and accessibility-size reflow are hard-won and covered by tests. This block
/// restyled the container around the row, not the row's behaviour.
struct CaptureInboxView: View {
    @StateObject private var service: CaptureInboxService
    let lifeAreas: [LifeArea]
    /// Retained so the empty state can offer a capture action of its own — reaching the inbox and
    /// finding it empty is exactly when a user is most likely to want to put something in it.
    private let captureClient: CaptureClientAdapting
    @State private var expandedCaptureId: UUID?
    @State private var isPresentingQuickCapture = false

    init(client: CaptureClientAdapting, lifeAreas: [LifeArea]) {
        _service = StateObject(wrappedValue: CaptureInboxService(client: client))
        self.lifeAreas = lifeAreas
        self.captureClient = client
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("captureInboxLoadingIndicator")
            case .failed(let message):
                failedState(message)
            case .loaded(let captures):
                if captures.isEmpty {
                    emptyState
                } else {
                    loadedState(captures)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle("Inbox")
        .sheet(isPresented: $isPresentingQuickCapture) {
            QuickCaptureView(client: captureClient) {
                Task { await service.refresh() }
            }
        }
        .task {
            await service.load()
        }
    }

    // MARK: - States

    private func loadedState(_ captures: [Capture]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                summaryHeader(captures)

                ForEach(captures) { capture in
                    row(for: capture)
                        .bentoCard()
                }
            }
            .padding(16)
        }
        .refreshable {
            await service.refresh()
        }
    }

    private func summaryHeader(_ captures: [Capture]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(CaptureInboxSummary.headline(count: captures.count))
                .font(.title2.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
            let breakdown = CaptureInboxSummary.breakdown(for: captures)
            if !breakdown.isEmpty {
                Text(breakdown)
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("captureInboxSummary")
    }

    /// An empty inbox is the goal state, not an error and not a void — so it reads as an
    /// achievement and points at the one thing worth doing next.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            Text("Inbox clear")
                .font(.title2.bold())
                .tracking(-0.5)
            Text(
                "Nothing waiting to be triaged. Anything you capture lands here first, "
                    + "so your head doesn't have to hold it."
            )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Capture something") {
                isPresentingQuickCapture = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("captureInboxEmptyCaptureButton")
        }
        .padding(24)
        .frame(maxWidth: 420)
        .accessibilityIdentifier("captureInboxEmptyState")
    }

    private func failedState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Couldn't load your inbox", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again") {
                Task { await service.load() }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("captureInboxRetryButton")
        }
        .bentoCard()
        .padding(16)
        .accessibilityIdentifier("captureInboxErrorMessage")
    }

    // MARK: - Row

    private func row(for capture: Capture) -> some View {
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
    }
}
