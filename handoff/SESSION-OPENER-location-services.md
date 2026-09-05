Location services — CONTINUATION session. Read `claudecode.md`, `CLAUDE.md` and the memory index
first, then this brief. Do not re-plan: the spec is settled, three of four blocks are built, and
the next tasks are named below with the decisions already made.

## Where things stand

- **Branch `feature/location-services`**, HEAD `c948411`, clean and pushed, INSTALLED on
  `wishwashwacky15`. Close-out compares local HEAD to **`origin/feature/location-services`**.
- **`main` is NO LONGER frozen** — the Momentum v3 redesign merged on 2026-08-27 (`453dabc`,
  `--no-ff`, 46 commits). The old "never compare against origin/main" rule is dead.
- Suite **1,584 tests / 0 failures**. Lint accepted debt is EXACTLY two: `TaskDetailView`
  file_length, UITests `static_over_final_class`. Anything else is new — fix it BEFORE committing.
- **Emulator:** `./scripts/emulators.sh`; "port taken" means it is ALREADY up. Check before every
  suite run.

## E's spec, settled — do not re-litigate

Location serves **BOTH** tagging where things happened **AND** triggering on arrival, using
**geofences plus a significant-change fallback**, stored in **Firestore alongside the record**.

E first said "significant-change only"; that was walked back once it was clear (a) significant
change is ~500m/cell-tower coarse and cannot detect arriving at a shop, and (b) it needs the SAME
`Always` grant as geofencing — so the coarse option bought no permission saving.

**E authorised ignoring the iOS 16 floor for this feature** (§7 deviation, reported). The Places
UI is `@available(iOS 17.0, *)`; the project target STAYS 16.0. On iOS 16 SwiftUI cannot convert a
tap to a map coordinate at all (`MapProxy` is 17+), so tap-to-drop needed the modern API. An iOS 16
device simply never sees the Places row.

## Built (blocks 1-3 partial)

- **Foundation** (`027c1ad`): `Place` (flat lat/long on the wire, snake_case, radius clamped
  100...5000m at BOTH init and decode), `PlaceGeometry`, `LocationAuthorizationState`,
  `FirebaseManager+Places`, `PlacesBackingStore`. `places` is in `firestore.rules` and **PUBLISHED
  LIVE** (verified by diffing the fetched ruleset against the repo).
- **Places UI** (`90d098c` + three followups): list from Settings, editor with tap-to-drop map +
  `MapCircle` radius, address search with live completions, shared `EmojiPicker`, capacity counter.
- **Tagging** (`e1bf0a6`, `eb2e323`, `5a096fb`): captures stamp where they were made, the place
  shows on the row / triage card / detail, a per-capture switch in the composer, the permission ask.
- **Colour unification** (`c948411`): 31 raw SwiftUI hues migrated onto tokens across app, widget
  and previews, and a `raw_hue_color` SwiftLint rule added so it cannot drift back.

## The traps that cost time — do not re-derive them

- **iOS monitors AT MOST 20 regions per app, SILENTLY.** Past that, some places just never fire,
  with no error. `PlaceGeometry.placesToMonitor` picks the nearest 20 and re-picks on every
  significant-change wake — that is what the fallback is FOR. `PlaceMonitoringCapacity` surfaces
  the budget in the UI, and a test asserts the counter agrees with the selection.
- **`PlaceResolution` picks the SMALLEST containing place, not the nearest centre.** An early
  version ranked by centre-distance and a test caught it immediately: a big place centred exactly
  where you stand beats a small one metres away, so standing in town centre would tag captures
  "town centre" rather than "the office". Centre-distance is only the tie-break.
- **Tagging works on When In Use; triggering needs Always.** Regions registered under When In Use
  deliver ONLY in the foreground, which defeats an arrival trigger entirely. Never request Always
  cold — iOS shows a weaker prompt users decline far more often. When In Use first, escalate later.
- **A stamp can only ever ADD a field.** Taken after validation, before the write, no failure path
  back to the caller. A location lookup must NEVER be why a thought doesn't get written down.
- **A failed fix produces NO stamp, never (0,0).** Null Island is a real point off Africa.
- **`CoreLocationFixProvider`'s continuation must resume EXACTLY once** — CoreLocation can call
  back twice or never; double resume traps, missing resume hangs forever. One `finish()` that nils
  `pending` first, plus an 8s timeout racing it.
- **Widget carries its OWN colorset copies.** A palette change must hit BOTH catalogs.
- Device install can fail once with `PackagePatchFailed` on the widget's `Assets.car` — that is
  iOS's delta installer, not the build. **Retrying the install clears it**; no uninstall needed.

## Still open — pick up here

1. **Block 3 remainder (mechanical, no decisions needed).** Journal entries, closed tasks and
   focus sprints do not stamp yet. Follow exactly what captures do: add `placeId`/`latitude`/
   `longitude` to the model (mind each collection's field convention — tasks are fully snake_case,
   captures camelCase apart from `created_at`/`tag_ids`), take the stamp in the service after
   validation, assert the wire spelling AND that the wrong spelling is absent.
2. **Captures archive tab shows no place labels.** `CapturesTabView` builds `CaptureRowView`
   without a places list; it needs one threaded through its own data source. Noticed, deliberately
   not fixed — it is a data-source change, not a display tweak.
3. **Block 4 — arrival triggering. ASK E BEFORE BUILDING.** This is where the real product
   decisions are: what should arriving somewhere actually DO (surface a filtered list? fire a
   notification? log silently?), and how the Always escalation is justified to the user. A geofence
   that fires the wrong thing is worse than none — E learns to ignore it. `LocationPermissionPrompt`
   already has the Always copy; the registration itself is unbuilt.
4. **Long-standing, unrelated:** auth screens still V1; captures archive still behind the Areas →
   "Handled captures" interim door; TaskDetail's sprint PLANNER default still ignores the
   default-sprint-length setting (one-tap starts DO use it).

## House rules that bit this session

- **Per change:** failing test first for new logic → `swiftlint` (exactly two debts, checked BEFORE
  committing) → full suite green with the emulator up → sim build → commit + push → SHA-verify vs
  `origin/feature/location-services` → device build + install.
- File budgets bite constantly: 400 lines/file, 250/type body, 50/function. House fix is a
  same-file extension (exempt, still sees `private`) or its own file with members made internal —
  the `CaptureInboxService+Create`/`+Triage`/`+Tags` precedent.
- **Colour is now LINT-ENFORCED.** A `raw_hue_color` custom rule in `.swiftlint.yml` bans
  `.orange`/`.red`/`.green`/etc. in favour of tokens. Semantic colours (`.primary`, `.secondary`,
  `.accentColor`, `.white`) stay allowed. Added because the convention had already failed silently.
- Steppers fire `onEditingChanged`, ONCE on release — never per increment. Passing
  `onEditingChanged` makes Stepper take two closures, so the label MUST move to an explicit
  `label:` or `multiple_closures_with_trailing_closure` errors.
- Haptics go through `Theme/Haptics.swift`'s six-feel vocabulary, never a fresh generator.
- Test-target `XCTAssert…` cannot take an inline `await` (autoclosure); hoist it to a `let` first.

Pick up at item 1 if E wants progress without decisions, or open item 3 with the questions if E is
ready to design arrival triggering.
