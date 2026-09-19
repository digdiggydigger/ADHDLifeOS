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
| `46` routine screen | one next step, one big button, skip, quiet list: the reference pattern |
| `47`, `48` Today close undo card / Inbox undo bar | the two existing undo shapes (Inbox Undo 34x16pt) |
| `49`, `50` toolbar + New task / board after adding "Book an eye test" (Not yet) | **an undated task vanishes from the board it was added from** |
| `52` round 1 evidence board | the labelled board method (built with `scripts/audit/board.py`, opened in Preview for E) |
| `53` round 2 evidence board | drafts (Task composer loses text, Journal keeps it until quit), the two undo shapes (in-place card vs a 34x16pt bar under the disc), and where a Recently Deleted list could live |
| `54` round 2b undo-bar options | three undo-bar designs rendered with the REAL tokens (throwaway `ImageRenderer` probe on iPhone 17 Pro / 27.0, deleted after E chose) and composited onto fresh 18 Pro / 27.0 frames: Tasks light / dark / AX3, Inbox, sprint running. The page band under the furniture is blanked to page colour where a design moves or removes furniture. **E chose A** (capsule in the disc row) |
| `round-2b-undo-bar/` | the 15 full-size composites behind board `54` (`<option>-<state>.jpg`) |
| `55` round 3 Today options | Today now (12 sections, 3,125pt) vs A (1,517pt) / B (880pt) / C (480pt), cut from the stitched frame `56` and rearranged — real pixels, no drawing. **E chose C** (one next thing) |
| `56` Today, full length | the first clean full-length Today: 350pt slow scrolls (no momentum) stitched by the `homeTitle` offset, bottom furniture cut out; routine live at the Gym, ring 3 of 5 (after the round 3 clean-up) |
| `57` round 4 sprint evidence | the sprint's four surfaces and four control sets (card, collapsed card, sheet p1–p2, Lock Screen, finished card) |
| `58` round 4c sprint controls | E's six controls on the card (V1 one row 174pt / V2 two rows 222pt / V3 'Add time' menu 166pt, vs today 148pt), light + dark on the real sprint frame, AX3, and the 'Focus screen + Details' with the Custom stepper. Real-token `ImageRenderer` probe (deleted after); the card's `.regularMaterial` approximated by the card surface. **E chose V2 + the inline stepper** |
| `round-4c-sprint-controls/` | the full-size composites behind board `58` |
| `59` round 5 the one card | Today's one card (round 3 'C') in three button hierarchies (H1 Start first / H2 equal pair / H3 routine model) × light, dark, AX3, plus its states (suggested with Pin + 'Not this one', paused Resume, Leave by, live routine — the routine card is the REAL crop from `56`). Rendered with the real tokens (throwaway probe, deleted after), composited under the real Today header above the real tab bar. At AX3 the card overflows the screen in all three. **E chose H1** |
| `round-5-hero/` | the full-size composites behind board `59` |
| `60` round 6 composer options | today's two doors (disc → Task forces 'due today'; Tasks '+' opens a different sheet; a 'Not yet' task vanishes from the board; the fan's 'Everything goes to the inbox') vs one composer C1 (title + 3 chips) / C2 (title + next step) / C3 (everything folded), light / dark / AX3, real-token renders. **E chose 'C1 AND the C3 chips'** |
| `61` round 6b E's combo as read | title + four 'when' chips + area/time menus — **E: the chips are correct, the layout 'quite ugly'** |
| `62` round 7 targets | controls under 44pt (red) / 48pt (orange) boxed from the accessibility tree: Settings 40×40, Tasks '+' 27×36, filters 36, composer Cancel 77×36, chips 36, tag Add 24×14, Back 36×36, steppers 47×32, Journal 'All activity' 38×36, inbox Undo 34×16 |
| `63` round 8 pressure copy | 'OVERDUE' in headers and rows, 'Close it — keeps a 6-day streak', orange 'quiet since Tuesday', 'oldest is 13 hours old', 'decide or bin them'. **E chose** 'Still open', no header count, neutral 'last closed Tue', and inbox stats KEPT but framed as progress (gamification is essential — E) |
| `64` round 7b composer layouts | E's settled composer content in three layouts — L1 tidy grid / L2 form card / L3 rides on the keyboard — keyboard up (drawn as a 336pt block; the sim hides the software keyboard) and down, light / dark / AX3. Re-rendered in session 3 before E saw it: L3's Time reads "15 min" whole (was "15 / min", then "15…"), and all segments are round 7's 48pt (L2 and L3 were 40 and 44). L3's AX3 column still shows its known overlap. **E chose L3**, plus a text-only Date segment that shows the picked date |
| `round-7b-composer-layouts/` | the 12 full-size composites behind board `64` (`<layout>-<up|down>-<L|D|A>.jpg`) |
| `65` round 9a Dynamic Type at AX3 | sign-in segments stay tiny (AUTH-01), the ring 'OF 5 C…', 'Arran/ge' mid-word, Areas' 2 columns ('Relatio…'), task rows clip the due status — AX3 frames from `full/`. **E approved the fix list but kept Areas at 2 columns** |
| `66` round 9b contrast and colour jobs | eight text pairs rendered from the colorsets' hex with their WCAG ratios (light fails all seven text pairs; dark two; plus the settled badge), accent blue on labels you can't tap. **E: contrast left to the colour arc; colour jobs approved** |
| `67` round 10a sheets, Save, tap twins, loading | the Places chain driven on the 18 Pro this session: Places (swipe-only delete) → Edit place (sheet 1, Save on top, 'monitoring slots', 'Drag to reorder') → Edit action (sheet 2) → Apple's contact picker (sheet 3); Settings' ~310pt gap; '0 OPEN' while loading. **E chose one sheet with pushes, Save/Add at the bottom, ↑ ↓ + Delete buttons** |
| `68` round 10b words | the sprint's 'Deep entry' / 'Flow calibration' / 'Sprint target', 7- and 17-line Settings footers, Tools' 'WORKSHOP' and 52-word empty Routines card, the inbox's untrue 'lands here first'. **E approved every rename, 'Tasked', sentence case, and footers of one sentence + More** |
| `full/` | **every seeded tab frame** — `s-<tab>-L|D|A-pN.jpg` (light / dark / AX3, top→bottom) and `s-taskdetail-L-*`; the HIG reviews cite these (rounds 3, 4, 9) |
