//
//  PlaceRoutineScreen.swift
//  ADHD LifeOS
//
//  The routine screen (F-Routines-3, the canvas Main board): the crossing's steps as an
//  externalized checklist — the screen IS the working memory. One dominant next-step card,
//  auto steps pre-ticked, Undo over confirm everywhere, and coming back mid-routine is the
//  normal path: the list holds your place across every app-switch.
//
//  Presented as a fullScreenCover, so it sits ABOVE the capture disc and the tab bar — no
//  clearance calls, by design (the CaptureDiscClearanceCallSiteTests table stays untouched).
//  17-gated with the rest of the Places UI.
//

import SwiftUI

@available(iOS 17.0, *)
struct PlaceRoutineScreen: View {
    @State private var run: RoutineRun
    private let store: RoutineRunStoring
    private let onOpenTab: (AppTab) -> Void
    private let onStartSprint: (Int?) -> Void
    /// ActivityKit cannot START an Activity from the background, and the crossing arrives with
    /// the app backgrounded — so the routine's Live Activity begins HERE, when the screen
    /// opens, and ends when the run does. Injected so the screen stays testable and previewable.
    private let activity: RoutineActivityPresenting
    /// The routine RECORD (F-RoutineRecord-1): every step change and the completion go to
    /// Firestore from here, on a Task nothing on screen waits for.
    private let recorder: RoutineRunRecording
    /// Every deliberate exit ends the run itself and `onDisappear` does it again as a net,
    /// which is right for the idempotent local end and wrong for the record: the journey found
    /// the completion written TWICE. Recorded once.
    @State private var hasRecordedEnd = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        run: RoutineRun,
        store: RoutineRunStoring,
        onOpenTab: @escaping (AppTab) -> Void,
        onStartSprint: @escaping (Int?) -> Void,
        // NOT defaulted: `RoutineActivityPresenting` is `@MainActor`, and a default argument
        // is evaluated in a nonisolated context. Every call site names its presenter.
        activity: RoutineActivityPresenting,
        // NOT defaulted either: the default would be `FirebaseRoutineRunRecorder()`, which
        // reaches `FirebaseManager.shared` inside every preview. The door passes the real one.
        recorder: RoutineRunRecording
    ) {
        _run = State(initialValue: run)
        self.store = store
        self.onOpenTab = onOpenTab
        self.onStartSprint = onStartSprint
        self.activity = activity
        self.recorder = recorder
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                progress
                if !resolvedIndices.isEmpty {
                    resolvedCard
                }
                if let nextIndex = PlaceRoutineProgress.nextPendingIndex(run) {
                    nextCard(at: nextIndex)
                }
                if !upcomingIndices.isEmpty {
                    upcomingCard
                }
            }
            .padding(16)
        }
        .background(Color.pageBackground)
        .task { activity.started(run) }
        // A run can end UNDERNEATH this screen (its departure crossing, the window, the
        // sweep) — `updateMatching`/`end(runId:)` keep the store honest while the checklist
        // keeps serving the person holding it.
        // A SAFETY NET, not the mechanism: `onDisappear` did not fire reliably for this
        // cover (caught by the routine journey — a finished routine kept its Today card), so
        // every deliberate exit calls `leaveScreen()` itself. Idempotent, so both firing is
        // harmless and neither firing is impossible.
        .onDisappear { leaveScreen() }
        .onChange(of: scenePhase) { _, phase in
            // Leaving the app with everything resolved ends the run (the settled rule: the
            // run ends when you LEAVE the screen, not at the final tap — Undo lives until
            // then).
            if phase == .background, PlaceRoutineProgress.isFullyResolved(run) {
                leaveScreen()
                dismiss()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(PlaceRoutineScreenCopy.eyebrow)
                    .sectionLabel()
                Spacer()
                Button {
                    Haptics.play(.light)
                    leaveScreen()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(PlaceRoutineScreenCopy.momentTitle(for: run))
                    .font(.largeTitle).bold()
                    .tracking(-0.5)
                    .minimumScaleFactor(0.8)
                subline
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // Combined so the moment reads as ONE sentence — and scoped to the text alone.
            // Combining the row above would swallow the Close button into the header element,
            // leaving a full-screen cover with no way out for VoiceOver.
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("routineHeader")
        }
    }

    private var subline: Text {
        let moment = Text("\(PlaceRoutineScreenCopy.momentPrefix(for: run.direction)) ")
            + Text(run.startedAt, style: .relative)
            + Text(" ago")
        guard let message = run.customMessage else { return moment }
        return Text("\u{201C}\(message)\u{201D} · ") + moment
    }

    // MARK: - Progress

    private var progress: some View {
        HStack(spacing: 8) {
            ProgressView(value: PlaceRoutineProgress.resolvedFraction(run))
                .tint(Color.accentColor)
            Text(PlaceRoutineProgress.progressLabel(run))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .layoutPriority(1)
        }
        // Combining would otherwise read the bar's raw percentage beside the words; the
        // label IS the sentence, and the journey asserts on exactly it.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(PlaceRoutineProgress.progressLabel(run))
        .accessibilityIdentifier("routineProgress")
    }

    // MARK: - Cards

    private var resolvedIndices: [Int] {
        run.steps.indices.filter { run.steps[$0].state != .pending }
    }

    private var upcomingIndices: [Int] {
        guard let next = PlaceRoutineProgress.nextPendingIndex(run) else { return [] }
        return run.steps.indices.filter { $0 > next && run.steps[$0].state == .pending }
    }

    private var resolvedCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(resolvedIndices, id: \.self) { index in
                PlaceRoutineResolvedRow(
                    step: run.steps[index],
                    onUndo: {
                        Haptics.play(.light)
                        apply(.pending, at: index)
                    }
                )
            }
        }
        .bentoCard()
    }

    private func nextCard(at index: Int) -> some View {
        let step = run.steps[index]
        let title = PlaceActionRowLabel.title(for: step.action)
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(PlaceRoutineScreenCopy.nextEyebrow(stepNumber: index + 1, of: run.steps.count))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .tracking(0.5)
                Text(title)
                    .font(.title2).bold()
                    .minimumScaleFactor(0.8)
            }
            Button(title) {
                Haptics.play(.solid)
                perform(step.action, at: index)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            Button {
                Haptics.play(.light)
                apply(.skipped, at: index)
            } label: {
                Text(PlaceRoutineScreenCopy.skipLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .bentoCard()
    }

    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(upcomingIndices, id: \.self) { index in
                PlaceRoutineUpcomingRow(
                    step: run.steps[index],
                    stepNumber: index + 1,
                    total: run.steps.count
                )
            }
        }
        .bentoCard()
    }

    // MARK: - Behaviour

    private func apply(_ state: RoutineStepState, at index: Int) {
        let updated = PlaceRoutineProgress.marking(run, stepAt: index, as: state)
        guard updated != run else { return }
        withAnimation(
            reduceMotion
                ? nil : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
        ) {
            run = updated
        }
        // Write-through ONLY while this run is still the live one — a run that ended
        // underneath us must stay gone, and this checklist keeps working locally either way.
        _ = store.updateMatching(updated)
        record { try await recorder.progressed(updated, at: .now) }
        activity.updated(updated)
    }

    /// The record writes ride a Task nothing on screen waits for, and a failure is dropped:
    /// the checklist keeps serving the person holding it whether or not Firestore answered.
    private func record(_ write: @escaping @Sendable () async throws -> Void) {
        Task { try? await write() }
    }

    /// Done-on-tap (the settled semantics): tapping the step IS running it — iOS offers no
    /// verification a design could wait on. Foreground button taps carry their own open
    /// attribution, so the 0c65ca5 fragility never applies here.
    private func perform(_ action: PlaceAction, at index: Int) {
        apply(.done, at: index)
        guard let route = PlaceActionTapRoute.route(for: action) else { return }
        switch route {
        case .open(let url):
            let title = PlaceActionRowLabel.title(for: action)
            openExternally(
                url,
                failureBody: "\u{201C}\(title)\u{201D} didn't work — the app may not be installed."
            )
        case .goToScreen(let screen):
            dismiss()
            onOpenTab(screen.appTab)
        case .startSprint(let minutes):
            // The sprint starts from a FOREGROUND tap — ActivityKit's requirement, and the
            // reason startSprint is a tap-step at all. The screen stays up: the routine is
            // the memory, and the timer bar is there when it closes.
            onStartSprint(minutes)
        }
    }

    private func openExternally(_ url: URL, failureBody: String) {
        PlaceLinkOpener(
            open: { url, universalLinksOnly, completion in
                UIApplication.shared.open(
                    url,
                    options: universalLinksOnly ? [.universalLinksOnly: true] : [:],
                    completionHandler: completion
                )
            },
            notifyFailure: { body in
                Task {
                    await NotificationCenterImmediateNotifier().post(
                        title: "That didn't open", body: body,
                        identifier: "placeActionOpenFailure"
                    )
                }
            }
        ).run(PlaceLinkOpenPlan.plan(for: url), failureBody: failureBody)
    }

    /// Leaving the screen is the moment a finished run ENDS — not the final tap, which is
    /// what keeps Undo available until then. Idempotent: `end(runId:)` only matches the run
    /// this screen owns, so calling it twice, or after a newer run replaced this one, is a
    /// no-op. Always announces, so Today re-reads whether the run ended or merely moved on.
    private func leaveScreen() {
        if PlaceRoutineProgress.isFullyResolved(run), !hasRecordedEnd {
            hasRecordedEnd = true
            store.end(runId: run.id)
            record { try await recorder.ended(runId: run.id, reason: .completed, at: .now) }
        }
        // The Activity is the SCREEN's, not the run's: it cannot be restarted from the
        // background, so leaving without it would strand a card nothing could ever update.
        activity.ended()
        DataChangeSignal.post()
    }
}

