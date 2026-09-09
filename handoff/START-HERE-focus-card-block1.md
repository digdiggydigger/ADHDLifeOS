# Start here — build F-FocusCard-1, the collapsed focus sprint card. The design is SETTLED; do not re-open it.

*Paste into a fresh Claude Code terminal. Written 2026-09-09 at the close of the session that shipped
B-2 (`F-HomeTasksLastKnown`) and then designed this arc with E in chat. **No code has been written for
this arc yet** — the previous session stopped at E's instruction to start block 1 in a fresh terminal.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is a
trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the same move
that writes your successor, at the END of your session, never at the start.

---

## Your job

**Build `F-FocusCard-1` only.** It is block 1 of a five-block arc. Stop at the end of it and wait for
E's device verdict — do not roll into block 2.

**The full specification and every architectural decision is in
`handoff/SESSION-OPENER-focus-card-design.md`. Read it before anything else.** It is a design RECORD
and is permanent — never archive it. It contains E's verbatim answers to sixteen design questions,
the reasons behind each choice, the exact pure types to build, the tests to write first with what each
one reads on the BROKEN build, and the traps.

**Everything in its "settled specification" was answered directly by E. Do NOT re-litigate any of it.**
If something seems wrong, say so to E rather than quietly deviating.

E's original screenshot is `../Ethan's Screenshot Folder/IMG_8307.jpg` — the Journal tab with a sprint
running, three green arrows pointing down, and a full-width black box over the action row.

## Where things stand

**`main` @ `e9fa9df`. No branch is in flight.** Nothing for this arc has been started; the previous
session created a `feature/focus-card-collapse` branch, wrote no code, and deleted it again.

**One PR is OPEN and awaiting E — do not merge it yourself:**
- **PR #41**, `chore/register-fifteenth-edition` — the open-items register's fifteenth edition. Touches
  `handoff/OPEN-ITEMS-REGISTER.md` only, so it will not conflict with your Swift work. E asked for it
  to be opened rather than landed.

Landed earlier in that session, both verified on `origin/main`:
- **PR #39** → `8b5f740`, `F-HomeTasksLastKnown`: `HomeService.load()` no longer empties `allTasks`
  on a failed fetch. Register item B-2, now CLOSED.
- **PR #40** → the block's completion record.

**Two decisions of E's that no commit records** — they live in PR #41's register edition:
- The tab-depth search-row spring on a tab SWITCH is **KEPT**, on E's word *"Keep it."* Closed.
- B-2 is closed.

## Read these, in this order

1. **`handoff/SESSION-OPENER-focus-card-design.md`** — the design record. The whole job is in it.
2. **`CLAUDE.md`** — Workflow, Version Control (`main` is protected; everything lands through a PR),
   Session handoff, Visual evidence, and UI/UX §1–§7. §2's 4/8/16/24 spacing grid and the iOS 16.0
   deployment floor both bite in this block.
3. **`claudecode.md`** — the TDD role definition.
4. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, fourteenth edition on `main`; the
   fifteenth is in PR #41.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect e9fa9df or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 720 files
ls -d *.xcresult                     # expect NONE — deleted after each read, E's standing word
```

Last verified ON MAIN at `e9fa9df`: unit suite **2,547 / 0** (emulator up, 0 `9099` hits, 0 skipped),
lint **0 / 720**, sim build `** BUILD SUCCEEDED **`, app target **24.76% (11,191/45,205)**.

**Start the Firebase emulator first** — `./scripts/emulators.sh` in a second terminal, or
`nohup ./scripts/emulators.sh > /tmp/emulators.log 2>&1 &`. With it down the four `FirebaseManager`
extension suites SKIP rather than fail, so the run stays green but the figures are not comparable.
It was left RUNNING at the end of the previous session; check `curl -s -m 2 http://127.0.0.1:4400/emulators`.

## Traps that matter for THIS block

- **`.gesture(DragGesture(...))` on the card SWALLOWS the Pause button's taps.** It must be
  `.simultaneousGesture`. This is the single most likely way to ship a collapsed card whose only
  remaining control does not work, and the call-site test guards it literally.
- **Widening `FocusSprintPersisting` breaks the WHOLE test target's compile** until BOTH recording
  fakes are updated — `FocusSprintPersistenceTests.swift:27-46` and `FocusLocationStampTests.swift`.
  That compile break IS the red step; do not treat it as a mistake.
- **The collapse read must sit ABOVE the `guard session == nil, let saved = sprintStore.read()` at
  `FocusSessionService+Persistence.swift:21`.** Below it, collapse silently fails to restore whenever
  no sprint is stored — and `testCollapseSurvivesWithNoSprintStored` exists to catch exactly that.
- **The flush drop uses `.offset(y:)`, NOT negative padding.** `FocusTimerBar` is the LAST child of
  `RootBottomOverlay`'s VStack; negative bottom padding there shrinks the stack and drags the search
  row and capture disc down 32pt with it.
- **`RootView.swift` sits at 399 of 400 lines.** A new member goes in an extension file
  (`RootView+Doors.swift`, `RootView+Reselect.swift` are the precedents). This block should not need
  to touch it at all — if you think it does, re-read the design record's collapse-state decision.
- **`FocusTimerBar.swift` is 250 lines and WILL blow the 400 ceiling** — split it preemptively into
  `FocusTimerBarContent.swift` as part of this block, not reactively when lint fails.
- **Block 1 alone has sticky collapse with no reset** (Confirm arrives in block 2). Say so in the
  report and tell E to expect it. Do NOT add a temporary escape hatch that block 2 deletes.
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME.
- **Read the `Executed N tests, with M failures` line** — `grep -c 'Test Case.*failed'` counts eight
  test NAMES that contain the word and reads as eight failures on a green suite. A trailing `grep -c`
  that finds nothing also exits 1 and makes a green run look failed; read the `exit=` you echoed.
- **Erase the sim between a UI run and any unit run** —
  `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`. The sim is erased, shut down and SIGNED
  OUT; a signed-in drive needs E (never automate auth).
- **E's phone is BEHIND main** — it runs `a6b8021`, main is `e9fa9df`. It was held deliberately
  because this arc will need a device build anyway. **Reinstall as part of this block's verdict.**

## Device reinstall recipe

```
xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates
xcrun devicectl device install app --device 3DBC979A-3255-5456-8C30-172DB19B99B3 "<Debug-iphoneos>/ADHD LifeOS.app"
xcrun devicectl device process launch --terminate-existing --device 3DBC979A-3255-5456-8C30-172DB19B99B3 com.ethananthony.ADHD-LifeOS
```

The `.app` path is in the build log, on the external SSD. A locked phone refuses the LAUNCH but not
the install — read `NSLocalizedFailureReason` before suspecting the build. The free-dev-account
profile is roughly valid to **2026-09-15**; an empty Xcode account list means E must sign in via
Xcode → Settings → Accounts, never Claude Code.
