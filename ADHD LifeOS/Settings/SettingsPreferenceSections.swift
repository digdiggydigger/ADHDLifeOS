//
//  SettingsPreferenceSections.swift
//  ADHD LifeOS
//
//  The momentum, focus and feedback preference sections, split from `SettingsView.swift` for its
//  file and type-body budgets once the 2026-08-25 Settings audit grew them (the
//  `HomeAccessoryStrips` arrangement).
//

import SwiftUI

extension SettingsView {
    // MARK: - Section 0 — What counts as momentum (Concept C, block M2)

    var momentumSection: some View {
        Section {
            Stepper(
                value: Binding(
                    get: { momentumPreferences.dailyGoal },
                    set: { newValue in
                        momentumPreferences.dailyGoal = newValue
                        momentumPreferencesStore.write(momentumPreferences)
                    }
                ),
                in: MomentumPreferences.goalRange,
                onEditingChanged: { editing in
                    // E's 2026-08-27 call: a stepper confirms ONCE, on release — holding to ramp a
                    // value must not machine-gun. `onEditingChanged` goes false when the press ends,
                    // which is also the end of a single tap, so every interaction ticks exactly once.
                    if !editing { Haptics.play(.selection) }
                },
                label: {
                    LabeledContent(
                        "Daily goal",
                        value: "\(momentumPreferences.dailyGoal) "
                            + (momentumPreferences.dailyGoal == 1 ? "item" : "items")
                    )
                }
            )
            .accessibilityIdentifier("settingsMomentumGoalStepper")

            Toggle("Show streaks", isOn: Binding(
                get: { momentumPreferences.showStreaks },
                set: { newValue in
                    momentumPreferences.showStreaks = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsMomentumStreaksToggle")

            Toggle("Count cleared captures", isOn: Binding(
                get: { momentumPreferences.countClearedCaptures },
                set: { newValue in
                    momentumPreferences.countClearedCaptures = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsMomentumCapturesToggle")

            Toggle("Count nudges", isOn: Binding(
                get: { momentumPreferences.countNudges },
                set: { newValue in
                    momentumPreferences.countNudges = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsMomentumNudgesToggle")

            Toggle("Show weekly charts", isOn: Binding(
                get: { momentumPreferences.showCharts },
                set: { newValue in
                    momentumPreferences.showCharts = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsMomentumChartsToggle")
        } header: {
            Text("What counts as momentum")
        } footer: {
            Text(
                "Turn streaks off and the app keeps every number but stops counting consecutive "
                    + "days. Counting cleared captures lets anything you archive, promote or "
                    + "journal from the inbox advance the ring too. Counting nudges does the same "
                    + "for every nudge you dismiss today. Weekly charts can be hidden without "
                    + "losing any numbers."
            )
        }
    }

    // MARK: - Focus (E's 2026-08-25 Settings audit)

    var focusSection: some View {
        Section {
            Stepper(
                value: Binding(
                    get: { momentumPreferences.focusDailyGoalMinutes },
                    set: { newValue in
                        momentumPreferences.focusDailyGoalMinutes = newValue
                        momentumPreferencesStore.write(momentumPreferences)
                    }
                ),
                in: MomentumPreferences.focusGoalRange,
                step: 5,
                onEditingChanged: { editing in
                    // E's 2026-08-27 call: a stepper confirms ONCE, on release — holding to ramp a
                    // value must not machine-gun. `onEditingChanged` goes false when the press ends,
                    // which is also the end of a single tap, so every interaction ticks exactly once.
                    if !editing { Haptics.play(.selection) }
                },
                label: {
                    LabeledContent("Daily focus goal", value: "\(momentumPreferences.focusDailyGoalMinutes) min")
                }
            )
            .accessibilityIdentifier("settingsFocusGoalStepper")

            Stepper(
                value: Binding(
                    get: { momentumPreferences.defaultSprintMinutes },
                    set: { newValue in
                        momentumPreferences.defaultSprintMinutes = newValue
                        momentumPreferencesStore.write(momentumPreferences)
                    }
                ),
                in: MomentumPreferences.sprintMinutesRange,
                step: 5,
                onEditingChanged: { editing in
                    if !editing { Haptics.play(.selection) }
                },
                label: {
                    LabeledContent("Default sprint length", value: "\(momentumPreferences.defaultSprintMinutes) min")
                }
            )
            .accessibilityIdentifier("settingsSprintLengthStepper")
        } header: {
            Text("Focus")
        } footer: {
            Text(
                "The daily goal is what the focus charts and the Home Screen widget's ring measure "
                    + "against. The sprint length is where a one-tap start begins for a task with "
                    + "no plan of its own — a task's saved plan always wins."
            )
        }
    }

    // MARK: - Feedback (E's 2026-08-25 Settings audit)

    var feedbackSection: some View {
        Section {
            Toggle("Haptics", isOn: Binding(
                get: { momentumPreferences.hapticsEnabled },
                set: { newValue in
                    momentumPreferences.hapticsEnabled = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsHapticsToggle")

            // Straight after Haptics, because these two govern the app's OWN feedback; the
            // notification row below them governs what iOS plays for a scheduled reminder.
            Toggle("Celebrations", isOn: Binding(
                get: { momentumPreferences.celebrationsEnabled },
                set: { newValue in
                    momentumPreferences.celebrationsEnabled = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsCelebrationsToggle")

            Toggle("Celebration sounds", isOn: Binding(
                get: { momentumPreferences.celebrationSoundsEnabled },
                set: { newValue in
                    momentumPreferences.celebrationSoundsEnabled = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsCelebrationSoundsToggle")

            Toggle("Notification sounds", isOn: Binding(
                get: { momentumPreferences.soundEnabled },
                set: { newValue in
                    momentumPreferences.soundEnabled = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsSoundToggle")

            Toggle("Remember where things happen", isOn: Binding(
                get: { momentumPreferences.locationTaggingEnabled },
                set: { newValue in
                    momentumPreferences.locationTaggingEnabled = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                }
            ))
            .accessibilityIdentifier("settingsLocationTaggingToggle")

            Toggle("Arrival nudges", isOn: Binding(
                get: { momentumPreferences.arrivalNudgesEnabled },
                set: { newValue in
                    momentumPreferences.arrivalNudgesEnabled = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                    Haptics.play(.selection)
                    // The fences must follow the switch NOW — a nudge arriving after E turned
                    // this off reads as the app ignoring them.
                    Task { await LocationTriggerService.shared.refreshRegistrations() }
                }
            ))
            .accessibilityIdentifier("settingsArrivalNudgesToggle")

            // The toggle above only decides whether the app ASKS; iOS holds the real gate. Without
            // this row a switch left on while permission is denied looks like a broken feature.
            if #available(iOS 17.0, *) {
                LocationPermissionBanner(wantsTriggering: false)
            }
        } header: {
            Text("Feedback")
        } footer: {
            // The sentences run in ROW order, not in the order they were written: appended at the
            // end, the celebration ones sit four rows below the switches they explain, and a
            // VoiceOver user swiping the section linearly reaches them last of all.
            Text(
                "Haptics are the app's tactile confirmations — saving, promoting, starting a "
                    + "sprint. Celebrations covers every full-screen moment — the confetti when you "
                    + "confirm a finished sprint, and the milestone celebrations still to come; "
                    + "haptics and the small in-place flourishes are left alone either way. "
                    + "Celebration sounds will add one soft chime to those moments, and does nothing "
                    + "until the chime arrives in a later update. Notification sounds only covers "
                    + "the reminders this app schedules; your iOS notification settings are "
                    + "untouched. Remembering where things happen records the spot a capture was "
                    + "made, and only ever while iOS has granted location access — turning it off "
                    + "here stops it regardless. Arrival nudges is the master switch over every "
                    + "place's nudges: one flip silences them all, and the per-place choices are "
                    + "kept for when it comes back on."
            )
        }
    }
}
