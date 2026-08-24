//
//  MomentumScoreboardViews.swift
//  ADHD LifeOS
//
//  Home's Momentum scoreboard sections in the v3 handoff's language (F-V3-Today, 2026-08-24):
//  the closure ring is green — the State palette's "closed" — the streak line names the best-ever
//  run after a close, the life areas render as rows with their identity hue's tint well and
//  progress bar, and the celebration is a green-washed moment with Undo one tap away. Spacing is
//  snapped to the §2 grid (v3's 20/22px rhythm → 16/24); every colour is a catalog token.
//

import SwiftUI

/// Track + progress arc + whatever belongs in the middle. The same ring draws at 126pt for the
/// day, 52pt per area and 64pt for the focus sprint (S4), so all three read as one instrument.
struct ClosureRing<Center: View>: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    /// What the arc strokes in — accent by default. Today's ring hands in the closure green; the
    /// sprint ring hands in a muted style while paused.
    var arcStyle = AnyShapeStyle(Color.accentColor)
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("TrackNeutral"), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    arcStyle,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            center()
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: progress)
    }
}

/// v3's solid 54pt action button — full width, 14pt corners, pressed scale per §3. The caller
/// names the fill and its on-colour; raw opacity states are prohibited, so pressing scales.
struct MomentumSolidButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.bold())
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// v3's bordered secondary — the quiet counterpart under a solid button.
struct MomentumBorderedButtonStyle: ButtonStyle {
    var minHeight: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(Color("LabelSecondary"))
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// v3's chip: small semibold text on a rounded tint. Colours come from the caller because the
/// chip's meaning does — solid blue for effort ("in motion"), an area's tint for identity,
/// surface-secondary for quiet metadata.
struct MomentumChip: View {
    let text: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(foreground)
    }
}

/// The scoreboard header: today's closure ring beside the streak (or, with no streak alive, the
/// honest "still open" counterweight — nothing here ever counts a miss). v3 draws this naked on
/// the page, not in a card, and paints the counts green the moment something closes today.
struct MomentumRingCard: View {
    let closedToday: Int
    let goal: Int
    let streak: Int
    /// Best-ever run, derived from history — named in the streak line after a close.
    let bestStreak: Int
    let openCount: Int
    /// Trailing seven days, oldest first — the dot row.
    let weekFlags: [Bool]
    /// The shortest due task's effort ("15 min"), feeding the counterweight line.
    let nextEffortLabel: String?

    private var countColor: Color {
        closedToday > 0 ? Color("StateGo") : Color("LabelPrimary")
    }

    var body: some View {
        HStack(spacing: 16) {
            ClosureRing(
                progress: MomentumScoreboard.ringProgress(closed: closedToday, goal: goal),
                size: 126,
                lineWidth: 10,
                arcStyle: AnyShapeStyle(Color("StateGoVivid"))
            ) {
                VStack(spacing: 0) {
                    Text("\(closedToday)")
                        .font(.largeTitle.bold())
                        .tracking(-1)
                        .monospacedDigit()
                        .foregroundStyle(countColor)
                    Text("of \(goal) closed")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                if streak > 0 {
                    Text("Streak")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streak)")
                            .font(.title.bold())
                            .tracking(-1)
                            .monospacedDigit()
                            .foregroundStyle(countColor)
                        Text(streak == 1 ? "day" : "days")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    dotRow
                    Text(MomentumScoreboard.streakLine(streak: streak, best: bestStreak, closedToday: closedToday))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Still open")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(openCount)")
                            .font(.title.bold())
                            .tracking(-1)
                            .monospacedDigit()
                        Text(openCount == 1 ? "item" : "items")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text(nextEffortLabel.map { "One of them is \($0)." } ?? "Close one to start a streak.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("homeMomentumRing")
    }

    private var dotRow: some View {
        HStack(spacing: 4) {
            ForEach(Array(weekFlags.enumerated()), id: \.offset) { _, closed in
                Circle()
                    .fill(closed ? Color("StateGoVivid") : Color("TrackNeutralStrong"))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }
}

/// The one task Home leads with. v3's card: effort in solid motion-blue, the area in its tint,
/// the due chip in warn, and one green full-width close. Start-session stays underneath — the
/// sprint funnel is this app's, not the mock's, and it must not vanish (hybrid adaptation).
struct BestNextMoveCard: View {
    let task: TaskSummary
    let lifeArea: LifeArea?
    let isDueNow: Bool
    let isClosing: Bool
    let showsStartSession: Bool
    let onClose: () -> Void
    let onStartSession: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best next move")
                .sectionLabel()
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                        // Solid motion-blue: effort is a promise of minutes, and blue carries
                        // "in motion" in the State palette. Accent IS the work hue, so its
                        // on-colour is the right constant white.
                        MomentumChip(
                            text: effort,
                            background: .accentColor,
                            foreground: AreaPalette.work.onColor
                        )
                    }
                    if let lifeArea {
                        areaChip(lifeArea)
                    }
                    if isDueNow {
                        MomentumChip(
                            text: "due today",
                            background: Color("CardSurfaceSecondary"),
                            foreground: Color("StateWarn")
                        )
                    }
                }
                Text(task.title)
                    .font(.title3.bold())
                    .tracking(-0.5)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Button(action: onClose) {
                    if isClosing {
                        ProgressView()
                            .tint(Color("OnStateGo"))
                    } else {
                        Label("Close it", systemImage: "checkmark.circle.fill")
                    }
                }
                .buttonStyle(MomentumSolidButtonStyle(fill: Color("StateGo"), foreground: Color("OnStateGo")))
                .disabled(isClosing)
                .accessibilityIdentifier("homeCloseTaskButton")
                if showsStartSession {
                    Button(action: onStartSession) {
                        Label("Start session", systemImage: "play.fill")
                    }
                    .buttonStyle(MomentumBorderedButtonStyle())
                    .accessibilityIdentifier("homeStartSessionButton")
                }
            }
            .bentoCard()
        }
        .accessibilityIdentifier("homeBestNextMoveCard")
    }

