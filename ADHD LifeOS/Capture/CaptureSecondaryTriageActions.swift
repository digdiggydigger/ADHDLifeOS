//
//  CaptureSecondaryTriageActions.swift
//  ADHD LifeOS
//
//  Split out of `CaptureRowComponents` when the journal exit grew its energy/mood strip and pushed
//  that file over its 400-line budget.
//

import SwiftUI

/// The triage exits that are not "make this a task". Before these, promote-to-task was the only way
/// out of the inbox, so anything that wasn't a task simply accumulated.
///
/// Discard only REQUESTS the confirmation — the dialog itself lives on the row, because it is the
/// row that knows which capture is about to go.
struct CaptureSecondaryTriageActions: View {
    @Binding var isLoggingToJournal: Bool
    let onLogToJournal: (EnergyLevel, String) async -> Bool
    let onRequestDiscard: () -> Void

    /// Owned here rather than by `CaptureRowView`: the row never reads these, and holding them
    /// there pushed it past its type-body budget for no benefit.
    ///
    /// Seeded to the web composer's own starting selection, so the one-tap journal exit still
    /// records something honest rather than nothing.
    @State private var journalEnergyLevel: EnergyLevel = .medium
    @State private var journalMoodEmoji = JournalMood.defaultEmoji

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pre-selected, so "Log to journal" below stays a ONE-TAP exit — the whole point of
            // this row. Adjusting first is optional; the web's inbox form made it a required stop,
            // which is exactly the friction an ADHD triage flow cannot afford.
            JournalEnergyMoodPicker(
                energyLevel: $journalEnergyLevel, moodEmoji: $journalMoodEmoji, isCompact: true
            )
            .accessibilityIdentifier("captureJournalEnergyMoodPicker")

            actionRow
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                Task {
                    isLoggingToJournal = true
                    _ = await onLogToJournal(journalEnergyLevel, journalMoodEmoji)
                    isLoggingToJournal = false
                }
            } label: {
                Label("Log to journal", systemImage: "book")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ChoiceChipButtonStyle(isSelected: false))
            .disabled(isLoggingToJournal)
            .accessibilityIdentifier("captureLogToJournalButton")

            Button(action: onRequestDiscard) {
                Label("Discard", systemImage: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ChoiceChipButtonStyle(isSelected: false))
            .accessibilityIdentifier("captureDiscardButton")
        }
    }
}
