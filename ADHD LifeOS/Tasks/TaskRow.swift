//
//  TaskRow.swift
//  ADHD LifeOS
//

import SwiftUI

/// The v3 Tasks page's dense row (F-V3-Tasks-rebuild, Option A of the b11 proposal): effort chip,
/// title over the one-line `TaskRowPresentation` meta, and a 44pt tap-circle that closes the task.
/// Due-today rows add a small ▶ that launches a focus sprint (E's b11 call: sprint-starting is a
/// today thing — other buckets stay quiet). The whole row opens the detail screen.
///
/// What the old `SwipeableTaskCard` had that this deliberately does not:
/// - No reopen CONTROL: a closed row's check is display-only. **"Closing is one-way" (E's
///   addendum) was retired on 2026-09-20 by `F-C1-UndoCapsule`** — the way back is the shared undo
///   capsule in the disc row, which the list records into. The row itself is unchanged.
/// - No swipe-left delete: delete lives on the detail screen now. Swipe-RIGHT-to-close survives
///   as a bonus gesture on open rows, resolved by the pure `TaskRowSwipe` below.
struct TaskRow: View {
    let task: TaskItem
    let lifeArea: LifeArea?
    /// True only for the Momentum board's Due-today bucket.
    let showsSprintStart: Bool
    let onClose: () -> Void
    let onInspect: () -> Void
    var onStartFocus: () -> Void = {}

