# Start here — the foundations were reset; pick the next arc

*Paste into a fresh Claude Code terminal. Written 2026-09-06 at the close of the session that
shipped Block B and then spent the rest of its time fixing what a CLONE had left behind.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is
a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the same
move that writes your successor, at the END of your session, never at the start.

---

## Read these, in this order

1. **`CLAUDE.md`** — it loads automatically, but read the **Repo layout**, **Workflow**, **Session
   handoff** and **Visual evidence** sections deliberately. They are new as of 2026-09-06 and they
   change how this project is run.
2. **`claudecode.md`** — the TDD role definition, rewritten this session.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — **the outstanding list.** Everything you could pick up
   next is in it, with recommendations. Update it at your close-out; do not improvise a list in
   chat.
4. `TODO-CLAUDE-CODE.md` only when you are working a block.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 4c7227d
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 677 files
```

Baseline on main: unit suite **2,348 / 0**, lint **0 / 677**, both targets build, full UI target
**23 / 6**. E's phone carries `1ab5ff2`, whose tree is byte-identical to main's app source.

**Before any unit suite, if a UI run has happened: `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`.**
Not shutdown, not reboot. A UI journey signs the sim in and the next unit suite then crawls at
60-80 seconds PER TEST, or gets killed for "low memory". This cost time twice on 2026-09-06. It is
in CLAUDE.md's Commands section as a command order rather than a fact to remember.

## What the last session did

**Shipped `F-Routines-B-ToolsSection`** (merged `511e55b`): Routines has its own section on the
Tools tab — one row per place+direction clearing the tap-step threshold, computed by
`PlaceRoutinePlan.make`, no new entity. E approved the scope from a rendered proposal, then
verified it on device in light and dark. Evidence in `screenshots/routines-tools-section/`.
**Arc 2 and the routine-record gap were deliberately NOT touched.**

**Then reset the project's foundations**, because E confirmed something that explained a lot: this
repo was **CLONED** from an earlier project built with a Cowork→Claude Code workflow, and the
documentation was never adapted. A clone copies its parent's docs wholesale, and documentation is
the layer nothing checks.

- **Cowork is gone.** Claude Code owns every file here; E is the design authority in chat. The
  Workflow section is rewritten; `WORKFLOW.md` is archived.
- **`docs/` was a trap in the start-of-session checklist.** Every session was told to read
  `docs/ARCHITECTURE.md` for context, where it learned this app is "a second client on the
  Es_Life_OS Supabase backend". Across those seven files: AWS 105 mentions, Supabase 70, Cognito
  64, **Firebase 0**. Now `docs/archive/` behind a README.
- **`legacy/`** holds the React prototype and the web build tooling the clone brought;
  `aws-backend/` was deleted. `functions/` was checked first and is self-contained, so no deploy
  could break.
- **Two conventions are now written down**: `screenshots/` (what earns a folder, README mandatory)
  and `handoff/` (this file's own rules, and the register as the outstanding list).

## What to do next

**Ask E.** The register's section B has six candidates in recommended order; nothing is authorised
until E picks. The top two:

1. **The routine record gap** — the thing most work is stacked behind, and it needs E's DECISION
   before any code: journal rows, or a real `routine_runs` collection. Nothing durable is written
   by any routine path today.
2. **The run-store sign-out leak** — a real bug, small and self-contained: the routine run store is
   app-local `UserDefaults` and survives sign-out, so one account's place name can surface on
   another account's Today.

**Do not start anything in the register's section C.** Those are parked on E's explicit
instruction.

## How this project works, in four lines

- **TDD is mandatory**: the failing test first, always. Then suite green, lint 0, both targets
  build, and a red-check with the injected regressions COUNTED.
- **A block is not done until the push is VERIFIED** — same SHA on both sides, pasted.
- **Stop for E's review** when a FEATURE block completes; don't roll on to the next unprompted.
- **Nothing else can run a build here**, so paste real terminal output. An unpasted "it passes" is
  an unverified claim.

## Traps that have actually bitten, in one place

- **`grep` for CALL SITES, not definitions.** This repo's most repeated defect — six instances — is
  a helper written, documented, unit-tested, and then called by nothing. Unit tests prove
  correctness, never REACHABILITY.
- **The first-run state is what nothing tests**, because every journey seeds its way out of it
  before launching.
- **An accessibility identifier on a container is inherited by its children** and overrides theirs.
- **A source-reading guard must strip comments** — `contains("Foo()")` matches `// Foo()`.
- **The full UI target's 6 failures are an UNSTABLE SET** — membership shifts between runs on an
  unchanged tree. Never bisect that family one run per commit.
- **Commit BEFORE any deliberate-regression red-check**, and never `&&` a commit onto a piped build
  (`| tail` masks the exit code).
