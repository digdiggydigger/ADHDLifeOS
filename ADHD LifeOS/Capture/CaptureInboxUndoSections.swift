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
// Two affordances, deliberately, because they answer different questions. The bar says WHAT just
// happened at the moment it happens and offers to take it back; the header arrow is the safety net
// you reach for later, when you have already looked away. Both drive the one spent-once action in
// `CaptureInboxService+Triage`, so they can never disagree about what would be reversed.

extension CaptureInboxView {
    /// The bottom bar has two jobs and they are mutually exclusive: offer the undo, or report what
    /// an undo left behind. The warning wins — it is news, and the offer it would replace has
    /// already been spent.
    @ViewBuilder
    var bottomBar: some View {
        if service.warningMessage != nil {
            triageWarningBar
        } else {
            undoBar
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

    @ViewBuilder
    var undoBar: some View {
        if let action = service.lastTriageAction {
            HStack(spacing: 8) {
                Label(
                    CaptureTriage.confirmation(
                        for: action, sortedInto: service.lastSortedAreaId, lifeAreas: lifeAreas
                    ),
                    systemImage: "arrow.uturn.backward"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Button("Undo") {
                    Task { await undoLastTriage() }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(minHeight: 44)
            }
            .padding(.leading, 16)
            // Trailing room for the capture disc, which otherwise floats directly over the Undo
            // button and makes it untappable (E's screenshot, 2026-08-28).
            .padding(.trailing, CaptureDiscMetrics.clearance)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(
                .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
                value: service.lastTriageAction
            )
            // `.contain`, not `.combine`. Combining merged the Undo button INTO the bar, leaving
            // one element carrying a label and an action fused together — the button could not be
            // addressed, reasoned about, or reached on its own. The bar is a container holding a
            // control, which is what `.contain` means. Same correction as the nudges section on
            // Today, and the reason this screen now has a journey that taps that button.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("captureInboxUndoBar")
        }
    }

    /// Always present once there is something to take back, so the net does not depend on noticing
    /// the bar before it goes.
    @ViewBuilder
    var undoHeaderButton: some View {
        if service.lastTriageAction != nil {
            Button {
                Task { await undoLastTriage() }
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
