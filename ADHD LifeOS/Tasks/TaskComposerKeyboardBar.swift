//
//  TaskComposerKeyboardBar.swift
//  ADHD LifeOS
//
//  `F-D2-ComposerKeyboardLayout`: round 7b's L3, E's pick. *"The title owns the page. Every
//  choice and Add sit in one bar just above the keyboard: the four 'when' segments on top; Area |
//  Time | Add below, with Add trailing."*
//
//  `TaskCreateView` mounts it with `.safeAreaInset(edge: .bottom)`, so SwiftUI's keyboard
//  avoidance lifts it on every OS the app runs on. It never goes in the `.keyboard` toolbar
//  placement, which is one row and cannot hold two (findings §L, Platform notes).
//
//  **E's decision, 2026-09-24: "Let it settle."** L3 was chosen on the condition that opening
//  Area, Time or the date picker would NOT put the keyboard down. The first run of the test that
//  condition asked for found that on iOS 27 all three do: the SwiftUI menu, a UIKit menu tried in
//  its place, and the popover. The keyboard does not come back afterwards. So the bar rides the
//  keyboard while you type, the first choice lets it settle at the bottom (the approved
//  keyboard-down frame), and it stays there for every later choice until a tap on the title raises
//  it again. Nothing re-focuses the title behind the user's back: that would be research §3.2's
//  drop-and-jump, the one thing worse than the drop.
//

import SwiftUI

/// The composer's numbers, from round 7b's probe: what E approved by looking at board `64`.
enum TaskComposerMetrics {
    /// Round 7: *"the composer's own chips stay 48"*.
    static let segmentHeight: CGFloat = 48
    /// Round 7: 48pt *"for anything that starts, closes, adds"*.
    static let addHeight: CGFloat = 48
    /// The segments' container, the menu tiles and Add, so they read as one set.
    static let controlCornerRadius = ComposerMenuTile.cornerRadius
    /// Around and between the segments inside their container.
    static let segmentInset: CGFloat = 4
    /// Concentric with the container: its radius less the inset between them.
    static let segmentCornerRadius = controlCornerRadius - segmentInset
    /// Between the bar's edge and its controls, and between the bar and the screen's edges and the
    /// keyboard. Two of them put the controls 16pt in, where the probe drew them.
    static let barPadding: CGFloat = 8
    /// Concentric with the controls it wraps: their radius plus the inset between them.
    static let barCornerRadius = controlCornerRadius + barPadding
    /// The date popover's calendar. A popover sizes itself to its content's IDEAL size, and a
    /// graphical `DatePicker` proposes almost none: the first build drew a calendar about 60pt wide,
    /// with its Next Month control off the edge of the screen. 320 is the narrowest iPhone width.
    static let datePickerWidth: CGFloat = 320
}

struct TaskComposerKeyboardBar: View {
    @ObservedObject var service: TaskCreateService
    @Binding var dueChoice: TaskDueChoice
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: TaskComposerMetrics.barPadding) {
            TaskWhenSegments(service: service, dueChoice: $dueChoice)
            HStack(spacing: TaskComposerMetrics.barPadding) {
                // Hidden only when there are no areas to offer: a question with no answers.
                if !service.offeredLifeAreas.isEmpty {
                    TaskComposerAreaMenu(service: service, compact: true)
                }
                TaskComposerTimeMenu(service: service, compact: true)
                TaskComposerAddButton(service: service, compact: true, action: onAdd)
            }
        }
        .padding(TaskComposerMetrics.barPadding)
        .modifier(ComposerBarContainer())
        .padding(.horizontal, TaskComposerMetrics.barPadding)
        .padding(.bottom, TaskComposerMetrics.barPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taskComposerKeyboardBar")
    }
}

/// The bar's container: §7.1's degraded site, and the one `#available` this block adds.
/// `virtual-keyboards.md › Mobile (iOS, iPadOS)`: *"apply Liquid Glass to the view that contains
/// your controls"*. On 18–25 the same raised panel is drawn in the bar material every other
/// composer footer wears (`ComposerFooterSurface`), with its hairline. It carries the same
/// information, a panel lifted off the page, in the floor's own material.
private struct ComposerBarContainer: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: TaskComposerMetrics.barCornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content
                .background(.bar, in: shape)
                .overlay(shape.strokeBorder(Color.cardBorder, lineWidth: 1))
        }
    }
}

#if DEBUG
private struct TaskComposerKeyboardBarPreview: View {
    @StateObject private var service = TaskCreateService.preview()
    @State private var choice: TaskDueChoice = .notYet

    var body: some View {
        VStack {
            Spacer()
            TaskComposerKeyboardBar(service: service, dueChoice: $choice) {}
        }
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    TaskComposerKeyboardBarPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskComposerKeyboardBarPreview()
        .preferredColorScheme(.dark)
}
#endif
