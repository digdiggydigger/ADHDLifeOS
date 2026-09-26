//
//  HomeTodayCard.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`: Today's ONE card, in the shape E chose from board `59` — round 5a, *"H1 ·
//  Start first, Close quiet. One prominent 'Start N min' (56pt, accent). 'Close it' is a quiet
//  green-tinted button below it. The card also carries: a pin toggle (44pt) in the corner; the
//  title; the next-step line; chips for time and area."* The suggested state adds "Not this one"
//  (idea 3); a paused sprint takes the card as the Resume card (round 4a, idea 4).
//
//  Geometry is the round-5 probe's, which rendered the frames E chose from: 16pt padding and
//  gaps, a 56pt filled Start, 48pt tinted quiet buttons, 16pt corners throughout. **Two departures,
//  both from later decisions of E's:** the eyebrow is `.secondary`, not the board's accent blue
//  (round 9: *"Blue always means 'tap me'"*), and the effort and area chips are the quiet grey the
//  board drew, not the old hero's solid blue.
//

import SwiftUI

/// The card leading with a task: pinned, suggested, or (once `F-F5` feeds it) leave-by.
struct TodayTaskCard: View {
    let eyebrow: String
    /// Round 9: blue means "tap me", so a label that is not tappable is secondary — except the
    /// leave-by eyebrow, which is a warning (the board's `StateWarn`).
    var eyebrowIsWarning = false
    let task: TaskSummary
    let lifeArea: LifeArea?
    let isPinned: Bool
    /// The suggested state only (idea 3, round 5b: *"Back in the list, not re-suggested today"*).
    let offersNotThisOne: Bool
    /// Hidden while any sprint runs, as the hero's was: the card must not offer a second sprint
    /// over the top of one already counting.
    let showsStart: Bool
    let startTitle: String
    /// `MomentumTaskContext.Context.closeButtonTitle` — the SAME words Task Detail's Close uses.
    let closeTitle: String
    /// b10's tracking half, kept from the hero this card replaced: once focus is logged against the
    /// task today, a chip says so.
    let loggedTodayLabel: String?
    let isClosing: Bool
    let onTogglePin: () -> Void
    let onStart: () -> Void
    let onClose: () -> Void
    let onNotThisOne: () -> Void
    /// Handed the draft when editing ENDS; the caller decides whether it is a change.
    let onCommitNextStep: (String) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var nextStepDraft = ""
    @FocusState private var isEditingNextStep: Bool

    var body: some View {
        // Round 5a: at accessibility sizes the card is taller than the screen, so the compact
        // layout moves the buttons up under the title — Start above the fold — and the details
        // follow them. Nothing is dropped; only the order changes.
        let compact = TodayCardLayout.isCompact(typeSize)
        VStack(alignment: .leading, spacing: 16) {
            header
            if compact {
                title
                buttons(compact: true)
                details
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    title
                    details
                }
                buttons(compact: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeTodayCard")
        .onAppear { nextStepDraft = task.nextStep ?? "" }
        // A different task in the card, or the line saved from Task Detail: show what is stored —
        // but never overwrite a draft the user is still typing.
        .onChange(of: task.id) { _, _ in nextStepDraft = task.nextStep ?? "" }
        .onChange(of: task.nextStep) { _, stored in
            if !isEditingNextStep { nextStepDraft = stored ?? "" }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(eyebrow)
                .font(.footnote.weight(.semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(eyebrowIsWarning ? AnyShapeStyle(Color("StateWarn")) : AnyShapeStyle(.secondary))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            pinButton
        }
    }

    private var pinButton: some View {
        Button {
            Haptics.play(.selection)
            onTogglePin()
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .modifier(TodayTint(tint: .accentColor))
                .contentShape(Rectangle())
        }
        .buttonStyle(TodayPressStyle())
        .accessibilityLabel(TodayCardCopy.pinLabel(isPinned: isPinned))
        .accessibilityAddTraits(isPinned ? .isSelected : [])
        .accessibilityIdentifier("homeTodayPinButton")
    }

    private var title: some View {
        Text(task.title)
            .font(.title3.bold())
            .tracking(-0.5)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            nextStep
            chips
        }
    }

    /// Read the way Task Detail's row reads (`F-E2`, its `apple-design` High): a caption naming the
    /// line, because a placeholder vanishes the moment there is text, and a saved line with no name
    /// reads as an unlabelled note.
    private var nextStep: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next Step")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("What to do first", text: $nextStepDraft, axis: .vertical)
                .font(.body)
                .submitLabel(.done)
                .focused($isEditingNextStep)
                .accessibilityLabel("Next Step")
                .accessibilityIdentifier("homeTodayNextStepField")
                // One line of intent, so Return means Done rather than a new paragraph.
                .onChange(of: nextStepDraft) { _, draft in
                    guard draft.contains("\n") else { return }
                    nextStepDraft = draft.replacingOccurrences(of: "\n", with: "")
                    isEditingNextStep = false
                }
                .onChange(of: isEditingNextStep) { _, editing in
                    if !editing { onCommitNextStep(nextStepDraft) }
                }
        }
    }

    private var chips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chipList }
            VStack(alignment: .leading, spacing: 8) { chipList }
        }
    }

    @ViewBuilder
    private var chipList: some View {
        if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
            quietChip(effort)
        }
        if let lifeArea {
            quietChip("\(lifeArea.colour) \(lifeArea.name)")
        }
        if let loggedTodayLabel {
            MomentumChip(
                text: "✓ \(loggedTodayLabel)",
                background: Color("CardSurfaceSecondary"),
                foreground: Color("StateGo")
            )
            .accessibilityLabel("Focus logged: \(loggedTodayLabel)")
        }
    }

    private func quietChip(_ text: String) -> some View {
        MomentumChip(text: text, background: Color("CardSurfaceSecondary"), foreground: Color("LabelSecondary"))
    }

    @ViewBuilder
    private func buttons(compact: Bool) -> some View {
        VStack(spacing: 8) {
            if showsStart {
                Button(action: onStart) {
                    Label(startTitle, systemImage: "play.fill")
                }
                .buttonStyle(TodayFilledButtonStyle(fill: .accentColor))
                .accessibilityIdentifier("homeStartSessionButton")
            }
            if offersNotThisOne && !compact {
                HStack(spacing: 8) {
                    closeButton
                    notThisOneButton
                }
            } else {
                closeButton
                if offersNotThisOne { notThisOneButton }
            }
        }
    }

    /// The fourth way to close a task: the same pop, haptic and undo capsule as the other three.
    private var closeButton: some View {
        CelebrationPopSource { handle in
            Button {
                Haptics.play(.taskClose)
                handle.pop()
                onClose()
            } label: {
                if isClosing {
                    ProgressView()
                        .tint(Color("StateGo"))
                } else {
                    Label(closeTitle, systemImage: "checkmark")
                }
            }
            .buttonStyle(TodayTintedButtonStyle(tint: Color("StateGo")))
            .disabled(isClosing)
            .accessibilityIdentifier("homeCloseTaskButton")
        }
    }

    private var notThisOneButton: some View {
        Button {
            Haptics.play(.light)
            onNotThisOne()
        } label: {
            Label("Not this one", systemImage: "arrow.triangle.2.circlepath")
        }
        .buttonStyle(TodayTintedButtonStyle(tint: Color("LabelSecondary")))
        .accessibilityHint("Moves it into the list below; it won't be suggested again today")
        .accessibilityIdentifier("homeNotThisOneButton")
    }
}