    @State private var dragOffset: CGFloat = 0
    /// The close-circle's centre in GLOBAL coordinates — where a TAP's confetti pop leaves from.
    @State private var popOrigin: CGPoint?
    /// The row's own frame in GLOBAL coordinates, so a SWIPE can pop from the finger instead.
    @State private var rowFrame: CGRect = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.celebrate) private var celebrate

    private var isClosed: Bool { task.status == .done }

    /// Both close paths — the tap-circle and the swipe — funnel here, so closing feels identical
    /// however you did it and the haptic can't be attached to one and forgotten on the other.
    /// E chose the celebratory success feel for this (2026-08-27), and `F-CTACelebrations-4` hung
    /// the pop off the same line for the same reason.
    ///
    /// **This is the one site of the nine that does not use `CelebrationPopSource`, and the reason
    /// is right here.** The wrapper reports the centre of whatever it wraps, and the swipe lives on
    /// the whole row — so wrapping enough of the row to catch the gesture would throw the paper
    /// from the middle of the row.
    ///
    /// **The two paths no longer share ONE origin, and that is E's call from the device.** The tap
    /// pops from the circle, which is the origin E approved by looking. The swipe pops from the
    /// FINGER: it used to borrow the circle's origin, and since the circle sits at the row's
    /// trailing edge, a swipe threw most of its paper off the right of the screen once the pop's
    /// throw grew to 208 pt. What the two paths still share is this method, so the haptic and the
    /// pop can never be attached to one and forgotten on the other.
    private func close(poppingFrom origin: CGPoint? = nil) {
        Haptics.play(.taskClose)
        celebrate.request(.pop, at: origin ?? popOrigin)
        onClose()
    }

    var body: some View {
        ZStack {
            revealLayer
            rowContent
                .offset(x: dragOffset)
                // The row's own position, so a swipe's pop can be placed from the finger. Measured
                // on the SAME view the gesture is attached to, so the drag offset is in both or
                // neither and the two cannot disagree.
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rowFrame = $0 }
                .gesture(isClosed ? nil : dragGesture)
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("taskRow-\(task.id.uuidString)")
        .accessibilityActions {
            if !isClosed {
                Button("Close task") { close() }
                if showsSprintStart {
                    Button("Start focus sprint", action: onStartFocus)
                }
            }
            Button("Open details", action: onInspect)
        }
    }

    // MARK: - Row

    private var rowContent: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                    MomentumChip(
                        text: effort,
                        background: Color("CardSurfaceSecondary"),
                        foreground: Color("LabelSecondary")
                    )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.callout)
                        .strikethrough(isClosed)
                        .foregroundStyle(isClosed ? Color("LabelSecondary") : Color("LabelPrimary"))
                        .lineLimit(2)
                    Text(TaskRowPresentation.metaLine(task: task, lifeArea: lifeArea))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel(TaskRowPresentation.accessibilityLabel(task: task, lifeArea: lifeArea))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onInspect)

            if showsSprintStart && !isClosed {
                Button(action: onStartFocus) {
                    Image(systemName: "play.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start focus sprint")
                .accessibilityIdentifier("taskStartFocus-\(task.id.uuidString)")
            }

            if isClosed {
                // Display-only. Not "no reopen path anywhere in the app" any more — since
                // `F-C1-UndoCapsule` the undo capsule reopens the task it just closed — but this
                // check is still a statement, not a control.
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color("StateGo"))
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            } else {
                Button { close() } label: {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(Color("LabelTertiary"))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .celebrationPopOrigin { popOrigin = $0 }
                .accessibilityLabel("Close task")
                .accessibilityIdentifier("taskCheckbox-\(task.id.uuidString)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .background(Color.cardSurface)
        .opacity(isClosed ? 0.6 : 1)
    }

    // MARK: - Swipe-right-to-close (bonus gesture)

    private var revealLayer: some View {
        HStack {
            Label("Close", systemImage: "checkmark")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .opacity(TaskRowSwipe.closes(forTranslation: dragOffset) ? 1 : 0)
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(dragOffset > 0 ? Color("StateGo") : Color.cardSurface)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // Horizontal only — vertical intent belongs to the enclosing scroll view.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dragOffset = TaskRowSwipe.rubberBanded(value.translation.width)
            }
            .onEnded { value in
                let closes = TaskRowSwipe.closes(forTranslation: value.translation.width)
                let finger = TaskRowSwipe.popOrigin(rowFrame: rowFrame, fingerInRow: value.location)
                dragOffset = 0
                if closes { close(poppingFrom: finger) }
            }
    }
}

/// The bonus gesture's outcome, pure and threshold-driven so it is unit-testable without a
/// gesture host. Right-only: there is no left action any more (delete moved to the detail
/// screen), so leftward drags don't move the row at all.
enum TaskRowSwipe {
    static let threshold: CGFloat = 75
    static let elasticLimit: CGFloat = 140

    /// Where a SWIPE's confetti pop leaves from, in global coordinates.
    ///
    /// **E found this on the phone** (2026-09-12): the swipe used to share the circle's recorded
    /// origin, and the circle sits at the row's TRAILING edge — so once the pop's throw grew to
    /// 208 pt, a swipe threw most of its paper off the right-hand side of the screen. E:
    /// *"make the animation origin at the tap location of the 'swipe to complete'."*
    ///
    /// The gesture reports the finger in the row's OWN space and the layer draws in the window's,
    /// so the row's measured global frame is what joins them. `.zero` means the row has not been
    /// measured yet, and `nil` is the honest answer there: the layer centres an origin-less burst,
    /// which is a sane pop, where a fabricated point would be a pop from somewhere nobody touched.
    static func popOrigin(rowFrame: CGRect, fingerInRow location: CGPoint) -> CGPoint? {
        guard rowFrame != .zero else { return nil }
        return CGPoint(x: rowFrame.minX + location.x, y: rowFrame.minY + location.y)
    }

    static func closes(forTranslation translation: CGFloat) -> Bool {
        translation > threshold
    }

    /// 1:1 tracking up to the threshold, then a damped tail toward `elasticLimit`; leftward
    /// translations pin to zero.
    static func rubberBanded(_ translation: CGFloat) -> CGFloat {
        guard translation > 0 else { return 0 }
        guard translation > threshold else { return translation }
        let damped = threshold + (translation - threshold) * 0.4
        return min(damped, elasticLimit)
    }
}

#if DEBUG
#Preview("Light") {
    VStack(spacing: 0) {
        TaskRow(
            task: TaskItem(
                id: UUID(), lifeAreaId: UUID(), title: "Break down Q3 proposal into micro-steps",
                status: .open, priority: .p1, dueDate: .now, focusDurationSeconds: 1500
            ),
            lifeArea: LifeArea(id: UUID(), name: "Work & Career", colour: "💼", sortOrder: 0),
            showsSprintStart: true,
            onClose: {}, onInspect: {}
        )
        Divider().padding(.leading, 16)
        TaskRow(
            task: TaskItem(
                id: UUID(), lifeAreaId: UUID(), title: "Drink 500ml water & stretch",
                status: .done, priority: .p3, dueDate: nil, focusDurationSeconds: 600,
                completedAt: .now
            ),
            lifeArea: LifeArea(id: UUID(), name: "Health", colour: "🏋️", sortOrder: 1),
            showsSprintStart: false,
            onClose: {}, onInspect: {}
        )
    }
    .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(16)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskRow(
        task: TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Clean audio equipment & organize cables",
            status: .open, priority: .p3, dueDate: Date().addingTimeInterval(86_400)
        ),
        lifeArea: LifeArea(id: UUID(), name: "Hobbies", colour: "🎨", sortOrder: 2),
        showsSprintStart: false,
        onClose: {}, onInspect: {}
    )
    .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(16)
    .preferredColorScheme(.dark)
}
#endif