    private func areaChip(_ area: LifeArea) -> some View {
        let family = AreaPalette.family(for: area)
        return MomentumChip(
            text: "\(area.colour) \(area.name)",
            background: family.tint,
            foreground: family.color
        )
    }
}

/// The moment after a close: v3's green-washed card — named win, the day's ordinal with the
/// area's weekly rate, Undo and the priced next move. Undo matters because Close-it lives one
/// tap from the scoreboard — reversibility is what makes that tap safe.
struct ClosureCelebrationCard: View {
    let taskTitle: String
    /// "Third today. Admin & Home is up to 75% this week." — built by the caller from
    /// `MomentumScoreboard.celebrationLine`.
    let line: String
    /// "Next: 15 min" — the next best move's price, from `nextButtonLabel`.
    let nextLabel: String
    let onUndo: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color("StateGo"))
            Text("\(taskTitle) — closed")
                .font(.title3.bold())
                .tracking(-0.5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Button("Undo", action: onUndo)
                    .buttonStyle(MomentumBorderedButtonStyle(minHeight: 44))
                    .accessibilityIdentifier("homeUndoCloseButton")
                Button(nextLabel, action: onNext)
                    .buttonStyle(MomentumSolidButtonStyle(fill: .accentColor, foreground: AreaPalette.work.onColor))
                    .accessibilityIdentifier("homeNextMoveButton")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            Color("StateGo").opacity(0.14),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color("StateGo").opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("homeClosureCelebration")
    }
}

#if DEBUG
private struct MomentumScoreboardGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                MomentumRingCard(
                    closedToday: 2, goal: 5, streak: 7, bestStreak: 9, openCount: 3,
                    weekFlags: [true, true, true, true, true, true, false],
                    nextEffortLabel: "15 min"
                )
                BestNextMoveCard(
                    task: TaskSummary(
                        lifeAreaId: nil,
                        status: .open, title: "Sort through mail pile on kitchen counter",
                        priority: .p2, notes: "Trash junk mail immediately. Only keep bills to scan.",
                        dueDate: Date(), focusDurationSeconds: 900
                    ),
                    lifeArea: LifeArea(id: UUID(), name: "Admin", colour: "📝", sortOrder: 0),
                    isDueNow: true, isClosing: false, showsStartSession: true,
                    onClose: {}, onStartSession: {}
                )
                ClosureCelebrationCard(
                    taskTitle: "Sort through mail pile",
                    line: "Third today. Admin & Home is up to 75% this week.",
                    nextLabel: "Next: 20 min",
                    onUndo: {}, onNext: {}
                )
                AreaMomentumList(items: MomentumScoreboard.areaMomentum(
                    areas: [
                        LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0),
                        LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 1)
                    ],
                    openTasks: [], allTasks: []
                ))
            }
            .padding(16)
        }
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.dark)
}
#endif