#if DEBUG
/// Preview scaffolding only. Built outside the `#Preview` body because a result-builder
/// closure cannot carry an explicit `return`, and the fixture needs a mutation.
@available(iOS 17.0, *)
enum PlaceRoutineScreenPreviewFixture {
    static var run: RoutineRun {
        let gymId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day")),
            PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: "snapchat", displayName: "Snapchat")
            ),
            PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: "gym", displayName: "Gym")
            ),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openLink(
                displayName: "Gym Music on Spotify",
                link: "https://open.spotify.com/playlist/abc", scheme: "spotify"
            ))
        ]
        var run = RoutineRun.make(
            event: PlaceTriggerEvent(
                placeId: gymId, kind: .arrival, occurredAt: .now.addingTimeInterval(-120)
            ),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: "Time to train", actions: actions,
                latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: .arrival)
        )
        // One tapped step, so the preview shows the Undo chip and a part-filled bar.
        run.steps[1].state = .done
        return run
    }
}

@available(iOS 17.0, *)
#Preview("Routine — light and dark") {
    HStack(spacing: 0) {
        PlaceRoutineScreen(
            run: PlaceRoutineScreenPreviewFixture.run,
            store: UserDefaultsRoutineRunStore(defaults: nil),
            onOpenTab: { _ in }, onStartSprint: { _ in },
            activity: InertRoutineActivityPresenter(),
            recorder: InertRoutineRunRecorder()
        )
        .environment(\.colorScheme, .light)
        PlaceRoutineScreen(
            run: PlaceRoutineScreenPreviewFixture.run,
            store: UserDefaultsRoutineRunStore(defaults: nil),
            onOpenTab: { _ in }, onStartSprint: { _ in },
            activity: InertRoutineActivityPresenter(),
            recorder: InertRoutineRunRecorder()
        )
        .environment(\.colorScheme, .dark)
    }
}
#endif
