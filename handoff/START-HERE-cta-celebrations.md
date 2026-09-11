# START HERE — celebrations for the app's other call-to-action buttons

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-11 at the close of the session that built the Confirm celebration. **The
session that writes this arc's successor archives this file in the same move.***

**STATUS: NOTHING IS BUILT FOR THIS ARC.** It starts with design, and E is the design authority.
Nothing below is a decision unless it quotes E.

## What E asked for, verbatim

> *"I want to focus on assigning animations such as this one we've just created to other CTA
> buttons etc. throughout the app."*

"This one" is the **Confirm celebration**: a full-screen done-green glow with confetti raining from
the top and fired from both bottom corners, plus the success haptic. It plays when a finished
sprint's card is confirmed. E approved it by video and called it "really good"; it is on E's phone.

## Read first, in this order

1. **CLAUDE.md's start-of-session checklist.** `claudecode.md`, "Architecture notes", and **§7**
   (the iOS 16 floor, modern APIs, Reduce Motion) in particular.
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (the twenty-eighth edition or later) — THE outstanding list.
3. **`handoff/SESSION-OPENER-confirm-celebration-design.md`** — the permanent record of how the
   Confirm celebration was designed: E's nine answers, the numbers, the §7.2 waiver, and why each
   choice was made. The next design should be run the same way.
4. The evidence: `screenshots/confirm-celebration-prototypes/` (what E chose from) and
   `screenshots/confirm-celebration-block-1/` (what shipped, including `12-…5.4s.mp4`).

## The device verdicts are in

E, after this opener was written: *"i have done the animation checks on my iphone with Reduce Motion ON and OFF and it works correctly in both states."* So:
- **`F-ModernIOS-2-Celebration` is CLOSED.** The draw-on timing and the 1.6 reduced halo stay as
  shipped.
- **`F-ConfirmCelebration-1` passed**, at the stretched 5.4 s.
- **`F-ConfirmCelebration-2`** (14 fireworks + light-mode 85% dim on the stack-clearing Confirm) is
  approved and no longer blocked on a verdict. It still has two open questions for E: does the +1.2 s
  stretch apply to the fireworks, and should block 2 wait for this arc's design, which may generalise
  the engine? **Ask before building it.**

## The constraints this arc cannot design around

- **Reduce Motion.** E's phone runs Reduce Motion ON. The rule (§7.2) is: replace motion with a fade,
  never remove the feedback.
  - **The Confirm celebration is the ONE sanctioned waiver**, and CLAUDE.md says it "covers that one
    site and nothing else". Every new site needs E's own Reduce Motion answer. Do not extend the
    waiver by analogy.
  - `testTheConfirmCelebrationIgnoresReduceMotionByDesign` pins the one waiver.
- **The off switch.** Register §D records a launch blocker: no way to turn the confetti off, which
  hits people who turned Reduce Motion on for motion sensitivity. **Spreading celebrations across the
  app makes this more pressing.** Put it to E in the design, not after.
- **The public launch** (memory: design for many users, not only E).
- **The iOS 16.0 floor (§7.1).** The engine is `Canvas` + `TimelineView` (iOS 15), so it needs no
  `#available`. Any modern tier ships only behind a gate with a complete 16 path.
- **Tokens only (§4, the `raw_hue_color` lint rule)**, the 4/8/16/24 grid (§2), and haptics through
  `Theme/Haptics.swift` (`.haptic(_:trigger:)` / `Haptics.play`), never `.sensoryFeedback` directly.
- **SwiftLint ceilings:** 400-line file, 250-line type body, 40-character type name. `RootView.swift`
  is at 394 and `FocusSessionService.swift` at 374.

## The engine that exists (reuse before rebuilding)

All in `ADHD LifeOS/Focus/`:
- **`ConfettiPhysics.swift`** — pure. `ConfettiPiece`, `ConfettiPhysics.state(of:at:)` (closed-form
  drag-damped flight, tumble, flutter, fade), `ConfettiRandom` (SplitMix64, deterministic).
- **`ConfirmCelebrationRecipe.swift`** — pure.
  - `ConfettiRecipe`: 120 rain + 100 cannons, 7 tokens, seeded per ordinal.
  - `ConfirmCelebrationGlow`: envelope, one glow at the strongest.
  - `ConfirmCelebrationBurst`.
  - `ConfirmCelebrationQueue`: cap 3, pruning, and E's 1.2 s stretch through `choreographyTime(of:at:)`.
- **`ConfirmCelebrationOverlay.swift`** — the view.
  - Mounted once in `RootView` (`.overlay { ConfirmCelebrationOverlay(focusService: focusService) }`),
    with no hit testing and hidden from VoiceOver.
  - `ConfirmCelebrationFrame(scenes:date:)` draws any instant, which is what makes render probes
    possible.
  - **It is keyed to ONE trigger:** `FocusSessionService.latestConfirmation`, a stamp written only
    by `confirmCompletion`.
- **Generalising it is a design question, not a decided one.** Other buttons live in other services
  (tasks, captures, journal, nudges, routines), so a cross-app trigger needs somewhere app-level to
  meet, for example an injected celebration object RootView owns. The 400-line bar and the "listener
  must be always mounted" trap (`testTheHapticListenerOutlivesTheStack`) both apply.
- Also existing: **`FocusCompletionCelebration`**, the small in-ring halo + tick (three motion modes,
  Reduce Motion first). It is a precedent for an IN-PLACE celebration rather than a full-screen one.

## A starting survey of the app's call-to-action moments

Surveyed read-only on 2026-09-11. **Every `file:line` below was re-read at close and lands on the
button described; the feedback column was spot-checked on 8 rows.** Line numbers drift, so re-read
before editing anything. Paths are under `ADHD LifeOS/`. "pre" means the haptic fires on
tap, before the write lands.

