# Routines permission footer — E's device confirmation (F-RoutinesPermissionFooter, PR #18)

**Environment:** E's iPhone 15 Pro (`wishwashwacky15`), iOS 26.4, build `a3e4bde` installed
via `devicectl` 2026-09-07 04:28, production Firebase, E's real account, shots taken
~04:30–04:34 the same morning. All four are E's own screenshots, landed from chat.

**E's verdict: "the footer works."** E flipped Settings → Arrival nudges OFF, then simulated
an arrival at Home with the DEBUG test-fire button. This walk settled two things no test
asserts:

1. **The footer's real look under real rows** — the ⚠️ card sits below four listed routines,
   headline/body/button rendering as designed, warn triangle in `StateWarn`, above the tab
   bar with the capture disc clear of it.
2. **The test-fire × switch interplay is BY DESIGN, not a defect.** Shot 01 shows two
   notifications delivered while the switch was off — which looks like the footer's copy
   lying. It is not: E's arrival came from the DEBUG simulate-arrival button, which hard-wires
   the gate open (`PlaceTriggerTestFire` passes `isEnabled: { true }`, and the button's own
   dialog says "Cooldown and the nudge master switch are bypassed"). A REAL crossing with the
   switch off registers no fence at all, and the fire-time gate kills stragglers. If this
   folder is ever read in an investigation of "notifications despite the switch being off",
   check whether the trigger was the test-fire button before suspecting the gate.

No throwaway data: the 4:30 journal rows are E's own deliberate test records, kept (the
review-session precedent).

| file | what it proves |
|---|---|
| `00-footer-under-listed-routines.jpeg` | THE block evidence: "Arrival nudges are off" card with body copy and the "Turn arrival nudges back on" button, rendered under four listed routine rows on Tools (04:31, switch off). |
| `01-testfire-notifications-switch-off.jpg` | Two arrival notifications delivered with the switch off — the DEBUG test-fire's designed bypass, NOT the gate failing. The routine offer's copy ("2 steps ready … Tap to run.") also legible. |
| `02-journal-offer-row-eye-on.jpeg` | The 4:30 "Routine offered at Home · not opened" row beside the arrival — the offer record from the bypassed fire, eye ON. |
| `03-journal-eye-off.jpeg` | The same timeline with the eye OFF: every routine row hidden, arrivals and the written log kept — the routine-record arc's eye rule still holding on this build. |
