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
    /// E's R4: the greeting says the ACCOUNT display name, the one Settings' account row shows.
    /// Defaulted, because `nil` is ordinary — email/password sign-up does not require a name —
    /// which is exactly why `RoutineRecordCallSiteTests` has to read the DOOR for it: a door
    /// that forgot to pass it would compile and greet everyone anonymously forever.
    private let displayName: String?
    /// The congratulation's "compare to your usual" line reads the record back through this.
    private let history: RoutineRunHistoryReading
    /// Guards against a second ending: the Completed tap is the only thing that writes one, and
    /// the journey once found a completion written TWICE. Recorded once.
    @State private var hasRecordedEnd = false
    /// Non-nil from the Completed tap onwards, which is both the moment the congratulation
    /// shows and the moment it displays. **Captured once, never read as `.now` from `body`:**
    /// E reversed R5's auto-leave, so this view can sit on screen indefinitely and a live clock
    /// would tick its four times apart in front of the reader.
    @State private var confirmedAt: Date?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.celebrate) private var celebrate

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
        recorder: RoutineRunRecording,
        displayName: String? = nil,
        // NOT defaulted for the recorder's exact reason: `FirebaseRoutineRunHistoryAdapter()`
        // reaches `FirebaseManager.shared`. Previews pass `InertRoutineRunHistoryReader()`.
        history: RoutineRunHistoryReading
    ) {
        _run = State(initialValue: run)
        self.store = store
        self.onOpenTab = onOpenTab
        self.onStartSprint = onStartSprint
        self.activity = activity
        self.recorder = recorder
        self.displayName = displayName
        self.history = history
    }

    /// **A `ZStack`, and it is load-bearing rather than stylistic.** A `Group` re-runs `.task`
    /// when its branch changes, which would restart the Live Activity moments after
    /// `complete()` ended it — and no test could see that, because the Activity guards only
    /// assert the `.task` string exists. So the lifecycle hangs on the stack and the branches
    /// carry nothing but their transition.
    var body: some View {
        ZStack {
            if let confirmedAt {
                PlaceRoutineCongratulationView(
                    run: run, displayName: displayName, confirmedAt: confirmedAt,
                    history: history, onClose: { leaveScreen(); dismiss() }
                )
                .transition(entrance.transition)
            } else {
                checklist
                    .transition(entrance.transition)
            }
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
        //
        // **It no longer ENDS the run, and the scenePhase hook that used to is gone.** Under
        // E's R1 only the Completed tap finishes a routine, so backgrounding a fully-resolved
        // checklist must leave it exactly where it was — finishing it there would end a run
        // the user never confirmed, silently, from another app.
        .onDisappear { leaveScreen() }
    }

    /// §7.2, resolved HERE rather than in the leaf: `accessibilityReduceMotion` cannot be
    /// injected through `.environment(\.)`, so the leaf takes what it needs as parameters and
    /// the one decision lives at the one place that reads the setting.
    private var entrance: PlaceRoutineCongratulationEntrance {
        PlaceRoutineCongratulationEntrance.resolve(reduceMotion: reduceMotion)
    }

    private var checklist: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                progress
                if !resolvedIndices.isEmpty {
                    resolvedCard
                }
                if let nextIndex = PlaceRoutineProgress.nextPendingIndex(run) {
                    nextCard(at: nextIndex)
                } else if PlaceRoutineProgress.isFullyResolved(run) {
                    // E's R2: the Completed card takes the slot the next step would have had,
                    // never a place beside it — a card offering to finish a routine while a
                    // live step is still pending is the one shape R1 cannot allow.
                    PlaceRoutineCompletedCard(run: run, onComplete: complete(from:))
                }
                if !upcomingIndices.isEmpty {
                    upcomingCard
                }
            }
            .padding(16)
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
                PlaceRoutineSubline.text(for: run)
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
            CelebrationPopSource { handle in
                Button(title) {
                    Haptics.play(.solid)
                    handle.pop()
                    perform(step.action, at: index)
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
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

    /// **The Completed tap, and it is the ONLY thing that finishes a routine** (E's R1,
    /// unprompted: *"the user must have to confirm by manually tapping a 'Completed' button
    /// before any actions such as logging it to the Journal or running the animation etc are
    /// run"*). Resolving every step and closing the screen leaves the run live and its card on
    /// Today, which is what the reversed journey now asserts.
    ///
    /// No haptic here: `PlaceRoutineCompletedCard` plays `.success` on the button itself, where
    /// the press is, and a second one would be a double buzz.
    ///
    /// **One `Date` for both writes.** The record's timestamp and the "Confirmed" line the
    /// reader sees are the same moment, so the Journal row and the screen cannot disagree by
    /// the width of a Task hop.
    private func complete(from origin: CGPoint?) {
        guard !hasRecordedEnd else { return }
        hasRecordedEnd = true
        let now = Date.now
        store.end(runId: run.id)
        record { try await recorder.ended(runId: run.id, reason: .completed, at: now) }
        // The Activity is the SCREEN's and the run is over, so it goes now rather than at the
        // dismiss — leaving a live card for a routine that has already been congratulated.
        activity.ended()
        DataChangeSignal.post()
        withAnimation(entrance.animation) { confirmedAt = now }
        // R-f decides whether this becomes confetti or a quiet pop; the origin is the Completed
        // button's own measured centre, handed up by the card.
        celebrate.request(.milestone(.routineFinished), at: origin)
    }

    /// Leaving the screen is no longer the moment a run ends — E's R1 moved that to the tap
    /// above, and this now only tidies up after the screen itself. Idempotent and always
    /// announcing, so Today re-reads whether the run ended or is merely waiting to be finished.
    private func leaveScreen() {
        // The Activity is the SCREEN's, not the run's: it cannot be restarted from the
        // background, so leaving without it would strand a card nothing could ever update.
        activity.ended()
        DataChangeSignal.post()
    }
}
