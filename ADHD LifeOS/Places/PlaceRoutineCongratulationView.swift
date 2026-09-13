//
//  PlaceRoutineCongratulationView.swift
//  ADHD LifeOS
//
//  The routine Completed flow's congratulation (`F-CTACelebrations-6`, E's R3–R5 and answers
//  1–9). E overruled "close the screen and celebrate over the app": the screen's own body is
//  REPLACED by this, the celebration plays over it on the cover's own layer, and it leaves by
//  itself when the confetti ends or on a tap anywhere.
//
//  **E reversed R5's auto-leave on 2026-09-13**, once the screen had grown a scrollable step
//  list, four clock times, per-step durations and a comparison: it now STAYS UNTIL DISMISSED.
//  So there is no timer here, and `PlaceRoutineCompletionCopy.closeHint` is load-bearing — with
//  nothing to time the view out, a user who cannot find the way out is stuck.
//
//  **The leaf carries no motion of its own, and that is load-bearing rather than tidy.** The
//  entrance is the SCREEN's decision (`PlaceRoutineCongratulationEntrance`, resolved from
//  Reduce Motion and applied as the ZStack branch's `.transition`), so this view has no first
//  frame for §7.2's opening-pose rule to be wrong in, and a render of it is deterministic
//  evidence rather than a photograph of one moment.
//

import SwiftUI

@available(iOS 17.0, *)
struct PlaceRoutineCongratulationView: View {
    let run: RoutineRun
    /// E's R4: the ACCOUNT display name, the one Settings' account row shows. `nil` is ordinary
    /// — email/password sign-up does not require a name — and the greeting simply drops it.
    let displayName: String?
    /// Captured ONCE by the screen at the Completed tap and passed in. Read from `body` as
    /// `.now` it would tick, and since E reversed R5 this view can be on screen indefinitely.
    let confirmedAt: Date
    /// Never defaulted: `FirebaseRoutineRunHistoryAdapter()` reaches `FirebaseManager.shared`,
    /// which is the reason the screen's recorder is not defaulted either. The door passes the
    /// real one; previews and tests pass `InertRoutineRunHistoryReader`.
    let history: RoutineRunHistoryReading
    let onClose: () -> Void

    @State private var records: [RoutineRunRecord]?

