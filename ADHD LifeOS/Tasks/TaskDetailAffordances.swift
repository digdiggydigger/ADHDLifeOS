//
//  TaskDetailAffordances.swift
//  ADHD LifeOS
//
//  Stateless presentational helpers for TaskDetailView's staged-vs-immediate clarity affordances,
//  split out to keep TaskDetailView.swift within the SwiftLint file-length budget. None of these
//  touch the view's private state — they are pure, reusable sub-views.
//

import SwiftUI

extension TaskDetailView {
    /// Transient "Saved" confirmation (Part 3). Icon + text (§4), on `.ultraThinMaterial` with a soft
    /// diffusion shadow (§5); green is redundant with the checkmark + word, so never colour alone.
    var savedConfirmationToast: some View {
        Label("Saved", systemImage: "checkmark.circle.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.green)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
            .accessibilityIdentifier("taskDetailSavedConfirmation")
    }

}