| area | site | what the user does | feedback today |
|---|---|---|---|
| Tasks | `Tasks/TaskRow.swift:110` (+ swipe :146) | closes a task (circle / swipe) | `.taskClose` (= `.success`) pre; strikethrough, no close animation |
| Tasks | `Tasks/TaskDetailFormSections.swift:93` | "Close it" | `.taskClose` pre; no animation |
| Tasks | `LifeAreaDetail/AreaTaskRow.swift:53` | closes a task from an area | `.taskClose` pre |
| Tasks | `Tasks/TaskCreateView.swift:256` | "Add the task" | `.solid` on success / `.error` |
| Today | `Home/MomentumScoreboardViews.swift:260` | "Close it" on Best next move | `.taskClose` pre; `ClosureCelebrationCard` pops in with NO animation |
| Today | `Home/DailySummaryView.swift:173` | "Generate" the daily summary | `.success` / `.error` after the await |
| Captures | `Capture/CaptureInboxSections.swift:183` | "Sorted" on triage | `.success` pre; green bloom = "ready", not a celebration |
| Captures | `Capture/CaptureDetailComponents.swift:286` | round ✓ Sorted on detail | **`.solid`** pre (vs `.success` on triage) |
| Captures | `Capture/CaptureRowComponents.swift:28` | "Create Task" from a capture | `.haptic(.success, …)` on success |
| Captures | `Capture/CaptureInboxSections.swift:155` | "Journal it" | `.success` pre |
| Captures | `Capture/QuickCaptureComponents.swift:368` | "Save to inbox" / "Add to Today" | `.solid` on success / `.error` |
| Journal | `Journal/LogComposerView.swift:299` | "Save entry" | `.solid` on success / `.error` |
| Nudges | `Nudges/NudgeDueCard.swift:34` | "Done for now" (a completion; feeds the streak dots) | **only `.light`** pre |
| Routines | `Places/PlaceRoutineScreen.swift:201` | a step's action (marks it done) | `.solid` pre; a spring on the run |
| Routines | — | finishing the whole routine | **nothing**: there is no finish button, and the run completes when the screen is left |
| Places | `Places/PlaceEditorView.swift:67` | "Save" a place | **no haptic in `save()`** |
| Focus | `Focus/FocusCompletionCard.swift:130` | **Confirm (the reference)** | full-screen celebration + `.success` |
| Focus | `Focus/FocusTimerBar.swift:142` | "Stop sprint" (early) | none |
| Focus | `Focus/OfflineSprintSummaryCard.swift:50` | "Got it" | none (and parked in register §C) |
| Auth | `Auth/LoginFormSections.swift:262` | "Sign in" / "Create account" | `.solid` / `.error` after the await |
| Areas / tags | `LifeAreaEditor/LifeAreaEditorListView.swift:198`, `TagEditor/TagEditorListView.swift:172` | create a life area / tag | `.solid` on success / `.error` |

**Also found:** the inbox-zero empty state (`Capture/CaptureInboxView.swift:237`) is written to
read as an achievement, and every primary button style shrinks to 0.97 on press. `HapticFeel` has
six cases (`selection`, `light`, `solid`, `success`, `warning`, `error`), plus the aliases
`tabChange` = `.light` and `taskClose` = `.success`.

## Questions that are E's (put one at a time, as the Confirm design did)

These are prompts, not recommendations. None is decided:
- **Which moments earn a celebration at all**, and at what size: full-screen (like Confirm),
  in-place on the button or row (like the in-ring halo), haptic-only, or nothing? Closing a task and
  saving a place are different in kind.
- **Frequency.** Does a task closed ten times a day get the same celebration as a sprint confirmed
  once? Is a celebration that plays on every close still a reward?
- **Reduce Motion, per site** (the waiver covers only Confirm), and whether the off switch now
  comes before launch.
- **Consistency the survey surfaced:**
  - Sorted is `.success` on triage but `.solid` on detail.
  - "Done for now" completes a nudge with only `.light`.
  - Saving a place and stopping a sprint have no haptic.
  - `ClosureCelebrationCard` pops in unanimated.

  Whether to tidy these is E's call.

## How to run the session

- **Use `superpowers:brainstorming` on the ARCHITECTURAL path** (a cross-app subsystem).
  - Questions one at a time, with options and a recommendation.
  - **Show, don't describe:** throwaway render probes and videos sent with SendUserFile. The Confirm
    prototypes were decided that way.
  - The probe technique (a scene-attached `UIWindow` + `drawHierarchy(afterScreenUpdates: true)`,
    an injected time, ffmpeg) is described in `screenshots/confirm-celebration-block-1/README.md`
    and the register §E.
- **Write a `SESSION-OPENER-*` design record** with E's answers verbatim and your recommendations
  kept separate. E approves it before any build.
- **Then FEATURE blocks, test-first:** a predicted red, red-checks on a committed tree, in-situ
  renders, and a device verdict per block (CLAUDE.md "Visual evidence" and §7.3's Verified paths
  line).

## Environment notes

- **Open Xcode on the project BEFORE starting the session**, or the `xcode` MCP bridge is absent all
  session (it was down this whole session).
- Start the Firebase emulator (`./scripts/emulators.sh`) before the suite; the bar is 0
  `127.0.0.1:9099` hits.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only runtime).
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3`. Its dev profile is valid to **2026-09-17**;
  when it lapses, E re-signs via Xcode → Settings → Accounts.
- **Baseline at close:** suite 2,710 / 0, lint 0 / 751, app coverage 26.87% (measured at block 1).
