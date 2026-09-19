# ADHD / neurodivergent UX audit — simulator evidence (2026-09-19)

**Environment:** iPhone 18 Pro simulator, iOS 27.0 (Xcode 27.0 / DeviceHub), Firebase **emulator** (never the live
project), throwaway account `audit@test.local` created by E by hand. First-run frames are the untouched new-account
state; everything else is after a scripted seed (33 documents: 17 tasks incl. 2 overdue and a 6-day closing streak,
5 captures, 3 journal entries, 2 nudges, 6 focus sessions — `seed_audit.py`, emulator only). Light unless the name
says `-D` (dark) or `-A` (Dynamic Type AX3). Branch `feature/adhd-ux-audit`.

**Why this folder exists:** the audit's findings are judged by looking and by driving the real screens — data loss
on Cancel, undo that is missing, density against E's Clutter Mandate, and what an ADHD user actually sees. Unit
tests cannot assert any of that. The yardstick is `handoff/SESSION-OPENER-adhd-ux-audit-design.md`.

**Throwaway data:** the emulator account and every seeded document die with the emulator; nothing touched the live
project. The simulator is to be erased at close-out.

| file | what it proves |
|---|---|
| `00`–`01` sign-in light / dark AX3 | primary action at the bottom; segmented control labels do not grow at AX3 |
| `02`–`08` first-run Home, Tasks, Captures, Tools, Settings p1–p3 | the brand-new-user path; Tasks says "3 OPEN" but lists 1; Settings footers; the Notifications card's empty gap (p3) |
| `09`–`12` seeded Today p1–p4 | Today is ~12 sections long (ring + streak, hero, life areas, due now, nudge, nudges, inbox, closed today, closed this week, week review, focus chart, 7-day trend) |
| `13`, `14` Today dark / AX3 | the same, dark and at AX3 |
| `15` Areas | Areas repeats Home's life-area list; orange "quiet since Tuesday" |
| `16`, `17` Tasks light / AX3 | overdue rows under "DUE TODAY"; "Overdue" meta; ▶ + ○ per row |
| `18`–`20` task detail | "Close it — keeps a 6-day streak"; sprint configurator; tags run off-screen; Save directly above Delete |
| `21`–`24` capture fan → Task composer → typed → reopened after Cancel | **Cancel silently discards typed text** |
| `25`–`27` Journal composer typed → reopened after swipe-down → after app quit | Journal keeps text across Cancel in-session; **loses it when the app quits** |
| `28`, `29` Capture Inbox | triage card + "Four are still sitting here — decide or bin them." |
| `30`, `31` Journal, Tools | timeline; Tools empty-state copy |
| `32`–`35` sprint card expanded / collapsed / full sheet p1–p2 | sprint surfaces vs E's Q2 "timer + task + +5m/End ONLY" |
| `36` Lock Screen Live Activity | FOCUS SPRINT, title, time, checkpoints, Pause + Stop; no +5m |
| `37`, `38` full right-swipe mid / after | **a full swipe closes a task with no confirm and no undo** |
| `39`, `40` nudge before / after "Done for now" | **nudge dismissal has no undo** |
| `41` Tasks while loading | reads "0 OPEN · 0 OVERDUE" before data arrives |
| `42` finished sprint card | "Take a 10-minute walk · 15m focused · 2 checkpoints · Confirm" |
| `43`, `44` Confirm celebration at 1.5 s / 3 s | full-screen dim + confetti + fireworks for a routine 15-minute sprint (settled design; recorded as evidence for the celebration-tier tension only) |
| `45` Tasks after ○ close | the closed task went straight to "Closed today": **no undo** |