    var body: some View {
        let density = PlaceRoutineCongratulationDensity.forStepCount(run.steps.count)
        let timeline = PlaceRoutineRunTimeline.make(run: run, confirmedAt: confirmedAt)
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(PlaceRoutineCompletionCopy.greeting(for: displayName))
                    .font(.largeTitle).bold()
                    .tracking(-0.5)
                    .minimumScaleFactor(0.8)
                    .accessibilityIdentifier("routineCongratulationGreeting")
                Text(PlaceRoutineCompletionCopy.summary(for: run))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.8)
            }
            // E's placement answer: pinned here, ABOVE the scroller. Inside it, a twenty-step
            // routine would hide the times behind the very scrolling they must survive.
            PlaceRoutineCongratulationDetails(
                timeline: timeline,
                comparison: PlaceRoutineComparison.verdict(
                    worked: timeline.workedDuration, history: records ?? [],
                    placeId: run.placeId, direction: run.direction, excluding: run.id
                )
            )
            // E's answer 2: the per-step list, so the count above can be checked against the
            // thing it counts. E REVERSED answer 6's "no scrolling" on 2026-09-13 — overflow
            // scrolls rather than clipping. A DRAG goes to the scroller and a TAP to the
            // parent's gesture, so tap-to-close survives; the journey taps a row to prove it.
            ScrollView {
                VStack(alignment: .leading, spacing: density.rowSpacing) {
                    let durations = PlaceRoutineStepDuration.durations(for: run)
                    ForEach(run.steps.indices, id: \.self) { index in
                        stepRow(run.steps[index], took: durations[index], density: density)
                    }
                }
            }
            .scrollIndicators(.visible)
            Text(PlaceRoutineCompletionCopy.closeHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(wash)
        // R5 as E reversed it: a tap anywhere closes, and nothing else does.
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .accessibilityAction(named: Text(PlaceRoutineCompletionCopy.closeAction), onClose)
        .task {
            // A failure leaves `records` empty, which reads as "no history" and draws nothing —
            // the comparison is a bonus, never a reason for this screen to look broken.
            records = (try? await history.fetchRoutineRuns()) ?? []
        }
    }

    /// E's answer 9: the routine screen's EXISTING row glyphs, reused rather than re-drawn —
    /// accent circle and `checkmark` for done *and* auto-done, `cardBorder` circle and `minus`
    /// for skipped. E ruled out a cross by name: the app uses `xmark` only as a Close button,
    /// so one here would read as "dismiss this" instead of "you skipped it".
    ///
    /// E's answer 4: what tells a tapped step from an automatic one is the WORD, never a second
    /// glyph and never colour alone. E's 2026-09-13 addition puts the step's own duration
    /// beside that word.
    private func stepRow(
        _ step: RoutineRun.Step, took duration: TimeInterval?,
        density: PlaceRoutineCongratulationDensity
    ) -> some View {
        HStack(spacing: 8) {
            PlaceRoutineStepCircle(state: step.state, size: density.circleSize)
            Text(PlaceActionRowLabel.title(for: step.action))
                .font(.subheadline)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(stateAndDuration(step, took: duration))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }

    private func stateAndDuration(_ step: RoutineRun.Step, took duration: TimeInterval?) -> String {
        let word = PlaceRoutineCompletionCopy.stateWord(for: step.state)
        guard let duration else { return word }
        return "\(word) · \(PlaceRoutineTimeFormatting.duration(duration))"
    }

    /// The done-green wash E's R3 asked for, under the page colour.
    ///
    /// **It is static, and it is the view's own.** On the full-screen path the cover's
    /// celebration layer also draws `ConfirmCelebrationGlow` — but that one is GONE BY 2.4 s of
    /// a 5.4 s celebration, so without this the screen would go flat afterwards; and on E's
    /// quiet beat no full-screen burst exists at all, so the layer draws nothing and this wash
    /// is the only colour the moment has.
    private var wash: some View {
        ZStack {
            Color.pageBackground
            RadialGradient(
                colors: [
                    Color(ConfirmCelebrationGlow.colorName).opacity(Self.washOpacity),
                    Color(ConfirmCelebrationGlow.colorName).opacity(0)
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: ConfirmCelebrationGlow.radius
            )
        }
        .ignoresSafeArea()
    }

    /// Deliberately under the layer glow's own 0.32 peak: for the first 2.4 s of a full
    /// celebration the two are added together. **E is picking this value by sight** (the ladder
    /// sent 2026-09-13); this is the shipped default until they do.
    private static let washOpacity: Double = 0.14
}

#if DEBUG
@available(iOS 17.0, *)
enum PlaceRoutineCongratulationPreviewFixture {
    /// A real spread of action KINDS, not eight `openApp`s: `PlaceActionRowLabel` prefixes
    /// "Open " to an app action, so a fixture of nothing but apps renders "Open Open Snapchat"
    /// and every render becomes a picture of the fixture's bug rather than of the view. Caught
    /// by looking at the first render, which is what renders are for.
    private static let kinds: [PlaceAction.Kind] = [
        .journalLine(body: "Leg day"),
        .openApp(scheme: "snapchat", displayName: "Snapchat"),
        .startSprint(minutes: 25),
        .openLink(
            displayName: "Gym Music on Spotify",
            link: "https://open.spotify.com/playlist/abc", scheme: "spotify"
        ),
        .openApp(scheme: "strava", displayName: "Strava"),
        .textContact(contactName: "Sam", phoneNumber: "+447000000000", messageBody: "Heading home"),
        .createCapture(text: "New bench PB"),
        .openApp(scheme: "notes", displayName: "Notes")
    ]

    static func run(steps: Int, name: String = "Gym 🏋️") -> RoutineRun {
        let states: [RoutineStepState] = [.autoDone, .done, .skipped, .done]
        return RoutineRun(
            id: UUID(), placeId: UUID(), direction: .arrival,
            startedAt: .now.addingTimeInterval(-1_800),
            displayName: name, customMessage: nil,
            steps: (0..<steps).map { index in
                RoutineRun.Step(
                    action: PlaceAction(
                        id: UUID(), direction: .arrival, kind: kinds[index % kinds.count]
                    ),
                    state: states[index % states.count]
                )
            }
        )
    }
}

@available(iOS 17.0, *)
#Preview("Congratulation — light and dark") {
    HStack(spacing: 0) {
        PlaceRoutineCongratulationView(
            run: PlaceRoutineCongratulationPreviewFixture.run(steps: 4),
            displayName: "Ethan", confirmedAt: .now,
            history: InertRoutineRunHistoryReader(), onClose: {}
        )
        .environment(\.colorScheme, .light)
        PlaceRoutineCongratulationView(
            run: PlaceRoutineCongratulationPreviewFixture.run(steps: 4),
            displayName: "Ethan", confirmedAt: .now,
            history: InertRoutineRunHistoryReader(), onClose: {}
        )
        .environment(\.colorScheme, .dark)
    }
}

@available(iOS 17.0, *)
#Preview("Congratulation — 20 steps, and no display name") {
    HStack(spacing: 0) {
        PlaceRoutineCongratulationView(
            run: PlaceRoutineCongratulationPreviewFixture.run(steps: 20),
            displayName: "Ethan", confirmedAt: .now,
            history: InertRoutineRunHistoryReader(), onClose: {}
        )
        .environment(\.colorScheme, .light)
        PlaceRoutineCongratulationView(
            run: PlaceRoutineCongratulationPreviewFixture.run(steps: 4),
            displayName: nil, confirmedAt: .now,
            history: InertRoutineRunHistoryReader(), onClose: {}
        )
        .environment(\.colorScheme, .dark)
    }
}
#endif
