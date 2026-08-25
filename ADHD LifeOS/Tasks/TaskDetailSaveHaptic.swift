//
//  TaskDetailSaveHaptic.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

extension View {
    /// Success confirmation haptic for a landed save (§3). Mirrors `CaptureInboxView`'s
    /// `promoteSuccessHaptic` exactly (§7): `.sensoryFeedback` is iOS 17+, so on iOS 16 the same
    /// `trigger` drives a `UIImpactFeedbackGenerator` instead — the deployment target stays iOS 16.0.
    /// Lives in its own file (rather than sharing `CaptureInboxView`'s private copy) because this
    /// block is confined to the Task Detail files; a later refactor could unify the two.
    @ViewBuilder
    func saveSuccessHaptic(trigger: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .solid), trigger: trigger) { _, _ in
                AppFeedback.hapticsEnabled()
            }
        } else {
            self.onChange(of: trigger) { _ in
                if AppFeedback.hapticsEnabled() {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }
}
