//
//  Haptics.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

/// The app's haptic vocabulary — six feels, agreed with E on 2026-08-27, so the whole app speaks
/// one tactile language instead of each screen inventing its own buzz.
///
/// Deliberately small. For an ADHD app, feedback at *everything* is noise, and noise is the thing
/// this product exists to reduce — see the "deliberately excluded" list in the F-V3-Haptics block
/// report (scrolling, pull-to-refresh, keyboard dismissal, navigation back, the sprint countdown).
enum HapticFeel: String, CaseIterable {
    /// Moving between things that were already there: filter chips, segmented pickers, toggles.
    case selection
    /// A minor press that isn't a commitment: chip toggles, expand/collapse, skip, dismiss.
    case light
    /// A committed write landed: save, create, apply, file, archive.
    case solid
    /// A completion worth marking: closing a task, promoting a capture, starting a sprint.
    case success
    /// You are about to do something destructive: a delete/discard confirmation appearing.
    case warning
    /// A write actually failed. Before this block a failed save was silent unless you read the
    /// message — this is the feel that most earns its place.
    case error
}

extension HapticFeel {
    /// E chose light impact over the iOS-conventional selection tick for the tab bar (2026-08-27).
    /// Named rather than inlined so the choice is greppable and testable, not buried in `RootView`.
    static let tabChange: HapticFeel = .light

    /// E chose the celebratory success feel for closing a task (2026-08-27). Every close path
    /// shares it: the row's tap-circle, swipe-to-close, the detail toggle, Today's due-now row,
    /// and Life-area detail's tick.
    static let taskClose: HapticFeel = .success
}

/// The seam. UIKit's feedback generators can't be asserted against, so the gate and feel-selection
/// are tested through a recording fake and the real generators live behind the single
/// `UIKitHapticPerformer` below.
protocol HapticPerforming {
    func perform(_ feel: HapticFeel)
}

/// The only place in the app that constructs a `UIFeedbackGenerator`.
///
/// `solid` maps to `.medium` and not `.heavy` deliberately: it preserves the exact feel of the
/// three modifiers this type replaces, so migrating the existing call sites changed nothing under
/// E's thumb.
struct UIKitHapticPerformer: HapticPerforming {
    func perform(_ feel: HapticFeel) {
        switch feel {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .solid:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

/// Play a feel, subject to the Settings toggle.
///
/// Two entry points exist on purpose:
/// - `Haptics.play(_:)` — imperative, for the many sites that are already button actions. Adding a
///   `@State` trigger to each of ~50 buttons purely to satisfy `.sensoryFeedback` would be worse
///   code than calling this.
/// - `.haptic(_:trigger:)` — the `#available`-split modifier below, for state-driven moments
///   (an async save landing, a confirmation appearing), which is what `CLAUDE.md` §3 prescribes.
///
/// Both consult the gate at FIRE time, so flipping Settings takes effect on the very next tap.
/// Call on the main thread — `UIFeedbackGenerator` requires it, and every call site is a SwiftUI
/// action or `onChange`, both of which already are.
enum Haptics {
    static func play(
        _ feel: HapticFeel,
        gate: () -> Bool = { AppFeedback.hapticsEnabled() },
        performer: HapticPerforming = UIKitHapticPerformer()
    ) {
        guard gate() else { return }
        performer.perform(feel)
    }
}

@available(iOS 17.0, *)
extension HapticFeel {
    /// The iOS 17+ equivalent of each feel. Kept beside the UIKit mapping so the two can't drift.
    var sensoryFeedback: SensoryFeedback {
        switch self {
        case .selection: return .selection
        case .light: return .impact(weight: .light)
        case .solid: return .impact(flexibility: .solid)
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        }
    }
}

extension View {
    /// Fire `feel` whenever `trigger` changes. `.sensoryFeedback` is iOS 17+ and the deployment
    /// target is 16.0 (`CLAUDE.md` §7), so on iOS 16 the same trigger drives the UIKit performer
    /// through `.onChange` instead.
    ///
    /// Replaces `saveSuccessHaptic` / `promoteSuccessHaptic`, which were the same code twice.
    @ViewBuilder
    func haptic<T: Equatable>(_ feel: HapticFeel, trigger: T) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(feel.sensoryFeedback, trigger: trigger) { _, _ in
                AppFeedback.hapticsEnabled()
            }
        } else {
            self.onChange(of: trigger) { _ in
                Haptics.play(feel)
            }
        }
    }
}
