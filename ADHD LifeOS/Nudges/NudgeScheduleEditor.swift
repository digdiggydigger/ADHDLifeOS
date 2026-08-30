//
//  NudgeScheduleEditor.swift
//  ADHD LifeOS
//
//  Split out of `NudgesView.swift` by F-NudgePresets, which pushed that file to 481 lines against
//  the 400 budget. The standing rule is that the next feature touching an over-budget file splits
//  it (the `TaskDetailView` precedent under F-DiscClearance), and the schedule editor is the
//  natural seam: it is the one part shared by the Add sheet and every row's Edit form.
//

import SwiftUI

/// Presets first, the day-by-day picker as the disclosure behind Custom, then the time.
///
/// Shared between the Add sheet and each row's Edit form, so both get the rebuild.
///
/// **Why presets lead.** Almost every nudge is "every day", "weekdays" or "weekends", and the old
/// editor charged five taps for the commonest of those on chips too narrow to read their own
/// labels. `NudgeSchedulePreset` carries the sets and the summary line; this view only renders
/// them, so the cron off-by-one that makes weekdays `1...5` rather than `0...4` is asserted in
/// unit tests rather than trusted here.
struct NudgeScheduleEditor: View {
    @Binding var schedule: NudgeSchedule
    let idPrefix: String

    /// Fires when the day-by-day row opens or closes, so a presenting sheet can grow to fit it.
    /// The editor stays self-configuring; the row Edit form, which is not a sheet, omits it.
    var onCustomDaysVisibilityChanged: ((Bool) -> Void)?

    /// Whether the day-by-day row is showing. Seeded from the schedule itself so EDITING a nudge
    /// that already has a custom pattern opens with its days visible rather than hiding them
    /// behind a chip the user would have to guess at.
    @State private var showsCustomDays: Bool?

    private var preset: NudgeSchedulePreset {
        NudgeSchedulePreset.matching(weekdays: schedule.weekdays)
    }

    private var isShowingDays: Bool {
        showsCustomDays ?? (preset == .custom)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Repeat").sectionLabel()
                presetGrid
                // The summary sits under whatever it is describing. With the day row CLOSED it
                // captions the preset chips; with it open it captions the days. Left above the
                // days it read as a contradiction — a lit "Custom" chip over the words "Every
                // day" — when in fact it was describing the seven days Custom had preserved.
                if !isShowingDays { daySummary }
            }

            if isShowingDays {
                VStack(alignment: .leading, spacing: 8) {
                    dayRow
                    daySummary
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()

            DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                .font(.body)
                .frame(minHeight: 44)
                .haptic(.selection, trigger: schedule.minute)
                .accessibilityIdentifier("\(idPrefix)TimePicker")
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: isShowingDays)
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: schedule.weekdays)
        .onChange(of: isShowingDays) { showing in
            onCustomDaysVisibilityChanged?(showing)
        }
    }

    private var daySummary: some View {
        Text(NudgeSchedulePreset.daySummary(weekdays: schedule.weekdays))
            .font(.footnote)
            .foregroundStyle(schedule.weekdays.isEmpty ? Color("StateRisk") : Color.secondary)
            .accessibilityIdentifier("\(idPrefix)DaySummary")
    }

    /// Two rows of two rather than one row of four: "Weekends" and "Custom" do not fit four-across
    /// at accessibility text sizes, and this is the shape that wrapped labels in the first place.
    private var presetGrid: some View {
        VStack(spacing: 8) {
            ForEach([[NudgeSchedulePreset.daily, .weekdays], [.weekends, .custom]], id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { option in
                        presetChip(option)
                    }
                }
            }
        }
    }

    private func presetChip(_ option: NudgeSchedulePreset) -> some View {
        Button {
            Haptics.play(.selection)
            if let days = option.weekdays {
                schedule.weekdays = days
                showsCustomDays = false
            } else {
                // Custom reveals the picker and KEEPS whatever is selected — it is a disclosure,
                // not a reset. Clearing here would throw away the days the user just chose.
                showsCustomDays = true
            }
        } label: {
            Text(option.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: isChipSelected(option)))
        .accessibilityIdentifier("\(idPrefix)Preset-\(option.rawValue)")
        .accessibilityAddTraits(isChipSelected(option) ? .isSelected : [])
    }

    /// Custom lights up whenever the day row is open, so the chip that produced the visible state
    /// is the one that looks chosen — including while a custom set is being assembled.
    private func isChipSelected(_ option: NudgeSchedulePreset) -> Bool {
        option == .custom ? isShowingDays : (preset == option && !isShowingDays)
    }

    /// Seven single letters at an equal share of the width. The old row put "Sun"/"Wed" in chips
    /// sized by `.bordered` inside a `Form` inset, which left roughly 40pt each — narrower than
    /// the label — so every one wrapped. Single letters plus `maxWidth: .infinity` cannot.
    private var dayRow: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { day in
                let isSelected = schedule.weekdays.contains(day)
                Button {
                    Haptics.play(.selection)
                    if isSelected {
                        schedule.weekdays.remove(day)
                    } else {
                        schedule.weekdays.insert(day)
                    }
                } label: {
                    Text(NudgeSchedulePreset.initials[day])
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ChoiceChipButtonStyle(isSelected: isSelected))
                .accessibilityIdentifier("\(idPrefix)WeekdayToggle-\(day)")
                .accessibilityLabel(NudgeSchedulePreset.symbols[day])
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var timeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: Date())
                    ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                schedule.hour = components.hour ?? schedule.hour
                schedule.minute = components.minute ?? schedule.minute
            }
        )
    }
}
