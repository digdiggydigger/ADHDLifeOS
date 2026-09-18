//
//  JournalComposeDisc.swift
//  ADHD LifeOS
//
//  The Journal's door to a new entry since `F-JournalPencilDisc` (E, 2026-09-18). It was a pencil in
//  the header until block 1 made it the ONLY door, and then it scrolled away with the header. Shown
//  a filled pencil splitting the toolbar's capsule, E moved it: *"move the filled pencil icon disc
//  down to the left-hand side of the FAB Icon. make the filled pencil disc inline with the FAB
//  icon"*. So it rides the capture disc's row (`RootBottomOverlay.discRow`), 16pt to the +'s left
//  and centred on its line, and is the +'s twin — *"twins with halos"* — through `CaptureDiscFace`.
//  Evidence: `screenshots/journal-pencil-step0/`, `screenshots/journal-pencil-disc/`.
//

import SwiftUI

enum JournalComposeDiscMetrics {
    /// **42, E's number.** Step 0 recommended 48 and E agreed, then, mid-session: *"decrease the size
    /// of the filled pencil disc from 48pt to 42pt"*. Smaller than the + disc's 60 on purpose — the +
    /// stays the primary action — and the row's height stays the +'s, so the centre line is shared.
    static let diameter: CGFloat = 42

    /// §3's floor is 44 and E's disc is 42. A real 44pt frame would widen the row and move the
    /// pencil's centre, so this takes the house `AppTabBarMetrics.slotHitOverflow` shape instead:
    /// padded out to the floor around the `contentShape`, then handed straight back to the layout.
    /// 1pt each side — the LAYOUT stays 42, taps land within 44.
    static var hitOverflow: CGFloat {
        max(0, (AppTabBarPresentation.minimumTouchTarget - diameter) / 2)
    }
}

/// When the pencil disc is on screen, and how it arrives — pure, so it is tested rather than read.
enum JournalComposeDoor {
    /// The Journal at its top level, and nowhere else. The search row's rule (F-TabDepth-2): a
    /// pushed task or capture door is its own screen, and a pencil beside it would write into a
    /// Journal the user cannot see. Loaded or not — E, 2026-09-18: *"Always on the Journal"*;
    /// saving an entry never depended on the timeline having loaded.
    static func isShown(selectedTab: AppTab, isAtRoot: Bool) -> Bool {
        selectedTab == .journal && isAtRoot
    }

    /// Appearing and leaving (a tab switch, a push, a pop) is a REDUCED SITE (§7.2). With motion it
    /// rides the search row's spring; under Reduce Motion a plain fade — geometry is already final,
    /// only opacity travels — and never `nil`, which would be a hard cut. Non-optional by type, so a
    /// `nil` cannot be written here at all.
    static func appearAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8)
    }
}

struct JournalComposeDisc: View {
    /// The + disc's sticky scrolled-down state. E's **"Follows the pill"**: while the + is a pill
    /// the pencil goes translucent with it, on its curves. Its SIZE stays 42 — the pill is 60×48,
    /// so the pair stays on one line.
    let showsPill: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AreaPalette.work.onColor)
                .frame(width: JournalComposeDiscMetrics.diameter, height: JournalComposeDiscMetrics.diameter)
                .background(CaptureDiscFace.pencil.gradient, in: Circle())
                .captureDiscHalo(CaptureDiscFace.glow(showsPill: showsPill))
                .opacity(showsPill ? CaptureDiscMetrics.pillOpacity : 1)
                .padding(JournalComposeDiscMetrics.hitOverflow)
                .contentShape(Circle())
                .padding(-JournalComposeDiscMetrics.hitOverflow)
                .animation(
                    CaptureDiscFace.pillAnimation(showsPill: showsPill, reduceMotion: reduceMotion),
                    value: showsPill
                )
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Write an entry")
        .accessibilityIdentifier("journalComposeButton")
    }
}

#Preview("Pencil disc — light") {
    JournalComposeDiscPreviewRow()
        .preferredColorScheme(.light)
}

#Preview("Pencil disc — dark") {
    JournalComposeDiscPreviewRow()
        .preferredColorScheme(.dark)
}

/// Both states beside the + disc, as the row draws them: at rest, then pilled.
private struct JournalComposeDiscPreviewRow: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 24) {
            ForEach([false, true], id: \.self) { pill in
                HStack(spacing: AppSearchRowMetrics.rowSpacing) {
                    JournalComposeDisc(showsPill: pill) {}
                    CaptureDiscLabel(isFabOpen: false, showsPill: pill)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.pageBackground)
    }
}
