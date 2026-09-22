//
//  CaptureInboxUndoSections.swift
//  ADHD LifeOS
//
//  The Inbox's undo affordances, moved out of `CaptureInboxSections.swift` in
//  `F-CTACelebrations-4` so that file had room for the Sorted and Journal it pop wrappers — it was
//  at 390 of SwiftLint's 400-line ceiling and the two wrappers would have left it at 399.
//
//  **Moved verbatim; nothing here changed.** The section was already self-contained: its own
//  `extension CaptureInboxView`, its own MARK, and no reference to any of the four `private`
//  members declared in the file it came from — which is what made it the safe seam rather than
//  the convenient one. `testTrailingClearanceStillReadsTheMetricDirectly` names this file now,
//  because both `.padding(.trailing, CaptureDiscMetrics.clearance)` call sites live here.
//

import SwiftUI

// MARK: - Undo (E, 2026-08-28: "both")
//
// Two affordances, deliberately, because they answer different questions. The bar said WHAT just
// happened at the moment it happened; the header arrow is the safety net you reach for later, when
// you have already looked away.
//
// **The BAR is gone as of `F-C1-UndoCapsule` (2026-09-20).** E chose "one bottom bar everywhere"
// (round 2, Option 1) and then its shape (round 2b, "A · Capsule in the disc row"), so this
// screen's own bar is now the app-wide `UndoCapsule` — same job, same words, one implementation
// for five surfaces instead of one for this screen. What is left here is the warning bar, which is
// this screen's alone, and the header arrow.
//
// **E kept the header arrow, and made it read the SAME slot** (Step 0 answer 2, chosen over the
// recommendation to retire it): it is shown by the shared `RecentActionCenter` holding a capture
// action, not by anything this screen remembers, so it cannot offer an undo the capsule has
// already spent — which is exactly what a second, mirrored copy would do the moment a task was
// closed on another tab.

extension CaptureInboxView {
    /// What is left of this screen's own bottom furniture: the partial-failure warning, and
    /// nothing else. The undo half moved to the app-wide capsule.
    @ViewBuilder
    var bottomBar: some View {
        if service.warningMessage != nil {
            triageWarningBar
        }
    }

    /// A partial success, said out loud. Undoing "Journal it" restores the capture first and
    /// deletes its entry second (see `undoJournalEntry`), so the delete can fail on its own — the
    /// capture is back, which is what was asked, but a duplicate entry is sitting in the journal
    /// and nothing else would ever mention it.
    ///
    /// Dismissed by tapping, not on a timer: a stray journal entry is not urgent, but it is the
    /// user's to deal with and it should not evaporate before they have read it.
    @ViewBuilder
    private var triageWarningBar: some View {
        if let warning = service.warningMessage {
            Button {
                service.warningMessage = nil
            } label: {
                HStack(spacing: 8) {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color("StateWarn"))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text("Dismiss")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tint)
                }
                .padding(.leading, 16)
                .padding(.trailing, CaptureDiscMetrics.clearance)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityIdentifier("captureInboxWarningBar")
        }
    }

    /// Always present once there is something to take back, so the net does not depend on noticing
    /// the capsule before it goes. Draws nothing without a centre — a preview, a snapshot — which
    /// is the same inert default every other site gets.
    @ViewBuilder
    var undoHeaderButton: some View {
        if let recentActionCenter {
            CaptureInboxUndoHeaderButton(center: recentActionCenter)
        }
    }
}

/// The header ↶, reading the app's shared slot.
///
/// **An `@ObservedObject` child rather than an `@Environment` read in the screen itself**, because
/// `@Environment` hands over the object without subscribing to it: a header that read
/// `center.pendingAction` directly would appear and vanish only when something else redrew the
/// screen. `CelebrationLayer` is the precedent.
///
/// It shows for a reversible CAPTURE action alone. The slot is shared now, so a task closed on
/// another tab can be sitting in it — and an arrow in the Capture Inbox's header that reopened a
/// task would be the wrong promise in the wrong place. The capsule itself is where that undo is
/// offered.
///
/// **`draftKeptInInbox` is a capture action and is still excluded** (`F-C2-DraftsToInbox`), which
/// is why the list below is not simply "the capture cases". This glyph is `arrow.uturn.backward`:
/// it promises to take something BACK, and a filed draft is kept rather than reversed — its
/// capsule offers "Reopen", not "Undo". Pointing a ↶ at a draft that is sitting in the very list
/// the user is looking at would promise an undo that does not exist.
struct CaptureInboxUndoHeaderButton: View {
    @ObservedObject var center: RecentActionCenter

    private var isCaptureAction: Bool {
        switch center.pendingAction?.kind {
        case .captureSorted, .captureSkipped, .captureJournalled, .captureDeleted:
            return true
        case .taskClosed, .nudgeDismissed, .draftKeptInInbox, .taskDeleted, nil:
            return false
        }
    }

    var body: some View {
        if isCaptureAction {
            Button {
                Task { await center.undo() }
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Undo the last triage action")
            .accessibilityIdentifier("captureInboxUndoHeaderButton")
        }
    }
}

// MARK: - The Reopen door (F-C2-DraftsToInbox)

extension CaptureInboxView {
    /// Opens the capture a filed draft's "Reopen" parked, then clears the slot.
    ///
    /// **It REFRESHES before it opens, and that is not belt-and-braces.** The draft was written
    /// seconds ago from a composer on another tab; this screen's list predates it, so without the
    /// refresh the capture would open over a list that does not contain it and closing the sheet
    /// would leave the user looking at an inbox missing the thing they were just told was kept.
    ///
    /// **Fetched by id rather than found in the list.** The list is filtered — the user may be on
    /// Sorted or Promoted — so a search through what happens to be loaded would silently fail on
    /// the two tabs out of three where the draft is not shown. A capture that has been deleted in
    /// between simply does not open; the slot is cleared either way so a failure cannot wedge the
    /// door shut.
    func drainReopenDoor() async {
        guard let captureId = pendingCaptureToInspect else { return }
        pendingCaptureToInspect = nil

        await service.refresh()
        guard let capture = try? await captureClient.fetchCapture(id: captureId) else { return }
        inspectingCapture = capture
    }
}
