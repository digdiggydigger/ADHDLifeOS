# Session opener — App Directory arc (written 2026-09-01, the session that designed it)

Read `claudecode.md`, `CLAUDE.md`, the **"App Directory arc"** section of
`TODO-CLAUDE-CODE.md`, and auto-memories `app-directory-arc-design` + `place-actions-arc`
first. The full approved implementation plan — data-model shapes, per-block file lists, the
weighed-and-rejected alternatives — is at
`~/.claude/plans/dont-action-anything-yet-structured-backus.md`; read it before Block 1.
This opener orients and sequences; it does not replace them.

## THE STATE GATE — check this before anything else

This arc is built **off `main`, only after `feature/place-actions` has merged**. On session
start, look at the actual state, not this document's snapshot:

1. **Block 3 (`F-PlaceActions-3-Execution`) still unticked** → the arc may NOT start. The only
   thing standing between the place-actions arc and its merge is E's double-confirm retest
   (does iOS's "wants to open Spotify?" dialog survive the synchronous-open fix `0c65ca5`? If
   it survives, it's Apple's cross-app guard — record it honestly, still tick). Wait for E, or
   if E reports the verdict in-session: tick Block 3 + record the verdict, then do (2).
2. **Block 3 ticked but branch unmerged** → do the arc close-out FIRST: `--no-ff` merge of
   `feature/place-actions` into `main` (the location-v1 precedent), full suite re-run ON main,
   push with the verified close-out, reinstall E's device (`wishwashwacky15`,
   `3DBC979A-3255-5456-8C30-172DB19B99B3`) from main, update `place-actions-arc` memory, ask E
   about deleting `feature/place-actions` (and the long-merged `feature/location-services`).
3. **Merged** → `git checkout -b feature/app-directory main`, and start
   `F-AppDirectory-1-Directory`.

## State at handoff (verified 2026-09-01, this session's close)

- `feature/place-actions` at `c7b7493`, pushed, tree clean; `main` does NOT contain the arc.
  Blocks 1, 2, 4 ticked (E field-passed Block 4 on device: "block 4 - success"); Block 3
  awaits only the retest above.
- Unit suite **1,983 / 0** (56 skipped = emulator suites, by design when it's down); SwiftLint
  **0 violations in 581 files**; sim + device builds green.
- Device `wishwashwacky15` carries the branch build at the Block-4 commit (`067ae11`-era,
  installed 2026-08-31 18:43 wireless, launch verified) — the phone is OFF main until the
  merge.
- No Firebase rules changes are pending from place-actions. The App Directory arc's Block 4
  will ADD one (`/catalog` read-only match) — E publishes, verify via the Firebase MCP diff.

## The arc in brief (full detail in the plan file — E's decisions are settled, do not re-ask)

Goal: the add-action flow should feel like picking any installed app. iOS's ceiling (no
installed-app enumeration exists, for anyone) is acknowledged by E; the shape is:

- **Block 1 — F-AppDirectory-1-Directory:** bundled Swift-constant directory (hundreds of
  curated apps; curation is the real work), lenient per-entry decode, pure merge, ranked
  search, `PlaceAppPickerView` searchable sheet replacing the 10-entry Picker. Zero wire
  change — saves stay `.openApp`. PLUS the forward encoder fix (known kinds preserve unknown
  extra fields via `extraPayload`).
- **Block 2 — F-AppDirectory-2-Links:** new wire kind `open_link` (display_name, link,
  optional scheme), pasted share-links in smart custom, destination templates (one `{value}`
  substitution), `PlaceLinkOpenPlan`/`PlaceLinkOpener` (universal-links-only first, plain
  fallback in the completion).
- **Block 3 — F-AppDirectory-3-Verify:** `LSApplicationQueriesSchemes` top ~45 + plist-parity
  test, three-state `PlaceAppInstallVerdict` decided BEFORE `canOpenURL`, pinned honest copy.
- **Block 4 — F-AppDirectory-4-Remote:** `/catalog/app_directory` global read (first ever —
  NOT the per-user Collection enum), new rules match (E publishes), 24h-TTL cache, every
  failure mode → bundled+cache.

Blocks 1 → 2 and 1 → 4 are hard dependencies; 3 can swap with 2. Field gate before the
`--no-ff` merge: E walks a directory pick, a pasted-link app, one deep destination, and one
"doesn't look installed" verdict.

## The five load-bearing constraints (all verified in code — designs around them, not through them)

1. **`PlaceAction`'s encoder DROPS unknown fields on KNOWN kinds** (only unknown KINDS are
   preserved, via `.unsupported`). Hence `open_link` is a new kind, and Block 1's
   `extraPayload` fix only protects builds from this arc forward.
2. **Tap attribution:** the notification tap's FIRST `UIApplication.open` must be SYNCHRONOUS
   on the delegate callback (`ADHD_LifeOSApp.swift`, the `0c65ca5` field lesson) — the
   universal-link attempt goes first and synchronously; the fallback lives in its completion.
3. **`canOpenURL` on an undeclared scheme is indistinguishable from "not installed"** — decide
   the three-state verdict BEFORE the call; undeclared → "can't check", never consulted
   (tripwire test).
4. **`Info.plist` currently has NO `LSApplicationQueriesSchemes`;** the key caps at 50, is
   compile-time only, and remote directory entries can never gain a verification slot.
5. **`firestore.rules` has no non-user path** — the remote doc needs a new top-level match,
   and rules publishing stays E's manual step (permission-denied until then ≡ offline).

## Traps paid for by the previous sessions (details in the memories)

- **The ios-simulator MCP's `launch_app` DROPS `SIMCTL_CHILD_` env vars** — a drive meant for
  the emulator silently ran against PRODUCTION once. Always launch with shell
  `SIMCTL_CHILD_LIFEOS_FIREBASE_EMULATOR_HOST=127.0.0.1 xcrun simctl launch booted …`, and
  verify the emulator actually received traffic (`accounts:query` POST on :9099 — the
  `GET /emulator/v1/...` endpoint doesn't exist and its 405 reads like "no users").
- Presentation modifiers on a Form `Section` apply PER ROW (dismissed the whole editor once) —
  hang sheets off ONE concrete view; sibling sheets on one view are fine.
- `try?` flattens nested optionals (SE-0230) — `container.contains` before `decodeIfPresent`.
- `PlaceEditorValidation.makePlace` REBUILDS the place on save — any new Place-level field
  must thread through it or an edit strips it. (Directory work shouldn't touch Place, but the
  trap generalises to any rebuild-on-save.)
- Commit BEFORE any deliberate-regression red-check; restore with `git checkout --`; prove by
  REBUILDING. Never `&&` a commit onto a piped build (`| tail` masks the exit code).
- DerivedData is on the external Es-SSD; never two xcodebuilds at once; pick DerivedData by
  mtime.

## House rules that bite here

- TDD first for every pure layer; no block claims done without pasted suite/lint/build output
  and the verified commit+push close-out (`git status --short` empty, local HEAD ==
  origin's).
- One FEATURE block at a time, then stop for E's review — unless E says bypass.
- Design skills precedence: `CLAUDE.md` §1–6 + the iOS 16.0 floor beat every skill; the
  Places UI is 17-gated with E's standing authorisation, but new NON-Places surfaces are not.
- The directory's schemes must be checked against published documentation before shipping —
  a wrong scheme "teaches E the whole feature is broken" (the catalogue's own comment).

## Out of scope (E's explicit calls — do not drift into them)

- A run-a-shortcut action kind: REJECTED (fragile, depends on user-maintained shortcuts).
- True Spotify account integration (OAuth, remote playback): PARKED for a future arc.
