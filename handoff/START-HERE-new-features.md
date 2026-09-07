# Start here — E is shifting focus to NEW features. Do not start a block; start a conversation.

*Paste into a fresh Claude Code terminal. Written 2026-09-07 at the close of the session that
closed **B4, the widget extension** (PRs #25–#26) and, doing it, corrected how this project reads
a coverage ratio at all. Nothing is half-done. No Swift under `ADHD LifeOS/` changed, so E's phone
is still current.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of
them is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/`
in the same move that writes your successor, at the END of your session, never at the start.

---

## The one instruction that matters

**E's direction, given 2026-09-07 in chat: "I want to shift our focus to spend some time working
on some new items to add to the LifeOS app."**

So your first move is **not** to open `TODO-CLAUDE-CODE.md` and build the next thing. There is no
next thing queued, deliberately. **E is the design authority and designs in chat** (CLAUDE.md,
"Workflow"), and this session exists to have that conversation and turn it into a spec.

**Do NOT pick the features for E.** Every arc in this repo — routines, the Tools tab, bottom
search, the app directory, place actions, captures, auth v3 — was settled by E in conversation
first and written down second. Bring the raw material to that conversation, not a roadmap you
invented.

### The shape that has worked, five arcs running

1. **Ask E what they want to build**, and keep asking until the *acceptance criteria* are concrete
   enough to test. Vague acceptance criteria are the documented cause of a `[BLOCKED]` stop.
2. **Write the design record** — `handoff/SESSION-OPENER-<arc>-design.md`. This is the WHY, and it
   is permanent (never archived). `SESSION-OPENER-routines-design.md` is the model to copy.
3. **Write the blocks** into `TODO-CLAUDE-CODE.md`, under `⚠ CLAUDE CODE ADDITIONS`. Claude Code
   owns that file in full now — blocks as well as checkboxes.
4. **Build test-first**, one block at a time, stopping for E's review after each.

---

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (every change lands through a PR), Session handoff,
   Visual evidence, and the UI/UX section (§1–§7), which governs any new screen. Its
   **"Coverage reality"** section was rewritten this session; read it before quoting any figure.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **sixth edition**, rewritten at
   this close-out. Two decisions sit in section A; section B is three carried items and **none is
   authorised**.
4. **`handoff/VISION-adaptive-lifeos.md`** — E's 2026-09-03 vision session. **This is the single
   richest source of candidate new work**, and it ends by naming its own next steps: *"pick the
   first adaptation verb to prototype, decide whether the island state machine becomes its own arc
   after Routines Arc 2, and put the Tier-1 sensing list through a real entitlement/docs
   verification pass."* It is a VISION record — **nothing in it is scoped or authorised**, and it
   is raw material for the conversation, not a queue.
5. `handoff/SESSION-OPENER-routines-design.md` — the newest settled design record, and the house
   style for writing one.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

---

## The material already on the table

Bring these to E; let E choose. Do not rank them as if the ranking were settled.

**From the vision map** (`VISION-adaptive-lifeos.md`) — the largest unbuilt ideas in the project:
- **The Island state machine** — ANCHOR > NEXT > CATCHER, one Activity with three faces rather
  than three Activities fighting for the island. The routines display-LA and the sprint LA are
  already its first two citizens, so this is *generalisation*, not green field.
- **The consent-first adaptation vocabulary** — what a low-capacity day actually changes,
  offer-never-impose.
- **The bad-day constitution** — count UP only, celebrate the return, a fresh-start gesture. E
  framed this as a design constitution that binds every future Momentum/analytics block.
- **The permission-gated sensing stack** — on-device, per-signal opt-in, Tier-0/Tier-1.

**From the register's section C**, parked on E's instruction — do not start unprompted, but they
are live candidates if E now wants them:
- **Routines Arc 2** — first-class routines + the "at a time" trigger. This is the object the
  island's NEXT state nominates, so it unblocks the island work above.
- **App connections** — real two-way sync (Apple/Google/Outlook calendars, Google Tasks, Todoist).
  **Flag before designing: Apple Notes has NO iOS API at all**, and Google/Microsoft are OAuth
  while EventKit and a Todoist token are easy. A different feature class from the app directory,
  which only opens a URL scheme.
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** (its data already lands in
  `routine_runs`).
- **The Live Activity design review** E parked — all Live Activity designs, both Activities ×
  four presentations each. Note the compact-island width has an iOS floor (the sensor cutout), so
  the glyph is the only lever.

**Constraints that shape any new feature, and are not negotiable:**
- **Public launch is the intent** (E, 2026-09-03) — design for many users: defaults, first-run
  states, permission ladders, accessibility. Not for E alone.
- **iOS 16.0** app target / **16.1** widget. Any iOS 17+ API is `#available`-gated or unused —
  this beats every design skill, see CLAUDE.md §7.
- **Firebase only.** New collections go in `firestore.rules` and get their own
  `FirebaseManager+<Domain>.swift`; adapters depend on a narrow per-feature `*BackingStore`
  protocol, never on `FirebaseManager`. Publishing rules stays E's call.
- **The 4/8/16/24 spacing grid, zero hex in Swift, semantic Dynamic Type.** CLAUDE.md §1–§6.

---

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 5dbfc41 (PR #26 merge) or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 711 files
```

Last verified: unit suite **2,497 / 0** (emulator up), lint **0 / 711**, app target
**24.72% (11,114/44,961)** at `93beff2`. **E's phone tracks main at `a3e4bde`** — everything
merged since touched tests, `handoff/` and `CLAUDE.md` only, so **no reinstall is owed**. The
free-dev-account profile is roughly valid to **2026-09-14**; a reinstall after that needs E to
re-sign in via Xcode → Settings → Accounts.

---

## Traps that matter right now

- **`TestResults.xcresult` ALREADY EXISTS in the repo root, and CLAUDE.md's documented test
  command writes to that exact path** — so running it verbatim fails *after* paying for the whole
  build. Pass a dated `-resultBundlePath`. There are now **twenty-two** bundles, 859 MB; deleting
  them is a section-A decision sitting with E.
- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. Unconditional, chained onto the run itself. The tell for
  a poisoned sim is `127.0.0.1:9099` in the log tail; grep for it rather than judging by feel. It
  did not bite this session (0 hits in all four logs, no UI target run).
- **A red-check with many failures is CHEAP — this was settled this session.** The slow-failing-test
  oddity carried since routine-record block 1 is a **one-off warm-up paid once per run**, not a
  per-failure penalty: seven failures ran `9.391 1.558 0.039 0.002 0.002 0.001 0.006` seconds in
  log order, and the whole suite took 49.8 s failing against 48.3 s green. **So never scope a
  red-check down to keep it fast.** Budget one slow first failure; the magnitude still varies
  (9 s here, 35–43 s yesterday) so do not treat any figure as a floor.
- **Coverage: check what the test host actually LINKS before reading a ratio as effort.** The
  widget target's 9.43% was never a measure of neglect — only 5 of its 14 files are compiled into
  the app target, so its testable surface is 233 lines, not 2,216, and it was at 89.7%. Use
  `xcrun xccov view --report --files-for-target <target> <bundle>` on both targets and intersect.
  **The coverage arc is CLOSED; do not reopen it unprompted.**
- **`xccov view --file` needs `--archive`**, or it reports "unrecognized file format", which reads
  like a corrupt bundle rather than a missing flag. It is the only way to see `(col, hits, 0)`
  region rows — and a `??` autoclosure is a REGION, invisible to a line-level sweep. Three of them
  were the entire gap in two files that looked finished this session.
- **Commit BEFORE any deliberate-regression red-check**, restore with `git checkout --`, and prove
  it by REBUILDING. E's standing rule after the same mistake twice.
- **Run long UI work one xcodebuild at a time, foreground and scoped** — the memory watchdog
  kills background UI runs mid-test.
- **The emulator was left running** (`scripts/emulators.sh`); if it is down after a reboot,
  restart it before any journey — they SKIP without it, and the four `FirebaseManager+*`
  integration tests skip too, which silently changes what a coverage run measures.
- **Never automate auth** — no scripted sign-ups, logins or credential entry. Hand auth to E.