/// The Resume card (round 4a: *"A paused sprint shows 'Paused · N min in · Resume', which feeds the
/// Resume card"*). Resume only: ending a sprint stays on the focus card below, whose confirm still
/// says "Stop" — the rename to "End" is arc F's, and two words for one action on one screen would
/// be worse than one control.
struct TodayPausedCard: View {
    let sprint: TodayPausedSprint
    let onResume: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(TodayCardCopy.eyebrow(for: .paused(sprint)) ?? "")
                    .font(.footnote.weight(.semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(sprint.taskTitle)
                    .font(.title3.bold())
                    .tracking(-0.5)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(TodayCardCopy.pausedDetail(sprint))
                    .font(.subheadline)
                    .foregroundStyle(Color("LabelSecondary"))
            }
            Button {
                Haptics.play(.selection)
                onResume()
            } label: {
                Label("Resume", systemImage: "play.fill")
            }
            .buttonStyle(TodayFilledButtonStyle(fill: .accentColor))
            .accessibilityIdentifier("homeResumeSprintButton")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeTodayCard")
    }
}

// MARK: - The card's controls (the round-5 probe's numbers)

/// The prominent action: 56pt, filled, 16pt corners; white on accent is the house's on-accent
/// contract (`PrimaryActionButtonStyle`). Presses scale, never fade (§3).
struct TodayFilledButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// The quiet action: 48pt (round 7: anything that closes or changes things), tinted, 16pt corners.
/// A long title wraps rather than truncating (§1 layout safety).
struct TodayTintedButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 48)
            .modifier(TodayTint(tint: tint))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// Press feedback for a control that draws its own shape (the pin well).
struct TodayPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// The tab bar's approved chip wash (`AppTabBarMetrics.chipTint*`), which the probe drew these
/// tints with: a colour's own tint under its own foreground, stronger in dark where a 12% wash
/// disappears into the card.
struct TodayTint: ViewModifier {
    let tint: Color
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.background(
            tint.opacity(scheme == .dark ? AppTabBarMetrics.chipTintDark : AppTabBarMetrics.chipTintLight),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

#if DEBUG
private enum TodayCardPreviewData {
    static let task = TaskSummary(
        lifeAreaId: nil, status: .open, title: "Reply to Priya about the Q4 roadmap",
        dueDate: Date(), focusDurationSeconds: 900, nextStep: "Say yes to the date, ask who owns the spec"
    )
    static let area = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)

    static func card(pinned: Bool) -> TodayTaskCard {
        TodayTaskCard(
            eyebrow: pinned ? "Next · Pinned" : "Suggested · Due today",
            task: task, lifeArea: area, isPinned: pinned, offersNotThisOne: !pinned, showsStart: true,
            startTitle: "Start 15 min", closeTitle: "Close it", loggedTodayLabel: nil, isClosing: false,
            onTogglePin: {}, onStart: {}, onClose: {}, onNotThisOne: {}, onCommitNextStep: { _ in }
        )
    }

    static var column: some View {
        ScrollView {
            VStack(spacing: 24) {
                card(pinned: true)
                card(pinned: false)
                TodayPausedCard(
                    sprint: TodayPausedSprint(
                        taskId: nil, taskTitle: task.title, durationSeconds: 1_200, remainingSeconds: 480
                    ),
                    onResume: {}
                )
            }
            .padding(16)
        }
        .background(Color.pageBackground)
    }
}

#Preview("Today card — Light and Dark") {
    HStack(spacing: 0) {
        TodayCardPreviewData.column.preferredColorScheme(.light)
        TodayCardPreviewData.column.environment(\.colorScheme, .dark)
    }
}
#endif
