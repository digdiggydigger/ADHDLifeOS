# F-CTACelebrations-2 — the two celebration switches

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2× from
the unit-test host on `feature/cta-celebrations-2` @ `84b94ca`, 2026-09-12 (07:16–07:19 BST).
- **No backend, no account, no sign-in, nothing written anywhere.** Every client is a test double
  (`FakeAuthClientAdapting`, `FakeTagEditorClientAdapting`, `FakeLifeAreaEditorClientAdapting`,
  `FakeAccountDeletionClientAdapting`, `FakeNotificationAuthorizationReading`) and the preferences
  store is in-memory, so the probe never touches Firestore and never writes the simulator's own
  `UserDefaults`.
- The scene in 00/01 is the **real `SettingsView.feedbackSection`** inside a real `Form` — in situ,
  not a copy of the rows. The scene in 02–04 is the **real `ConfirmCelebrationOverlay`** over
  `Color.pageBackground`, with the Confirm stamped **after** mount so the layer's own `.onChange` is
  what starts (or refuses) the burst.
- The probe (`ZZCelebrationSwitchProbe.swift`) ran from the test target and was removed from the
  tree before the commit that adds this folder. Rebuild it from "How to rebuild the probe" below.
- **No throwaway data was created**, on device or in any backend, so there was nothing to clean up.

The design: `handoff/SESSION-OPENER-cta-celebrations-design.md` — E's decisions **#3** ("a
Celebrations switch, ON by default, turning off every FULL-SCREEN celebration; haptics and in-place
feedback stay") and **F5** ("Celebration sounds", OFF by default), and §4 "The switches and the
chime".

## Verified paths (CLAUDE.md §7.3)

> **No `#available` site is added or changed by this block, and no tier was passed over.** The two
> `Toggle`s, the preferences round-trip and the fire-time gate are all iOS 13–15 API; §7.1's filter
> asks whether a later tier shows the user something the tier below cannot, and here none does.
> - **Full path:** run on the 26.5 simulator (00–04 below) and on E's phone from `main`.
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.
>
> **No RM-on device pass is owed, and this is the reason** (§7.3, E's call 2026-09-12). A block owes
> one only when it ADDS or CHANGES a reduced site. This block adds none: two switches, a
> preferences round-trip and a gate render nothing, and the one thing they gate — the Confirm
> celebration — is **§7.2's named waiver**, which reads Reduce Motion nowhere and plays identically
> with the setting on or off. An RM-on pass here would prove nothing that the RM-off pass does not.
> The first block that owes one is `F-CTACelebrations-4`, the nine pops.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

`CelebrationSwitchCallSiteTests` proves the gate is **in the tree** — that `guard celebrationsGate()`
sits inside the Confirm listener, ahead of the line that appends the burst. It cannot prove the tree
**runs**: a gate whose closure is never evaluated, or evaluated against the wrong store, is a string
that passes every assertion while the confetti falls anyway. 02–04 are that proof, and they were
produced by driving the real listener rather than by reading the source.

The two rows are the other half. No test in this repo can say whether a `Toggle` reads well, sits
where a user expects it, or is explained by the sentence beneath it.

## What these settle that the tests cannot

1. **The rows are where the design put them, in both appearances.** Haptics → **Celebrations** →
   **Celebration sounds** → Notification sounds → Remember where things happen → Arrival nudges,
   with Celebrations shipped ON and Celebration sounds shipped OFF — visible in 00 and 01 as the
   only grey switch in the section.
2. **The switch OFF is not "quieter", it is nothing.** 02 and 03 are **byte-identical**, SHA-256
   `e317cfd203b95e95e888579c350e88ffd35a8eb7ef29470ca727fbfa46215161` for both — a window that
   mounted the overlay with the switch off, and a window that never mounted the overlay at all.
   Measured in the probe by comparing raw RGBA: **0 differing pixels of 943,200**.
3. **And that claim is not vacuous, which is the point of 04.** "Identical to nothing" is also true
   of a probe that forgot to stamp a Confirm. The same scene with the gate forced ON differs from
   the never-mounted baseline in **943,200 of 943,200 pixels** — every pixel, because the done-green
   glow washes the whole screen. The probe asserts the control FIRST and fails loudly if it ever
   stops differing.
4. **The footer explains the rows beside them.** The two new sentences follow the Haptics sentence,
   in row order, rather than being appended at the end where they would sit four rows below the
   switches they describe — and where a VoiceOver user swiping the section linearly would reach them
   last of all. Raised by the `apple:hig-reviewer` pass; pinned by an assertion red-checked against
   the appended version.

## The files

| file | what it proves |
|---|---|
| `00-feedback-section-light.jpg` | The real Feedback section, light. Both new rows present, in row order after Haptics, at their shipped defaults (Celebrations on, Celebration sounds off), with the full footer legible below. |
| `01-feedback-section-dark.jpg` | The same section, dark. The off switch still reads as off against the dark card; nothing clips. |
| `02-confirm-switch-off.png` | A Confirm stamped into the real listener with the Celebrations switch **off**. Nothing drew. PNG because the claim is pixel-exact. |
| `03-confirm-overlay-never-mounted.png` | The same scene with **no overlay mounted at all**. Byte-identical to 02 — same SHA-256. PNG for the same reason. |
| `04-confirm-switch-on-control.jpg` | The **control**: the same scene with the switch **on**, differing from 03 in every one of its 943,200 pixels. Without this row, 02 = 03 would prove nothing. JPEG — the pixel count comes from the probe's in-memory RGBA comparison, not from this file. |

## How to rebuild the probe

A throwaway `XCTestCase` in the test target (`@MainActor`, named `ZZ…` so it sorts last), deleted
before the commit. The pieces that matter, all of which cost a run to get right somewhere in this
arc:

- **A scene-attached `UIWindow`.** `drawHierarchy(in:afterScreenUpdates:)` renders nothing from a
  detached one — take `UIApplication.shared.connectedScenes.first as? UIWindowScene` and fail loudly
  if it is missing.
- **A synchronous run-loop pump**, not an `async` test: `TimelineView(.animation)` needs the main
  run loop to turn, and `RunLoop.main.run(mode:before:)` in a `while` is what turns it. Mount, pump
  ~0.25 s, THEN write `service.latestConfirmation` — stamping before mount would let the layer come
  up with the burst already in place and would not exercise `.onChange` at all.
- **Appearance via `window.overrideUserInterfaceStyle`**, which materials and system colours honour.
- **Compare RGBA, not PNG bytes.** Redraw each `CGImage` into a `CGContext` over
  `CGColorSpaceCreateDeviceRGB()` and diff the buffer; PNG encoding can differ where pixels do not.
- **Always render the control.** A probe that shows "nothing drew" is worth nothing until the same
  harness has been shown to draw something.
