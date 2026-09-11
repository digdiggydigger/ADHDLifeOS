# Start here — after the focus card arc

*Paste into a fresh Claude Code terminal. Written 2026-09-11 at the close of the session that
shipped `F-FocusCard-4` (PR #58, E's device verdict: "the pre-beat reads fine") and
`F-FocusCard-5`, the close-out. The arc is CLOSED.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is
a trap. Archive this file into `handoff/archive/` in the same move that writes your successor, at
the END of your session, never at the start.

---

## Where things stand

**The focus card arc — five blocks — is CLOSED and on `main`.** Blocks 1–4 were each verified by E
on device; block 5 was doc-only. The design record is `handoff/SESSION-OPENER-focus-card-design.md`
(permanent), and it now opens with a postscript table of everything that shipped against it — read
that table before reading the specification.

**No branch in flight; `main` is the only branch on GitHub. E's phone runs the block-4 build**,
which is byte-identical in code to `main` (block 5 changed comments and docs only).

## Your job

**There is no queued block.** `handoff/OPEN-ITEMS-REGISTER.md` (twenty-first edition) is THE
outstanding list — read it and take direction from E. Section B's recommended order starts with
E's one un-run check (airplane mode + pull-to-refresh Home, `F-HomeTasksLastKnown`) and the
small card defects that were carried through the arc. **Do not start a section-C item unprompted.**

## Read these, in this order

1. `handoff/OPEN-ITEMS-REGISTER.md` — THE outstanding list.
2. `CLAUDE.md` — Workflow, Version Control (`main` is protected), Session handoff, Visual
   evidence, UI/UX §1–§7. §2 carries the app's one sanctioned off-grid value (`peekStep = 14`).
3. `claudecode.md` — the TDD role definition.
4. `handoff/SESSION-OPENER-focus-card-design.md` — only if the work touches the focus card.

**Do NOT read `docs/`.** It is an archive describing a deleted Supabase backend.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # and compare to origin/main
```

## Hard-won this arc, and all of it will bite again

- **A green suite cannot see a `View`'s appearance — proved FIVE times in one arc.** Render the
  view to PNG from a unit test before the device build: `UIHostingController` in a
  **scene-attached** `UIWindow`, `drawHierarchy(in:afterScreenUpdates: true)` — **`false` renders
  blank white from a test host** — `overrideUserInterfaceStyle` for dark, run loop pumped between
  captures. It captures **in-flight animation frames**, so motion can be evidenced too; note
  `onAppear` fires ~0.4s late in the host, so timestamps are ordering, not timing.
- **`accessibilityReduceMotion` is NOT writable via `.environment(\.)`.** Render the leaf with the
  flag as a parameter; hold the parent's pass-through with a call-site test.
- **A `.onChange` / `.sensoryFeedback` listener on a view inserted in the SAME update that changes
  its trigger never fires for that first change.** Put it on the persistent parent.
- **`FocusSessionService.swift` is at 394 of 400 lines.** The next stored property needs another
  move-out first (precedent: `sprintDeadline`/`sprintStartedAt` → `FocusWidgetPublishing.swift`).
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`.
- **Commit BEFORE any red-check**, restore with `git checkout -- "ADHD LifeOS/"`, prove by
  re-running; inject regressions ONE AT A TIME and predict the count first.
- **Erase the sim between any UI run and the next unit run** —
  `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`, chained unconditionally.
- **`handoff/archive/` can already hold a file of the name you are archiving** (a predecessor
  opener with the same title) — `git mv` refuses; add a date suffix.

## Device reinstall recipe

```
xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates
xcrun devicectl device install app --device 3DBC979A-3255-5456-8C30-172DB19B99B3 \
  "/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-etcfckccqnfwduaoegzziavhdjel/Build/Products/Debug-iphoneos/ADHD LifeOS.app"
xcrun devicectl device process launch --terminate-existing \
  --device 3DBC979A-3255-5456-8C30-172DB19B99B3 com.ethananthony.ADHD-LifeOS
```

**A launch denied with `Security` / "invalid code signature… not explicitly trusted" right after a
re-issued profile is TRANSIENT — retry once before escalating to E.** A **locked** phone refuses
the LAUNCH but not the install. **The profile is valid to 2026-09-17**: an empty Xcode account
list means E must sign in via Xcode → Settings → Accounts, never Claude Code.
