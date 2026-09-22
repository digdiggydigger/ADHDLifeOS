# START HERE — arc C is CLOSED. `F-D1-ComposerBothDoors` is next.

*Written 2026-09-22 by the session that finished `F-C4-TagsRecentlyDeleted`. A disposable pointer:
archive it when you write your successor. Its predecessor,
`archive/START-HERE-adhd-audit-arc-C4-tags.md`, is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## 0. Before anything else

1. **CHECK THE REGISTER AGAINST WHAT YOU WERE HANDED.** The session that wrote this was pasted an
   opener that had already been spent — it asked for two device looks, a screenshots folder and a
   whole block, all three of which had landed in editions 73–75. `git log --oneline -8` and
   `OPEN-ITEMS-REGISTER.md`'s header take ten seconds and are the only defence. This is the same
   species of trap `handoff/`'s own rules were written for.
2. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-d1-composer`.
3. **Read:** `CLAUDE.md` (§1–§7, especially §7.6), `claudecode.md`, the
   `### FEATURE: F-D1-ComposerBothDoors` block in `TODO-CLAUDE-CODE.md`, and
   `OPEN-ITEMS-REGISTER.md` edition 77. Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`.
4. **Start the emulator** — `./scripts/emulators.sh --import scripts/audit/emulator-state` — and
   **restart it if it has been up for hours** (E's rule; a long-running emulator goes before any
   baseline).
5. **ERASE the simulator before the first unit run** if the previous session left it signed in:
   `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`.

### 0.1 ONE thing is owed to E, and it is a decision rather than a look

**Register §A-CAPSULE: the Undo capsule is MOUNTED but INVISIBLE in the Tag Editor.** Settings is a
`.sheet` from Today; the capsule lives in `RootBottomOverlay` beneath it. E chose the capsule over
a confirmation and is currently getting neither. Three options are written out in the register.
**Do not fix it unasked** — it touches app-wide furniture, every constant of which is E-approved.

**Nothing else is owed.** No device look and no RM-on pass for `F-C4`: no `#available` site, no
reduced site.

## 1. What arc C leaves behind that arc D reuses

Arc D's own dependency note says it: *"D does not re-implement either — it reuses whatever Arc C
ships for a composer's leading header control and its dismiss behaviour."*

- **`RecentActionKind`** now has eight cases. A new close surface adds a case and the exhaustive
  switch in `CaptureInboxUndoSections` will refuse to compile until you decide which side of the
  inbox header's ↶ it belongs on. That is the design working; `UndoCapsuleCallSiteTests` pins the
  literal, so update it DELIBERATELY.
- **Cancel → Close** and the silent draft-save on dismiss are `F-C2`'s and shipped.
- **Soft delete** covers tasks, captures and tags. `deleteTask(`/`deleteCapture(`/`deleteTag(` and
  `replacingWith: nil` are banned outside `Firebase/` and `RecentlyDeleted/` by two tree-walking
  tests. If a composer needs to destroy something, it wants the soft form.

## 2. Traps this session paid for — read before writing ANY render harness

All five are in `screenshots/recently-deleted-tags/README.md` in full. The short form:

1. **`quickCaptureButton` exists from frame one and is NEVER hittable.** Wait on existence, never
   `settle`. Two journeys died at 144s and 166s having photographed nothing.
2. **`tap(_:untilGone:)` returns true WITHOUT TAPPING when the doomed element is already absent** —
   and scrolling a `Form` makes elements absent. An absence the previous step caused is not a
   signal. This is trap #1 in the C3 harness's own header and it was walked into anyway.
3. **`openTab` returns early when the tab is ALREADY selected**, so from a pushed screen it never
   taps and never pops. Tap `UITestSession.tabButton(…)` explicitly, `untilExists:` a root control.
4. **Waiting on a row below the fold reads as "the screen never opened."** Wait on the SHEET, then
   scroll to the row.
5. **A `Form` builds rows lazily**, so a chip below the fold is genuinely absent from the
   hierarchy — and reads as "it was never attached".

And the one that matters most: **XCUITest finds OCCLUDED elements.** `untilExists: capsule` passed
on a screen where no capsule was drawn. If a frame is meant to prove something is VISIBLE, look at
the frame.

## 3. What must NOT be re-tuned or re-litigated

- **The capsule's radius cap, `peekStep = 14`, `floatingPaddingHorizontal = 12`, the tab bar, the
  capture disc, the appearance override, the Confirm celebration's RM waiver.**
- **Do NOT "improve" task detail's autosave to on-blur** — saving resets the Form's scroll.
- **Do NOT re-add a confirmation to a soft delete.** E has now dropped three (task, capture, tag).
  *"Delete forever"* keeps its confirm and is the only place *"This can't be undone."* is true.
- **Do NOT reverse E's tag decisions**: no delete confirm, and the survivor alert asks which
  spelling wins.

## 4. The state you inherit — VERIFIED, not assumed

- **`main` @ the merge of `F-C4`**, `git status` clean.
- Suite **3,306 / 0**, SwiftLint **0**, build **SUCCEEDED**, coverage **30.03% (15,103/50,300)**.
- The three tag render journeys: **3 tests, 0 failures**, run in light and dark.
- **E's phone has `main` @ `4917955`** — `F-C1` + `F-C2` only. It has seen neither `F-C3` nor
  `F-C4`. Nothing owes a look, but that install is the prerequisite if E asks to see either
  (memory: `ask-for-device-checks-on-a-build-e-has`).
