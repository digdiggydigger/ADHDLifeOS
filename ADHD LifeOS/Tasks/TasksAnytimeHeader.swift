//
//  TasksAnytimeHeader.swift
//  ADHD LifeOS
//
//  `F-D3-TasksAnytimeRow` — the Momentum board's "Anytime · N" row (round 6: *"The Tasks board
//  gains one collapsed 'Anytime · N' row at the bottom: the tail stays folded, but a new task is
//  visible where it was added."*). Its own file because `TaskListView` sits at SwiftLint's type-
//  and file-length limits; the fold's STATE stays there, where the rows it gates are drawn.
//

import SwiftUI

/// The house fold, so the chevron points AT the content (E, 2026-08-28) and VoiceOver hears the
/// state. `summary` is nil because the title, "Anytime · N", already says what the fold holds.
/// Quiet by design — no tone, per round 9's "no colour" for anything that is not due-now,
/// tomorrow or closed.
///
/// The header is PINNED like its neighbours, and Anytime is the one bucket whose own rows scroll
/// under its own header once opened, so it is painted the page exactly as `pinnedSectionHeader()`
/// paints every other one — otherwise the rows would show through it.
struct TasksAnytimeHeader: View {
    let title: String
    @Binding var isCollapsed: Bool

    var body: some View {
        CollapsibleSectionHeader(
            title: title,
            summary: nil,
            isExpanded: !isCollapsed,
            onToggle: { isCollapsed.toggle() }
        )
        .background(Color(PinnedHeaderMetrics.surfaceAssetName))
        .accessibilityIdentifier("tasksAnytimeHeader")
    }
}

#if DEBUG
private struct TasksAnytimeHeaderPreview: View {
    @State private var collapsed = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TasksAnytimeHeader(title: "Anytime · 3", isCollapsed: $collapsed)
            if !collapsed {
                Text("…the undated tasks…")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bentoCard()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.pageBackground)
    }
}

#Preview("Light") { TasksAnytimeHeaderPreview().preferredColorScheme(.light) }
#Preview("Dark") { TasksAnytimeHeaderPreview().preferredColorScheme(.dark) }
#endif
