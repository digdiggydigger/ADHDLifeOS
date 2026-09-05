# Open items register — 2026-09-06

**This file is THE outstanding list.** It is rewritten at every session close-out (CLAUDE.md,
"Session handoff"), so it is the thing to read — and to update — rather than improvising a list in
chat. Supersedes the 2026-08-30 edition, which sat unmaintained for six days while two ad-hoc
lists were produced in conversation instead. Its rendered HTML twin is in `archive/`.

Every figure below was measured this session unless marked UNVERIFIED.

## State

`main ab86362` · working tree clean · `origin/main` matches · unit suite **2,348 / 0** ·
SwiftLint **0 violations in 677 files** · both targets build · **full UI target 23 / 6** ·
E's phone carries `1ab5ff2`, whose tree is byte-identical to main.

**Shipped this session:** `F-Routines-B-ToolsSection` — Routines has its own section on the Tools
tab, merged `511e55b`, device-verified by E in light and dark. Plus the `screenshots/` convention
written into CLAUDE.md, and the two screenshot trees folded into one.

**Branches:** `feature/routines` and `feature/routines-tools` both merged into main, both KEPT on
E's word. Deletion is an open decision.

## A · Decisions only E can make — minutes each

- [ ] **Delete the two merged branches?**
- [ ] **Re-measure coverage?** CLAUDE.md still records **23.62% at `b1f4b6f`**, several arcs stale.
      The file's own rule is *re-measure, never estimate*, and that figure now misleads.
- [ ] **The permission-banner footer** on the Routines section — a listed routine cannot fire when
      the nudge master switch is off or location is not Always. Offered, never explicitly ruled on;
      it lapsed when E took the other recommendations.
- [ ] **Give the `Home` place an emoji.** Cosmetic. It renders the 📍 fallback, and with three rows
      the glyph is what separates them at a glance.

## B · Real work, ready to start — recommended order

1. **The routine record gap.** The thing most work is stacked behind, and it needs E's decision
   before any code: journal rows, or a real `routine_runs` collection. Verified: no routine path
   writes anything durable, so completion is never recorded and a tap-only routine leaves no trace
   either way. Blocks 3 and the smart-skip fast-follow.
2. **The run-store sign-out leak.** Real bug: the routine run store is app-local `UserDefaults` and
   survives sign-out, so one account's place name can surface on another account's Today. Small,
   self-contained, privacy-shaped with launch in view.
3. **Arc 2 — first-class routines + the "at a time" trigger.** Designed in outline, NOT authorised.
   E's week-one inventory makes it concrete: the morning TIME routine is the one that genuinely
   needs the first-class object. Shape depends on 1.
4. **The tab-root not-hittable defect — new angle, 2026-09-05.** The failing SET shuffles between
   runs on an unchanged tree (`FirstRunJourney` failed though recorded fixed at `f9f7b24`;
   `testDueNudge` passed though it failed twice the same day in narrower runs). So the cause is
   ORDER or STATE, not any one screen, and a reproducer should vary run order against a fixed tree
   rather than varying the tree. That inverts how it has been chased.
5. **`F-Search-3-Journal`** — UNCHECKED with "⚠ RECONSIDER FIRST". Captures was built then reverted
   because the bottom row suits a SCANNING surface; Journal is a WRITING surface. Recommendation is
   to kill the block rather than build it — E's call.
6. **The Live Activity design review** E parked: all designs, both Activities × four presentations.
   Compact-island width has an iOS floor, so the glyph is the only lever.

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. Reproduced on E's 26.4 phone,
  not on the 26.5 sim. Write no fix until E has updated and it is retested.
- **App connections** — real two-way sync (Apple/Google/Outlook calendars, Google Tasks, Todoist).
  EventKit and a Todoist token are easy; Google and Microsoft are OAuth; **Apple Notes has no iOS
  API at all**, which must be said before anyone designs around it.
- **LA interactive buttons**, **time-of-day triggers**, **smart skip with prune and reorder.**

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day provisioning profiles, the reason the App Group blocker recurs weekly.
- **Sign in with Apple** built but dormant, same cause.

## E · Known, not work

- **Six UI-target failures.** Better understood than "pre-existing": the set is unstable across
  runs, so membership shifts without the tree changing. None involves the routines work.
- **Twelve `screenshots/` folders without READMEs** — deliberately left on E's call; CLAUDE.md says
  so, so nobody reads them as a backlog.
- **Stale unchecked bullets inside four finished blocks** — `F-DiscPill`, `F-PadNightRender`,
  `F-PadWarmNeutral` (itself marked SUPERSEDED) and `F-Tools-2-Morph`. They read like open work and
  are not. Left because there is no direct evidence for each.
