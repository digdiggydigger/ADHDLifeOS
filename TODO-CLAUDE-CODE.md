# TODO-CLAUDE-CODE.md

*Handoff document: Cowork → Claude Code*
*Project: **ADHD LifeOS (Es_Life_OS mobile)***

**Created:** 2026-07-17
**Status:** Xcode project scaffolded (SwiftUI, XCTest). SwiftLint + 70% coverage bar decided. No architecture doc or FEATURE blocks yet — first Cowork design session pending.

---

## How Claude Code Uses This File

See `WORKFLOW.md` for the full cycle and FEATURE block template. Quick version:

1. Before each work session: read this file top-to-bottom.
2. Pick the next `[ ] UNCHECKED` item under **Current Sprint**.
3. Read the associated docs in `/docs/`.
4. Execute the task step-by-step (TDD, per `claudecode.md`).
5. Mark as `[x] COMPLETED` when done.
6. Commit: `[Feature/Fix] Brief description`.
7. **Stop after one FEATURE block and wait for review** (one clear next action, no batching).

---

## Current Sprint

**Queued 2026-08-28 from E's on-device review**, in the order E asked for. Five device screenshots
of `22dba79` covered three of the four things that had shipped unseen; the fourth (the journal
pad's NIGHT face) is still unconfirmed, which is what block 4 exists to fix. Two of the four blocks
are defects the screenshots exposed, one is a gap they explained, one is taste.

**Ownership note:** these blocks were written by Claude Code, not Cowork, on E's direct instruction
("draft all of them up in a block starting with both the capture bugs"). That crosses the usual
line in `WORKFLOW.md` the same way the 2026-08-23 archive split did, and for the same reason — E is
directing this queue in chat. Cowork should feel free to rewrite or replace any of it.

---

### FEATURE: F-FanLandscape — the fan points left when the phone is sideways  [x] COMPLETED

**E's call (2026-08-31, with a device screenshot of the broken state): "This DOES NOT work.
You've got to change the direction of the fan to horizontal pointing to the left direction."**
This is the design decision the F-LandscapeFix sweep logged: the portrait arc's 519pt of
`fromBottom` put Note and Voice above a 402pt landscape screen, Photo half-clipped, composers
unreachable through the fan sideways.

**The shape: the SAME arc, rotated.** `CaptureFan.horizontalSlots` is the portrait table with
its axes swapped — 78pt centres now running leftward (Task nearest the FAB at 207, Note farthest
at 519), the 57/70/75/70/57 bow turned vertical, the reverse-frequency stagger untouched. The
overlay picks the table by `verticalSizeClass` (compact = landscape iPhone); portrait keeps the
E-settled arc byte-for-byte.

**Acceptance criteria**
- [x] **Unit red first**: two new `CaptureFanTests` (explicit values, not the derivation) failed
      to compile on the unfixed tree — `type 'CaptureFan' has no member 'horizontalSlots'`,
      EXIT=65. Green after the table: CaptureFanTests **7 / 0**.
- [x] **Journey red proved REACHABILITY, not just correctness** (the dead-shared-component
      guard, this repo's six-instance defect class): with the table implemented and unit-green
      but the overlay still unwired, the reworked sweep — which now taps `captureFan-note`
      DIRECTLY in landscape instead of detouring through portrait — failed at exactly the old
      defect: `captureFan-note` at `{{724.0, -168.0}}`, kAXErrorCannotComplete, EXIT=65.
- [x] **Green after the one-line wiring, twice consecutively** (138.8s, 191.4s). Ground truth on
      the external recording (`screenshots/fan-landscape/`): all five tiles on-screen in a
      leftward row out of the ✕, middle tile at the bow's crest, stagger arriving Task-first;
      the note composer opens and submits in landscape.
- [x] Full unit suite **1,888 / 0**, EXIT=0. `swiftlint lint` 0 violations.
- [x] **Full UI target run whole: `Executed 23 tests, with 0 failures (0 unexpected) in
      2589.293 seconds`, EXIT=0** — including the reworked sweep tapping the fan in landscape.
- [x] Device carries the block — built 08:02:59, `devicectl` install + launch verified
      2026-08-31 08:04.

**E's device verdict (2026-08-31, on `bbc54b7`): "the fan feels good - tick it."** The
landscape fan is SETTLED alongside the portrait arc — both directions now carry an E-approved
arrangement; do not re-litigate either.

**Flake note for the record:** the swallowed-rotation sulk hit once more (a sweep run failed at
the window guard after heavy interactive idb driving); a fresh `simctl` boot cleared it, exactly
as [[landscape-fix]] records. The guard doing its job is why the failure was legible.

---

### FEATURE: F-ComposerSingleSave — one commit button on the capture composer  [x] COMPLETED

**E's report (2026-08-31, two device screenshots): the Task-kind composer showed BOTH a toolbar
"Save" and the green "Add to Today", while the New task sheet has a single footer button.**
Diagnosis: both called the same `submit()` — the toolbar Save was a pure duplicate, for all four
kinds, not just Task. Shipped as `4c0630f`: toolbar Save deleted, the footer CTA (the designed
primary, with the week-counterweight line) is the single commit, and it now carries the
`quickCaptureSubmitButton` identifier (`quickCaptureCTAButton` no longer exists).

**Acceptance criteria**
- [x] No new pure logic → no new unit tests; the guard is the landscape render sweep, which taps
      that identifier to submit a note. Re-run post-change: passed (122.6s), EXIT=0 — the footer
      stays reachable above the keyboard in landscape.
- [x] Full unit suite **1,888 / 0**; lint 0 violations; build succeeded.

### FEATURE: F-JournalComposerLocation — the entry composer's location switch  [x] COMPLETED

**E's ask (2026-08-31): "add the ability to log a location when a Log or Journal entry is
created — the same way that captures etc can", settled in chat as a COMBINATION of the per-entry
toggle and showing the place while composing.** Entries were already stamped SILENTLY behind the
global toggle; the gap was visibility and per-entry control. Shipped as `4dcb21b`:
`JournalService.composerAttachLocation` gates the stamp (the captures rule verbatim — seeded
from the global toggle, reset on load + after every save, and OFF requests no fix at all), the
default stamp closure moved `RecordLocationStamp` → `CaptureLocationStamp` so the global re-read
cannot veto an explicit opt-in, and the subtitle names the resolving place live — "This entry
will record you're at The Office 💼." — through a `JournalTimeline.placeLine(placeId:)` overload
the saved row's spelling delegates to. Triage's Journal-it path is untouched (it never stamped).
The subtitle takes `composerSoftInk`, never `.secondary` — the gold-pad half-alpha trap.

**Acceptance criteria**
- [x] TDD: 8 new tests across `JournalLocationStampTests` / `LogComposerCopyTests` /
      `JournalPlaceLineTests`; red-check run properly per the standing rule — gate reverted
      AFTER the commit, off-test failed for the right reason (`("1") is not equal to ("0") —
      off must not cost a fix`), restored with `git checkout --`, re-run green.
- [x] Full unit suite **1,896 / 0**, EXIT=0; lint 0 violations in 566 files; build succeeded.
- [x] Device carries both blocks — `devicectl` install + launch verified 2026-08-31 09:40.

**E's device verdict (2026-08-31, on `4dcb21b`): "i tried both things and both are working
well."** Both blocks are settled — the single-commit composer and the location switch's gold-pad
styling both passed E's on-device look.

---

## Place Actions arc — E's spec, settled 2026-08-31 in chat (branch `feature/place-actions`)

**E's ask: "assign specific actions to a place — when I go to a certain location, it opens a
specific application, or sends a text message to a predefined contact, etcetera."** Settled
through two question rounds; these decisions are E's and are not to be re-litigated per block:

- **Execution model: BOTH, layered.** One-tap actionable nudges from our app are the core
  (iOS hard-blocks auto-opening apps and auto-sending texts from a background wake — no
  third-party app can do either silently); a "Make this automatic" helper walks E into Apple's
  Shortcuts app for the actions Apple lets run zero-touch, and our in-app actions ship as App
  Intents so Shortcuts can drive them too.
- **Action kinds at launch: ALL of** open app / open URL / text a predefined contact / in-app
  (start sprint, create capture, journal line, open screen) — **"and likely more"**, so the
  kind enum is an open catalogue: an unknown kind decodes as unsupported WITH its payload
  preserved, never a failed place. (E's device routinely lags main — an old build editing a
  place must not strip a newer build's action.)
- **Directions: arrival AND departure, per action.** A place carries a LIST of actions, each
  with its own direction.
- **Firing rule: option 1 now** — a configured action counts as content, so its crossing fires
  (the custom-message precedent), and the 30-min bounce cooldown applies. **Option 3 (per-action
  re-fire tuning) is E's declared follow-up, later** — the model leaves room (a future `refire`
  field per action), but no UI or behaviour for it ships in this arc.
- Config lives on the **Place editor** (Settings → Places), as E said ("defined in the settings").
- One tap can only do ONE thing on iOS: external actions each get their own notification;
  in-app actions run themselves on the wake and the nudge reports what happened.

### FEATURE: F-PlaceActions-1-Model — the action catalogue, fences, and snapshot  [x] COMPLETED

The pure layer, TDD-heavy. `PlaceAction` (id, direction, kind + per-kind payload; snake_case
wire, flat fields with a `kind` discriminator; unknown or payload-broken kinds degrade to
`.unsupported` carrying the raw payload for verbatim re-encode). `Place.actions: [PlaceAction]`
(absent on every existing document → `[]`, the nudge-toggle precedent). An action for a
direction makes the place WANT that crossing: `wantsArrivalCrossing` / `wantsDepartureCrossing`
(toggle OR action), consumed by `LocationTriggerPlan` so an action-only place earns a region
slot — configuring an action IS the opt-in gesture the per-place philosophy requires.
`AtPlaceSnapshot.PlaceEntry` carries the actions (background wakes can't count on network).

**Acceptance criteria**
- [x] Round-trip tests for every kind through JSON AND `FirestoreDocumentCoder`; unknown-kind
      payload preservation pinned; a pre-actions place document decodes quietly. 23 new tests
      across four suites.
- [x] Plan tests: action-only place gets a region with the right directions; quiet places
      still get nothing; toggle + action compose across directions on one region.
- [x] Deliberate-regression red-check after commit (the standing rule), full suite **1,918 / 0**,
      lint 0 violations in 568 files, build succeeded.

**Found en route:** `PlaceEditorValidation.makePlace` REBUILDS the place on save, so `actions`
had to be threaded through it and `PlaceEditorView.save()` (`existing?.actions ?? []`) in THIS
block — without that, any rename or radius tweak would have silently stripped a place's actions
the moment block 2 shipped them. The id/createdAt preservation precedent, now pinned by a test.
Also: `try?` FLATTENS nested optionals (SE-0230), so `decodeIfPresent` alone cannot tell
"minutes absent" (valid) from "minutes undecodable" (degrade) — the decoder checks
`container.contains` first, and a test failure caught it before it shipped.

### FEATURE: F-PlaceActions-2-Editor — actions on the Place editor  [x] COMPLETED

An **Actions** section on `PlaceEditorView`: list rows ("On arrival → Open Spotify"),
add/edit/delete. Direction → kind → detail flow: curated app catalogue (known URL schemes:
Spotify, Maps, YouTube, Phone, Mail…) + custom-scheme field (iOS has no third-party app picker
— the catalogue is the ceiling); system contact picker (`CNContactPickerViewController`, no
Contacts permission needed for one-off picks) + message body for texts; screen list for
open-screen; minutes for sprint (defaulting to E's sprint setting); text fields for
capture/journal bodies. Validation in a pure `PlaceActionValidation` (trimmed-to-nil like
`arrivalMessage` — "" must never save).

**Acceptance criteria**
- [x] Validation + row-label logic pure and tested first (`PlaceActionEditing.swift` /
      `PlaceActionEditingTests`, 16 tests: per-kind validation, scheme/web-address
      normalization, draft↔action editing round trip, honest unsupported labels, screen tokens
      pinned to `AppTab` spellings). The Places feature is iOS-17-gated with E's standing
      authorisation, so no fresh 16.0 gating was needed.
- [x] Editing a place with an UNSUPPORTED action shows it honestly (named row + "kept safe"
      footnote, not editable, delete allowed) and preserves it on save (`PlaceActionDraft`
      REFUSES to open for one — test-pinned — so the sheet can never save a stripped version).
- [x] Suite **1,934 / 0**; lint 0 in 571 files; build succeeded. Simulator drive against the
      emulator: fresh account → Settings → Places → New place → two actions added (arrival →
      Spotify from the catalogue, departure → text with typed number), place saved, REOPENED
      and both rows decoded back with the same ids — the full write→read round trip through
      the live rules. Screenshots sent to E.

**Found en route (device-class bug, caught in the simulator drive):** `.sheet(item:)` attached
to a Form `Section` gets applied PER ROW, and the duplicate presentations dismissed the whole
place editor the moment "Add an action" was tapped — the sheet now hangs off the Add button
(any single concrete view inside the section works). This never surfaced in unit tests and
never could; it is exactly what the drive exists to catch.

### FEATURE: F-PlaceActions-3-Execution — actions fire on a crossing  [x] COMPLETED

The wake path: after the cooldown gate, matching-direction actions execute. **In-app actions
run themselves** (journal line writes place-stamped, capture drops into the inbox, sprint
starts) and the nudge REPORTS what ran; **external actions each post their own notification**
whose tap executes exactly one thing (URL-scheme open; `sms:` compose pre-filled to the
predefined contact — the final Send tap is Apple's floor). An action makes its crossing fire
(firing-rule extension in `ArrivalNudgeContent` / a new `PlaceActionExecuting` seam, fake-driven
in tests). Not-installed app → honest in-app "couldn't open" surface, never silence.

**Acceptance criteria**
- [x] Executor seam unit-tested with fakes (31 new tests: every kind, both directions, cooldown
      respected, kill-switch split — auto-runs are records and run with it OFF, notifications
      don't — failed-write-retries, empty-never-fires untouched for action-less places).
- [x] Verified on simulator against REAL geofence crossings (a drive into a
      Buckingham Palace fence, route-simulated movement): the auto-run journal line written place-stamped from a
      background wake and visible in the Journal timeline; the crossing nudge reporting it
      ("You're at Gym 🏋️ — Journaled …"); the arrival external ("Open Spotify … tap to open.")
      and the departure external ("Text … — sending stays with you.") both delivered. Tap
      routing is pin-tested through the router; the delegate glue follows
      `FocusNotificationRouter`'s proven pattern — the sim's lock screen kept swallowing
      interactive taps, so the tap-through is E's field test's to confirm.
- [x] **Field test on `wishwashwacky15`** — a real crossing runs an in-app action and delivers
      an external one, and the taps route — before this block may be ticked (the location-merge
      precedent). **FIRST PASS DONE (E, 2026-08-31, on foot):** E configured real actions —
      "Open Monzo, on arrival" at the Bank (the CUSTOM scheme field, proven in anger: Monzo is
      not in the catalogue) and "Open Spotify, when leaving" on Home alongside BOTH custom
      messages — walked the fences, and the notifications fired and routed. One wrinkle: after
      the tap, iOS asked "do you want to open Spotify?" — the async hop before
      `UIApplication.open` breaks the tap's user-initiated attribution, which is what invites
      that dialog. Fixed to open synchronously in the delegate callback (`0c65ca5`); E re-tests
      on the next walk. If the dialog survives, it is Apple's cross-app guard, stated honestly.
      The in-app auto-run half is simulator-proven; E can field-confirm by adding a journal-line
      action to any place.
      **SECOND PASS DONE (E, 2026-09-01): "block 3 it works"** — the double-confirm retest
      passed with the synchronous-open fix in place; block ticked, arc complete, merged to
      main the same day.

**Found on the drive (both fixed, both red-checked):**
- **Duplicate-delivery race (`338005f`):** iOS delivered one arrival twice in seconds; both
  passed the cooldown check before either wrote it (the handler suspends between read and
  write) and the journal line landed TWICE. In-flight guard keyed place|direction, set before
  the first await. The test only went red once the fake writers SUSPENDED like Firestore —
  a sync fake never opens the race window.
- **Deviation from this block's sketch, reported:** `startSprint` is TAP-to-start, not
  auto-run — ActivityKit refuses to start a Live Activity from a background wake, and a sprint
  silently half-spent before E sits down punishes the arrival it was meant to reward.
- **Sim-harness traps for the record:** `simctl privacy grant location-always` on the shared
  simulator breaks two unit tests that read live authorization (the hosted test target IS the
  app) — `simctl privacy reset location` after any drive. A location TELEPORT collapses the
  significant-change replan and the crossing into one instant (fence registers already-Inside,
  no didEnter) — simulate a `simctl location start` ROUTE instead. Notifications need the
  app's own permission prompt first (start a sprint once).

### FEATURE: F-PlaceActions-4-Shortcuts — the zero-touch layer  [x] COMPLETED

App Intents ("Start a sprint", "Capture a note", "Log a journal line") so Shortcuts can drive
the in-app actions; a "Make this automatic" row per external action opening a step-by-step
guide into Apple's Shortcuts app (Apple allows NO programmatic creation of automations — the
guide is the honest ceiling, and it says which steps are E's). iOS 16 App Intents floor
verified per API used.

**Acceptance criteria**
- [x] Intents callable from the Shortcuts app on device; guide content pure and tested.
      **E's field verdict, 2026-08-31 evening: "block 4 - success"** — the device walk passed.
      **BUILT and sim-verified 2026-08-31 (device half is E's):** three intents ship —
      "Capture a note" and "Log a journal line" run WITHOUT opening the app (writes through
      `ShortcutIntentRunner`, stamped via `RecordLocationStamp`, `DataChangeSignal` posted so
      an open app refreshes); "Start a sprint" opens the app (`openAppWhenRun` — ActivityKit's
      background refusal, the block-3 precedent) and rides `PlaceActionNotificationRouter.open(_:)`,
      the notification-tap plumbing minus the notification. An `AppShortcutsProvider`
      (`@available(iOS 16.4, *)` — the `shortTitle:systemImageName:` init's floor; on 16.0–16.3
      the intents still sit in the action library) surfaces all three under a LifeOS section
      with zero setup. Guide content is `PlaceAutomationGuide` (9 tests, every word pinned):
      guides ONLY for openApp/openURL/textContact/startSprint — journal/capture already run
      zero-touch on OUR fences, openScreen has no Shortcuts action that could reach it, and
      unsupported can't be taught; the intro says every tap is E's (Apple allows no programmatic
      automation creation), and the afterword warns the in-app action keeps nudging unless
      deleted. Sheet + per-action "Make this automatic" rows on the place editor
      (`PlaceActionsSection`, split to its own file at the 400-line lint bar).
      **Sim drive (18:04–18:35):** all three actions found and run from Apple's Shortcuts app —
      capture dialog "Captured …to your inbox." and the capture in the inbox peek card; journal
      dialog "Journaled …" and the line in the timeline; sprint foregrounding the app with the
      timer bar + Live Activity running at the default length. One sim quirk: tapping an App
      Shortcut TILE directly says "Unable to run App Shortcut" (the Siri runner path); inside a
      shortcut the actions run fine — retest the tile on device.
      **Editor drive (second pass, properly against the EMULATOR via shell `simctl launch`):**
      fresh account → Settings → Places → New place "Gym" → arrival Open Spotify action →
      the "Make “Open Spotify” automatic" row appeared, its sheet presented over the editor
      (sibling sheets on the Add button — the block-2 per-row trap did NOT recur), all four
      steps + intro + afterword rendered naming Gym and Spotify, and Open Shortcuts handed
      off into Apple's app. Reachability proven, not just tested (the dead-shared-component
      lesson).
      **Drive honesty:** the ios-simulator MCP's `launch_app` DROPPED the `SIMCTL_CHILD_` env
      (shell `simctl launch` passes it fine), so the FIRST drive silently ran
      against PRODUCTION on a throwaway account (block4drive@example.com) — created 18:04,
      verified, then deleted through Settings → Delete Account (re-auth flow exercised live);
      `auth_get_users` confirms `users: []`. Nothing of E's was touched. Upside: the intents
      are proven against the LIVE rules, not just the emulator.
- [x] Suite, lint, build; E walks one real automation end-to-end on device.
      **Both halves done 2026-08-31:** suite **1,983 / 0** (18 new: 9 guide + 7 runner + 2
      router), SwiftLint 0 violations in 581 files, sim build succeeded, red-check after
      commit; E walked the automation on `wishwashwacky15` and reported success the same
      evening. The arc's merge still waits on Block 3's double-confirm retest (E: "will test
      later").

---

## App Directory arc — E's design, settled 2026-09-01 (fresh session, branch `feature/app-directory`, AFTER the place-actions merge)

**E's ask: when adding a place action, "select an application that they have installed on the
device" — fully custom, any app.** Designed in a six-question round on 2026-09-01; the full
approved plan (with the four blocks in implementation detail) lives at
`~/.claude/plans/dont-action-anything-yet-structured-backus.md` and the session opener at
`../Momentum-v3-Design-Handoff/SESSION-OPENER-app-directory.md`. E's settled decisions — not
to be re-litigated per block:

- **iOS ceiling acknowledged:** no installed-app enumeration API exists for anyone. The shape
  is a big searchable directory (hundreds of curated apps) + a "smart custom" path (bare
  scheme, kept, AND any pasted share-link opened as a universal link — app if installed, web
  if not) + config-time verification for a budgeted subset.
- **Verification is three honest states** — installed / doesn't look installed / can't check —
  because `LSApplicationQueriesSchemes` caps at 50 schemes per build (the plist currently has
  NONE) and `canOpenURL` on an undeclared scheme lies. Tap-time honesty stays the backstop.
- **Deep destinations too** (Spotify playlist, Maps directions to the place itself, chat) via
  a **new wire kind `open_link`** — a new KIND, never a field on `open_app`, because the
  encoder drops unknown fields on known kinds but preserves unknown kinds via `.unsupported`.
- **Directory ships bundled + remote top-up**: Swift-constant base list; a read-only
  `/catalog/app_directory` Firestore doc (the app's first global read, new rules match block,
  E publishes) grows it without a release. Every failure mode degrades to bundled+cache.
- **REJECTED: a run-a-shortcut action kind** (fragile, user-maintained). **PARKED: true
  Spotify OAuth integration** — a separate future arc E wants "at some point".
- **Sequencing (E, explicit): built in a FRESH session, only after `feature/place-actions`
  merges to main** (which waits on E's Block 3 double-confirm retest). The opener carries the
  state gate.

### FEATURE: F-AppDirectory-1-Directory — the big searchable directory (bundled)  [x] COMPLETED

`PlaceAppDirectoryEntry` (scheme = identity, name, keywords, universal-link hosts, destination
templates, rank, hidden) with per-entry lenient decode (a malformed entry is dropped, never
fatal) and a pure `merge(bundled:remote:)` keyed by scheme. Bundled list as a Swift constant
(`PlaceAppDirectoryBundled.swift`), few hundred curated apps — curation IS the work; a wrong
scheme teaches E the feature lies, so long-tail entries prefer universal links over guessed
schemes. `PlaceAppDirectorySearch.filter` ranked name-prefix > contains > keyword > scheme.
`PlaceAppPickerView` (iOS 17-gated searchable List sheet) replaces the 10-entry Picker;
"Something else…" leads to smart custom. Saves still produce plain `.openApp` — zero wire
change. ALSO lands the forward encoder fix: known kinds capture and re-encode non-typed extra
fields (`extraPayload`), so future optional fields survive builds from this arc on.

**Acceptance criteria**
- [x] Directory model, lenient decode, merge, search ranking, and the extras round-trip
      (`open_app` JSON + stranger field → re-encode → intact) all TDD-pinned; every bundled
      entry swept through `normalizedScheme` by a test. (2026-09-01: 33 new tests across
      `PlaceAppDirectoryTests`, `PlaceAppDirectoryBundledTests`, `PlaceActionExtraPayloadTests`
      + draft threading in `PlaceActionEditingTests` — the edit-save rebuild was a second
      stripping hole, closed via `PlaceActionDraft.extraPayload`. Bundled list is **152
      entries**, not "few hundred": the curation rule (documented schemes only, omit rather
      than guess — Google Calendar, Dropbox, Cash App, Fantastical, Prime Video, Max checked
      and OMITTED) outranked list size; block 4's remote top-up is the growth path.)
- [x] Picker sheet drives on the simulator: search finds apps ("Spot" → Spotify), a pick saves
      as `.openApp` (verified ON THE WIRE in the emulator's Firestore doc: flat snake_case,
      `kind=open_app scheme=spotify display_name=Spotify`), custom path reachable via
      "Something else…" (+ honest not-in-the-list empty state). Suite **2,015/0** (0 skipped —
      emulator up), lint 0/587, build green; red-check after commit.

### FEATURE: F-AppDirectory-2-Links — pasted links, `open_link`, universal-link opener, destinations  [x] COMPLETED

New wire kind `open_link` (`display_name`, `link`, optional `scheme`): pasted share-links and
deep destinations. Old builds degrade it to `.unsupported` with payload preserved and the
honest "added by a newer version" row — the designed-for path. Smart custom gains the
paste-a-link field (https-only via `normalizedWebAddress`, name inferred from host, editable).
Destination step in the picker for entries with templates (one `{value}` substitution,
percent-encoded; skippable in one tap — the default is the plain open; Maps gets "Directions
to this place" from the place's own coordinate). `PlaceLinkOpenPlan` (https → universal-first,
scheme → direct) + `PlaceLinkOpener`: attempt 1 with `.universalLinksOnly: true` issued
SYNCHRONOUSLY on the delegate callback (the 0c65ca5 attribution lesson — pinned by a test that
the fake open fires before the call returns), plain open in the completion on failure, honest
banner only after the last attempt. Router signature untouched.

**Acceptance criteria**
- [x] `open_link` round-trips through JSON AND `FirestoreDocumentCoder` (degradation pinned
      through the CODEC too); route/split/labels/notification copy/automation guide extended
      and pinned; `PlaceLinkOpenPlan` + `PlaceLinkOpener` with the synchronous-first-attempt
      pin. (2026-09-01: 41 new tests. Two design additions the plan implied but didn't spell:
      `placeCoordinatePrefill` flag on destination templates — curated, remote-decodable,
      never name-matched — and `PlaceActionDraftLinkPick`, a verbatim carrier so a
      destination's SCHEME link never meets the https-only hand-paste rule; plus
      `seededKindChoice` → `seededWireKind`, because open_app and open_link share one editor
      menu choice and extras must follow the WIRE kind.)
- [x] Sim drive against the emulator: pasted share link saved and HOST-RECOGNISED (wire shows
      `open_link` + display_name "Spotify" + scheme spotify, neither typed); destination step
      drove "Directions to Gym" one-tap → wire shows `comgooglemaps://?daddr=51.51520%2C-0.14180`;
      the coordinate-daddr form OPENED Apple Maps into its directions flow, and the https link
      fell to Safari (web-if-not-installed). The notification TAP itself is unit-pinned
      (router + opener synchrony) — a real crossing tap is field-gate territory. Suite
      **2,056/0** (0 skipped), lint 0/594, build green; red-check after commit.

### FEATURE: F-AppDirectory-3-Verify — config-time install verification  [x] COMPLETED

`Info.plist` gains `LSApplicationQueriesSchemes` (curated top ~45 of the bundled list —
headroom under the 50 cap; compile-time only, remote entries can never buy a slot).
`PlaceQueryableSchemes.declared` + a parity test reading the plist via `Bundle.main`
(set-equality, count ≤ 50 — drift is a red test). `PlaceAppInstallVerdict` decides the three
states BEFORE `canOpenURL` (undeclared → can't-check, never consulted — tripwire-tested).
Copy pinned in `PlaceAppInstallCopy`; never claims "not installed" when it can't know.
One-method `SchemeInstallChecking` adapter. Note: the simulator has almost no third-party
apps, so "doesn't look installed" is the expected sim state; declared schemes get one manual
device sweep.

**Acceptance criteria**
- [x] Verdict logic (incl. the never-calls-canOpen tripwire), copy, and plist parity all
      TDD-pinned (9 new tests; parity reads the BUILT product's Info.plist via `Bundle.main`
      and set-compares both ways). **45 declared schemes** — top of the rank order + the
      everyday-UK four (strava, deliveroo, ubereats, monzo) — in `Info.plist` (the target
      merges the plist FILE into its generated one, so array keys ride there).
- [x] Badges/footers render on the simulator WITH real discriminators: Apple Maps — the one
      declared app actually installed on the sim — carries the quiet positive-only checkmark
      while every other row stays clean; picking Spotify shows the pinned "Doesn't look
      installed. Saving is fine…" footer with Save still enabled. Suite **2,065/0**
      (0 skipped), lint 0/596, build green; red-check after commit. Each declared scheme
      still needs its one manual DEVICE sweep (sim has no third-party apps) — field-gate
      territory; a "doesn't look installed" there for an app E HAS is a wrong scheme to cull.

### FEATURE: F-AppDirectory-4-Remote — the directory grows without a release  [x] COMPLETED

`/catalog/app_directory` single-doc read — the app's FIRST global Firestore read, deliberately
NOT in the per-user `Collection` enum: named `fetchAppDirectoryDocument()` in
`FirebaseManager+AppDirectory.swift`, narrow `AppDirectoryBackingStore` +
`FirebaseAppDirectoryClientAdapter` + recording fake. Rules addition (E publishes manually;
verify live via the Firebase MCP diff): `match /catalog/{docId} { allow read: if request.auth
!= null; allow write: if false; }` — until published, permission-denied is treated exactly
like offline. Fetch when the picker opens, throttled by a pure 24h-TTL cache policy; the sheet
always renders bundled+cache synchronously and a completed fetch updates the NEXT open (no
reshuffle under E's finger). Cache = JSON blob + fetchedAt in UserDefaults behind a two-method
protocol; corruption degrades to bundled.

**Acceptance criteria**
- [x] Cache policy, cache resilience, per-entry lossy remote decode, and the composition
      (fetch error → cache stamp AND snapshot untouched) all TDD-pinned with recording fakes
      (11 new tests, incl. the no-reshuffle pin: a taken snapshot never moves, the NEXT open
      sees the fetch). `fetchGlobalDocumentData(path:)` added to the manager CORE as the one
      global-read plumbing; `+AppDirectory` names the document; NOT in the `Collection` enum.
- [x] Emulator drive (2026-09-01): seeded `/catalog/app_directory` with a rank-100 "Zzz
      Remote Test" entry — FIRST picker open showed bundled only (fetch kicked), SECOND open
      showed the remote entry at the very top. The read went through the NEW rules match
      (emulator hot-reloaded `firestore.rules`). Suite **2,076/0** (0 skipped), lint 0/600,
      build green; red-check after commit.
- [x] **Rules diff for E to publish:** `firestore.rules` gained
      `match /catalog/{docId} { allow read: if request.auth != null; allow write: if false; }`
      — LIVE production still lacks it; until E republishes, the app's remote fetch fails
      permission-denied and behaves exactly like offline (bundled + cache carry the picker),
      so nothing breaks in the meantime.

**Arc close-out:** field gate before the `--no-ff` merge — E walks, on device: a directory
pick, a pasted-link custom app, one deep destination, and one "doesn't look installed"
verdict for an app E doesn't have.

---

### FEATURE: F-TabBarMinimize — the tab bar gets out of the way while you scroll down  [x] COMPLETED

**E's ask (2026-08-31, in chat): "make the nav bar at the bottom of the screen transparent when
scrolling downwards", plus keep the newest build on the phone.**

**The read on "transparent":** the intent is the bar stopping covering content while reading
downwards. iOS 26 has a system behaviour for exactly this — the Liquid Glass bar collapses to
just the selected tab on scroll down and returns on scroll up (`tabBarMinimizeBehavior(.onScrollDown)`,
`@available(iOS 26.0, *)`, verified in the SDK swiftinterface). That shipped, as one gated
modifier on `RootView`'s TabView (`minimizesTabBarOnScrollDown()`, the same `@ViewBuilder`
`#available` shape as `.haptic`). It is the same directional grammar the capture pill speaks
(F-PillStay), delivered by the system so the two never fight. If E literally wants a full-size
but see-through bar instead, that is a different dial — say so on device review.

- iOS 16–25 keep the standard bar: the behaviour does not exist there and hand-rolling
  transparency against a UIKit bar is not worth the fight on a floor the app will outlive.
- No new pure logic → no new unit tests; the verification is renders with a genuine
  discriminator, the F-DiscPill proof pattern.

**Acceptance criteria**
- [x] Build succeeds; `swiftlint lint` clean on the touched file; RootView 377 lines.
- [x] **Discriminator renders** (simulator, restored emulator session, idb swipes;
      `screenshots/tabbar-minimize/`): full five-tab bar at rest → after a scroll-down swipe the
      bar is a single Today-glyph pill and content flows through where it sat → after a decisive
      scroll-up flick the full bar is back. A gentle 220pt up-drag did NOT restore it in the sim
      — consistent with the system's own threshold and/or idb gesture synthesis; E judges the
      real feel on device.
- [x] Full unit suite **1,886 / 0**, EXIT=0.
- [x] **Full UI target run whole: `Executed 23 tests, with 0 failures (0 unexpected) in
      2569.535 seconds`, EXIT=0.** This was the load-bearing gate: journeys address
      `app.tabBars.buttons` after scrolling, which is precisely what this behaviour changes —
      all 23 individually green.
- [x] Device carries the block — built 06:34:40, `devicectl` install + launch verified
      2026-08-31 06:35.

---

### FEATURE: F-LandscapeFix — the login screen works sideways, and the landscape sweep ran  [x] COMPLETED

**E's calls, made in advance (session opener, 2026-08-31): both orientations stay supported; fix
the login screen first, then sweep the other screens.** The proven defect was F-PortraitArrival's:
`loginPasswordField` never hittable in landscape, 45s × ten tests.

**The diagnosis is NOT what the opener guessed.** The form was already in a `ScrollView`, and it
fits landscape fine until a field is focused (ground-truth frame: everything visible, footer
included). The defect is keyboard-shaped: the landscape keyboard plus the footer bar riding above
it leave a viewport of roughly two card-heights, SwiftUI's keyboard avoidance keeps only the
FOCUSED field inside it, and the password card below is buried BY CONSTRUCTION the moment Email is
focused. Nothing scrolls it into reach — XCUITest doesn't scroll, and a person shouldn't have to.

**Scroll-on-focus was tried twice and condemned by its own evidence** (kept as the comment on
`fieldsSection`): `scrollTo`'s anchors align against the scroll view's FULL bounds — the keyboard
inset is invisible to it, so anchoring the successor's `.bottom` was a 45-second no-op on the test
recording — and the `.top`-anchor retry with a settle timer passed once, then flaked back red on
identical code: a one-shot timed scroll loses to the system's own caret-keeping scrolls mid-typing.
A fix whose success depends on unexplained timing is not a fix.

**The fix that shipped: the row.** In compact height `fieldsSection` lays the cards side by side —
email + password (plus name in Create mode) in one `HStack`. Keeping the focused field visible
keeps the whole row visible, because the row IS all the fields. No timers, no scroll choreography,
nothing for the keyboard to bury. Portrait renders the approved stack untouched.

**Acceptance criteria**
- [x] **Red first**: `LandscapeLoginUITests.testSignIn_completesInLandscape` — portrait arrival,
      rotate, then the SAME shared `UITestSession.signIn` flow every journey uses (made internal
      for exactly this). On the unfixed tree it died at the identical line and message as the ten
      F-PortraitArrival failures: `"loginPasswordField" SecureTextField never became hittable`,
      EXIT=65.
- [x] **Green, twice consecutively** — 0 failures at 103s and 94s runs on the same code, unlike
      the scroll attempt's one-green-then-red. Ground truth on the screen recording: email typed
      and password card SIDE BY SIDE above the keyboard, footer's Sign in visible below.
- [x] **Anti-vacuity guard that earned its keep**: the journey asserts the WINDOW is wider than
      tall before signing in — and on its second-ever run it caught a real swallowed rotation
      ("Device orientation changed to Landscape Left" with no interface change ever following).
- [x] `UITestSession.rotateToLandscape(_:)` — the set retried through a portrait toggle, judged
      by the window's own frame; `resetToPortrait` moved with it into `UITestOrientation.swift`
      (UITestSession had hit 408 lines against the 400 budget; now 355).
- [x] **The landscape sweep ran as renders, not guesses** (`testRenderLandscapeSweep`, kept in
      the render harness): all five tabs plus BOTH composers, each composer driven to a real
      submit in landscape on the throwaway emulator account.
- [x] **Ground truth is the screen recording, not `app.screenshot()`** — on a rotated simulator
      the XCTAttachment stills come back letterboxed in a portrait frame with the content column
      squeezed, which reads as a half-black broken screen that the simctl recording proves is
      full-bleed and fine. Evidence for this block was extracted from
      `xcrun simctl io recordVideo` frames.
- [x] `swiftlint lint` → 0 violations. Unit suite **1,886 / 0** (EXIT=0). Coverage 30.09%
      (11,227/37,314) — denominators differ from the recorded 23.62% (37,314 vs 36,721) so the
      ratios are not comparable; covered lines 8,673 → 11,227.
- [x] **Full UI target run whole: `Executed 23 tests, with 0 failures (0 unexpected) in
      2493.052 seconds`, EXIT=0** — every prior test plus the landscape journey (91.4s) and the
      sweep (176.1s), with `testLaunch`'s four configuration runs reported individually (the old
      "17" counted that sweep as one line; nothing was dropped — all 23 are individually named
      and green in the log).

**Sweep findings — logged, deliberately not fixed here:**
1. **The capture fan clips off-screen in landscape (REAL defect, needs E's design call).** The
   glass tiles arc UP from the FAB; landscape height can't hold the arc — NOTE and VOICE sit
   fully off the top edge (`captureFan-note` frames at y = −168), PHOTO is half-clipped; only
   TASK and LINK remain usable, so the composers are unreachable through the fan sideways. The
   fan's arc is E-settled design (capture-disc arc, do-not-re-litigate) — a landscape arrangement
   is a design decision, not a patch. The sweep photographs it and routes around it (composer
   opened portrait, rotated, typed, submitted — a route a user genuinely has).
2. Everything else swept clean: Today, Tasks, Areas, Captures, Journal, the note composer and the
   journal pad all render full-bleed and usable in landscape.
3. One cosmetic note, not logged as a defect: on landscape Today the floating glass tab bar sits
   directly over the Best-next-move card's green "Close it" button and picks the green up through
   the glass. Same composition exists in portrait; landscape just brings them together.

**Harness debt observed, out of scope:** `signOutIfSignedIn`'s "settled" wait says *whichever
appears first* but `XCTWaiter().wait(for:)` completes when ALL expectations do — so every
signed-out launch that lands on the login screen burns the full 45s before proceeding. Correct
behaviour, wasted time; worth its own small tick.

---

### FEATURE: F-PromoteSheetPolish — the Make-a-task sheet stops looking like debug UI  [x] COMPLETED

**E's screenshot verdict (2026-08-31): "this view/display needs fixing - it looks horrible."**

Root cause, found in source: `ChoiceChipButtonStyle` styles only the BACKGROUND — the sprint
planner pads its own labels, but this sheet passed bare `Button("10 min")`s, so the fill hugged
the text and the selected state read as a text highlight. Beside that, `Picker("Priority")` sat
outside any `Form`, which renders as a bare "P4 ⌄" floating with no label, and the Due Date
toggle was an orphan row.

**What shipped:** one `chip()` builder — equal-width, 44pt-min labels (§3's target is the
VISIBLE control) — worn by all four groups: EFFORT (10/15/30 min + "Unsure", was lowercase
"unknown"), WHEN (Today/Tomorrow/Someday), PRIORITY (P1–P4 chips replacing the floating
picker), and DUE DATE (section label + "Exact day" toggle + date picker). Groups 16pt apart in
the bento card, macro groups 24pt (§2). Behaviour, service calls and all accessibility
identifiers untouched.

**Verified:** SwiftLint 0, suite 1,886 / 0, build green; rendered end-to-end on the simulator
through the REAL path (fan → note → save → Captures → Task it):
`screenshots/promote-sheet/`.

**SEEN BY E ON DEVICE, 2026-08-31 (IMG_8134/8135):** interactions confirmed working (Today
selected, Exact day toggled, Date row appears). One nit PARKED at E's direction, not actioned:
the iOS-default GREEN toggle sits off-palette beside the blue chips — "flag the green-iOS-
toggles to be dealt with later down the line." It is on the pre-release UI list in the
register; an app-wide `.tint` decision, not a per-sheet patch.

---

### FEATURE: F-PillStay — the pill stays until you scroll back up  [x] COMPLETED

**E's direction (2026-08-31), changing the settled motion model:** *"currently, the pill button
returns back to its normal size — I want this to stay in pill form until the page is scrolled
upwards again."*

So the pill goes DIRECTIONAL and STICKY, the classic FAB pattern: scrolling down (finger moving
up) collapses the disc and it STAYS collapsed — through the stop, through momentum, through
reading; scrolling up (finger moving down) restores the disc immediately. The 1.2s settle timer
and its debounce machinery are REMOVED, not parked — dead code is this repo's most repeated
defect. The shrink spring and the expanding-fade regrow animations are untouched; only the
trigger changes.

**Mechanics:** the window-level pan observer now forwards `.changed` translation; the model
keeps a directional anchor and flips on ±12pt of travel in the new direction, so jitter can't
flap it and a mid-drag reversal switches state without a new touch. One judgment call beyond
E's words: a TAB CHANGE resets to the disc — a sticky pill on a fresh tab reads as a bug, and
E can veto this.

**Acceptance criteria:**

- [x] `CaptureDiscScrollActivity` rewritten: `prefersPill`, ±12pt directional latch with a
      re-basing anchor, no timers — 8 synchronous tests.
- [x] `CaptureDiscPanObserver.react(to:translationY:)` forwards began + changed; terminal
      states silent by design — 4 tests.
- [x] Call-site guards moved to `.prefersPill`; wiring chain asserted end to end.
- [x] SwiftLint 0 violations, suite 1,886 / 0 (settle-timer tests removed with the timer),
      build green (2026-08-31).
- [x] Discriminator rendered on the simulator (`screenshots/pill-stay/`): the pill still
      standing FIVE seconds after the down-scroll ended — the old build regrows at 1.2s — then
      the disc back after one up-scroll.
- [x] **APPROVED BY E ON DEVICE, 2026-08-31: "looks good."** The tab-change reset was offered
      for veto and not vetoed — it stands.

---

### FEATURE: F-FabDeepField — the FAB gets an identity, and the fan stops shouting  [x] COMPLETED

**E's verdict on device (2026-08-30):** the FAB's colour is wrong — *"the colors when the FAB is
extended… altogether it just doesn't look right."* Diagnosis, confirmed in source: the FAB wore
plain `AccentColor` (the same blue as the tab tint, "Clear the deck", Arrange and the Work bars),
the fan was five full-saturation solids borrowed from tile/bar tokens, and the Note disc's fill
literally WAS `AccentColor` — a second FAB inside the fan.

**Process: a real A/B, rendered before choosing.** Two directions E picked from four were built
and screenshotted on the simulator (rest / pill / fan-open, archived in
`screenshots/fab-colour-variants/`): **A** ink FAB (inverted neutral surface) + glass fan, **B**
deep-field gradient FAB + the same glass fan. **E chose B, explicitly.**

**What shipped:**

- **Deep-field disc**: `CaptureDeep` (new colorset, light `#4C3FE0` / dark `#5246E8`) → accent
  blue in a top-to-bottom `LinearGradient` on the one `Capsule`. Both hues live in the asset
  catalog — no raw colour in Swift (§4). Accent glow retained.
- **Glass fan**: each disc is its kind colour at 18% over `.ultraThinMaterial`, glyph + label in
  the full kind colour, hairline ring at 40% — the same tinted-tile language as the app's 44pt
  card icon tiles, so the open fan matches the app instead of fighting it. The Note disc no
  longer twins the FAB.
- The unused ink-variant colorsets were DELETED, not left behind (this repo's dead-component
  rule); variant A survives only as its archived renders.

**Verified:** SwiftLint 0, suite 1,887 / 0, build green, simulator renders of both variants.

- [x] **APPROVED BY E ON DEVICE, 2026-08-31** — six screenshots (IMG_8124–8130, light AND
      dark): *"variant B looks very nice."* The glass fan and gradient disc hold up in both
      appearances in the field.

**Addendum — E's margin pass (2026-08-31):** *"ADD more spacing/padding to the top and bottom of
the capture button when it is in pill form. ALSO the WHOLE capture icon location needs more
Margin applied to the bottom and right-hand side."* Shipped as: pill 52×32 → **52×40**; trailing
margin 16 → **24** (now `CaptureDiscMetrics.edgeMargin`, read by RootView); the overlay stack
lifted 52 → **60** off the tab bar — the SAME 8pt delta on both axes, which is what lets
`clearance` stay one number (84 → **92**) for the bottom inset and the trailing clearance alike.
All eleven `.captureDiscClearance()` call sites inherit 92 automatically; the freeze test moved
with the derivation. Suite 1,887 / 0.

**SETTLED BY E ON DEVICE, 2026-08-31** — after two more dials (pill height 40 → 48, then width
52 → 60, i.e. "goto 4pt" per side): *"those proportions look much better on the app."* The
capture-disc arc is closed end to end: F-DiscPill → F-PillTune (0.68 glass) → F-FabDeepField
(gradient + glass fan + margins + 60×48 pill). Do not reopen any of these numbers without a new
E verdict.

---

### FEATURE: F-PillTune — the pill grows up, and the disc comes back like a sunrise  [x] COMPLETED

**E's device verdict on F-DiscPill (2026-08-30, five stills):** the mechanism works everywhere,
and two things need retuning: *"the pill button is too small and needs to regrow EVEN slower, a
slow gradual expanding fade effect would look good."*

**The three turns of the dial:**

1. **Bigger pill** — 40×24 reads as a sliver on device. Goes to **52×32, glyph scale 0.8**:
   unmistakably a button, still clearly smaller than the 60pt disc it stands in for.
2. **Longer settle** — `settleDelay` 0.7s → **1.2s**. The finger has to be up for a beat longer
   before the disc starts coming back.
3. **The regrow becomes an expanding fade** — the shrink stays a snappy spring (it must feel tied
   to the finger), but the regrow drops the spring for a **slow `easeOut` (0.9s)**, and the pill
   state carries slight translucency so the expansion visibly *fades in* to the full disc. One
   asymmetric-animation ternary; `reduceMotion` still snaps both ways.

**Acceptance criteria:**

- [x] `CaptureDiscMetrics` 52×32, glyph 0.8; the relative guard now bounds height by the full
      diameter — its point (strictly smaller than the disc) intact.
- [x] Settle delay 1.2s; the 0.3–1.5s deliberate-beat bounds test holds unchanged.
- [x] Asymmetric: shrink keeps the finger-tied spring, regrow is `easeOut(0.9)` + a pill-state
      opacity of 0.85 so the expansion fades in. Reasons in comments at the site.
- [x] SwiftLint 0 violations, suite 1,886 / 0 (+1: `testRootViewRendersTheDiscLabel`, added
      because the face moved to `Theme/CaptureDiscLabel.swift` for the 400-line file limit and
      the wiring chain needed the new link asserted), build green (2026-08-30).
- [x] Re-rendered on the simulator against the emulator account: `screenshots/disc-pill-tune/`
      — bigger pill mid-drag, a frame mid-regrow, settled disc. Feel verdict stays E's, on
      device.

**Addendum, same evening — the pill goes glass (E's GIF verdict).** E recorded the tuned build
(`Capture PillButton preview.gif`, 85 frames analysed via an ImageIO frame dump) and dialled the
pill's translucency himself: *"try .68 — just below the 0.7 sweet spot."* Shipped as
`CaptureDiscMetrics.pillOpacity = 0.68` (one spelling; the label reads the metric), guarded by
`testPillOpacityStaysInTheReadableGlassBand` — bounds 0.5…<1 because at 1.0 the trailing corner
swallows content again (the GIF showed the opaque pill covering a nudges chip and a capture
row's edge) and below ~0.5 a blue control reads as disabled. Suite 1,887 / 0.
`screenshots/disc-pill-tune/4-glass-pill-068.png` shows the Money row's progress bar reading
through the pill. The GIF also confirmed the design's known boundary: stop mid-page and the disc
regrows over content after the settle — flagged to E as a decision, not changed.

---

### FEATURE: F-DiscPill — the capture disc gets out of the way while you scroll  [x] COMPLETED

**Queued 2026-08-30 via the post-nudges session opener; E's report, made twice:** the capture disc
sits over real content throughout the app — over a nudge row's time, over a capture's subtitle,
over the "Week review" card. E's words: *"the FAB sits over multiple places throughout the app at
different stages."* Evidence in-repo: `screenshots/nudges-door-device/*` and
`screenshots/first-nudge-reachable/*`.

**E's design call, already made — do not re-ask:** *shrink the disc to a small pill while
scrolling.* (Offered and NOT chosen: hide-on-scroll, move into the tab bar, fixed disc + more
clearance.)

**What this is NOT:** F-DiscClearance (`b62aea4`) already fixed the END of every scroll with the
84pt `safeAreaInset`. This block is about the disc parking over content MID-scroll.

**Design (Claude Code's execution of E's call):**

- While a drag is in progress anywhere in the signed-in UI, the 60pt disc shrinks to a small
  pill; when the finger lifts, it grows back after a short settle delay so stop-and-go scrolling
  doesn't flap. Scroll detection is a window-level `UIPanGestureRecognizer` — the exact
  `KeyboardTapAway` shape: `cancelsTouchesInView = false`, always-simultaneous, zero per-screen
  wiring, covers every screen added later.
- The morph is visual-only: the button's OUTER frame stays 60×60, so the ≥44pt hit target (§3),
  the timer-bar stack layout, and every UI-test frame assertion are untouched. `Circle` becomes
  `Capsule` for free — a 60×60 capsule IS a circle — so one shape animates both states.
- Geometry lives in `CaptureDiscMetrics` beside `clearance`, which does NOT change: the rest
  state is still a 60pt disc, so the 84pt clearance the eleven call sites depend on holds.
- The fan overrides the pill: `isFabOpen` forces the full disc (the scrim blocks scrolling
  anyway, and the ✕ rotation needs the disc).
- Springs per §5; `reduceMotion` collapses the morph to a snap.

**Acceptance criteria:**

- [x] `CaptureDiscScrollActivity` (ObservableObject): `dragBegan()` shrinks immediately,
      `dragEnded()` restores after a settle delay (0.7s), a new drag inside the window cancels
      the restore. Deterministic tests via an injected delay — 8 tests.
- [x] `CaptureDiscPanObserver`: window-level pan → activity model, state mapping unit-tested via
      a `react(to:)` seam (`.began` → began; `.ended/.cancelled/.failed` → ended; nothing else)
      — 5 tests.
- [x] Call-site guards in the `CaptureDiscClearanceCallSiteTests` mould — 5 tests. Red-checked
      before wiring: all three RootView guards failed at their own assertions on the unwired
      tree (18-test run: 15 pass / 3 fail), then 18/18 after wiring. Not vacuous.
- [x] SwiftLint 0 violations, unit suite 1,885 / 0, build green (2026-08-30).
- [x] SIMULATOR verification, stronger than the block dared ask for: a fresh emulator account
      driven through the real signup (`SIMCTL_CHILD_LIFEOS_FIREBASE_EMULATOR_HOST` + idb), then
      a 2s background drag with a screenshot MID-GESTURE. `screenshots/disc-pill/`: full disc at
      rest → pill mid-drag with the Relationships row readable past it → full disc again 1.5s
      after the lift. The discriminator is real: absent the fix, the mid-drag still shows the
      60pt disc, as the other two stills do.
- [ ] OUTSTANDING — E has not seen it on device. The morph's FEEL (spring, settle beat) is a
      device judgement; the simulator proves the mechanism only. Side-finding for the register:
      the fresh-account signup on the emulator DID seed — six life areas, 5-item today, nudges
      section present — which answers half of the opener's "did seeding land?" for the code
      path; E's device run still answers it for production.

---

### FEATURE: F-SignUpPolish — two things E marked on the signup screen  [x] COMPLETED

**From E's fresh-account signup on device, 2026-08-30** — the first time anyone has walked the
new-user path end to end.

**1. The Done bar floating above the keyboard: "it's clogging the screen up."**

This is BUG-b5 from E's own 2026-08-26 checklist ("the keyboard must never be a trap"), so it was
NOT deleted. `.keyboardDismissal()` was applied to the `Group` wrapping BOTH auth branches, so the
login screen inherited a bar meant for the tabs. It now sits on the tabs only.

**That does not reopen b5.** `KeyboardTapAway` is installed window-level and already covers login —
its own note says tapping away is *"the gesture people actually reach for"*. The bar was redundant
there, not load-bearing. Verified by reading the install site, not assumed.

**2. The password field's uneven top/bottom spacing** (E marked the gaps on the screenshot).

The reveal button was an `HStack` sibling at `.frame(width: 44, height: 44)`. §3 requires that
44×44 target — and in a row, its HEIGHT drove the whole card: **Password ≈ 76pt against Email and
Name at ≈ 53pt**, since `fieldCard` adds 16pt padding all round to a ~21pt text row. The button is
now an `.overlay`, which keeps the full target and contributes nothing to layout height. All three
cards match.

**Acceptance criteria**
- [x] Login no longer shows the keyboard Done bar; the tabs and modal composers still do.
- [x] Password, Email and Name cards are the same height, verified in a render.
- [x] The reveal button keeps its 44×44 target (§3) — an overlay, not a shrunken frame.

**Verified 2026-08-30:**
```
swiftlint lint          → Found 0 violations, 0 serious in 558 files
xcodebuild test (unit)  → Executed 1867 tests, with 0 failures (0 unexpected)
render (signup form)    → dark EXIT=0, light EXIT=0 — the three cards visibly match
```

**The Done bar removal is NOT visually verified, and that is stated rather than glossed.** The
render harness could not show it: the simulator runs with a hardware keyboard attached, so no
software keyboard appears and a `ToolbarItemGroup(placement: .keyboard)` has nothing to attach to.
`defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false` plus a sim restart
did not take for the headless test runner.

**No assertion was added for it either**, deliberately: with no software keyboard there is no
toolbar, so `XCTAssertFalse(app.buttons["Done"].exists)` would pass whether or not the fix existed
— a vacuous guard, worse than none. See [[geometry-journey-vacuity]]. E reported it from the
device and confirms it there.

**A near-miss worth recording.** The first signup render was named `5-signup-keyboard-up`, its
`app.keyboards.element` assertion passed, and the image contained no keyboard — `app.keyboards`
was satisfied by the hardware keyboard's accessory state. Had it shipped as evidence it would have
proved nothing. Third time this session a picture nearly passed for proof of something it could not
show: **an assertion going green is not the same as the screen showing the thing.**

---

### FEATURE: F-FirstNudgeReachable — a new account can actually make its first nudge  [x] COMPLETED

**A brand-new user could not create a nudge by any action available to them.** Three true things
that only add up to a dead end when you put them together:

1. `loadedNudgesSection` was gated on `!due.isEmpty || scheduled > 0` — no nudges, no section.
2. First-run seeding creates six life areas, five tags, three tasks and a journal entry, and
   **never a nudge**.
3. The **only** route to the Nudges screen is the door inside that section.

So the feature was unreachable until a nudge already existed, and nothing the user could do would
produce one.

**Found by accident, and the accident is the interesting part.** `RenderHarnessUITests` failed on a
fresh account with "Today never rendered the nudges door" while being pointed at something else
entirely. The message was true; the assumption that a signed-in account can see the door was not.

**This is [[dead-shared-component-pattern]] for the SIXTH time, and the most clear-cut yet.** The
empty-state copy for this exact card already existed AND was already unit-tested:

```
doorSubtitle(0, 0) → "Recurring reminders you set for yourself."   HomeNudgesDoorTests:61
chipText(0, 0)     → "None yet"                                     HomeNudgesDoorTests:79
countLine(0, 0)    → "No nudges yet"                                HomeNudgesSectionTests:86
```

Its own doc comment says *"The empty case describes what nudges ARE, because someone with none has
no idea."* Someone designed this screen, wrote down why it mattered, and unit-tested every string —
and the gate meant no user could ever see a word of it.

**The gate was DELIBERATE, and is preserved rather than reversed.** Its doc comment read *"Silent
when there is nothing due AND nothing scheduled: an empty schedule is not news, and Today does not
need a card to say so."* That reasoning is right about a STATUS card and only wrong about a
feature's sole entrance. E's call was the third option offered: **show it empty only until the
first nudge exists.** So `shouldRenderSection(hasAny:hasEverHadAny:)` has three states, not two,
and silence returns the moment the user has ever had a nudge.

**E's design call on the empty face, 2026-08-30:** *"show the nudges door with something such as a
grayed out effect over the nudges section with a clear direction to 'Add your first nudge'."*
Muted context, one lit action.

**Acceptance criteria**
- [x] `HomeNudgesSection.shouldRenderSection(hasAny:hasEverHadAny:)` — pure, three tests written
      first, covering all three states including the preserved silence.
- [x] `NudgeFirstRunMarker`, keyed **per account** by uid. Latched by `.task` (arriving with
      content) AND `.onChange` (the list arriving later, or the user creating their first) —
      never written during body evaluation.

**A defect I shipped inside this block, and the correction.** The flag was first written as a
plain `@AppStorage("nudges.hasEverHadAny")` — which is UserDefaults, and therefore **per DEVICE**.
A second account signed into one phone would inherit the first account's answer, so a genuinely
new user would never see their first-run door: **the exact dead end this block exists to remove,
reintroduced one layer up.**

Worse, it shipped with a comment asserting the failure was harmless — *"the worst case is the
empty door appears once more than it needed to, which is the harmless direction"*. That is
backwards. This flag can only ever SUPPRESS the door, never add a spare one, so **every error it
makes is in the harmful direction.** The reasoning was done once, written down confidently, and
not checked.

No test caught it. It surfaced because E asked to SEE the first-run door on the device, which
forced the question of what would actually happen — and the answer was "nothing, because your
phone's flag is already set". `NudgeFirstRunMarker` is keyed by uid, and
`testTwoAccountsOnOneDevice_doNotShareAnAnswer` is the guard that exists so this cannot come back.
- [x] The first-run face: ⏰ desaturated with **`.grayscale`, not `.opacity`** — an emoji cannot be
      de-emphasised with `foregroundStyle`, and a translucent glyph reads as broken rather than
      quiet. §4 bans opacity as a substitute for semantic colour; desaturating a picture is a
      different operation.
- [x] "Add your first nudge" is a **real 44pt Button**, not styled text — it has to be pressable to
      mean what it says.
- [x] `FirstRunJourneyUITests` — seeds NOTHING on purpose. The moment it arranges a nudge it stops
      testing the thing it exists for.

**Red-checked, and it failed at its own assertion rather than incidentally:**
```
RED    FirstRunJourneyUITests.swift:51: XCTAssertTrue failed - A brand-new account cannot see
       the nudges door, so it can never create a first nudge. The section is gated on already
       having one, and nothing else routes there.
       Executed 1 test, with 1 failure (0 unexpected)

GREEN  Executed 1 test, with 0 failures (0 unexpected)   EXIT=0
```

**Verified 2026-08-30:**
```
swiftlint lint          → Found 0 violations, 0 serious in 558 files
xcodebuild test (unit)  → Executed 1867 tests, with 0 failures (0 unexpected)
                          ** TEST SUCCEEDED **   (1859 + 3 predicate + 5 marker, all first)
render harness          → first-run door, dark and light, both EXIT=0
```

---

### FEATURE: F-NudgePresets — the New nudge sheet stops charging five taps for "weekdays"  [x] COMPLETED

**E's verdict, from the device, 2026-08-30: "THIS NEEDS RE-DESIGNING! Its very ugly and awkward to
use."** The still is `screenshots/nudges-door-device/new-nudge-sheet-BEFORE.jpeg`. Six defects, and
the ugly one was a genuine layout failure rather than taste:

1. **Every weekday label wrapped mid-word** — "S/un", "M/on", "Tu/e", "W/ed", "Th/u", "Fr/i",
   "Sa/t". Seven `.bordered` buttons in a bare `HStack` inside a `Form` inset get ~40pt each,
   narrower than the label needs. §1 forbids exactly this ("must never clip or truncate
   unexpectedly").
2. **Sub-44pt hit targets** at ~40pt wide (§3), and a stock `.bordered` where §3 requires an
   explicit primitive press style.
3. **One action wearing three labels** — nav title "New nudge", section header "Add Nudge",
   submit row "Add Nudge".
4. **The submit read as disabled placeholder text**, not a button, and sat at the bottom of the
   form instead of the nav bar where iOS puts a confirming action.
5. **A full-height sheet** holding roughly a third of a screen of content.
6. **The header `+` was 40×40**, under the same 44pt floor.

**The root cause is this repo's most-repeated defect, for the fifth time.** `ChoiceChipButtonStyle`
is the house chip — **13 call sites across 8 files**, and `FocusCadenceEditorCard` already uses it
for preset chips in this exact shape. The New nudge sheet was the ONLY place using stock
`.bordered`. It never adopted the app's own vocabulary, which is why it read as foreign.
See [[dead-shared-component-pattern]].

**E's design call, asked before building** (the F-NudgesDoor precedent): *presets first.*

**Acceptance criteria**
- [x] `NudgeSchedulePreset` — Daily / Weekdays / Weekends / Custom, with the weekday sets, the
      chip titles and the summary line. **Pure logic, tested first, 13 tests.**
- [x] Chips laid out 2×2, not 4-across: "Weekends" and "Custom" do not fit four-across at
      accessibility text sizes, and cramming is what wrapped the labels in the first place.
- [x] The Custom day row uses **single letters** (S M T W T F S, Sun-first like the Clock app's
      alarm repeat) at `maxWidth: .infinity, minHeight: 44`, so a label *cannot* wrap and the
      target meets §3. VoiceOver still reads the full day name via `accessibilityLabel`.
- [x] **Custom is a disclosure, not a reset** — it reveals the day row and KEEPS the current
      selection. Clearing would throw away days the user just chose.
- [x] Editing a nudge that already has a custom pattern **opens with its days showing**, rather
      than hiding them behind a chip the user would have to guess at.
- [x] Save in the nav bar (`.confirmationAction`), one title, `.presentationDetents([.medium, .large])`.
- [x] `ChoiceChipButtonStyle`, `Haptics`, `.bentoCard()`, `.sectionLabel()` reused — no new chip
      style, no new colour, no new haptic vocabulary.
- [x] The header `+` raised 40 → 44pt.
- [x] `NudgesView` hit 481/400, so the standing rule fired: the feature touching an over-budget
      file splits it. `NudgeScheduleEditor` moved to its own file — **338 / 155**.

**The cron off-by-one is the reason this got unit tests rather than eyeballs.** Sunday is `0`, so
"weekdays" is `1...5`; the obvious-looking `0...4` schedules Sunday–Thursday and still reads
correct in review. The red-check planted exactly that:

```
RED    (weekdays returning [0,1,2,3,4])
       testWeekdays_isMondayToFriday_notSundayToThursday   failed
       testMatching_recognisesEachNamedPreset              failed
       testDaySummary_namedPresets_readAsWords             failed
       Executed 13 tests, with 4 failures (0 unexpected)

GREEN  (restored to [1,2,3,4,5])
       Executed 13 tests, with 0 failures (0 unexpected)   ** TEST SUCCEEDED **
```

The empty set is covered too: it resolves to `.custom`, never `.daily`. Promoting it would light a
Daily chip for a schedule `NudgeValidation` rejects and `NudgeSchedule.parse` treats as
never-computably-due.

**E's three calls on the first render, all applied and re-rendered:**
1. **`.large` when the day row opens.** At `.medium` the day row pushed the time picker below the
   fold, and setting a time is half the point of the sheet. It GROWS and never shrinks — snapping
   back on close would yank the sheet out from under the thumb for no gain. The cost is empty
   space below Time when Custom is open, and that is the right way round.
2. **"Nudge name"**, replacing a seven-word question that `sectionLabel()` rendered in caps.
3. **The summary line follows what it describes** — under the chips when the day row is closed,
   under the DAYS when it is open. The wording was never wrong; the position was. Above the days,
   a lit "Custom" chip over the words "Every day" read as a contradiction when it was in fact
   describing the seven days Custom had preserved.

**The harness caught its own bad evidence, which is the reason it is being kept.** The first
Weekdays still was shot immediately after the tap and caught the spring mid-flight: the day row
ghosting as it collapsed, the chip half-filled, its label washed out. The state was right and the
picture was a lie — worse than no picture. It now settles on a real CONDITION, not a sleep:
choosing Weekdays closes the day row, so `tap(_:untilGone:)` on that row IS the animation-finished
signal. `RenderHarnessUITests` is committed deliberately (E's call), not deleted — the
F-PadNightRender rule is satisfied by choosing, not by deleting.

**A separate finding, logged not actioned.** The harness failed on its first run with "Today never
rendered the nudges door", and it was telling the truth: `loadedNudgesSection` is gated on
`!due.isEmpty || scheduled > 0`, so on an account with no nudges the whole section — door
included — does not render. First-run seeding creates life areas, tags, tasks and a journal entry
but **never a nudge**, and the only route to the Nudges screen is through that hidden door. **A
brand-new user therefore has no way to create their first nudge.** Not this block's scope; needs
E's call on the fix (an empty-state door, or a route from Settings).

**Verified 2026-08-30:**
```
swiftlint lint          → Found 0 violations, 0 serious in 555 files
xcodebuild test (unit)  → Executed 1859 tests, with 0 failures (0 unexpected)
                          ** TEST SUCCEEDED **   EXIT=0   (1846 + the 13 written first here)
render harness          → dark EXIT=0, light EXIT=0, settled
```
Six stills in `screenshots/nudge-presets-block/`, both appearances × three states, all at rest.

---

### FEATURE: F-PortraitArrival — the journeys stop inheriting the last test's orientation  [x] COMPLETED

**Found by F-LoginTestIsolation's own verification, and it is the same defect one layer down.**
Fixing the login tests meant running the WHOLE UI target for the first time. It came back
**17 tests, 10 failures** — and all ten were one cause, at one line, with one message:

```
UITestSession.swift:318: "loginPasswordField" SecureTextField never became hittable
```

**`ADHD_LifeOSUITestsLaunchTests` sets `runsForEachTargetApplicationUIConfiguration`,** so XCTest
runs `testLaunch` once per UI configuration. Two of the four are landscape, and the LAST one
leaves the simulator in **Landscape Left**. Orientation, exactly like the keychain, outlives the
app process — so every test scheduled after it launched into landscape, where the login form's
password field never becomes hittable.

```
1203  testLaunch (4th config) started
1206     Interface orientation changed to Landscape Left
1381  testLaunch passed                                    ← and the device stays there
1385  AccountNameJourney            → Landscape Left → FAILED
1991  CaptureDiscClearance/nudges   → Landscape Left → FAILED
2594  CaptureDiscClearance/today    → Landscape Left → FAILED
      … JournalJourney, SignedInJourney ×5, SignedOutLaunch — all of them, all identical
```

**Why nobody had seen it.** The whole UI target had never been run in one go. The run recorded as
"9/9 journeys" totalled twelve tests, which only adds up as **three plus nine** — so it cannot have
included `testLaunch`. Every previous run was scoped, and the scope excluded the one test that
poisons the rest. `JournalJourneyUITests` proves the ordering-dependence directly: it passed alone
in 150s at 04:39 and failed in-suite at 05:31.

**Not introduced by F-LoginTestIsolation.** That block changed `testLaunch`'s BODY; the
configuration sweep comes from `runsForEachTargetApplicationUIConfiguration`, which it did not
touch, and a test body cannot change how many configurations XCTest requests.

**Acceptance criteria**
- [x] `UITestSession.resetToPortrait()`, called from `launchSignedIn` (every journey) and by
      default from `launchSignedOut`.
- [x] **`testLaunch` is the one deliberate exemption** (`resettingOrientation: false`). Forcing
      portrait there would collapse the four-configuration sweep into four identical portrait
      screenshots — fixing the suite by silently deleting the capability that exposed the bug.
      The sweep keeps rotating; `resetToPortrait` absorbs what it leaves.
- [x] `swiftlint lint` → 0 violations, 0 serious in 551 files.
- [x] **Full UI target green** — and it is the first time the whole target has ever been green:

```
BEFORE   Executed 17 tests, with 10 failures (0 unexpected) in 1847.015 seconds
         ** TEST EXECUTE FAILED **      EXIT=65

AFTER    Executed 17 tests, with  0 failures (0 unexpected) in 1893.673 seconds
         ** TEST EXECUTE SUCCEEDED **   EXIT=0
         passed: 17   failed: 0
```

The fix is visible in the trace rather than merely inferred — `testLaunch`'s last configuration
still ends in Landscape Left, and the very next line of the following test is
`Interface orientation changed to Portrait`. The sweep keeps rotating; the next arrival rights
itself. Each previously-failing test is individually accounted for: AccountName 140.5s,
CaptureDisc 109.7s / 97.9s, Journal 113.4s, SignedInJourney 5/5, SignedOutLaunch 1/1.

**Open question for E, NOT actioned.** The app declares landscape support on iPhone
(`INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone`, the Xcode template default). If the
login screen genuinely cannot reach its password field in landscape, that is a real usability
defect on a supported orientation — but "not hittable inside 45s" is evidence, not proof, and
nothing here changes app behaviour. A landscape still of the login screen would settle it.

---

### FEATURE: F-LoginTestIsolation — the login tests stop inheriting the last run's session  [x] COMPLETED

**Two failures on every full UI-target run, and the harness caused both.**
`testLoginForm_rendersFieldsAndValidatesInput` and
`testSignIn_invalidCredentials_showsInlineErrorAndStaysOnLoginForm` only called `app.launch()`.
Firebase Auth persists its session in the simulator keychain; the keychain outlives the app
process **and the whole test run**; so the app restored into the tab bar and `loginEmailField`
never appeared.

**Why those two tests could not be their own guard — this is the part that was not yet written
down.** XCTest orders classes by name and `ADHD_LifeOSUITests` sorts ahead of every journey, so
within a single run they execute BEFORE anything signs in, and pass. The session that breaks them
is left by the PREVIOUS run. That is why `xcrun simctl keychain booted reset` made them pass, and
why it was never a fix: a person has to remember it, every time, forever.

**And that is the real cost.** Two failures that must be manually discounted on every run is
exactly how a genuine failure eventually gets waved through.

**Acceptance criteria**
- [x] `UITestSession.launchSignedOut()` — one entry point, reusing the harness's own
      `signOutIfSignedIn` rather than a second copy of the sign-out walk.
- [x] The emulator host is set **only when the emulator answers**. A keychain session can only
      have come from a journey, and journeys only run against the emulator — so this signs out of
      the same backend that signed in. With no emulator there is nothing to point at, and
      `ADHD_LifeOSUITests`' own header promise (fresh clone, zero local setup) still holds.
- [x] Applied to every member of the class, not just the two that were reported:
      `testLaunchPerformance` (it was timing whichever state got restored) and
      `ADHD_LifeOSUITestsLaunchTests.testLaunch` (it was photographing one).
- [x] `UITestEmulator.isRunning` exposed — a test can now ADAPT to the emulator, not only skip.
- [x] `SignedOutLaunchUITests`, the guard neither existing test can be: it signs in, then asserts
      a relaunch still reaches the login form.
- [x] Red-checked before the fix, and deliberately regressed after it.

**The deliberate regression, run 2026-08-30 after the block was committed and pushed.** The guard
had only ever gone red for the ORIENTATION reason (F-PortraitArrival), never for the reason it
exists — and [[geometry-journey-vacuity]] is this repo's standing proof that a test can pass
against a build with its fix removed. So `signOutIfSignedIn(app)` was removed from
`launchSignedOut`, the tree REBUILT, and the guard run against it:

```
BROKEN    SignedOutLaunchUITests.swift:40: error: XCTAssertTrue failed - A relaunch after
          signing in restored the session instead of reaching the login form.
          Executed 1 test, with 1 failure (0 unexpected) in 143.062s   EXIT=65

RESTORED  git checkout -- ; REBUILT (exit 0); signOutIfSignedIn(app) back at lines 61 and 95
          Executed 1 test, with 0 failures (0 unexpected) in 166.768s  EXIT=0
          ** TEST EXECUTE SUCCEEDED **       working tree clean
```

Two things make that a real check rather than a ritual. It failed at **line 40 — its own
assertion, in its own words** — not incidentally at an earlier step, which is how a vacuous test
fakes a red. And `resetToPortrait` was left in place throughout, so orientation is excluded and
the missing sign-out was the only variable. Restoration was proven by REBUILDING, not assumed.

**A second change, deliberate and worth flagging.** `ADHD_LifeOSUITests` carried its own
`focusAndType`, a drifted copy of `UITestSession.focusAndType`. The shared one is strictly better
— it retries on FOCUS rather than on the keyboard existing, which is the distinction that made the
password field type into nowhere — and the local copy had none of that. Deleted in favour of the
shared one. This is [[dead-shared-component-pattern]] again: a helper exists, is documented, and a
caller hand-rolls a worse copy beside it.

**Verified 2026-08-30:**
```
RED   (unmodified main, a journey's session in the keychain)
      ADHD_LifeOSUITests.swift:50: error: testLoginForm_rendersFieldsAndValidatesInput
      ADHD_LifeOSUITests.swift:80: error: testSignIn_invalidCredentials_showsInlineError…
      Executed 2 tests, with 2 failures (0 unexpected) in 83.652 seconds
      ** TEST EXECUTE FAILED **   EXIT=65

GREEN (same keychain session, with the fix)
      testLoginForm_rendersFieldsAndValidatesInput                passed (89.245 seconds)
      testSignIn_invalidCredentials_showsInlineErrorAndStays…     passed (69.546 seconds)
      Executed 2 tests, with 0 failures (0 unexpected) in 158.792 seconds
      ** TEST EXECUTE SUCCEEDED **   EXIT=0

swiftlint lint  →  Found 0 violations, 0 serious in 551 files   (550 + the new test file;
                   the zero baseline set by F-DiscClearance holds)
```

**The exit-code trap fired again, and the standing rule caught it.** The green-check run's shell
reported success while the real `xcodebuild` exit was 65, because `echo "EXIT=$?" | tee` returns
tee's status, not xcodebuild's. `EXIT=` was captured separately, which is the only reason the RED
above is a measurement rather than an assumption. See [[build-machine-limits]].

---

### FEATURE: F-TriageCardTruth — the decision card says what it is, and the tabs say how many  [x] COMPLETED

**Two defects, both visible in one screenshot of the Capture Inbox, both about a number or a word
that disagrees with the truth beside it.**

**Bug 1 — the top triage card renders a blank title for a photo capture.**
`CaptureInboxSections.swift:30` is `Text(capture.title ?? capture.content)`. `title` is `String?`
and `content` is a non-optional `String`, so a photo capture with no title and empty content
renders `Text("")` — E's screenshot shows the "Photo / 47 hours old" chips above an empty card.
The shared helper `CaptureRowPresentation.primaryText(for:)` already has the correct four-step
fallback chain ending in `"Photo capture"`, and is already unit-tested for exactly this input
(`CaptureRowPresentationTests:72`). The `Then` rows and Today's list use it and render correctly.
The decision card simply hand-rolls its own chain instead.

This is the SECOND time the card being a separate view from `CaptureRowView` has cost something —
the comment at `CaptureInboxSections.swift:34` records the first (the place label, E, 2026-08-27).

**Bug 2 — every count in the filter picker goes stale after any triage exit.**
The screenshot reads **"To triage (18)"** beside **"17 left"** with a **17** tab badge, and
**"Sorted (8)"** on a screen where a capture had just been journalled. The headline counts
`state`; the picker reads `service.counts[option]` (`CaptureInboxView.swift:204`). `removeCapture`
(`CaptureInboxService.swift:324`) rewrites `state` and never touches `counts`, and the only other
writers are `load()`, `refresh()`, `refreshInactiveCount()` and `refreshToTriageCount()` — the last
of which early-returns on this screen, because it is guarded on the screen NOT offering the
to-triage slice. So all four exits (`sort`, `logToJournal`, `discard`, `undoSeen`) leave it stale.

**Acceptance criteria**
- [x] The top decision card resolves its title through `CaptureRowPresentation.primaryText(for:)`;
      a photo capture with no title and empty content reads "Photo capture", not a blank line.
- [x] After any triage exit, `counts[activeFilter]` matches the list on screen — the picker can
      never contradict the headline.
- [x] After an exit, the DESTINATION tab's count is re-learned too (journalling raises Promoted,
      sorting raises Sorted), by the existing failure-tolerant `refreshInactiveCount` contract:
      a failed count fetch leaves that number alone and never surfaces an error.
- [~] `CaptureInboxService.swift` ends BELOW its 400-line ceiling, not at 398 — it is at the
      ceiling now, so this block splits before it grows.
      **PARTIAL, and stated rather than glossed: it ends at 397.** `refreshInactiveCount` moved out
      to `+Counterweight`, which paid for `removeCapture` growing, but the net is ONE line. That is
      not headroom. `removeCapture` and `replaceCapture` cannot follow it — `state` has a
      `private(set)` setter, so its writers are pinned to this file — so a real split has to move
      something larger (`promoteToTask` is the candidate). The brief's warning stands unchanged.
- [x] Unit tests first, covering each exit's effect on the active count and the destination count.
- [x] The Captures UI journey seeds a photo capture as the decision card and asserts it renders a
      title — the unit suite cannot see a SwiftUI body, and this defect only ever existed there.

**Two things found while fixing it, both folded in:**
- `promoteToTask` was a FIFTH exit site — it open-coded `state = .loaded(captures.filter { ... })`
  rather than calling `removeCapture`, so "Task it", the most-used verb of the five, carried the
  same staleness. It goes through the same door now.
- Undo needed the identical treatment in reverse: it moves a capture OFF another slice, and
  `refresh()` only ever corrected the tab being stood on.

**Deliberately NOT done, reasoning in the code:** `weekCounterweightLine` ("27 captured · 10 cleared
this week") goes stale on the same screen for the same reason. Refreshing it costs a third read per
tap (`fetchCaptures` pulls everything) on a screen built for rapid one-at-a-time triage, and unlike
the tab labels nothing sits directly above it contradicting it. `refreshCountsAfterExit` is the
function it belongs in if that ever changes.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 543 files
                                (TaskDetailView 438 file_length + UITests static_over_final_class)
xcodebuild build-for-testing  → ** TEST BUILD SUCCEEDED **
xcodebuild test (unit)        → Executed 1806 tests, with 0 failures (0 unexpected)
xcodebuild test (5 journeys)  → Executed 5 tests, with 0 failures (0 unexpected) in 526.633s
coverage                      → CaptureInboxService 91.24%, +Triage 96.08%, +Counterweight 73.68%
```

**Journey flakiness, recorded because it cost time and will recur.** The first five-journey run on
this tree failed THREE of them — `testDueNudge`, `testSettings`, `testTaskDetail` — all with
messages pointing at `signOutIfSignedIn` ("Settings never presented", "Settings did not open, so
sign-out could never be reached"). Every one passed when re-run alone, and all five then passed
together on the rebuilt tree in 526s. So it is the documented harness fragility, not this block, and
not the app. The remaining weak point is visible: `UITestSession.swift:94` taps `settingsButton`
ONCE with no retry, so a swallowed tap surfaces two lines later as a true statement about the wrong
step. That helper has already been hardened twice; a third pass wants a retry loop around the tap.

---

### FEATURE: F-ArrangeFold — Arrange hides inside the fold with the list it reorders  [x] COMPLETED

**E's screenshot note, 2026-08-28:** with the life-areas list collapsed, the Arrange button stays
sitting there on its own. It should fold away with the list.

It is a control over the ROWS, so with the section folded its entire effect happens off-screen —
and it is worse than merely useless, because entering Arrange mode force-expands the section, so
tapping it while folded silently undoes the fold the user just chose.

The existing `activeAreas.count >= 2` test stayed and gained a second condition, both now stated
once in `HomeLifeAreasSection.showsArrangeControl(areaCount:isExpanded:)` rather than inline at the
call site. That same force-expansion is what makes hiding it safe: `isExpanded` is true throughout
Arrange mode, so the button — reading "Done" by then — stays on screen as the way back out. There
is no state where this strands someone inside the mode, and a test says so.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 543 files
xcodebuild test (unit)        → Executed 1810 tests, with 0 failures (0 unexpected)
xcodebuild build-for-testing  → ** TEST BUILD SUCCEEDED **
```
No journey run: nothing in `ADHD LifeOSUITests` references the Arrange control or the life-areas
list, and `home.lifeAreasCollapsed` defaults to false, so Today looks to them exactly as before.

---

### FEATURE: F-NudgesDoor — the nudges section stops reading as a footer  [x] COMPLETED

**E's screenshot note, 2026-08-28:** the circled nudges area "needs a little bit of work — make it
stand out more and more prominent to the user's eye."

What it was: a grey caps eyebrow ("NOTHING DUE · 4 SCHEDULED") over a grey chevron row, sitting
between a bold ring/streak block and a loud blue "Clear the deck" CTA. It read as the end of the
screen rather than a part of it.

**E's three calls, asked before building:**
1. **Shape** — match the Capture inbox card's anatomy (icon tile, title, subtitle, count chip) and
   list the next few nudges underneath. Chosen over a one-line "next up" and over a louder version
   of the same single row.
2. **Due state** — raise it too. If the quiet state becomes a card, a due nudge sharing that
   surface would read as equally optional, which on this screen is the wrong signal.
3. **Position** — leave it where it is. Folding the life areas already pulls it up the screen.

**What shipped**
- `nudgesDoorCard` mirrors `inboxPeekCard` exactly — same 44pt tinted tile, title, subtitle, chip.
- Rows read "Today 18:00" / "Tomorrow 05:00" / "Mon 09:30", soonest first, capped at
  `maxCards` with "and N more scheduled". Beyond tomorrow the weekday is NAMED — "in 4 days" makes
  the reader do the arithmetic they asked to avoid.
- Due nudges now come FIRST and carry a new `urgentBentoCard` (warn tint + matching border), so
  urgent still visibly outranks quiet.

**Two implementation notes worth keeping**
- **The next-fire maths is dueness's own, not a second copy.** `NudgeDueness.nextFireTime` existed
  but was private; it gained a `nextFire(for:after:)` wrapper rather than a duplicate weekday-walk
  in `HomeNudgesSection`. The two questions genuinely differ and the seam says so: a nudge that
  fired last Tuesday has a next fire in the PAST, which is exactly what makes it due, and is not
  what a user reading "next up" is asking. Display passes `now`; dueness passes the nudge's own
  reference date.
- **The urgent tint is an alpha over the card surface, not a new colorset.** `StateWarn` is already
  the app's single "wants attention" hue (inbox chip, inbox headline, the old nudges eyebrow), and
  a second baked token would be one more thing to keep in agreement with it.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 544 files
xcodebuild build-for-testing  → ** TEST BUILD SUCCEEDED **
xcodebuild test (unit)        → Executed 1827 tests, with 0 failures (0 unexpected)
xcodebuild test (5 journeys)  → Executed 5 tests, with 0 failures (0 unexpected) in 524.424s
```
`testDueNudge_appearsOnHomeAndCanBeDismissed` is the one that matters: it proves the due card still
reaches Today and its dismiss button is still addressable after the cards moved to the top of the
section and changed surface. The journey run was clean first time — no repeat of the
`signOutIfSignedIn` flakiness recorded under F-TriageCardTruth.

**[x] APPROVED BY E ON DEVICE, 2026-08-30.** All four states shot on `wishwashwacky15` at
`b1f4b6f` and archived in `screenshots/nudges-door-device/`:

```
dark-5-due.jpeg          chip "5 due" amber · warn-tinted cards above · "and 2 more due"
light-4-due.jpeg         chip "4 due" amber · same anatomy in the light appearance
dark-nothing-due.jpeg    chip "8 scheduled" neutral · "Nothing due — all on time."
light-nothing-due.jpeg   ditto, light
```

E's verdict: **"Approved — tick it."** The door reads as a card in both appearances, the quiet
state is settled rather than deficient, and the due state visibly outranks it. This was the last
unticked acceptance criterion in the whole file.

**Two things the stills exposed that are NOT this block's**, both now their own entries:
- The three stacked full-width green "Done for now" buttons dominate the due state. E flagged it as
  a secondary concern while approving the door — noted, not actioned here.
- The capture disc obscures real content in **all four** shots. See F-DiscPill.

---

### FEATURE: F-DropAltButton — the composer's second button goes  [x] COMPLETED

**E's call, 2026-08-28, from two device screenshots** ("Retake the photo", "Send to inbox
instead"): "on proper reflection, these buttons need to be removed from all capture types."

One control, five labels — `CaptureComposerCopy.altLabel(for:)` driving a single bordered button
under the CTA in `QuickCaptureView`'s footer:

| Kind  | Label                      | What it did                    | Still reachable without it?          |
|-------|----------------------------|--------------------------------|--------------------------------------|
| note  | Make it a task instead     | switch kind to task            | **No** — see below                   |
| task  | Send to inbox instead      | switch kind to note            | **No** — see below                   |
| voice | Discard and start again    | clear recording, start again   | **Yes** — the record button already reads "Re-record" and `toggleRecording()` nils the URL and restarts. An exact duplicate. |
| photo | Retake the photo           | clear image, open camera       | **Yes** — "Take Photo" and "Choose Photo" are both already on screen |
| link  | Clear the link             | empty the text field           | **Yes** — the field is editable and has a paste button |

So three of the five were pure duplicates of a control sitting inches away, which is very likely
why they read as noise on device.

**The one real loss, stated rather than buried: note ↔ task kind-switching mid-composition is
gone,** and nothing replaces it. Changing your mind now means cancelling and reopening from the
capture fan. That is defensible — the fan is where a kind is chosen, and this button was an odd
hybrid that let the composer contradict the door you came through — and it is the same instinct as
the round-2 audit's "too many places it lives". But it IS a capability that existed this morning
and does not now. If E misses it, the honest replacement is a kind control at the TOP of the
composer next to the title, not a second button in the footer.

Removed all four pieces rather than orphaning any: the button, `altLabel(for:)`, `performAlt()`,
and the two assertions in `CaptureFanTests`. `isShowingCamera` and `CameraCapturePicker` survive —
"Take Photo" still uses them, checked rather than assumed.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 546 files
xcodebuild test (unit)        → Executed 1827 tests, with 0 failures (0 unexpected)
xcodebuild build-for-testing  → exit 0, all targets
```
No journey run: nothing in `ADHD LifeOSUITests` opens the quick-capture composer (the
`composerAreaChip` hits are the capture TRIAGE card, a different screen).

---

### FEATURE: F-PadBalance — the pad stops fighting its own wardrobe  [x] COMPLETED

**E's reframing, 2026-08-28, and it is the thing that finally settled this:** "it would be much
easier to perform a light redesign of the rest of the Journal Card in order to create a balanced
colour scheme … in order to facilitate my request of yellow."

That was correct, and the arithmetic proves why. Asked only to "make the night face more gold", the
ceiling was hard and close: with the parchment ink fixed, `#7A6000` (which E had ALREADY rejected as
mustard) measured 4.67:1, and anything goldier failed AA outright. **The ceiling was a consequence
of the wardrobe, not of the yellow.** A warm page was wearing cool clothes:

| Element | Was | Hue vs goldenrod (43°) |
|---|---|---|
| Selected chips | `AccentColor` `#0A7CFF` | **210° — near-exact complement** |
| Quiet chips | `CardSurfaceSecondary` | ~225°, cool grey |
| Writing box | `CardSurface` (`#1D2027` at night) | ~218°, cool |

**What shipped**
- **`JournalPaperChrome`** — the desk. In LIGHT it is the pad's own gold, so the day face reads
  full-bleed exactly as approved; at night it goes dark and the same structure becomes a lit pad on
  a dark desk. One layout, two appearances, decided entirely in tokens — **there is no
  `colorScheme` branch in the palette and there must not be one.**
- That structural move is what buys the gold: the night pad is a real `#C99A1E` with dark ink,
  reusing the day face's already-proven pairing instead of hunting the mid-tone valley where no ink
  passes.
- **`JournalPaperSurface`** — a warm sheet for the writing box and quiet chips. `CardSurface` was
  only ever half a fix: white by day, but a COOL near-black at night, i.e. the same mistake in the
  other appearance.
- **Monochrome selection** (E's pick): a chosen chip fills with the pad's own ink and labels itself
  in the page gold. No new hue. Per-area tints are suppressed on the pad — eight more hues is the
  last thing a surface with a hue problem needs.
- Four follow-ups from the first render: the Save button (the last cool object), the footer (moved
  to the chrome so the inset pad's bottom corners survive), the placeholder, and "optional".

**Two findings worth more than this block**
1. **There is no dimmed ink on the gold page, and that is arithmetic.** Primary ink clears AA at
   only ~5.2:1, so anything dimmed lands under 4.5 (`#6B4E12` on `#DAA520` = 3.45:1). Hierarchy
   comes from weight and size (§1), never a lighter ink or an opacity (§4). Encoded as
   `softInkAsset(for:)` returning the SAME ink, with the measurement in its doc comment.
2. **The sheet is the one exception**, because the ink clears ~9.5:1 there — which is why the
   placeholder can be `#6B5220` (5.98:1 day / 5.61:1 night) and still pass.

**Blast radius, and how it was contained.** Four shared components across ~20 call sites
(`ChoiceChipButtonStyle` ×7, `PrimaryActionButtonStyle` ×10, `ComposerAreaChips` ×3,
`ComposerSectionHeader` ×3). Every override is OPTIONAL and defaults to nil, so only the pad opts
in — verified by the journeys, not merely argued.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 546 files
xcodebuild test (unit)        → Executed 1831 tests, with 0 failures (0 unexpected)
xcodebuild build-for-testing  → exit 0, all targets
xcodebuild test (5 journeys)  → 4 passed; testCreateTask failed in signOutIfSignedIn setup
                                (UITestSession.swift:102) and PASSED alone in 114.061s —
                                the documented harness flakiness, third occurrence today
```
`testCreateTask` is the journey that walks `TaskCreateView`, which uses BOTH changed chip
components — so its passing is the specific evidence that the nil-default containment holds.

**Superseded:** `F-PadWarmNeutral` below is subsumed by this — the cool `#E9ECF3` chips it existed
to fix are gone from both faces.

---

### FEATURE: F-PadNightRender — put the journal pad's night face in front of E  [x] COMPLETED

**CLOSED 2026-08-28.** The harness was rebuilt from `22dba79`, both faces were rendered in both
appearances with `simctl ui … appearance` driving it explicitly, and E ruled: "make the night face
more gold", then — after seeing the contrast ceiling — "perform a light redesign of the rest of the
Journal Card". That produced `200d0ea` (F-PadBalance) above. The cameras were deleted again at E's
instruction once the judging was done; their four hard-won traps are recorded in
[[journal-pad-design]] rather than in the repo.

**Not a code block — a verification block, and the reason the other three can be judged.** E's
five screenshots were all light appearance, so the gold pad's night face (`9848ee8`) remains the
one thing from 2026-08-28 that no human has seen. It also has the worst track record of anything
in the app: three colour attempts were rejected on device before the render loop was built.

Rebuild the throwaway harness rather than re-deriving it —
`git show 22dba79:"ADHD LifeOSUITests/ComposerLookCaptureUITests.swift"` is the exact file, deleted
in `891ea8f`. Drive the appearance explicitly with `xcrun simctl ui <udid> appearance dark`; do not
trust whichever way the simulator happens to be pointing, because that is precisely what let a
"forced light" pad ship with no night face at all. Let the spring settle before the shutter — a
capture fired mid-animation once showed Log's content on the gold footer and read as an app defect.

**Acceptance criteria**
- [ ] Day and night stills of the journal composer, extracted and handed to E.
- [ ] The harness is deleted again before commit, or committed deliberately — not left behind.
- [ ] E's verdict recorded here before anything else touches the pad's colours.

---

### FEATURE: F-PadOneInk — the pad's one ink stops being half an ink  [x] COMPLETED

**Found by measuring E's device shots of `200d0ea` (2026-08-28, four screenshots: both kinds ×
both appearances), not by reading the code.** The pad's TOKENS were all correct and all clear AA.
What shipped wrong is that most of the page never used them.

**The tokens, verified against the asset catalog and E's actual pixels — these are fine:**

| pair | light | dark |
|---|---|---|
| page (`#DAA520` / `#C99A1E`) + ink (`#4A3506` / `#3D2B05`) | 5.20:1 | 5.25:1 |
| writing sheet (`#F5E7C0` / `#EFE0B4`) + ink | 9.47:1 | 10.34:1 |
| placeholder `#6B5220` on sheet | 5.98:1 | 5.61:1 |
| selected chip label on selected fill | 5.20:1 | 5.25:1 |

The night face is genuinely gold (`#C99A1E`, L=0.356), not the brown 20%-lightness version. The
inset card with near-black gutters at night is intentional and documented. `200d0ea` held.

**Bug 1 — every quiet label on the pad is the ink at HALF alpha, and fails AA.**
`LogComposerView` sets `.foregroundStyle(Color(inkAsset))` once on the container, and its comment
claims `.secondary` inside therefore "turns warm ink instead of system grey". Half true, and the
half that is wrong is the whole defect: under a container whose foreground style is a plain
`Color`, `.secondary` inherits that colour **at roughly half alpha**. It is warm — which is why it
looks fine and why five renders missed it — and it is dimmed.

Measured off E's device, and the blend arithmetic proves the mechanism rather than suggesting it:

- ink `#4A3506` at 50% over `#DAA520` predicts `#926D13`; measured **`#916D12` = 2.13:1**
- ink `#3D2B05` at 50% over `#C99A1E` predicts `#836212`; measured **`#836212` exactly = 2.18:1**

Against a 4.5 bar, on a page where the same ink at full strength clears 5.20:1 / 5.25:1. Affects
"WHAT KIND OF ENTRY?", "ENERGY", "MOOD", "LIFE AREA", "TAGS", the lead caption and the kind
explainer. The tell was visible in one screenshot: "optional" — same component, same line, one
`detailAsset` away — renders the full 5.20:1 while the title beside it renders 2.13:1.

**`JournalComposerPalette.softInkAsset` — the helper written for exactly this, carrying the 5.2:1
reasoning in its doc comment — was DEAD CODE.** No view called it. Worse, its unit test
(`testJournalHasNoSecondaryInk`) passed the entire time, because it asserts the helper returns the
right answer and nothing asserts anyone asks it. A green test guarding an unused function.

It was also unusable in its old shape: it returned `"LabelSecondary"` for a log, and an opaque
`LabelSecondary` is not what `.foregroundStyle(.secondary)` paints — wiring it up would have
restyled the ordinary composer as a side effect. It now returns `String?`, `nil` meaning "keep
exactly what you already do".

**Bug 2 — the energy sublabels dim by alpha, same class of error.** `.opacity(0.7)` on
`level.detail` renders ink at 70% on the parchment chip: predicted `#7D6A3E`, measured **`#7D6A3D`
= 4.27:1**, under the bar by day. Full ink clears 9.47:1 there. The chip's fill already carries
selection, so the dimming bought no signal.

**Bug 3 — the footer caption is a cool grey on gold, and it is LIGHT-ONLY.** `footerBar` hangs off
`.safeAreaInset`, outside the ink container, so it inherits nothing: system `#3C3C43` at 60% over
gold = **2.47:1**. At night it lands on the near-black chrome and measures 6.12:1 — so a dark-only
or a render-only check passes it. It was also the last cool grey left on this screen.

**The trap inside the fix, caught by measuring before shipping rather than after.** The obvious
repair — hand the footer the page ink — is wrong, because the footer sits on the CHROME, not the
page, and the chrome tracks the appearance while the page does not. Page ink `#3D2B05` on the night
chrome `#1A1610` measures **1.33:1**: an invisible line, in the dark half only. Hence a separate
`JournalPaperChromeInk` token (light `#4A3506` = 5.20:1 on gold, dark `#EFE0B4` = 13.71:1 on
near-black). The ink follows the surface.

**Bug 4 — `JournalComposerPalette`'s own doc comments record a night face that does not ship.**
They describe a `#2A2109` page with parchment `#F2E2B8` ink, and a writing box "white by day and
near-black by night". Neither value exists in any colorset; the writing box is warm parchment in
both appearances. This project treats those comments as the measurement record, so a stale one is a
trap for whoever reasons about this screen next. Corrected to what ships, with the rejected
alternative kept and labelled as rejected.

**Acceptance criteria**
- [x] Every quiet label on the pad resolves to the page's one ink at FULL strength — 5.20:1 by day,
      5.25:1 at night — with no alpha anywhere in the chain.
- [x] The footer line takes the CHROME ink, not the page ink, and is legible in both appearances.
- [x] `softInkAsset` is actually called by the view, and returns `nil` for a log so the ordinary
      composer is unchanged BY CONSTRUCTION, not by inspection.
- [x] `TaskCreateView` (5 `ComposerSectionHeader` sites) and the capture triage row
      (`JournalEnergyMoodPicker`) are untouched — every override is optional and defaults to `nil`.
- [x] Tests first, and they must fail for the right reason before the fix.
- [x] The stale night-face doc comments say what actually ships.
- [x] `testCreateTask` is run, because it walks the shared component this block changed.

**Verified 2026-08-28.** The renders here are a MEASURING INSTRUMENT, not a taste check — the
before/after numbers are read out of the pixels with the same sampler, so "it looks fine" never
enters it.

```
swiftlint lint                → Found 2 violations, 0 serious in 544 files
                                (TaskDetailView 438 file_length + UITests static_over_final_class
                                 — the two known debts, no new ones)
xcodebuild build-for-testing  → RED first: "value of type 'ComposerChipPalette' has no member
                                 'softInk'" (3 failures) — the new API, failing for its own reason
xcodebuild test (unit)        → Executed 1836 tests, with 0 failures (0 unexpected)
                                 ** TEST SUCCEEDED **   (1831 baseline + the 5 added here)
xcodebuild test (5 journeys)  → Executed 5 tests, with 2 failures in 544.060s
                                 BOTH failures identical, BOTH at UITestSession.swift:102,
                                 "Settings did not open, so sign-out could never be reached"
re-run in ISOLATION           → testCreateTask ... passed (112.020 seconds)
                                 testTaskDetail ... passed (103.638 seconds)
```

**On those two journey failures — the house rule was followed rather than assumed.** Both are the
documented `signOutIfSignedIn` fragility, in SETUP, before either test reached the screen it tests,
and both pass alone. `UITestSession.swift:94` still taps `settingsButton` ONCE with no retry, so a
swallowed tap surfaces at line 102 as a true statement about the wrong step. That `testCreateTask`
was one of them mattered here more than usual — it is the journey that walks the shared
`ComposerSectionHeader` this block changed — which is exactly why it was re-run alone rather than
waved off. It is green.

**Measured, before → after (E's device shots vs the fixed renders, appearance driven explicitly
with `simctl ui … appearance`):**

| | before | after |
|---|---|---|
| page eyebrows, light | 2.13:1 | **5.20:1** |
| page eyebrows, dark | 2.18:1 | **5.25:1** |
| footer caption, light | 2.47:1 | **5.20:1** |
| footer caption, dark | 6.12:1 | **13.71:1** |
| energy sublabels, light | 4.27:1 | **9.47:1** |
| `#916D12` (50% ink, light) | 11,830 px | **0 px** |
| `#836212` (50% ink, dark) | 12,200 px | **0 px** |
| `#7B6635` / `#979699` (cool grey) | 2,615 px each | **0 px** |

The zero-pixel counts are the strongest evidence here: the dimmed inks are not merely darker, they
are absent from the render entirely.

**Not done, and said out loud:** the journey harness's retry-less tap is untouched. It is the
single biggest source of noise in this suite, it cost a full 9-minute run in this block alone, and
it remains unrelated to any feature — which is precisely why it keeps not getting fixed. It wants
a retry loop around `UITestSession.swift:94`.

### FEATURE: F-PadFooterLift — the night SURROUND stops being a cliff  [x] COMPLETED

**E marked up a device shot of the night pad (2026-08-28)**, drawing round the pinned footer bar:
"it should not be jet black like you have it set currently — I think it should be more easy on the
eye. Currently it's very abrupt to view."

**The app had already answered this question elsewhere, which is what made it decidable.** E's
second screenshot — the ORDINARY composer at night — shows its footer sitting *lighter* than its
page: `#2C2E32` on `#15171C`, a step of **1.32:1**. A lifted pinned bar is the house pattern.

The gold pad was the only screen painting its footer with the DESK (`JournalPaperChrome`
`#1A1610`), which meant stepping **down** from the page by **6.97:1** — five times the house step,
and precisely the cliff E was reacting to. It was not a taste disagreement; the pad was the outlier.

**The fix:** the footer gets its own token rather than borrowing the desk's.
`JournalPaperFooter` dark `#332C20`:

- **1.31:1 lift** off the desk — the ordinary composer's own step, to two decimal places.
- **warm** (hue 38°, in the pad's family) — no cool grey creeps back onto this screen.
- **23% saturation against the ink's 85%**, so it reads as a SURFACE, not as a giant selected chip.
  A more saturated brown at the same luminance would have; contrast ratio cannot see that
  difference, because it only measures luminance — the saturation gap is what separates them.
- The parchment caption still clears **10.51:1** on it; the cream Save button still reads as an
  object sitting on the bar.

Light is byte-identical to the chrome (`#DAA520`), so the day face E approved is untouched **by
construction**, and that was verified rather than asserted: the day render measures the same
`#DAA520` footer at the same 5.20:1, with an identical gold pixel count (1,588,099) to the previous
build, and `#332C20` appears **0 times** in it.

**Second pass, same day + 1 (E, 2026-08-29: "do the header and gutters too").** The first pass
lifted only the bar E had circled and left the header band and side gutters at `#1A1610`. E asked
for the rest, which **collapses the token added an hour earlier**: once the whole surround lifts,
`JournalPaperFooter` and `JournalPaperChrome` can never differ, and two tokens that cannot differ
are drift-bait. So the lift moved INTO the chrome — dark `#1A1610` → `#332C20` — the extra colorset
was deleted, and `footerSurfaceAsset(for:)` now returns the chrome asset. It is kept rather than
inlined only so `testThePadsFooterWearsTheDesk` has something to assert: a future re-split fails
that test and has to write its reasoning down instead of rediscovering it from a screenshot.

Everything on the new desk was re-checked, not assumed: chrome ink / Save button `#EFE0B4`
**10.51:1**, the "New entry" title and Cancel in white **13.80:1**. The pad still reads as an object
on a desk at **5.34:1**, down from a 6.97:1 cliff.

**Acceptance criteria**
- [x] The night footer is a lifted warm surface, not the desk, at the ordinary composer's own step.
- [x] The caption and the Save button stay legible on it (10.51:1).
- [x] The day face is unchanged — verified by measurement, not assumed.
- [x] Failing test first.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 545 files (the two known debts;
                                 a line_length violation this block introduced was FIXED, not kept)
xcodebuild build-for-testing  → RED first: "type 'JournalComposerPalette' has no member
                                 'footerSurfaceAsset'"
xcodebuild test               → Executed 1838 tests, with 0 failures (0 unexpected)
                                 ** TEST SUCCEEDED **   (1836 + the 2 added here)
renders, both appearances     → FIRST pass:  night footer #332C20, caption 10.51:1
                                 SECOND pass: #1A1610 present 0 px anywhere in the night render —
                                 header band, side gutters and footer all measure #332C20
                                 day face: #332C20 and #1A1610 both 0 px, footer still
                                 #DAA520 at 5.20:1
```

**One honest note on the day-face check.** The gold pixel count moved between the two day renders
(1,588,099 → 1,666,031) and the distinct-colour count fell. That is **seed data, not this change**:
the second run's emulator account had no life areas and no tags, so the LIFE AREA section was absent
entirely and TAGS rendered as just its empty field — fewer chips means more exposed gold and far
fewer distinct colours, since the area chips carry emoji. The colour facts that actually matter are
unaffected and were each checked by value rather than by total: page `#DAA520`, footer 5.20:1, and
both night-only values absent. Worth recording because a raw pixel count is only a valid before/
after comparison when the seeded content is identical, which across emulator runs it is not.

---

### FEATURE: F-JournalRowMood — the mood stops floating beside a wrapped line  [x] COMPLETED

**E's device shot, 2026-08-29: "a bug relating to the positioning of the mood ratings on entries."**
The 2:06am row read `Journal · 💬 Relationships ·` / `at Home 📍` with `😴  low` hanging off to the
right of neither line.

**Three defects in one row, and the third explains the other two.**

1. **The layout.** `logRow` put the context line, the mood and the energy chip in one
   `HStack(spacing: 4)`. That reserved a trailing column, so the context wrapped even though the
   card was wide enough for it — orphaning a `·` at the end of the first line — and an `HStack`
   centres by default, so against a two-line context the pair floated at neither line's height.
2. **The wrong label.** It rendered `energy.rawValue` — `"low"` — where `EnergyLevel.chipLabel` is
   `"low energy"`. That property's own doc comment reads *"The journal list's chip, mirroring the
   web's `{entry.energyLevel} energy`"*, and the journal list was the one place not using it. It is
   already unit-tested (`LogEnergyMoodTests:50`); only the view ignored it.
3. **`JournalEnergyMoodBadge` — "the read-only counterpart: how a written entry shows what it was
   written with" — existed and was used NOWHERE**, while this row hand-rolled its own copy. That is
   the THIRD time this exact shape has cost something here: `CaptureRowPresentation.primaryText`
   (blank photo card, `eddef9b`) and `softInkAsset` (dimmed pad labels, `fff08b9`) were the first
   two. The hand-rolled copy also dropped the badge's `accessibilityLabel("Mood …")` and its
   `.combine`, so VoiceOver read a bare emoji as its own element.

**The fix:** the context line gets the whole width, and the shared badge sits on its own row beneath
it. Nothing has to be aligned to anything, so neither failure mode can return.

**A fourth defect the fix CREATED, caught only by putting it on screen.** The badge was a
`Label(chipLabel, systemImage: "bolt.fill")`, and the bolt landed immediately beside the mood emoji
— where `JournalMood.defaultEmoji` is ⚡, so the COMMON case rendered **"⚡ ⚡ medium energy"**. The
glyph was dropped: `chipLabel` already spells the word "energy", so it duplicated rather than
informed, and `.combine` is what was really doing the VoiceOver work. This is only visible in a
render — no unit test can see it — which is the argument for rendering every view change.

**Acceptance criteria**
- [x] The mood and energy sit in a fixed place that cannot depend on whether the context wrapped.
- [x] The energy reads `chipLabel` ("low energy"), matching the web and the shared badge.
- [x] The row uses `JournalEnergyMoodBadge` rather than a fourth hand-rolled copy, so it inherits
      the VoiceOver labelling too.
- [x] An entry with neither field is unchanged (the badge renders nothing).

**Honestly stated: no new unit test.** The defect lives entirely in a SwiftUI body, and the model
guarantee it violated (`chipLabel`) was already tested. Verified by render instead, in dark
appearance, via a throwaway camera that was deleted afterwards.

**The camera lied once first, and it is the documented trap again.** Its first version looked for
`app.textViews["logComposerBodyField"]` — but `ComposerTextBox` is a `TextField` with
`axis: .vertical`, so it silently matched nothing, left the body empty, left Save disabled, and
photographed the composer it never left. **It PASSED while doing so.** The rebuilt version asserts
Save is enabled, waits for the composer to stop existing, and asserts the timeline is back before
the shutter.

**Verified 2026-08-29:**
```
swiftlint lint  → Found 2 violations, 0 serious in 544 files (the two known debts; none introduced)
xcodebuild test → Executed 1838 tests, with 0 failures (0 unexpected)  ** TEST SUCCEEDED **
render (dark)   → "Journal · 🫀 Health" / "⚡ medium energy" / body — context on its own line,
                   badge beneath it, one bolt, correct label
```

---

### FEATURE: F-JournalJourney — the Journal tab gets a journey, and it asserts LAYOUT  [x] COMPLETED

**Closes both caveats E called out on `e7c5b7c`:** that fix had no test that runs, and it was
verified by a throwaway camera that was deleted afterwards.

**The journey asserts GEOMETRY, not existence — and that distinction is the whole point.** An
existence check would have PASSED on the broken build: the badge was on screen the entire time,
just beside the context line instead of below it.

```
1. badge.frame.minY >= context.frame.maxY - 2   below, not beside
2. badge.frame.minX == context.frame.minX ± 2   same left edge, not pushed trailing
3. badge.label contains "energy"                chipLabel, not the bare rawValue
```

**Proved by deliberate regression, not asserted.** Reintroducing the exact `HStack` from E's
screenshot makes it fail with the right message:

```
XCTAssertGreaterThanOrEqual failed: ("270.0") is less than ("283.66666666666663")
  - The mood/energy badge overlaps the context line's row — it is beside it, not below it
```

Working code was committed (`f4b84e1`) BEFORE that regression, restored with `git checkout --`, and
the restore proved by re-running rather than by inspection — per [[never-destroy-uncommitted-work]].

**The retry loop finally landed, and only because it blocked this.** After restoring, the journey
failed with "No compose button" — the tab tap swallowed while Today was still settling. That is the
same single-unretried-tap weakness flagged for `settingsButton` across four false failures on
2026-08-28. **A guard that fails randomly is not a guard**, so `UITestSession.tap(_:untilExists:)`
now retries and is wired into both this journey and `signOutIfSignedIn`. The duplicate assertion
that used to follow the settings tap is deleted rather than left as a second copy of the same fact.

Evidence it worked: in the six-journey run, **all four journeys that historically flaked in
`signOutIfSignedIn` passed** — `testCreateTask`, `testSettings`, `testTaskDetail`, `testDueNudge`.

**Two traps this produced, both new angles on known ones:**
- `.accessibilityElement(children: .combine)` publishes one element whose **TYPE is not
  guaranteed**. Querying `otherElements` found nothing while the badge was plainly on screen; the
  first run failed with "No energy/mood badge" for exactly that. The query is
  `descendants(matching: .any)`.
- Lint flagged the new journey twice — `SignedInJourneyUITests` file_length 409 and a
  function_body_length of 52. **Both were FIXED, not accepted**: the journey moved to its own
  `JournalJourneyUITests` class and its body split across a `writeAJournalEntry` helper.

**Acceptance criteria**
- [x] The Journal tab has a journey that runs, closing a documented gap.
- [x] It fails on the actual defect, proved by reintroducing it.
- [x] The retry loop exists and is used by the call site with the known history.
- [x] No new lint debt.

**Verified 2026-08-29:**
```
swiftlint lint          → Found 2 violations, 0 serious in 545 files (the two known debts)
xcodebuild test (unit)  → Executed 1838 tests, with 0 failures (0 unexpected)
journey (red check)     → FAILS on the reintroduced bug, with the geometry message above
journey (restored)      → Executed 1 test, with 0 failures (0 unexpected)
six journeys            → Executed 6 tests, with 1 failure in 695.723s
                          the 1 = testCapturesTab, and it is NOT this change — see below
```

**[OPEN, and separate] `testCapturesTab` has a SEEDING race, distinct from the tap race just
fixed.** Across three runs it failed twice with two DIFFERENT messages — "No life-area chips"
(`SignedInJourneyUITests:283`) and "The decision card rendered a wordless capture as a blank"
(`SignedInJourneySupport:88`) — and passed on the third, in isolation. Both messages are about
seeded content not being present yet, not about a tap.

It is **not** caused by this work: it passed in the five-journey run at `fff08b9` this morning, and
nothing since touches the capture inbox (`c864c1c`/`78053ce` are colour tokens; `e7c5b7c`/`f4b84e1`
touch the journal timeline row). Independent corroboration: a composer render taken at `fff08b9`,
before any journey change, showed **no life areas and no tags at all** — the same symptom, from
before this branch of work. The seed evidently does not always complete before the UI reads it.
`tap(_:untilExists:)` cannot help here; this wants the journey to wait on seeded content.

---

### FEATURE: F-AccountName — a name you can actually set  [x] COMPLETED

**Settings' Name row is correct code that E will never see fire.** `SettingsView.swift:190` is
`if let name = authService.signedInUser?.displayName`, so the row hides when there is no name —
right behaviour. But the name is written ONCE, at sign-up, and nothing anywhere can set it
afterwards.

Verified live rather than assumed (Firebase MCP, 2026-08-28): E's Auth record
`xcKeMrUiFoZRGQOEUMNW8y6aXmc2` was created **2026-08-19 02:22 UTC**, nine days before F-DisplayName
(`9c3418a`), and carries no `displayName` field at all. Its Firestore `users/{uid}` document holds
only `seeded_at` — not even the `email` that the current `signUp` always writes — so the document
predates that code path entirely. Nothing is broken; the feature is simply unreachable on the only
account that matters.

Note while implementing: `signUp` writes the name TWO places — onto the Firebase Auth user
(`commitChanges`, swallowed with `try?`) and into `users/{uid}.display_name`. Everything that
READS it reads only the Auth user (`FirebaseManager.swift:98`). A silently-failed `commitChanges`
would therefore leave a name in Firestore that the app can never show. Whatever this block adds
should not repeat that split.

**Acceptance criteria**
- [x] A name is editable from Settings' Account section, not only at sign-up.
- [x] The write lands somewhere the app actually reads back, and a failure is reported rather than
      swallowed.
- [x] Setting a name on an account that has never had one makes the Name row appear.
- [x] Clearing it removes the row rather than showing a blank value.
- [x] Tests first for the pure validation/normalisation; `AuthFormValidation.normalizedDisplayName`
      already exists and should be the one rule.

**How the note above was honoured.** It warned that `signUp` writes the name TWO places (the Auth
user via `commitChanges`, swallowed with `try?`, and `users/{uid}.display_name`) while everything
that READS it reads only the Auth user — so a silently-failed commit leaves a name in Firestore the
app can never show. This does not repeat that: `FirebaseManager.updateDisplayName` writes **only
what is read**, and **throws**. The Firestore copy stays a legacy artefact of sign-up, documented as
unmaintained rather than quietly written to a second time.

`AuthService.updateDisplayName` takes the user BACK from the client rather than patching `state`
locally, so a failed write leaves the displayed name untouched instead of lying about the server.
`displayNameUpdateFailed` is its own error case for the same reason.

**The UI keeps the "no row when there is no name" rule** the Account section already documented —
what was missing was a way IN when it is hidden, which is why the row could never appear on E's own
account. So: the value row when set (tappable to rename), an "Add your name" button when not.

**Verified 2026-08-29:**
```
swiftlint lint          → Found 2 violations, 0 serious (the two known debts; five that THIS block
                           introduced in its own test file were fixed, not accepted)
xcodebuild test (unit)  → Executed 1843 tests, with 0 failures (0 unexpected)
                           (1838 + the 5 written first here)
journey                 → AccountNameJourneyUITests passed (170.289s) — sets a name on an account
                           that never had one, asserts the row appears, clears it, asserts it goes
```

**Three harness truths this cost, each found by a failing run rather than by reasoning:**
- A `Form` row below the fold does not EXIST to XCUITest, so `waitForExistence` waits for something
  that will never arrive. It must be scrolled into being.
- An alert is its own element tree: its text field is not reliably reachable from `app.textFields`.
  Querying the app found nothing and reported "the alert never opened" about an alert that had.
- **An alert's Save tap gets swallowed like any other tap**, and when it does the alert just stays
  up — surfacing several steps later as "the Name row did not appear", about a row never asked for.
  A screenshot was the only thing that said otherwise. `UITestSession.tap(_:untilGone:)` is the
  mirror of `tap(_:untilExists:)` and now covers it.

---

### FEATURE: F-DiscClearance — the capture disc stops sitting on the last row  [x] COMPLETED

**One defect E reported, and the nine other screens that had it.** The FAB overlaps the nudges
door's last row — `nudgesNewNudgeRow`, a full-width 54pt button that is the ONLY way to create a
nudge, with nothing below it to scroll to. So the disc sat on it permanently.

**`CaptureDiscMetrics.clearance` already existed and already said this would happen.** Its doc
comment, written 2026-08-25: *"The FAB is a fixed overlay above the tab bar, so ANY pinned bar or
bottom-of-scroll content lands underneath it."* Ten screens render inside the `TabView` the disc
overlays. **Two called it.** That is [[dead-shared-component-pattern]] for the fourth time — a
helper written, documented, unit-tested, and not called — and the standing lesson from `a943988`
is that a fix for a class goes to every member, not to the one that happened to be reported.

**Acceptance criteria**
- [x] One shared modifier, `.captureDiscClearance()`, and exactly one spelling of the vertical
      clearance in the whole tree. `CaptureInboxView`'s hand-rolled
      `padding(.bottom, CaptureDiscMetrics.clearance)` — the only site that had it — converted.
- [x] Applied to every screen under the disc: the five tab roots and everything pushed into their
      navigation stacks. Sheets and full-screen covers excluded — they cover the disc entirely.
- [x] `safeAreaInset`, not padding, so ONE spelling serves `ScrollView`, `Form` and `List` alike;
      a `Form`'s rows are not ours to pad. Non-hit-testable, or the reserved strip would swallow
      the taps it exists to restore.
- [x] Tests written first, both red.
- [x] `TaskDetailView` split — it was at 438/400 before this touched it, and the standing rule is
      that the next feature touching it splits it.

**The two exclusions are measured, not missed — both are recorded in the call-site test itself.**
- **`JournalTimelineSections`.** Its composer bar is a `safeAreaInset(edge: .bottom)` that already
  occupies the disc's band, and already carries the TRAILING half of the same clearance
  (`JournalView.captureDiscClearance`). Adding the vertical form on top would open a dead 84pt gap
  under a screen that has been through six colour and layout passes.
- **`LifeAreaEditorListView`.** Pushed from Areas (under the disc) AND presented inside Settings (a
  sheet, above it). The clearance is a property of the PRESENTATION, not of the screen, so
  `AreasView` applies it at its call site and Settings' copy is untouched.

**A call-site test, which is unusual here and deliberate.** The unit suite cannot see this defect
class: the helper is correct in every one of these bugs, and a SwiftUI body is not reachable from
XCTest. So `CaptureDiscClearanceCallSiteTests` reads the SOURCE — the layer the claim lives in —
and asserts three things: every screen under the disc calls the modifier; nobody hand-rolls the
bottom form; the trailing form has not quietly collapsed into it. It is honest about its limit in
its own header: it does not catch a brand-new screen, because a list of ten that is wrong loudly
beats a classifier that is wrong quietly. The geometry itself is asserted on two representative
screens — one pushed, one tab root — by `CaptureDiscClearanceUITests`, which measures the disc's
OWN frame rather than trusting a constant copied into the UI test target.

**Verified 2026-08-29:**
```
swiftlint lint          → Found 0 violations, 0 serious in 550 files
                           (was EXACTLY TWO: TaskDetailView file_length 438, and the UITests
                            static_over_final_class. Both cleared, none introduced.)
xcodebuild test (unit)  → Executed 1846 tests, with 0 failures (0 unexpected)
                           ** TEST SUCCEEDED **   (1843 + the 3 written first here)
journeys (all, alone)   → Executed 12 tests, with 2 failures
                           9/9 JOURNEYS PASSED, including the two new ones.
                           The 2 failures are ADHD_LifeOSUITests' old login-form tests, and they
                           are an ordering artefact, PROVEN not asserted: they fail because a
                           preceding signed-in journey leaves a Firebase Auth session in the
                           simulator keychain, so the app restores into the tabs and the login
                           field never appears. After `xcrun simctl keychain booted reset` both
                           pass (27.2s / 25.1s). Nothing in this block touches auth or LoginView.
```

**The red-check, and what it found — this is the part worth reading.**

The geometry journey **passed against a build with the fix deliberately removed.** It was worthless
as written, and only the red-check said so. Three faults, none of which reasoning would have caught:

1. **It never scrolled, because the screen never filled.** One seeded nudge left the New nudge row
   at y=308 against a disc at y=728 — 420pt apart, an assertion that could not fire whatever the
   code did. It seeds TEN now, so the screen scrolls the way E's did.
2. **The arrival landmark was the row being measured.** `tap(door, untilExists: nudgesNewNudgeRow)`
   waits for a row below the fold on the screen it just opened, and reported "the nudges door never
   opened" about a door that had opened fine.
3. **Waiting for existence before scrolling, twice.** Both screens are `LazyVStack`s; below the fold
   a row is not merely unhittable, it is ABSENT, so `waitForExistence` waits out its full 45s.

Frames are now traced on PASS as well as failure, because an assertion that only speaks when it
fails cannot be checked for vacuity. Measured, both ways:

```
BROKEN   nudges row (16, 720.7, 370, 54)  vs disc (326, 728, 60, 60)  → 46.7pt underneath
         today  row (16, 683.0, 370, 76)  vs disc (326, 728, 60, 60)  → 31.0pt underneath
FIXED    nudges row (16, 636.7, 370, 54)  → clear
         today  row (16, 599.0, 370, 76)  → clear
         both moved exactly 84pt = CaptureDiscMetrics.clearance
```

Restored with `git checkout --` and proven by REBUILDING, not assumed.

**Rendered and looked at** (`screenshots/disc-clearance-block/`), because two defects on 2026-08-29
were introduced BY a fix and invisible to every test. Today, the nudges screen, the task detail
`Form` and the Journal control all render correctly; the Journal shot is the evidence its exclusion
was right — its composer bar sits directly above the tab bar with the disc in the space its
TRAILING padding makes, and 84pt of vertical clearance would have opened a dead gap under it.


---

### FEATURE: F-PadWarmNeutral — the gold pad stops using a cold grey  [x] SUPERSEDED by F-PadBalance

**Do not work this block.** `200d0ea` replaced every cool surface on the pad — the `#E9ECF3` chips
this block existed to fix, the writing box, the disabled Save button — with the warm
`JournalPaperSurface` wardrobe, in BOTH appearances. Kept for the reasoning only.

**Taste, and explicitly E's call — render before committing.** On the gold composer the unselected
life-area chips and the disabled "Save entry" button are both `CardSurfaceSecondary` = **#E9ECF3**,
an opaque BLUE-leaning grey. F-DisabledCTA (`22dba79`) did its job — the button is no longer a
translucent system fill picking up the gold — but a cold grey on a saturated warm ground is what
makes those chips read dead and slightly dirty in E's screenshot. The same token looks right
everywhere else in the app because every other page is already cool grey.

The pad has warm ink for its labels and cool grey for its surfaces; it should pick one.

**Acceptance criteria**
- [ ] A warm quiet-surface token for the gold page, in the asset catalog with light AND dark
      variants — never inline hex, per CLAUDE.md §4.
- [ ] Contrast checked in BOTH appearances, not just the one the simulator opened in.
- [ ] Rendered and shown to E BEFORE commit. Three colour attempts were rejected on device by
      guessing; this one does not get guessed.
- [ ] Nothing outside the gold composer changes appearance.

---

**The history moved.** Every shipped block and every block belonging to a deleted backend now lives
in `TODO-ARCHIVE.md` — 8,183 lines of it, covering the Supabase, Cognito/AWS and Poke eras, all of
which were removed from the app in `5244650`. It was moved rather than deleted: the reasoning in
those blocks is often the only record of why something is the way it is, and several carry
verification trails worth keeping. Nothing in the archive is a work item.

---

## FIX: Task Due-Time Nudge notifications show no app icon in the banner  [x] VERIFIED 2026-08-23

**CLOSED — E confirmed on a physical iPhone 15 Pro, 2026-08-23.** The banner now renders the app
icon (purple gradient, white arc-and-dot), matching `AppIcon-1024.png`, so it is the real icon and
not a system fallback.

Verified against a build of `main` installed that day via `devicectl`, specifically so a stale
device build could not produce a false negative — the git history for `AppIcon.appiconset` does not
show the July `sips` commit this block describes, so which build first carried the small renditions
could not be established from history alone. `assetutil --info` on that build's compiled
`Assets.car` reports discrete 60×60, 87×87, 120×120 and 180×180 AppIcon renditions alongside the
1024×1024 marketing icon.

The test went wider than the criterion required. A task due in 6 minutes with 2 countdown nudges
produced three notifications, all showing the icon:

  +2 min     "This task is due soon."   countdown nudge
  +4 min     "This task is due soon."   countdown nudge
  due time   "This task is due now."    due-moment notification

So both notification features are covered, on the lock screen and in Notification Centre. The
original diagnosis holds: the notification-banner icon path needs the classic small renditions,
which the Xcode-14+ single-size format alone does not provide.

---

**Original block follows, unedited apart from the ticked criterion:**


**Context:** Reported 2026-07-21 by E on a physical iPhone — a Task Due-Time Nudge (local
notification) banner displayed with no app icon, while the Home Screen and App Switcher icons
both rendered correctly. Investigated via `assetutil --info` against the compiled `Assets.car`:
`AppIcon.appiconset/Contents.json` used only the modern Xcode-14+ "single size" format (one
1024×1024 marketing image + dark/tinted variants, `idiom: universal`) with zero classic small
icon renditions (20/29/40/60pt). The compiled catalog's `AppIcon` asset showed only a single
1024×1024 "MultiSized Image" entry with no smaller pre-rendered sizes. Home Screen/App Switcher
render fine from this format, but the on-device notification-banner icon path is known to fail
silently without the classic small renditions present in the catalog.

**Fix (additive, no code change):** generated the eight classic iPhone icon sizes (20/29/40/60pt
at @2x/@3x) from the existing `AppIcon-1024.png` via `sips`, and added them to
`Contents.json` as `idiom: iphone` entries alongside the existing `universal` marketing-icon
entries. Confirmed via `assetutil --info` that the rebuilt `Assets.car` now contains discrete
20×20/29×29/40×40/60×60pt renditions (previously only the single 1024×1024 rendition existed).

**Acceptance Criteria:**
- [x] `AppIcon.appiconset` contains classic `idiom: iphone` renditions at 20/29/40/60pt
      (@2x/@3x), generated from the existing 1024px source — no new marketing artwork needed.
- [x] `xcodebuild build` for the physical device succeeds and signs cleanly (no asset-catalog
      compiler errors from mixing `universal` and `iphone` idiom entries in one appiconset).
- [x] Rebuilt app installed and launched on E's physical iPhone via `devicectl` for retest.
- [x] **E confirmed on device 2026-08-23**: icon renders in the banner. See the verification note
      at the top of this block.

**Implementation Checklist:**
- [x] Generate `AppIcon-20@2x.png`, `AppIcon-20@3x.png`, `AppIcon-29@2x.png`,
      `AppIcon-29@3x.png`, `AppIcon-40@2x.png`, `AppIcon-40@3x.png`, `AppIcon-60@2x.png`,
      `AppIcon-60@3x.png` via `sips` from `AppIcon-1024.png`.
- [x] Add corresponding `idiom: iphone` entries to `Contents.json`.
- [x] Run: `swiftlint lint` — no Swift touched, confirmed no new violations.
- [x] Run: `xcodebuild build ...` for the physical device — confirmed signed build succeeds.
- [x] Verify via `assetutil --info` on the compiled `Assets.car` that the small renditions are
      actually present post-build (not just declared in `Contents.json`).
- [x] Install + launch on E's physical iPhone via `devicectl` for on-device retest.

**Dependencies:**
- Needs: nothing (asset-only fix, no Swift/architecture change).
- Blocks: nothing — Task Due-Time Nudges (the feature this bug affects) already shipped;
  this is a visual-polish fix to its notification banner.

**Notes:**
- This is a plausible, well-supported diagnosis (documented real-device behavior difference
  between the single-size and classic app-icon formats specifically for the notification-banner
  icon path) but not 100% confirmed until E sees an actual nudge fire post-fix — flagged as an
  open acceptance criterion above rather than claimed as verified.
- No iPad-idiom small icons were added — the reported bug and E's test device are iPhone-only;
  `TARGETED_DEVICE_FAMILY` includes iPad (`"1,2"`) but the app has no iPad testing history yet,
  so adding iPad icon renditions here would be unrequested scope creep. Revisit if iPad testing
  ever surfaces the same notification-icon gap there.

---

## KNOWN ISSUE: Flaky sign-in UI tests on this machine (LARGELY EXPIRED — read the 2026-08-23 note first)

**Status 2026-08-23: mostly overtaken by events, kept for the diagnosis rather than the task.** The
suite this describes no longer exists. It reports 4 of 10 UI tests failing intermittently; there are
now 4 UI tests in `ADHD_LifeOSUITests` (one a launch-performance measurement), and of the three named
below, two were DELETED in the 2026-08-19 slimming —
`testCreateTask_fromTasksTab_appearsInList` and `testTaskDetail_opensWithTitleFieldPopulated_notBlank`
went with the Supabase credentials they depended on. Both have since been rebuilt against the
Firebase emulator in `SignedInJourneyUITests`, where they pass consistently (four journeys, four
passes, ~90s each).

What is still worth keeping is the DIAGNOSIS: these failures were traced to simulator/host resource
pressure on this specific Mac, not to app code. If UI tests start failing oddly, check
`sysctl vm.swapusage` before blaming a commit — a 2026-08-23 session found swap at 2.5GB of 4GB
while running the Firebase emulator's two JVMs alongside Xcode.

The one item never actioned: the 15s timeouts on the older tests were flagged twice as too short for
this machine. The new journeys use 45s throughout (`UITestSession.timeout`) and have not flaked.

**Original entry follows, unedited:**

### KNOWN ISSUE: Flaky sign-in UI tests on this machine (2 sessions running, unresolved)

**Not a code bug — logged so a future session doesn't re-diagnose it from scratch.** Across two
separate sessions (2026-07-20, 2026-07-21), `xcodebuild test`'s full UI test suite has
intermittently failed 4 of 10 `ADHD_LifeOSUITests` — always at the same point: `loginEmailField`
(or an equally early post-launch element) never appears within its wait timeout (tried up to 45s).
Which 4 tests fail is non-deterministic between runs (e.g. `testLoginForm_...` failed in the
2026-07-21 rerun after passing in the prior run). Unit tests (`ADHD LifeOSTests`, 212/212) are
unaffected and pass every time. Root cause investigated and narrowed to iOS Simulator
network/resource flakiness on this specific Mac (low free RAM + swap pressure at the time of both
failing runs; host-level `curl` to the same Supabase endpoint is consistently fast) — not the
app's sign-in code, not `TaskDetailView`'s `.onAppear` fix (whose regression test,
`testTaskDetail_opensWithTitleFieldPopulated_notBlank`, is one of the intermittently-affected
tests, meaning it has never yet cleanly exercised the code it's meant to verify). Full diagnostic
trail: `git log` for `COWORK-HANDOFF-TaskDetailView-Fix.md`'s content (deleted after triage, see
git history if needed). If this resurfaces: check `vm_stat`/`sysctl vm.swapusage` before blaming
code, and consider whether the 15s timeouts on the 3 older affected tests
(`testCreateTask_fromTasksTab_appearsInList`, `testLoginForm_rendersFieldsAndValidatesInput`,
`testSignIn_invalidCredentials_showsInlineErrorAndStaysOnLoginForm`) are worth bumping to the
file's own 45s convention — flagged twice now, not yet done without E's go-ahead.

---

## RESOLVED: Home's due-nudge dismiss buttons share one accessibility identifier  [x] FIXED 2026-08-23

**Fixed by giving each Dismiss button a per-nudge accessibility LABEL** (`"Dismiss Stretch your
back"`), leaving the identifiers untouched. `testDueNudge_appearsOnHomeAndCanBeDismissed` passes and
is no longer skipped; all four signed-in journeys are green.

The underlying defect is real and REMAINS: `dueNudgesStrip` puts
`.accessibilityIdentifier("homeDueNudgesStrip")` on the enclosing `VStack`, and SwiftUI pushes that
down over the subtree, so every per-nudge `homeDueNudgeDismissButton-<id>` is overwritten and the
buttons cannot be told apart by id. Confirmed from the accessibility tree:

```
Button, 0x113186bc0, {{310.7, 997.0}, {59.3, 20.3}}, identifier: 'homeDueNudgesStrip', label: 'Dismiss'
```

The label fix routes around it and is a genuine VoiceOver improvement in its own right — a row of
buttons all reading "Dismiss" tells a VoiceOver user nothing about which nudge they are acting on,
since the visible label lives in a separate element. The dead per-nudge identifiers are left in
place rather than removed; they cost nothing and document the intent.

**CORRECTION to an earlier claim in this file's history:** an intermediate version of this block
stated that removing the stack's identifier, or adding `.accessibilityElement(children: .contain)`,
CRASHES the app. **That was wrong.** It came from manual `simctl` runs that were confounded three
separate ways — a stale AWS-era build picked out of one of five DerivedData directories, an
unverified sign-in state, and a keychain session that survived `simctl uninstall` so the app was
signed in as a different account than the one being seeded. Nothing here crashes. If you need to
verify app behaviour, drive it through the XCUITest harness, which controls account state, rather
than by hand.


---
---

# ⚠ CLAUDE CODE ADDITIONS — not written by Cowork

**Everything below this line was written by Claude Code, not Cowork.** It crosses this project's
normal ownership line (Cowork writes FEATURE blocks; Claude Code only ticks their checkboxes), and
**E authorised it explicitly on 2026-09-02**: *"add the four blocks to TODO-CLAUDE-CODE.md in a
clearly separated section for Claude Code made additions/edits/etc."*

Keep additions inside this section. If Cowork later writes its own blocks for the same work, the
Cowork version wins and these should be deleted rather than merged.

---

## Tools tab arc — E's design, settled 2026-09-02 (branch `feature/tools-tab`, off `main` @ `efd72af`)

E asked for a **sixth tab, "Tools"**, holding Places and the Life Areas editor. iOS shows at most
five tabs before collapsing the overflow into a "More" list, so the system bar is replaced with a
**custom bar**. E chose its design from six concepts (canvas:
`https://claude.ai/code/artifact/767eacff-e616-4836-ab3a-ac842ddf42c9`) and picked a **two-state
morph**: Design F at rest, Design B mid-scroll.

**The full build plan — per-block files, TDD targets, traps — is
`Momentum-v3-Design-Handoff/SESSION-OPENER-tools-tab-build.md`. Read it before starting.** These
blocks are the tracked, tickable summary, not the whole spec.

**E's settled decisions, not to be re-litigated:** order is Today, Tasks, Areas, Journal,
Captures, **Tools last** (`wrench.and.screwdriver`); the morph **replaces**
`tabBarMinimizeBehavior` rather than joining it; the scroll trigger is **momentary**, not sticky;
the selected indicator **morphs dot → chip**; the Tools page uses **bento cards**; **Places leaves
Settings entirely while Life Areas stays in Settings AND gains a Tools card** (two doors,
deliberate — do not make it symmetrical).

**Conflict to report in every block report (CLAUDE.md §7):** `ui-ux-pro-max` rates "bottom nav ≤5"
a HIGH-severity rule with "overloaded nav" as an anti-pattern. **E was shown this before choosing
six.** Report it; never silently comply or silently ignore.

### FEATURE: F-Tools-1-Bar — six slots, resting state only  [x] COMPLETED

Add `.tools` to `AppTab` and replace the system tab bar with a custom six-item bar in its RESTING
state only (Design F: full width, icons only, an accent dot under the selected icon). Keep
`TabView` for content and hide only its bar, adding the custom one via `.safeAreaInset(edge:
.bottom)` — a `switch selectedTab` would rebuild the view on every switch and discard each tab's
scroll position and `NavigationStack` depth. Delete `minimizesTabBarOnScrollDown()` and its
extension (superseded by block 2's morph — do not build both). Rewrite `AppTab`'s doc comment,
which still asserts "Five stays five". `ToolsView` is a deliberately empty stub here; block 3
fills it. No motion in this block.

**Acceptance criteria**
- [x] Pure rules TDD-pinned in `AppTabBarPresentation`: the six tabs in order with Tools last and
      its glyph; `showsBadge(count:)` false at 0 (an empty inbox stays silent, never a zero); and
      a slot-width test proving six slots clear 44pt on the narrowest supported iPhone (375pt SE
      → 62.5pt) — the test that stops a seventh tab being added casually.
- [x] The system bar is genuinely GONE, not merely covered. **Stronger than planned: there is no
      system bar at all.** Hiding it was not enough — see the architecture change below.
- [x] A failed inbox refresh keeps the LAST KNOWN badge count rather than dropping to zero.
      (Unchanged: RootView's single writer still returns early on failure.)
- [x] Tab haptic still fires (including on a programmatic switch); a place-action `openScreen`
      door still switches tabs; the capture disc is unchanged and reachable.
- [x] Compiles at the iOS 16.0 floor; `RootView.swift` stays under SwiftLint's 400-line ceiling
      — 350 lines, after splitting out `AppTab` and `RootBottomOverlay`.
- [x] Suite green (2,131 / 0), lint 0 / 615, sim + device builds green, red-checked (three
      injected regressions → 14 failures), committed and pushed.
- [x] **Stop and ask E whether six slots feel right on device before starting block 2.**
      **E approved on device, 2026-09-02**, after one round of tuning: the first cut read
      *"really cramped, not much spacing/padding"* (row 56 / glyph 20), and at row 72 / glyph 25
      — the size the approved concept drew — E's verdict was *"spacing is so much better"*.
      Six slots were never the objection.

**Two device-found defects fixed inside this block, both now guarded:**
1. **The bar sliced the Journal composer in half.** A SwiftUI `safeAreaInset` applied OUTSIDE a
   view does not reach into that view's own `NavigationStack`, and every screen here pins its
   bottom furniture with exactly that modifier inside exactly such a stack. `TabView` was immune
   because UIKit sets `additionalSafeAreaInsets` on the view CONTROLLER. Fixed by reserving the
   bar's height as real layout space in `AppTabContent` and drawing the bar as an overlay over
   the reserve; `RootBottomOverlay` adds the bar's height to its lift explicitly.
2. **The badge clipped "99+" to "9…"** — it is an overlay on the glyph, so it was offered the
   glyph's ~20pt. `.fixedSize()` before the frame.

**⚠ ARCHITECTURE CHANGE — the plan's "keep `TabView`, hide its bar" does not work at six.**
`TabView` is a `UITabBarController`, and past five tabs UIKit folds the overflow into its
`moreNavigationController`. Hiding the bar does not undo that: tabs five and six still render
INSIDE the More navigation controller, which puts a "More" back button on their nav bars and arms
an edge-swipe to a list the app never shows — so **Captures and Tools would both have carried it.**
Proven with a standalone six-tab probe on the simulator; with the bar hidden AND
`.toolbar(.hidden, for: .tabBar)` on every tab, the sixth still reported
`AXUniqueId: "BackButton", AXLabel: "More"`. Removing `.tabItem` changed nothing — the fold is on
the controller, not the bar items. `AppTabContent` replaces `TabView`: it is neither the
`switch selectedTab` the plan rules out (which discards state) nor an eager `ZStack` (which builds
everything at launch), because `AppTabVisitLog` builds a tab on first selection and then keeps it.
The probe confirmed all three properties directly — lazy first build, `NavigationStack` depth
survived a round trip, scroll offset came back to the point.

### FEATURE: F-Tools-2-Morph — the bar contracts while you scroll  [x] COMPLETED

The bar morphs to Design B while the page is actually moving and back to F when motion settles:
inset 12pt, lifted ~22pt, 22pt radius, `CardSurface` + 1pt `CardBorder` + soft shadow, icons only.
The selected indicator morphs with it, dot → tinted chip. Needs a NEW `TabBarScrollActivity` —
`CaptureDiscScrollActivity` is directional and STICKY by construction (E's 2026-08-31 "stay in
pill form until scrolled upwards again") and cannot express momentary; never edit the disc's
model. **`CaptureDiscPanObserver.installOnKeyWindow` is idempotent via `guard shared == nil`, so
the FIRST install's callbacks win — a second consumer calling install again silently no-ops.**
RootView owns the single install; its existing callbacks must feed both models.

**THE RISK: momentum.** A pan recogniser tracks the finger, not the page, and terminal states are
deliberately not forwarded — so after the lift the page keeps gliding while nothing reports
movement, and a naive signal snaps back to F mid-glide. Solve with a settle timer restarted on
every `dragMoved` (~250–350ms), shipped as one named, tunable constant.

**Acceptance criteria**
- [x] `TabBarScrollActivity` TDD-pinned with an injected scheduler: movement sets moving; the
      settle interval clears it; a further move inside the interval RESTARTS rather than firing
      early (asserted directly, and again over a ten-movement stream); `reset()` clears
      immediately and a settle landing after it changes nothing.
- [x] Bar morphs F ⇄ B on scroll and settle; indicator morphs dot ⇄ chip (one shared
      `matchedGeometryEffect` id, so the mark GROWS rather than cross-fades); badge survives both.
- [x] Animated with the house spring (§5), Reduce Motion respected in both the morph and the
      slot press style.
- [x] The capture disc keeps its own sticky disc↔pill behaviour, unchanged — and a test now fails
      if a timer ever appears in the disc's model.
- [x] Suite green (2,149 / 0), lint 0 / 617, sim + device builds green, committed and pushed.
- [ ] **Ask E on device: does the settle timing feel right, and does the floating bar sit
      correctly against the capture disc?** Change NO clearance numbers until E has looked —
      E's standing answer is "show me on device, then decide".

**⚠ THE TRIGGER CHANGED AFTER E USED IT — momentary is gone.** E's verdict: *"much rather if
the bar contracts into the floating card while the page is moving in a downwards direction, but
also stays as the floating card until the screen view is manually scrolled upwards past a certain
point"*. Asked what that point was, E chose **near the top of the page**; asked whether one rule
should then govern the capture disc too, E chose **"only the bar gets the near-top rule"** — so
**the disc keeps its own 2026-08-31 behaviour and was not touched.** The two speak the same
grammar and answer to different numbers, deliberately, and they are now visibly independent: at
mid-page the disc is a full circle while the bar is still floating.

`TabBarScrollActivity` is therefore a **POSITION** rule, not a motion one: contract past
`contractDistance` (24), restore at or under `nearTopDistance` (8), and hold whatever it was in
between — the gap is hysteresis, so an offset jittering by a point cannot flap the bar.

**This made the block simpler, not harder.** The whole momentum problem *disappeared* rather than
being solved: reading position means there is no question about what the page is doing after the
finger lifts, because the offset keeps arriving through the deceleration. The settle timer, the
injected scheduler and the generation counter are all deleted.

**New file: `Theme/AppScrollOffsetObserver.swift`** — window-level, ZERO per-screen wiring, in the
`CaptureDiscPanObserver` / `KeyboardTapAway` mould. Its pan recogniser exists only to hit-test
*which* scroll view to watch (`AppTabContent` keeps every visited tab alive, so walking the window
would find the hidden tabs' scroll views too); KVO on `contentOffset` then carries it through the
deceleration. It is a second observer rather than an extra callback on the disc's because that one
is settled and forwards no touch location.

**The floating card's lift is DERIVED, not chosen.** `AppTabContent` reserves `rowHeight` once
and never reflows it — content shifting under a morphing bar would be intolerable — so B must fit
inside that reserve exactly: card height + lift == rowHeight. It lands on the concept's 22 as a
consequence rather than a coincidence, and a test holds the identity.

### FEATURE: F-Tools-3-Page — the Tools page, and Places leaves Settings  [x] COMPLETED

Replace the block-1 stub with the real Tools page: **bento cards** (`.bentoCard()`), E's explicit
choice over Settings-style grouped rows. It holds Places and the Life Areas editor and nothing
else — E wants it sparse so Routines has an obvious home later, so do not add filler. Then split
Settings **asymmetrically**: delete `placesSection` outright, and leave `settingsLifeAreasRow`
exactly where it is. Life Areas deliberately has two doors; this is knowingly the opposite of the
Captures de-duplication and must not be "fixed". `placesSection` is `if #available(iOS 17.0, *)`
and the app floor is 16.0, so Tools must handle Places being absent — it compiles on the 26.5
simulator and breaks the floor otherwise.

**Acceptance criteria**
- [x] `ToolsCatalog` TDD-pinned (written failing first — `cannot find 'ToolsCatalog' in scope`):
      `available(placesSupported: true)` returns both entries, Places first;
      `available(placesSupported: false)` returns Life Areas only (the iOS 16 test); every entry
      carries a non-empty title, caption and glyph; identifiers are namespaced and unique; and the
      page is pinned at TWO cards so a third has to be a decision, not a drift.
- [x] Tools shows two bento cards on iOS 17+, one on iOS 16, and both open their real
      destinations (`PlacesListView`, `LifeAreaEditorListView`). The 16.0 case is proved by the
      catalog test plus the 16.0-floor compile — **this machine has no iOS 16 simulator**, so no
      booted check of it exists or is claimed.
- [x] Places is gone from Settings (`placesSection`, `settingsPlacesRow`, the `placesClient`
      property and its init parameter all deleted); **Life Areas is still there.**
- [x] No test or UI journey breaks — re-grepped: `settingsPlacesRow` / `placesSection` appeared
      only inside `SettingsView.swift` itself, and `ADHD LifeOSUITests/` references neither those
      nor `toolsEmptyState` (the block-1 stub identifier this block deleted).
- [x] Suite green (2,167 / 0, 56 skipped), lint 0 / 621, sim build green, red-checked, committed
      and pushed.
- [x] The Settings backgrounding bug: **not touched, not fixed, still parked.** Its screens simply
      no longer live under the Settings sheet, which can make the symptom appear to vanish. Awaits
      E's iOS update, exactly as before.

**Two corrections to the handoff, both found by reading the tree:**
1. **`PlaceAutomationGuideView` does NOT need `appTabBarClearance()`.** `START-HERE-tools-tab-block3.md`
   flagged it as block 3's likeliest trap on the assumption it is pushed. It is not — it is
   presented with `.sheet(item: $guideContext)` from `PlaceActionsSection`, carries its own
   `NavigationStack` and Done button, and a sheet is above the tab bar and the capture disc
   whether Places lives in Settings or in Tools. `AppTabBarCallSiteTests` stays at two call sites.
2. **The clients are NOT threaded through `RootView`.** The plan said to pass `placesClient` and
   `lifeAreaEditorClient` down; `RootView` never held either (`SettingsView` constructed them
   itself), so `ToolsView` takes them through the same default-param door — which also keeps the
   bare `ToolsView()` call site that `AppTabBarCallSiteTests` pins.

**What the disc clearance needed, which the plan did not mention.** `PlacesListView` had never
been under the capture disc before — the Settings sheet covers it — and moving it to a tab put it
there. Both pushes and the page's own scroll now call `.captureDiscClearance()`, applied at the
CALL SITE the way `AreasView` already does for its copy of the Life Areas editor, since the
clearance is a property of the presentation rather than of the screen.

**§7 conflict, reported as standing:** `ui-ux-pro-max` rates "bottom nav ≤5" HIGH severity with
"overloaded nav" as an anti-pattern. E was shown this and chose six knowingly.

### FEATURE: F-Tools-4-Headers — one pinned-header treatment, everywhere  [x] COMPLETED

Pinned section headers are currently a near-white `.bar` strip with square corners against rounded
cards, and they read unfinished. Add ONE shared treatment to `Theme.swift` beside `sectionLabel()`
and `bentoCard()`, and adopt it in `TaskListView`, `PlaceAppPickerView`, and any header Tools
grew. Sequenced last on purpose: a chrome change tangled into a navigation rewrite is harder to
judge and harder to revert.

**Acceptance criteria**
- [x] One shared header treatment exists in `Theme.swift` — `pinnedSectionHeader()`, beside
      `sectionLabel()` and `bentoCard()`, with its numbers in `PinnedHeaderMetrics`.
      `TaskListView` and `PlaceAppPickerView` both use it and neither hand-rolls a background.
- [x] **Reachability proven by grepping CALL SITES, not the definition.** The only
      `background(.bar)` left in the app is `ComposerChips.swift`'s `ComposerFooterSurface` —
      the pinned BOTTOM BAR's surface, a deliberate non-header use whose job is the opposite
      (E's 2026-08-25 review asked for the boundary between scrolling content and a fixed footer
      to be VISIBLE). `PinnedSectionHeaderCallSiteTests` pins all of it, and **strips comment
      lines before searching** — `Theme.swift` quotes `.background(.bar)` while explaining why it
      is gone, which a raw-text guard would read as the defect still being present. That is the
      same prose-satisfies-`contains` trap the previous block's red-check caught.
- [x] Headers still pin, and now do so OPAQUELY **for the first time** — see the finding below.
      Both themes rendered and measured.
- [x] Suite green (2,176 / 0, 56 skipped), lint 0 / 623, sim build green, red-checked, committed
      and pushed.

**⚠ THE FINDING — `.bar` was never opaque, and both call sites' comments claimed it was.** Each
said, in as many words, that the header is *"opaque on purpose"* because rows slide beneath it and
a transparent one lets their text show through the letters. `.bar` is a **material**: it blurs what
is behind it rather than hiding it. Scrolled so a row sat under the pinned header, sampling the
band to the RIGHT of the label — where no header text exists at all — gave:

```
before   43-59 distinct colour bands   (the row underneath, showing through)
after     1 band, #F0F3F6              (the page)
```

The comment named the exact defect it was failing to prevent, and nothing checked it.
`PinnedSectionHeaderTests.testTheHeaderSurfaceIsFullyOpaque` now resolves the token in both
appearances and asserts alpha 1, so the claim is a guard rather than prose.

**The geometry E actually saw.** A row through the header and a row through the card beneath gave
`header #F9F9F9 / card #FFFFFF / page #F0F3F6`, all spanning x 16.0 → 386.0pt — so the strip was a
THIRD surface, neither page nor card, with SQUARE corners resting on a 16pt-rounded card. Nine
units off the page is too little to read as a deliberate surface and too much to disappear. In dark
it was worse: `#242A30` against a `#181820` page. **The fix is subtraction** — paint it the page,
and the rectangle stops existing because its fill and the 16pt gutters either side are the same
colour. A pinned header now looks exactly like every other `sectionLabel()` in the app.

**Raised, not silently fixed:** `cardEdges()` is file-private in `PlaceAppPickerView` while
`TaskListView` hand-rolls the identical card treatment (clip + `CardSurface` + `CardBorder`, 16pt
continuous). That is the same dead-shared-component shape one layer over, but it is a CARD, not a
header, so it is out of this block's scope. E's call whether to promote it to `Theme.swift`.

---

## Bottom search arc — E's design, settled 2026-09-03 (branch `feature/bottom-search`, off `main` @ `8d895d1`)

**Why this exists: the Tools arc created it.** E photographed "a peculiar box below the menu nav
tab bar" on Tasks. It is **iOS 26's `.searchable` field**, which iOS 26 renders as a capsule pinned
to the bottom of the screen and docks into a `TabView`'s bar where one exists. **Block 1 of the
Tools arc deleted the `TabView`** (it folds a sixth tab into "More"), so the capsule stands alone
and lands UNDER the custom bar. Measured on E's iPhone 15 Pro: bar inset 12 / bottom 809pt; the
stray outline inset ~30 / bottom 823pt. Reproduced and removed on the simulator, controlled both
ways. **It was introduced in Tools block 1 and only became VISIBLE in block 2**, because the
resting bar is a full-width opaque plane that covers the capsule entirely.

**It is not merely cosmetic: Tasks search is currently UNREACHABLE** — the field sits under the bar
and cannot be tapped.

**The full build plan — per-block files, TDD targets, traps — is
`Momentum-v3-Design-Handoff/SESSION-OPENER-bottom-search-build.md`. Read it before starting.**

**E's settled decisions (four questions, answered 2026-09-03 — do not re-litigate):** search stays
at the BOTTOM (E was offered the navigation bar and rejected it) and moves ABOVE the custom tab
bar into the capture disc's band; **one row, field filling the leading width, disc at the trailing
end, centres aligned**, with the **60pt gap between the bar top and the capture stack preserved**
(E asked for this by name); **always visible** where a screen has search; scope is **Tasks,
Captures AND Journal**; and focus opens a **FULL-SCREEN search surface**, not an in-place filter.

**Two facts that shape the whole build:** the field must be **ours** — iOS 26 owns that capsule's
placement and will not move it, and `.navigationBarDrawer` (which does clear the box) puts it at
the top, which E rejected. And because focus opens a full-screen surface, **the row's control is a
Button styled as a search field and never takes focus** — so no keyboard ever displaces the bar or
the disc. That is the arc's biggest simplification; do not build a live `TextField` into the row.

### FEATURE: F-Search-1-Row — the row, the surface, and Tasks  [x] COMPLETED

Build the shared machinery and prove it on one screen. `.searchable` comes OFF `TaskListView`
(that is the bug fix); a field-shaped Button joins the capture disc in one `HStack` inside
`RootBottomOverlay`, so alignment is by construction rather than two views agreeing on a number.
Tapping it opens a full-screen surface that `TaskListView` presents itself — **the ROW is
app-level, the SURFACE is screen-level**, which avoids hoisting `TasksService` up to `RootView`.
Filtering goes through the EXISTING `TaskListRefinement.apply(tasks:searchText:)`; do not write a
second filter.

**The trap that will bite first:** `AppTabContent` keeps every visited tab alive, so
`.onAppear`/`.onDisappear` fire once and then effectively never again — any "register my scope when
I appear" design is silently broken. **Drive the scope from `selectedTab`,** which `RootView`
already owns.

**The clearance problem:** `CaptureDiscMetrics.clearance` is 92 and eleven files lean on it. The
three searchable screens need more room than the other eight. **Extend the existing helper
(`captureDiscClearance(hasSearchRow:)`) rather than adding a second spelling** —
`CaptureDiscClearanceCallSiteTests` must keep passing.

**Acceptance criteria**
- [ ] `AppSearchScope` TDD-pinned: `.tasks` for the Tasks tab and `.none` for every other; every
      scope carries a non-empty placeholder; every `AppTab` is answered. **Only `.tasks` exists in
      this block** — `.captures`/`.journal` arrive with their screens, so the surface's exhaustive
      switch forces each to be handled rather than shipping two cases nothing renders.
- [ ] `AppSearchModel` TDD-pinned: changing scope CLEARS the query and CLOSES the surface; opening
      on `.none` is a no-op.
- [ ] Metrics TDD-pinned: the field is ≥44pt (§3), the search-row clearance is strictly greater
      than the plain one by exactly the row plus its spacing (derived, not a second typed number),
      and the disc's 24pt trailing margin is unchanged.
- [ ] The stray iOS 26 capsule is GONE from Tasks — proven by rendering the bottom band, not by
      reasoning.
- [ ] Row above the bar, field leading, disc trailing, centres aligned; the 60pt gap unchanged.
- [ ] Tapping opens the surface, Cancel returns, the query filters through the existing refinement.
- [ ] The row appears on Tasks and nowhere else in this block.
- [ ] A call-site guard: `.searchable(` appears in NO tab-root file, permitting only
      `PlaceAppPickerView.swift` (sheet-presented) by name. Strip comment lines before searching.
- [x] Suite green (2,201 / 0, 56 skipped), lint 0 / 631, sim + device builds green, red-checked
      (three regressions → three failures), committed, pushed, installed and launch-verified.
- [ ] **Stop for E's device verdict on the row's position and spacing before block 2.**

**⚠ THE BUG THE RENDER FOUND, and it is bigger than the feature: THE CAPTURE DISC HAS BEEN SITTING
ON THE TAB BAR.** `RootBottomOverlay` is an `.overlay(alignment: .bottom)`, and its `.bottom`
resolves to the screen's **original safe area** — NOT to the top of the bar, even though the bar is
applied as a `safeAreaInset` above it. The file's own comment asserted the opposite and
`testTheBottomFurnitureIsLiftedFromTheTopOfTheBar` was written to enforce it, so the 60pt lift was
measured from the home indicator: on E's iPhone 15 Pro the disc's 60pt frame ended at **758pt**
against a bar top of **751pt** — a **7pt overlap**.

E reported it in passing while approving this row (*"I just wanna make sure that you have added
spacing between the top of the menu/nav tab bar and the collapsed pill"*) and **Claude Code
answered, wrongly, that the 60pt gap was real and deliberate.** It was not. Proven by a controlled
probe rather than by reading: adding the bar's height moved the disc's frame bottom from 779.8 to
721.8 against an unchanged bar top of ~772. The lift is now
`AppSearchRowMetrics.bottomFurnitureLift` (gap + `AppTabBarMetrics.rowHeight`) and the guard is
inverted, with the measurement recorded as its reason.

**Also worth keeping:** `CaptureDiscClearanceCallSiteTests` failed the moment Tasks changed which
form of the clearance it calls — the guard working. It was made STRICTER rather than looser: the
table now carries `(file, expected call)` per screen, plus a second test that only screens which
actually draw the row may reserve its height.

### FEATURE: F-Search-2-Captures — Captures adopts the row  [~] BUILT, THEN REVERTED ON E'S CALL

New behaviour, not wiring: `CaptureInboxService` has no search state and no capture filter exists
anywhere (grepped). Add `CaptureSearchRefinement` in `TaskListRefinement`'s shape and a surface;
add `.captures` to the scope.

**The test that matters:** a capture has a title OR content and may have neither (photo captures).
`CaptureRowPresentation.primaryText` already owns that fallback, and **a photo capture rendering
blank is a bug this repo has already shipped once** (`eddef9b`). Search must go through the same
presentation rule rather than re-deriving it, or photo captures become silently unmatchable.

**⚠ BUILT AND THEN REVERTED, 2026-09-03. E's call after seeing it on device: *"I dont think it
works at all. How about remove it from the capture page for now?"* — and E is right for a reason
that is structural rather than cosmetic.**

**The Captures tab is not a list you scan; it is a one-at-a-time DECISION screen.** Its bottom half
is where the decisions live — the Task it / Journal it / Skip stack, the Sorted + undo bar, the
"where does this live?" area picker. E's screenshots show the floating field landing squarely on
top of them: over the triage card's THEN section in one, over a photo capture's image and its tags
in another. A persistent field there competes with the exact controls the screen exists for.

Tasks works because Tasks IS a list you scan and its bottom is empty space. That difference is the
lesson: **the bottom search row suits a scanning surface, not a deciding one.**

Reverted whole (`72e7b77` reverted) rather than left unwired — an unreferenced
`CaptureSearchRefinement` + `CaptureSearchSurface` is precisely this repo's most repeated defect.
The work is intact in history and can be restored the moment a placement is agreed.

**What the block proved and is worth keeping when it returns:** matching must go through
`CaptureRowPresentation`, because a capture may have no title AND no content and would otherwise
be visible-but-unfindable — the quiet form of the blank photo-capture card from `eddef9b`. The
red-check confirmed it by name.

**Original acceptance criteria, all met before the revert** (suite 2,218 / 0, lint 0 / 634,
red-checked with three regressions → seven failures, installed and launch-verified):
- [x] Matching went through `CaptureRowPresentation`.
- [x] Trimmed / empty-query / order / no-match behaviour matched `TaskListRefinement`.
- [x] Shared row and surface, no second copy.
- [x] Suite green, lint 0, builds green, red-checked, committed and pushed.

### FEATURE: F-Search-3-Journal — Journal adopts the row  [ ] UNCHECKED — ⚠ RECONSIDER FIRST

**Do not start this without asking E.** The Captures revert above applies here with MORE force,
not less: the Journal tab's bottom furniture is the "One line about today…" composer — a field.
Putting the search row in that band would place a field immediately above another field, on the
one screen whose bottom is already spoken for. It is the same objection E raised for Captures,
and the same reason (a deciding/writing surface, not a scanning one).

The honest reading of E's feedback is that the bottom search row belongs on **Tasks alone** unless
a different placement is designed for the other two.

Same machinery, plus the wrinkle only this screen has: the Journal timeline interleaves logs,
tasks and focus sprints, so **what search covers must be decided and stated, not left ambiguous**.
Log text only is the honest default — it is what a person means by "search my journal" — and the
surface's empty state should say so.

**Also:** the Journal composer is a `safeAreaInset` inside its own `NavigationStack` and already
calls `appTabBarClearance()`. It now has to clear the search row too, and
`AppTabBarCallSiteTests` enumerates that call site — **grow it in the same commit**, or the
composer's caption line goes back under the furniture, which is exactly what E photographed during
the Tools arc.

**Acceptance criteria**
- [ ] Journal search covers log text, and the surface says so where results are empty.
- [ ] The composer clears the tab bar AND the search row; the call-site test is updated in the
      same commit.
- [ ] Suite green, lint 0, builds green, red-checked, committed and pushed.

---

## Routines arc — E's design, settled 2026-09-03 (branch `feature/routines`, off `main` @ `218d289`)

E's top-priority feature: a place's tap-actions, run in saved order, become a **routine** — one
notification per qualifying crossing opens an ordered, tap-through routine screen. **E authorised
adding these blocks on 2026-09-03** ("yes go ahead and queue the feature blocks into the TODO").

**The full build plan — settled semantics, hard constraints, per-block detail, audited traps — is
`Momentum-v3-Design-Handoff/SESSION-OPENER-routines-build.md`; a fresh session starts at
`START-HERE-routines-build.md`. Read them before starting.** These blocks are the tracked,
tickable summary, not the whole spec.

**E's settled decisions, not to be re-litigated:** place-scoped (Option A; first-class routines +
time triggers are ARC 2); routine notification at **2+ tap-steps** (one keeps today's direct
notification; below iOS 17 keeps the per-action spray); run lives **until departure** (departure
runs: 30-min window; lazy end-of-day sweep, no timers); **autoRun steps pre-ticked**; task nudges
stay a SEPARATE, visually distinct notification species; Undo over confirm everywhere; **zero
wire/schema changes and nothing to republish, all arc**; display Live Activity in-arc, its
buttons are the fast-follow. E's field walk gates the merge.

### FEATURE: F-Routines-1-Order — drag-to-reorder + the pure core  [x] COMPLETED

Reorder support on the place actions editor (order = array order, already persisted), the
`PlaceRoutinePlan` pure type, `RoutineDefaults` (threshold 2, departure window 30 min — named,
never magic), and the stale startSprint footer copy fix (`PlaceActionsEditorView.swift:207`).

**Acceptance criteria**
- [x] Actions ForEach reorders — plain `.onMove`, NO editMode: the sim probe showed scoped
      `.environment(\.editMode, .constant(.active))` renders no grips on iOS 26 (visually
      inert) while long-press drag reorders fine without it, Button rows included, and
      swipe-to-delete/taps unaffected; the automation-guide ForEach does NOT move (pinned:
      exactly one `.onMove` in the file).
- [x] Reorder round-trips through the REAL Firestore codec preserving order; `makePlace` still
      threads actions AND their order (strip-risk pinned both ways).
- [x] `PlaceRoutinePlan` decides ordered steps + the ≥2 threshold, fully pinned (membership
      reuses `PlaceActionPlan.split`, so the two layers cannot disagree).
- [x] Sprint footer copy corrected ("Arrives as a notification — tapping it starts the
      sprint.") and pinned by source: only createCapture and journalLine may claim to run
      by themselves.
- [x] Suite green, lint 0, builds green, red-checked, committed and pushed.

### FEATURE: F-Routines-2-Notify — run store + one notification at 2+  [x] COMPLETED

`RoutineRunStore` (UserDefaults; create/end/newest-wins/30-min-window/lazy-sweep transitions —
the future smart-skip sensing seam) and the handler branch: at ≥2 tap-steps (and iOS 17+), write
the run BEFORE posting ONE routine notification (`placeRoutine-` prefix — the `placeAction-`
prefix is greedy; own `UNNotificationCategory`; userInfo = minted run UUID only).

**Acceptance criteria**
- [x] Run lifecycle transitions sit BEFORE the cooldown guard and OUTSIDE `isEnabled()` — pinned
      by the stacked-cooldown fixture (arrive→leave→return→leave inside 30 min); creation obeys
      the same placement (newest wins), so a bounce-return inside the cooldown still puts the
      routine back on Today while posting nothing.
- [x] Kill-switch OFF still writes the run; only the notification honours it (stated to E at the
      stop). Cooldown CONSUMPTION unchanged: a silent run write alone does not consume.
- [x] Below threshold and below iOS 17: existing paths byte-identical (regression-pinned; the
      per-action tap payload compared by decoded action — JSON key order is nondeterministic).
- [x] Routine body absorbs message + auto-run report (phrasing pinned); `ArrivalNudgeContent`
      gains the tasks-only fifth path (nil when no tasks).
- [x] Tray hygiene: that place's delivered `placeAction-` notifications removed on routine post
      (removal rides the post — switch off touches no tray); `ImmediateNotifying` widened as
      protocol requirements (all four conformers updated).
- [x] Interim inert tap reported to E at the stop.
- [x] Suite green, lint 0, builds green, red-checked, committed and pushed.

### FEATURE: F-Routines-3-Screen — the door and the screen  [x] COMPLETED

`PlaceRoutineNotificationRouter` (pending-door replay; own delegate branch; signed-out goes
pending), the `RootView` door (17+ gated fullScreenCover; `RootView+Doors.swift` split with the
private→internal demotions — `HomeView.arrangeAreas` precedent), and the routine screen per the
canvas Main board: pre-ticked auto rows, dominant next-step card (48pt), Skip, Undo chips,
progress semantics AS PINNED IN THE PLAN, stale-tap → Today.

**Acceptance criteria**
- [x] Cold-launch and signed-out taps drain correctly (`PlaceRoutineNotificationRouter`, the
      third pending-door replay); a stale/missing/broken run key opens Today, pinned — the door
      resolves the tapped UUID against the STORE, so a blank routine screen is unreachable.
- [x] Step taps run through the EXISTING action plumbing (`PlaceActionTapRoute` +
      `PlaceLinkOpener`); sprint steps start in the foreground, which is why startSprint is a
      tap-step at all.
- [x] Progress/Skip/Undo/completion behave exactly as the plan's pinned semantics — "N of M
      done" excludes skipped, the bar's resolved fraction includes it, auto-done is immutable,
      and a fully-resolved run ends when the screen LEAVES (dismiss or background), never at the
      final tap, so Undo lives until then.
- [x] A11y: rows are combined elements, the step circle is `accessibilityHidden` because the
      SUBTITLE words carry the state (never colour alone), semantic Dynamic Type throughout.
- [x] Sim-driven end-to-end via the DEBUG test-fire button — `RoutineJourneyUITests`, an
      emulator-backed journey covering blocks 2+3+4 together: seed a 4-action place, test-fire
      the arrival, find the card on Today, Continue into the screen, Skip, Undo, resolve
      everything, close, and watch the card go. Screenshots attached at six stops.
- [x] Suite green (2,271/0), lint 0/651, builds green, red-checked, committed and pushed.

### FEATURE: F-Routines-4-HomeCard — the way back in  [x] COMPLETED

Today card while a run is live ("At <place> · routine live", steps left, next step, Continue →
the screen); gone when no run. `HomeView.swift` is at 391/400 — card content in its own file,
extract in the same commit if needed. While a run is live for a place, its `ArrivalSurfaceCard`
is suppressed (decided; E can veto at the stop).

**Acceptance criteria**
- [x] Reachability proven by a real journey, not just greps: the card is FOUND on Today after a
      test-fired crossing, Continue opens the screen, and the card is GONE once the routine is
      finished — plus `HomeRoutineCardCallSiteTests` pins the render site, the refresh site and
      the router door in source.
- [x] Card appears only while live; Continue opens the screen through the same router door the
      notification tap uses (the `PlaceActionNotificationRouter.open` precedent — no new
      parameter threaded through HomeView); suppression rule pinned.
- [x] Lint stays 0 (654 files). `HomeView.swift` tipped to 402 and was brought back to 398 by
      moving the rationale into `HomeRoutineCard.swift`, where the code it explains lives.
- [x] Suite green (2,289/0), builds green, red-checked, committed and pushed.

**Three real defects the journey caught that unit tests could not**, all fixed here:
- `onDisappear` did NOT fire reliably for the full-screen cover, so a finished routine kept its
  Today card. Every deliberate exit now calls `leaveScreen()` itself; the callback is only a net.
- The card's refresh was sequenced BEHIND `await CurrentPlaceResolution.current()`, so a cheap
  UserDefaults read waited on a CoreLocation fix. It now runs first.
- Home had no foreground refresh at all, and a routine of only tap-steps writes nothing to
  Firestore — so a crossing during backgrounding left the recovery surface stale in exactly the
  case it exists for. Added, and the handler now announces run lifecycle like every other change.

**A11y defect found while wiring the journey** (fixed): the routine screen's header combined its
children INCLUDING the close button, which would have left a VoiceOver user inside a full-screen
cover with no way out. The combine is now scoped to the title and subtitle alone.

### FEATURE: F-Routines-5-LiveActivity — the display anchor  [x] COMPLETED

Second `ActivityConfiguration` in the widget extension (16.1 floor): place, done/total, next
step, progress. STARTS when the routine screen opens (ActivityKit cannot start from background —
do not "fix"); updates on step changes; ends on run end (verify background end). Tap-to-return
via `widgetURL`. NO buttons (settled fast-follow).

**Acceptance criteria**
- [x] Shared attributes file added to the pbxproj `membershipExceptions` (both targets compile);
      pinned by `RoutineActivityCallSiteTests` so a "cannot find type" in the extension can never
      be mistaken for a code problem again.
- [x] `Color("AccentColor")` explicit, and `Color.accentColor` asserted ABSENT from the code (the
      LA ignores the widget's global accent).
- [x] Activity lifecycle matches the run store on sim — proven by an ActivityKit probe run on the
      simulator: `areActivitiesEnabled=true`, `REQUEST_OK … count=1`, `afterEnd=0`. **The
      simulator does not composite a Live Activity onto the Home Screen island or a freshly
      booted lock screen, so there is no sim SCREENSHOT of it — E's field walk on the 15 Pro is
      the visual gate, exactly as the plan says.** The probe was deleted at close-out (it
      XCTFails by design) and ended what it started.
- [x] Tap returns via the widget-link door: `AppDeepLink.routineScreen`, resolved against the
      STORE like the notification tap, so a stale card lands on Today rather than a blank screen.
- [x] Suite green (2,304/0), lint 0/662, builds green, red-checked, committed and pushed.
- [x] Full re-run → `--no-ff` merge → re-verify ON main → pushed. **MERGED `0cea871`
      (2026-09-05)**: unit 2,326/0, lint 0/672, both targets build, verified ON main before the
      push. Merged on the BISECT evidence at E's direction — the UI target's remaining failures
      were re-run at `2c46ee7` and reproduce there, so they predate the arc and sit on main
      either way. Branch KEPT (E's call, asked and answered).
- [x] E's Block A field walk — **ALL EIGHT CHECKS PASSED 2026-09-05**, evidence inline in
      `Momentum-v3-Design-Handoff/ON-DEVICE-CHECKLIST-blockA-2026-09-05.md` (1-2 by E on device,
      3-8 by Claude Code via mirroring + Firestore-as-ledger + a real simulated fence crossing
      with an on-control). The light-mode keyline question is CLOSED with photos: iOS suppresses
      `keylineTint` in light appearance, so no colour change can or need fix it.
- [x] `wishwashwacky15` carries the current tree — reinstalled 2026-09-05 at `1ab5ff2`, whose
      tree is byte-identical to main at `511e55b` (`git diff` between them is empty).

**Two things found while wiring it, both fixed:**
- The presenter was constructed inside a `@ViewBuilder`, so every re-render replaced the object
  holding the ActivityKit handle — updates and the end would have quietly no-opped, stranding a
  Lock Screen card nothing could move. It is now a shared instance, pinned by test.
- The bundle registered the widget behind `if #available(iOS 16.1, *)`. The extension's floor IS
  16.1, so the gate bought nothing, and a conditional in a `WidgetBundle` body can silently drop
  the widget from the bundle — it compiles and simply never registers.

---

### FEATURE: F-Routines-B-ToolsSection — Routines gets its own section on Tools  [x] COMPLETED

**E's ask, 2026-09-05: "the routines section deserves its own 'Routines' section on the Tool
list."** Placement and naming were settled by that sentence; the DATA MODEL was not, so the scope
was put to E as a rendered proposal before any Swift, and **E answered "go with your
recommendations" (2026-09-05)**, taking all four: an inline section rather than a third card, the
count-only row copy, the always-shown two-flavour empty state, and a branch
(`feature/routines-tools`, off `main` @ `705fb43`).

**The version that needs no new entity, and that is the point.** A routine still has no
independent existence — it IS a place's actions for one direction, computed by
`PlaceRoutinePlan.make` — so the section lists one row per place+direction that clears
`RoutineDefaults.stepThreshold` tap-steps. **First-class routine records remain Arc 2 and are NOT
authorised**, and the [[routine-record-gap]] work (offered / accepted / completed history) stays
parked for E's own session — this block deliberately records nothing.

**Acceptance criteria**
- [x] `ToolsRoutinesCatalog` is pure and TDD'd first (16 tests, red → green): membership, the
      count, the two empty states, order, identity and glyph. It **decides nothing** — membership
      is `plan.qualifiesAsRoutine` and the count is `plan.tapSteps.count`, so the row, the
      notification and the Today card cannot disagree about one routine.
- [x] Rows are computed by `PlaceRoutinePlan.make`, never a re-implemented "≥ 2" in the Tools
      layer, and ordered by `PlacesService.sorted` — the Places list's own comparator, reused not
      copied — with arrival before departure within a place.
- [x] Auto-run steps are counted nowhere and cannot carry a place over the threshold;
      `.unsupported` actions from a newer build neither count nor appear.
- [x] Two empty states, not one, because they are two problems with two different next actions:
      no places at all, and places with too few tap-steps. Shown rather than hidden — a section
      that vanishes when empty can never teach the rule that fills it, and a brand-new account is
      in exactly this state.
- [x] A row opens the place editor sheet, whose Actions section with drag-to-reorder IS the
      routine editor under E's settled Option A. No second editor was invented.
- [x] The section sits behind the SAME iOS-17 gate as Places, through a real `if #available` —
      `placesSupported` is a `Bool` and cannot narrow a type's availability.
- [x] **Reachability is the acceptance test** (this repo's most repeated defect, six instances):
      six call-site guards in `ToolsPageCallSiteTests` read the comment-stripped source and pin
      that the page renders the section, the section asks the catalog, neither Tools file reaches
      for `tapSteps`/`stepThreshold` itself, a row opens the editor, and the empty state's push
      clears the capture disc.
- [x] `ToolsCatalog` still pins TWO CARDS — Routines is a section, not a third door — and both
      its own doc comment and `ToolsView`'s were rewritten, since both described a sparse page
      waiting for exactly this and would otherwise have become stale the moment it arrived.
- [x] **`ToolsRoutinesJourneyUITests` is the block's real proof** — three emulator-backed
      journeys that walk all three states in the REAL app: a fresh account seeing the first-run
      empty state, a one-step place getting the OTHER empty state (the discriminator — it also
      asserts the first-run one is absent, so a single generic message cannot pass both), and a
      qualifying place appearing as a row that reads "Gym · 2 steps" and opens the real place
      editor. Screenshots attached at four stops.
- [x] The journey was RED-CHECKED too, not just written: with the section unrendered, both the
      empty-state and the row journeys fail. A journey that passes on a broken build is this
      repo's `geometry-journey-vacuity` lesson, and this one is not vacuous.
- [x] Suite green (2,348 / 0, up 22), lint 0 / 677, both targets build, red-checked with counted
      injected regressions (3 injected → 4 failures, each the guard aimed at it), committed and
      pushed.

**Deliberately NOT built, offered and declined by omission:** a permission-banner footer warning
that a listed routine can still never fire (nudge master switch off, or location not Always). It
was put to E as an optional extra and is not part of the recommendations E accepted.

---

## The routine record — E's design, settled 2026-09-06 (branch `feature/routine-record`, off `main` @ `ebc5865`)

**E's ask (2026-09-05): "clearly differentiating between a Routines Arrival, a Routines Accepted
and when a Routine is completed."** Verified: no routine path writes anything durable. E picked the
real `routine_runs` collection over journal rows, then answered eleven questions in three rounds;
the record and the why is `handoff/SESSION-OPENER-routine-record-design.md`. **Read it first.**

**E's settled decisions, not to be re-litigated:** ignored/swiped OFFERS ARE recorded — an
explicit exception to Block A's "no trace" (Block A's other half, no auto-step and no journal line
until the tap, stands); a Journal header switch "All activity", off by default, reveals offered
rows muted; started and finished rows are always visible under Everything, TWO rows per run, the
arrival row kept beside them; unfinished runs read gently ("· 2 of 4 done", never "abandoned");
swiped vs timed-out offers share a row with different subtitles ("· cleared" / "· not opened");
the Tools Routines row gains a last-run line; the run-store sign-out leak is folded in. Rules
change → **E republishes**.

### FEATURE: F-RoutineRecord-1-Ledger — the collection, the seam, the six write points  [x] COMPLETED

`RoutineRunRecord` (Codable, snake_cased, `FirestoreDocumentCoder` round-trip pinned, wrong
spellings asserted ABSENT), `FirebaseManager+RoutineRuns` behind a `RoutineRunsBackingStore`
protocol, the `RoutineRunRecording` seam with `FirebaseRoutineRunRecorder` and a recording fake,
`FirestoreFieldPayloads.routineRun*` for every partial update, `RoutineRunReconciliation` (pure),
the six write sites, `routine_runs` in `firestore.rules` and `Collection`, and the per-user run
store key.

**Acceptance criteria**
- [x] `RoutineRunRecord` round-trips through the REAL codec with every field in the design
      record's table; the payload tests assert `place_id`/`offered_at`/`dismissal_method` present
      and `placeId`/`offeredAt` absent.
- [x] Phase is DERIVED from the stamps (`RoutineRunRecord.phase`), pinned for every combination
      including a stray `dismissed_at` beside a `started_at` (reads started).
- [x] `completed_steps_count` equals `PlaceRoutineProgress.doneCount` for the same run — one
      truth, pinned by a test that feeds both the same fixture; `time_spent_seconds` runs to the
      last step interaction, not the end stamp (pinned with a departure an hour later).
- [x] Site 1: a POSTED routine banner writes `offered`; a crossing suppressed by cooldown, the
      kill-switch, threshold or the 17-gate writes nothing. `RoutineDeferredLoggingTests` say in
      words that the offer record is the sanctioned exception.
- [x] Site 2: the tap writes `started` + `dismissal_method: tap`; a second tap (`.open`) writes
      nothing; a replaced live run gets `ended(replaced)` first (ordering pinned via the log).
- [x] Site 3: the routine category carries `.customDismissAction` (call-site guard on the ONE
      registration); the delegate's dismiss branch writes `dismissed` + `swipe`, never starts a
      routine, never touches the tap router (pinned by a pure `RoutineDismissRouting` test and a
      source guard).
- [x] Site 4: every `apply` on the screen writes `progressed`; site 5: leaving a fully resolved
      screen writes `ended(completed)`, the departure crossing writes `ended(left_place)`.
- [x] Site 6: `RoutineRunReconciliation.updates(records:liveRunId:now:)` is pure and pinned —
      unopened offers past their lifetime → `expired`; started runs past it → `window_lapsed` or
      `day_ended`; the live run and already-terminal documents are never touched; called after
      the Journal load (Tools load joins in block 2).
- [x] Sign-out leak: the run-store key is per-user; signed out reads nil and drops writes;
      `AuthService.signOut()` and `completeAccountDeletion()` clear it (pinned).
- [x] `firestore.rules` lists `routine_runs` in the generic CRUD match; an emulator test proves
      create + update + fetch are ALLOWED for the owner through the REAL rules
      (`FirebaseManagerRoutineRunsTests`, 2 tests, run with the emulator up). The "denied for
      another user" half was NOT built: the manager only ever addresses `users/{currentUid}`, so
      proving denial would mean adding a raw-path method to production for a test's sake.
      **Not live until E republishes `firestore.rules`.**
- [x] Suite green (**2,424 / 0**, up 76, emulator up so nothing skipped), lint **0 / 693**, both
      targets build, red-checked (3 injected → 11 distinct failing tests, each the guard aimed at
      its regression; restored tree 37 / 37), committed and pushed.

**Two things found while building, neither fixed here:**
- `UserDefaultsArrivalNudgeStateStore` — the at-place SNAPSHOT (place names, custom messages) —
  has the same app-local, unscoped shape the run store had. Same leak class; on the register.
- The screen's `record { }` writes and the activator's `recordTask` are best-effort by design
  (a lost write is a gap in history, never a broken routine), so an OFFLINE run's progress reaches
  Firestore only through the SDK's own offline queue. Not verified on device.

### FEATURE: F-RoutineRecord-2-Surfaces — Journal rows + switch, Tools last-run line  [x] COMPLETED

`JournalTimeline.Entry` gains `.routineOffered` / `.routineStarted` / `.routineEnded` with a
composite `String` id; `JournalTimeline.routineLine(...)` holds every word; the "All activity"
header switch; `ToolsRoutinesCatalog.rows(from:runs:)` with the last-run subtitle; the
reconciler joins the Tools load; a UI journey that fires a crossing, walks the routine and finds
the rows.

**Acceptance criteria**
- [x] Every row's words pinned: started, finished (completed), unfinished (gentle), offered
      cleared / not opened; names resolve through the CURRENT place; dangling places drop the row;
      never under a life-area filter or a non-Everything chip.
- [x] Offered rows appear ONLY with the switch on (pinned both ways); the switch is off on
      launch and not persisted; muted styling uses tokens, never opacity.
- [x] One document → started + ended rows with distinct ids; a live run shows started only.
- [x] Tools rows: last-run subtitle from the newest STARTED record for that place+direction;
      rows without history byte-identical; the catalog still decides nothing about membership.
- [x] Reachability: call-site guards pin that the Journal renders all three kinds, the header
      renders the switch, the Tools section passes runs to the catalog.
- [x] `RoutineRecordJourneyUITests`: seeds two places, fires and finishes the gym routine,
      fires the office arrival untouched, finds `Started` + `Finished … · 1 of 4 done` on the
      Journal with the offer ABSENT, flips the switch and finds `Routine offered at Office 💼 ·
      not opened`, then reads `last run today, 1 of 4` on the Tools row. PASSED (264 s) on an
      erased simulator. Screenshots + README in `screenshots/routine-record/`.
- [x] Suite green (**2,453 / 0**, emulator up), lint **0 / 704**, both targets build,
      red-checked (3 injected → 5 failing tests, each its guard; restored 37 / 37), committed
      and pushed. **Still owed: E's device review, `--no-ff` merge, re-verify on main.**

**Two defects the journey caught, both fixed in this block — neither was in the design:**
- **A routine banner outlives a sign-out.** The third journey run tapped the PREVIOUS account's
  untouched Office banner and started that routine under the new account; every record write
  then failed server-side ("no entity to update", the emulator log). `RoutineNotificationTray`
  clears the routine species as a session ends; the default `onSessionEnding` calls it.
- **The tab-root "not hittable" defect (register B3) — mechanism found.** The failure dump had
  the HIDDEN Today tab's elements in the accessibility tree, its momentum ring over the Places
  card's centre. `accessibilityHidden` stops at each tab's UIKit navigation controller. Hidden
  tabs are now parked off-screen (`AppTabContentLayout.hiddenTabOffset`, pinned). Whether this
  also settles the UI target's unstable set is UNVERIFIED — the full UI target was not re-run.
- Also: the screen recorded `completed` TWICE (Close and `onDisappear` both end the run);
  recorded once now. And the CLAUDE.md erase rule bit in a new disguise — the tray, not the
  keychain — so the journey was run on an erased sim from then on.

**Post-walk, 2026-09-06 (end of session) — two corrections to the block above:**
- **E's call on device: the eye hides EVERY routine row**, not only offers. Implemented
  test-first in a `WIP:` commit, then FINISHED by the review session (2026-09-06): the journey
  passed on the new rule on an erased sim (206 s), `00-`/`01-` re-captured, suite **2,454 / 0**
  (emulator up), lint **0 / 704**, build green, red-checked (3 injections → 4 + 6 + 1 failing
  tests, each its guard; restored 19 / 19). The criteria above that say offered rows are the
  only hidden ones are superseded. Still owed: the phone re-install and E's device confirmation.
- **The swipe path is PROVED on device (review session, 2026-09-06).** E's walk answer ("a mix
  of both") plus zero `· cleared` rows looked like a broken dismiss branch; a controlled
  experiment (test-fire through iPhone Mirroring, E's physical Notification Centre clear, the
  document read live before and after) flipped run `6EE57B3C…` to `dismissed` / `swipe`.
  Swiping a PRESENTED banner up reports nothing to iOS — only a Notification Centre clear is a
  "swipe" — so the walk's `· not opened` rows were honest. Evidence: `screenshots/
  routine-record/09-`/`10-` and the design record's swipe section.
- **The tab-root "mechanism found" bullet is WITHDRAWN as a finding**: a later journey run on a
  build carrying the off-screen change failed identically, hidden elements still in the dump.
  Register B3 stays open.

---

## The tab bar, reopened — E's call, 2026-09-08 (branch `feature/tabbar-select-pill`, off `main` @ `e5a572f`)

E reopened the bar against the ORIGINAL canvas
(`https://claude.ai/code/artifact/767eacff-e616-4836-ab3a-ac842ddf42c9`, page "All six
options") and chose to **combine B and C**: *"I want C to be the resting state when the user is
at the top of the page. When they scroll I want to stay as B."* Confirmed "Yes, exactly that"
against the reading below. **This supersedes the Tools-tab arc's "F at rest, dot → chip"
decision**; B, the trigger, the band and the pane are unchanged. Design record:
`handoff/SESSION-OPENER-tabbar-select-pill-design.md`.

**Conflicts reported (CLAUDE.md §7):** `ui-ux-pro-max` "bottom nav ≤ 5" — still six, still E's
knowing call; C's 10pt/6pt spacing is off-grid → 8/8 under §2.

### FEATURE: F-TabBar-SelectPill — C's labelled pill at rest, B's chip scrolled, ONE floating card  [x] COMPLETED

**Round 1** put C on the flat full-width pane; E's device verdict the same night: *"the nav bar
shouldn't extend down to the bottom of the screen… must stay floating as it is in the scrolling
screenshot BUT MUST still display the labelled pill."* **Round 2 (what is built):** one floating
card in BOTH states — the opaque pane is gone for good. At rest the card sits **wider and
higher** (inset 8, lift 16) and the selected tab is a **capsule pill** holding glyph AND label;
scrolled, the card **contracts inward and drops** (inset 12, lift 8 — B, unchanged) and the mark
is B's chip. The other five slots share the width the pill leaves. `rowHeight` is now the card
plus the LARGER lift (66) so the `safeAreaInset` never moves with the morph.
`TabBarScrollActivity` already decides "near the top" with hysteresis, so the trigger is
untouched. Files: `Theme/AppTabBar.swift`, `Theme/AppTabBarPresentation.swift`,
`AppTabBarPresentationTests.swift`. E's five round-2 answers are verbatim in the design record.

**Acceptance criteria**
- [x] Pure rules TDD-pinned (12 "no member" errors on the red run, then green):
      `showsLabel(isSelected:isFloating:)` is true only for the selected slot at rest;
      `restingSlotWidth(barWidth:pillWidth:count:)` beside the widest pill on the SE is
      **46.2 ≥ 44** — the resting state's "stops a seventh tab" test (seven → 38.5); the guard
      returns 0 below two slots; the pill cap is never narrower than the chip; the pill's three
      spacings are on the 4/8/16/24 grid.
- [x] `rowHeight` still 58 and still derived — the search row lift, `bottomClearance`, and
      `appTabBarClearance()` untouched; `testTheRestingPaneIsExactlyTheFloatingStatesFootprint`
      still passes.
- [x] Identifiers `tabBar.<Label>` and `.isSelected` unchanged — no UI journey edited.
- [x] Label hidden from VoiceOver (the button carries the name); one line, `minimumScaleFactor`
      before any clip (§1); house spring, nil under Reduce Motion.
- [x] Suite **2,502 / 0** (emulator up), SwiftLint **0 / 711**, sim build green. Red-checked
      after the commit: four regressions → exactly the four predicted test cases (five
      assertions), restored with `git checkout --`, no marker left, full suite green again.
- [x] Device build with `-allowProvisioningUpdates` (no account/profile trouble), installed on
      `wishwashwacky15` at `96681a3`; launch refused only because the phone was locked.
- [x] **E's round-1 device verdict** — *"I like what you've done"*; the pane must go, the bar
      must float in both states with the pill. Answered with five questions; capsule corners
      chosen, height/label/gap kept, B's 4pt card padding kept, "wider, lower AND drops".

**Round 2 acceptance**
- [x] Pure rules TDD-pinned (7 "no member" errors on the red run): the band is the card plus the
      larger lift (`cardHeight` 50 + 16 = 66); the card is wider AND higher at rest
      (`restingInset` 8 < 12, `restingLift` 16 > 8); the pill is a capsule
      (`pillCornerRadius` = chipHeight / 2); the resting spacing is on the grid; the SE floor is
      measured inside the resting card, (375 − 16 − 8 − 120) / 5 = **46.2 ≥ 44**.
- [x] The flat pane, its 40-line history and `restingPaddingHorizontal` deleted; one card,
      inset and lift picked by `isFloating`, bottom-aligned in the band; the chip keeps radius 11
      so B is unchanged and the mark animates capsule → 11.
- [x] Suite **2,504 / 0**, SwiftLint **0 / 711**, sim build green. Red-checked after the commit;
      **three regressions together produced only two of three predicted failures — two of them
      cancelled** (`restingLift` 8 made `max(8, 8)` equal `floatingLift`); re-run with the band
      regression alone → exactly one predicted, one actual. Restored, no marker, green again.
- [x] Device: rebuilt and reinstalled on `wishwashwacky15` at `e9cd764`, launch verified.
- [x] **E's round-2 device verdict** — *"I like what you've done… some obvious spacing and
      positioning things"*, then three asks with two annotated shots: move the whole bar down a
      little, WIDEN it (marks ~6pt from the edges), more inner padding around the icon in the
      highlight. Measuring first found the card was **60pt on the device while the metrics said
      50** (the slot's 44 `minHeight` leaked into the row) — reproduced in a simulator probe.

**Round 3 acceptance** (`8578a23`)
- [x] Insets 8/12 → **4/8**, lifts 16/8 → **8/4**, highlight **44** tall in both states, pill
      inner padding **16**; `slotHitOverflow` carries §3's target without growing the card, so
      `cardHeight` 60 and `rowHeight` 68 are TRUE. SE floor (375 − 8 − 8 − 120) / 5 = **47.8**.
- [x] Probe-verified right side up: card 59.0 both states; bottom +8.7 rest / +4.7 scrolled;
      inset 4 / 8; glyph 9.3 above and 9.0 below inside the highlight (was 4.3 / 4.0).
- [x] Tests: one new (hit overflow), two updated (47.8; lift floor 4). Red first: 2 "no member"
      errors. Suite **2,505 / 0**, SwiftLint **0 / 711**, sim build green.
- [x] Red-checked ONE regression at a time (the round-2 cancelling lesson): overflow negative,
      scrolled lift 2, resting inset 12 — predicted 1 / 1 / 3, see the session report for actual.
- [x] Device reinstalled at `8578a23` (05:35, launched) and **E's round-3 verdict, 05:43:
      *"I think it looks good."*** Three approval screenshots; the 44-tall chip while scrolling
      was accepted as is.
- [x] `screenshots/tabbar-select-pill/` — rounds 1–3 filed (00–10): the rejected pane, E's two
      annotated round-2 shots, and the three round-3 approvals, each row saying what it settled.
- [x] PR #29 merged to `main` @ `76a4f47` (04:46 UTC); re-verified ON main — suite 2,505 / 0,
      lint 0 / 711, sim build green, 24.77% (11,133/44,940); phone rebuilt from main, installed
      and launched 05:52. Only `main` exists.

**Logged from E's aside, NOT this block:** *"the 'YOU'RE AT HOME' notification box at the top of
the Today page does not stay there when the user drag-reloads the Today page. Which is kind of
pointless."* → register section B as a candidate; needs its own look at the Today refresh path.

---

## Arrival card on Today — E's item, 2026-09-08 (branch `feature/arrival-card-refresh`, off `main` @ `e8d1605`)

E's report, closing the tab-bar session: *"the 'YOU'RE AT HOME' notification box at the top of
the Today page does not stay there when the user drag-reloads the Today page. Which is kind of
pointless."* E's instruction opening this one: investigate FIRST, then ask which case, then
design. **E's answer, 06:12: the task was STILL OPEN** — and E's four 06:14 screenshots
(`screenshots/arrival-card-refresh/`) show it: card with `test quick`, one pull, no card,
`test quick` still open.

**What the investigation found (live Firestore + a swiftc probe over the real geometry files):**
the opener's two hypotheses were both real but neither was the main cause. E's home holds
**three saved places with the 100 m floor radius** — `Home`, `Action Test 01/09/2026` (centre
**1.2 m** from Home's) and `routines test` (34.5 m) — and only Home ever has at-place tasks.
`PlaceResolution.place(containing:)` picks ONE place: smallest radius, then nearest centre. With
equal radii that is a coin flip per fix, and the card followed the coin: Home wins **50% at 10 m
jitter, 40% at 20 m, 31% at 40 m** (100% / 100% / 96% with Home alone). Every fix succeeds; the
card still goes on most pulls. Secondary: a fix that never arrives (8 s timeout, a request
already pending, airplane mode) also overwrote the card with nil.

### FEATURE: F-ArrivalCardRefresh — the card considers every containing place, and a refresh replaces it only when a fix says otherwise  [x] COMPLETED

Two pure rules, TDD-pinned, no visual change:

1. **"Here" is EVERY place the fix fell inside, tightest first.** `PlaceResolution.places(
   containing:in:)` returns the ordered list (`place(containing:)` is now its head, so the two
   cannot disagree); `ArrivalSurface.make(currentPlaces:tasks:)` shows the first containing place
   with something open. A test place 1.2 m from Home can no longer hide Home's work.
2. **A refresh replaces the card only when a fix positively says otherwise.**
   `CurrentPlaceResolution.current()` now reports what it knows — `.off` (toggle off, no
   permission, no saved places), `.noFix` (fix or places fetch did not arrive), `.inside([Place])`
   — and `ArrivalSurface.refreshed(previous:fix:tasks:)` applies it: `.off` clears; `.noFix` keeps
   the previous card re-checked against the fresh tasks (closed work drops it, new work joins
   it); `.inside([])` is the one honest "you have left" and clears; `.inside(places)` rebuilds.
   The fix provider is injectable (`provider:`), so every outcome of the gate has a test.

**Acceptance criteria**
- [x] Tests first, watched red: `LocationStampingTests` (+3: the ordered list, equal radii by
      centre distance, outside → empty), `ArrivalSurfaceTests` (+4: E's real three-place shape,
      both-with-work → the tighter one, nothing open → nil, inside none → nil),
      `ArrivalSurfaceRefreshTests` (new, 15: eight refresh-rule cases, seven resolution-gate
      cases). RED: `type 'PlaceResolution' has no member 'places'`, then `no member 'refreshed'`
      / `extra argument 'provider'` — the missing members, not typos.
- [x] `refreshArrivalSurface()` applies the fix to the card already showing.
- [x] Touched-file lint clean (`.at` → `.inside` for `identifier_name`; `HomeMomentumSections`
      back to 399 lines); full `swiftlint lint` **0 / 712**.
- [x] Suite **2,526 / 0** (emulator up, 0 `9099` hits), sim build green, app target **24.82%
      (11,162/44,965)** — denominator +25 (the new rules), numerator +29, comparable. Committed
      `4d8de11`, THEN red-checked one regression at a time: no-fix → nil predicted 2 / actual 2;
      first-place-only predicted 1 / actual 1 (its three assertions); restore proven 39 / 0.
- [x] Device: built from the branch at `4d8de11`, installed and relaunched on `wishwashwacky15`
      06:38 (binary mtime 06:37).
- [x] **E's device verdict, 06:5x: *"the card does stay across repeated pulls."*** The only
      verification that reaches the coin flip, and it passed. No after-shot was supplied; the
      verdict is the record (README says so).
- [x] PR #32 merged to `main` @ `99d9211`; branch deleted by the merge; re-verified ON MAIN
      (lint 0 / 712; suite figures in the register's tenth edition). Phone stays on the `4d8de11`
      build — the merge touched no Swift, so it is functionally main.

**Deferred, on record (not this block):** a fix that ARRIVES but lands outside every radius
(a poor-accuracy cell fix; the app ignores `horizontalAccuracy`) still clears the card — the
probe puts that at ~3% of pulls at 40 m jitter with Home alone, 27% at 65 m. If E still sees
drops after this lands, accuracy-aware containment for the card is the next lever.
`HomeService.load()` also empties `allTasks` on a failed fetch, which would drop the card
through the re-check; the inbox precedent keeps last-known on failure, and this should too.

**Logged from E's aside at 06:20, NOT this block:** *"we need to remove the 'search tasks'
search bar from a full view task screen"* — `02-task-detail-at-place-home-open.jpeg` shows the
Tasks tab's bottom search row still on screen with a task detail pushed. → register section B.

---

## Tab depth arc — E's two navigation asks, 2026-09-08 (branch `feature/tab-depth`, off `main` @ `38b309c`)

E, 06:20: *"remove the 'search tasks' search bar from a full view task screen."* E, ~07:00:
*"The nav bar tab items need to direct the user back to that tab item's top-level page. Example:
when on the Today tab, if the user navigates into 'Nudges', there is no way to get back to the
Today main page. If the user taps the tab they are already on, BUT THEY ARE NOT AT THE TOP-LEVEL
PAGE then that tab needs to return to the top-level page."* Asked four questions; E took the
recommended answer to each: **scroll to top on a re-tap at the top level; Nudges gets a visible
Back control; sheets are untouched; one arc, pop-to-root first.**

**What the investigation found:** the bar's button only sets the selection, so a re-tap is a
no-op by construction. No tab holds a navigation path the root could reset. Today's Nudges
screen hides the navigation bar and draws no back control, so the edge swipe was the only way
out. And a simulator probe (`scratchpad/navprobe`, iOS 26.5, photographed) settled what CAN pop
what: a closure-link push and a flag push are invisible to the stack's `NavigationPath`
(`count` stays 0) and **a path reset pops neither**; clearing a flag pops its screen; a value
push counts and a reset pops it; and a closure push NESTED above a value or flag screen
collapses with it. So the root cannot pop anyone's stack from outside — each root must pop
itself — and Tools, whose top-level pushes were closure links, had to change how it pushes.

### FEATURE: F-TabDepth-1-PopToRoot — a re-tap returns to the tab's top-level page, or scrolls to the top there; Nudges gets a Back control  [x] COMPLETED

- `TabNavigation.swift`: `TabReselectionResponse.response(isAtRoot:)` (the rule),
  `TabNavigationCoordinator` (re-tap counts DOWN, depth UP; `isAtRoot` defaults true),
  `TabRootScrollAnchor`, and `.tabRoot(_:isAtRoot:onPopToRoot:)` — a `ScrollViewReader`
  modifier every tab root applies INSIDE its stack.
- `AppTabBarPresentation.tapOutcome(current:tapped:)` — select vs reselect; `AppTabBar` routes
  through it and calls `onReselect`; `RootView` owns the coordinator and injects it.
- Six roots wired: Today (four flags + a `homePath` for the value pushes, in `HomeView+TabRoot`),
  Tasks (one flag), Areas (a flag + `areasPath`), Journal (two flags), Captures (one flag),
  Tools (ONE flag — its two closure links became a `pushedDestination` flag push; the closure
  links deeper in that stack collapse with it, per the probe).
- `NudgesView` shows the bar with only `TaskDetailView`'s Back chevron on it (empty inline
  title, hidden background).

**Acceptance criteria**
- [x] Tests first, watched red (`cannot find 'TabReselectionResponse'`, `'TabNavigationCoordinator'`,
      `no member 'tapOutcome'`): `TabNavigationTests` (8), `TabNavigationCallSiteTests` (6 —
      every root calls the modifier and carries the anchor, the bar routes through the rule,
      RootView injects, no pushed screen hides the bar without a back control, Tools pushes by
      flag), and `TabReselectionJourneyUITests` (3 — E's Today → Nudges → re-tap journey, the
      Nudges Back control, and the top-level re-tap scrolling by FRAME).
- [x] Scoped unit run GREEN: 50 / 0 across the two new classes plus `AppSearchCallSiteTests`
      and `AppTabBarPresentationTests`. Touched-file and full lint **0 / 717**.
- [x] **The UI journey GREEN as one class run — 3 / 0 (452 s), the tenth run; sim ERASED after
      every one of the ten.** Everything the journey caught was in the HARNESS or the journey,
      never the app: `UITestSession.openTab` returns early on an already-selected slot, so it had
      never re-tapped (`reTapToday`); `staticTexts["Today"]` matched the tab bar's pill label
      (`homeTitle`); the first anchor overshot by 16 pt AND added 16 pt of dead space at the top
      of every tab (`.tabRootScrollAnchor()` on the padded root); a fresh account's Today is too
      short to scroll until its sections load; and the late "Save Password?" sheet swallowed a
      Back tap, then a door tap ("not hittable" on a door that existed at y = 542), then two
      swipes — the journey now waits for HITTABLE, sweeping the sheet and any springboard alert
      before every tap and swipe it depends on (`openNudgesFromToday`, `settleSystemSurfaces`).
- [x] Full suite **2,540 / 0** (emulator up, 0 `9099` hits), lint **0 / 717**, sim build green,
      app target **24.76% (11,188/45,189)** — denominator +224 (the new view code; the two new
      files are view state the journey reaches, not a unit test). Committed `639cf24`, THEN
      red-checked one at a time: rule-always-scrolls predicted 1 / actual 1; Tools-forgets-the-
      modifier predicted 1 / actual 1; restore proven 14 / 0. One earlier full-suite failure was
      `ToolsPageCallSiteTests.testTheEmptyStatePushClearsTheCaptureDisc` reading the OLD Tools
      push; rewritten to follow the new three-link chain (section → `onOpenPlaces` → ToolsView's
      `.places` destination with the clearance).
- [x] Device: built green at `96aa629` (09:00); the first install FAILED — **E's phone was out
      of storage** (`No space left on device`) — E freed space and it installed and relaunched
      **09:22**. The phone is on the branch build.
- [x] **E's verdict on the phone, 2026-09-08 evening: *"All 4 checks were successful."*** (Today
      → Nudges → re-tap; the Nudges Back chevron; a re-tap at the top level scrolling up) —
      deferred by E to the same sitting as block 2, with E's screenshot of the chevron filed at
      `screenshots/tab-depth/00-`.
- [x] PR #35 open (`https://github.com/digdiggydigger/ADHDLifeOS/pull/35`), awaiting E's device
      verdict. Register + opener at close-out.

### FEATURE: F-TabDepth-2-SearchRowAtRoot — the bottom "Search tasks" row hides while a task detail is pushed  [x] COMPLETED

E, 2026-09-08 06:20, with `screenshots/arrival-card-refresh/02-task-detail-at-place-home-open.jpeg`:
*"we need to remove the 'search tasks' search bar from a full view task screen such as the one
shown in one of the screenshots."* The row is mounted once at the root (`RootBottomOverlay`) and
`RootView` derived its scope from `selectedTab` ALONE, so the root never learned the tab had gone
deeper. Block 1's coordinator already carries each tab's depth; this block reads it.

- `AppSearchScope.scope(for:isAtRoot:)` — `.none` for any tab below its top-level page, **no
  default** for `isAtRoot` (a caller that forgot it would put the row back under the pushed
  screen). The one-argument form is gone; every caller states the depth.
- `RootView.searchScope` — the selected tab's scope masked by `tabNavigation.isAtRoot(selectedTab)`;
  `.onChange(of: searchScope)` feeds the model, so a tab switch AND a push/pop both move it — and
  switching back to Tasks with its detail still pushed keeps the row hidden, which the old wiring
  would have got wrong from the other side.
- `RootBottomOverlay` gains a second `.animation(value: searchScope)` on the house spring: the row
  leaves and returns on it. **Judgment call E can veto:** the same spring now fades the row on a
  tab switch too (it used to pop with the hard-cut tab content).
- Built on `feature/tab-depth` on top of block 1 (E, 2026-09-08 late morning: the three block-1
  checks are deferred to the same phone sitting as block 2), so PR #35 carries the whole arc.

**Acceptance criteria**
- [x] Tests first, watched red: `AppSearchScopeTests` (6, was 4 — `extra argument 'isAtRoot'`
      ×5 at compile), then with the rule in and the root still feeding `isAtRoot: true`,
      `AppSearchCallSiteTests` red on its own assertions (3 failures across 2 tests: the root
      derives from tab AND depth; the overlay animates on the scope), then
      `SearchRowDepthJourneyUITests` red against that build at *"E's screenshot, unchanged"*
      (162 s, the row still in the tree with the detail pushed). `seedTask` hoisted to
      `UITestSession` (`UITestFixtures.swift`); `SignedInJourneySupport`'s copy delegates.
- [x] Scoped unit run GREEN: 34 / 0 across `AppSearchScopeTests`, `AppSearchCallSiteTests`,
      `AppSearchModelTests`, `TabNavigationTests`, `TabNavigationCallSiteTests`.
- [x] **The UI journey GREEN — 1 / 0 (132 s)**, sim ERASED after both runs: the row is on the
      list, gone once the seeded task's detail is pushed, and back once block 1's Tasks re-tap
      pops it (the detail's title field gone). Its two attachments show exactly that.
- [x] Full suite **2,543 / 0** (emulator up, 0 `9099` hits, 0 skipped), lint **0 / 719**, sim
      build green, app target **24.76% (11,189/45,196)** — denominator +7 over block 1's 45,189
      (the guard, the computed scope, the animation), numerator +1.
- [x] Committed `c4fba78`, THEN red-checked one at a time: the rule ignores the depth —
      predicted 2 / actual 2 (the two depth tests); the root feeds `isAtRoot: true` — predicted
      1 / actual 1 (the call-site derivation guard). Restore proven 13 / 0.
- [x] Device: built green at `c4fba78` (binary 12:06, `-allowProvisioningUpdates`, no
      provisioning trouble) and `App installed` at 12:07 on E's phone — BOTH blocks. The launch
      was refused because the phone was LOCKED (`NSLocalizedFailureReason … Locked`); E opens
      it by hand, force-quit first.
- [x] **E's verdict on the phone, 2026-09-08 evening: *"All 4 checks were successful."*** — the
      row gone over a pushed task detail (E's screenshot, `screenshots/tab-depth/01-`), back on
      the list; block 1's three checks passed in the same sitting. PR #35 merged on that verdict;
      phone reinstalled from main.

### FEATURE: F-PillReTap — a scroll-to-top re-tap restores the capture disc from its pill  [x] COMPLETED

E, 2026-09-08 evening, with a GIF (`../Ethan's Screenshot Folder/capture-button-pill-scroll-bug-1.gif`):
*"the Quick Capture button, if in collapsed pill form, when tapping the same tab page and it
scrolls to the top of the page, the pill stays collapsed."* The frames: at 0 s the page is
scrolled with the bar floating and the disc a pill; 2 s after the re-tap the page is at the top,
the bar has restored, the disc is STILL the pill; it expands only at ~5 s when a finger nudges it.

- **Cause:** `CaptureDiscScrollActivity` has two inputs — the window-level pan gesture's finger
  travel and `reset()` on a tab change. The re-tap's scroll-to-top is `proxy.scrollTo`, a
  programmatic scroll with no touch, so the pan recogniser reports nothing. The bar restores
  because `TabBarScrollActivity` reads the scroll view's `contentOffset`, which does move.
- **Fix, inside the settled disc rule (E's 2026-08-31 "stay in pill form until the page is
  scrolled upwards again" — this IS that scroll):** `TabReselectionResponse.restoresCaptureDisc`
  (true for `.scrollToTop`, false for `.popToRoot` — a pop brings the list back at its old
  offset, where the pill is still honest); `RootView.reselectTab(_:)` in `RootView+Reselect.swift`
  routes the bar's repeat tap into the coordinator and resets the pill on a scroll-to-top. The
  disc's own spring animates the morph. Nothing about the collapse rule, thresholds or timing
  changes. `discScrollActivity` and `tabNavigation` are internal on RootView now (the doors
  precedent — that file is at 399 of 400 lines).

**Acceptance criteria**
- [x] Tests first, watched red: `TabNavigationTests` +2 (`has no member 'restoresCaptureDisc'` at
      compile); then with the rule in and the root still routing straight to the coordinator,
      `TabNavigationCallSiteTests` red on its own assertions (2 tests: the new guard reading
      `RootView+Reselect.swift`, loud on the missing file; the `onReselect: reselectTab` line).
- [x] Scoped unit run GREEN: 40 / 0 across `TabNavigationTests`, `TabNavigationCallSiteTests`,
      `CaptureDiscPillCallSiteTests`, `CaptureDiscScrollActivityTests`, `AppSearchCallSiteTests`.
      Touched-file lint 0 / 5; full lint **0 / 720**.
- [x] Full suite **2,546 / 0** (emulator up, 0 `9099` hits, 0 skipped), sim build green, app
      target **24.76% (11,192/45,206)** — denominator +10 over `1100a01`'s 45,196 (the rule and
      the reselect method), numerator +3.
- [x] Committed `9a919a8`, THEN red-checked one at a time: the rule restores the disc on a POP
      too — predicted 1 / actual 1; the root forgets the reset — predicted 1 test / actual 1
      test (both wiring assertions). Restore proven 17 / 0.
- [x] Device: built green at `9a919a8` (binary 20:50, no provisioning trouble), `App installed`
      and `Launched` on E's phone. PR #37 open
      (`https://github.com/digdiggydigger/ADHDLifeOS/pull/37`), awaiting E's device verdict.
- [x] **E's verdict on the phone, 2026-09-08 evening: *"I've just checked that on my phone and
      it works."*** — scroll a tab down until the disc is the pill, re-tap the tab: the page
      scrolls to the top AND the disc is the full disc again. No UI journey can see this one
      (the disc's outer frame is 60×60 in both states by design); the verdict is the record.
      PR #37 merged on it; phone reinstalled from main.

## Home keeps what it knows — register item B-2, E's call 2026-09-08 (branch `fix/home-alltasks-keep-last-known`, off `main` @ `bd03bf5`)

### FEATURE: F-HomeTasksLastKnown — a failed task fetch keeps the last-known set instead of emptying it  [x] COMPLETED

Carried on the register since the arrival-card arc (`OPEN-ITEMS-REGISTER.md`, B-2), deferred out
of PR #32 on purpose and picked up on E's word: *"First do B-2."*

- **Defect:** `HomeService.load()` read `allTasks = (try? await allTasksResult) ?? []`. A failed
  `fetchAllTasks()` therefore published the positive claim **"there are no tasks"**, not "don't
  know" — and every consumer downstream believed it. `lifeAreas` and `openTasks` never had this
  problem: they throw into the `catch`, which leaves both holding their last-known values.
- **Why it reaches the arrival card, which is what the register flagged:** Home refreshes the card
  deliberately AFTER the load — `HomeView.refreshEverything()` awaits the parallel block, then
  `refreshArrivalSurface()`, commented *"so the card is built from the tasks that just landed"*.
  `ArrivalSurface.refreshed` re-checks the card it is already holding against those tasks and
  drops it when its work is gone (`testRefreshed_noFix_dropsTheCardWhenItsWorkClosed` is that rule
  working as designed). The rule cannot tell **"the work here closed"** from **"the fetch
  failed"**, and it should not have to — so the fix belongs upstream in the service, not in
  `ArrivalSurface`. On a pull that only hiccuped, the card the user was looking at vanished.
- **Blast radius is wider than the card**, and worth saying because it was never the stated
  symptom: `MomentumScoreboard.streak`/`bestStreak`, `trailingWeekClosureFlags`,
  `MomentumWeekCharts.closedPerDay`, `TaskCompletionStamp.completedTasks`, the week-review row and
  `MomentumTaskContext.build` all read `homeService.allTasks`. A failed fetch zeroed E's streak.
- **Fix, one line, following the inbox precedent** (`CaptureInboxService.refresh()`, which keeps
  the captures on screen when a refresh fetch fails): `if let fetchedAllTasks = try? await
  allTasksResult { allTasks = fetchedAllTasks }`. Success still overwrites the set wholesale, so
  nothing goes stale while the network works. `HomeService` is a `@StateObject` on `HomeView`,
  inside the signed-in tree, so a last-known set cannot outlive an account switch.

**Acceptance criteria**
- [x] Test first, watched red — and it had to be a **two-load** test to discriminate. The existing
      `testLoad_scoreboardFetchFailure_stillLoadsTheScreen` fails the fetch on a FIRST load, where
      `allTasks` is `[]` before and after, so it passes either way and pins nothing; a new
      single-load test would have been vacuous the same way. The new test lands `[done]`, flips
      the fake to `.failure`, loads again, and asserts the set survived.
- [x] Scoped red: `Executed 14 tests, with 1 failure` — the final assertion, `("[]") is not equal
      to ("[…Closed…]")`. The precondition assertion passed, proving the first load did land the
      history; the existing first-load test passed alongside, confirming it never pinned the bug.
- [x] Scoped green after the fix: 38 / 0 across `HomeServiceTests`, `ArrivalSurfaceRefreshTests`,
      `ArrivalSurfaceTests`.
- [x] Full suite **2,547 / 0** (emulator up, 0 `9099` hits, 0 skipped) — +1 over `a6b8021`'s
      2,546, the new test. Full lint **0 / 720**, sim build **BUILD SUCCEEDED**, app target
      **24.76% (11,191/45,205)** — denominator −1 against `a6b8021`'s 45,206 (the `?? []` swapped
      for an `if let`), so the two ratios are measuring the same extent and are comparable.
      `HomeService.swift` itself 92.47% (86/93).
- [x] Committed `8b5f740`, THEN red-checked: defect reinstated → **predicted 1 failure / actual
      1**, and exactly the named test, with the other 13 green. Restore proven 14 / 0.
- [x] Landed: PR #39 (`https://github.com/digdiggydigger/ADHDLifeOS/pull/39`) merged to `main`
      @ `39228d8`, branch deleted both sides, `origin/main` verified to contain `8b5f740`.

**Evidence is the unit test, not a device verdict, and not a screenshot.** Firestore's default
persistence serves offline reads from cache, so a failed `fetchAllTasks()` cannot practically be
induced on E's phone; and per CLAUDE.md "Visual evidence", a folder is earned only by what a test
cannot assert — this is asserted, so no folder.

## Focus card arc — E's design session, 2026-09-09 (from `IMG_8307.jpg`; branch TBD, off `main` @ `e9fa9df`)

**The full design record is `handoff/SESSION-OPENER-focus-card-design.md` — read it, not this
summary.** It holds E's verbatim answers to sixteen design questions, the reason behind each
choice, the pure types, the tests-first table with what each test reads on the BROKEN build, and
the traps. Everything in its "settled specification" was answered directly by E: **do not
re-litigate it.**

The card (`ADHD LifeOS/Focus/FocusTimerBar.swift`) is one fixed presentation today, so an active
sprint permanently occupies a band above the tab bar on every screen. It gains a collapsed state
and a completion-confirmation flow, tied by one rule of E's: the card stays collapsed *"until the
user has tapped the final, and new, 'Confirmed' button"*.

Five sequential blocks, E reviews each on device:

### FEATURE: F-FocusCard-1 — the collapsed running card and its four toggles  [x] COMPLETED

*Merged `59fcf20` 2026-09-09 (PR #43 → close-out #44 → fix #45). E on device: "That all works
very nicely." **The block description below was overtaken during the build** — E reversed
full-bleed (the collapsed card is inset 16, 60pt tall, no bottom keyline, no chevron and no
PAUSED badge), and the long-press was RETIRED: a single tap opens the detail sheet in both
states, and collapse is the swipe and the grabber only. `screenshots/focus-card-collapse/`
records what the rejected versions looked like.*

Collapsed = ring + name + Pause ONLY, full-bleed to both screen edges, rounded TOP corners, dropped
FLUSH onto the tab bar. Toggled by swipe (down collapses), tap anywhere, the chevron (today a
decorative `Image`, becomes a real control), and a new grabber. Long-press opens the detail sheet —
it is the app's ONLY door to `FocusSprintDetailView` and tap-to-collapse takes its gesture.
Collapse persists across tab switches, backgrounding and relaunch, on `FocusSessionService` through
the existing `FocusSprintPersisting` seam (`RootView.swift` is at 399/400 lines, so a new
`@StateObject` there is impossible).

**Acceptance criteria**
- [ ] Tests first, watched red. `FocusBarCollapseTests` — the direction-aware swipe (a naive
      `toggle()` must FAIL `testSwipeIsDirectionAwareNotAToggle`), the top-only corner shape
      (assert `contains(1,99)` AND `!contains(1,1)` — a `RoundedRectangle` fails one, a `Rectangle`
      the other, nothing passes both by accident), `inset(by:)` actually shrinking, and the flush
      lift DERIVED from `AppTabBarMetrics.rowHeight` rather than hard-coded 68.
- [ ] Collapse persistence: a SECOND service over the same fake reads it back, and it restores even
      when no sprint is stored (the `+Persistence.swift:21` ordering trap).
- [ ] `FocusBarCollapseCallSiteTests` — the wiring guards, including that `FocusSprintDetailView(`
      is STILL referenced (the orphan guard) and `RoundedRectangle(cornerRadius: 24` is GONE.
- [ ] `FocusTimerBar.swift` split into `FocusTimerBarContent.swift` preemptively — it is 250 lines
      and will blow the 400 ceiling.
- [ ] Full suite, full lint, sim build, coverage; committed, THEN red-checked one at a time.
- [ ] Device build on E's phone (it is behind main at `a6b8021`) and E's verdict. The morph may be
      invisible to XCUITest the way the capture disc's pill is — if so, say so rather than shipping
      a vacuous journey.
- [ ] **Report that block 1 alone has STICKY collapse** — nothing resets it until block 2's Confirm.

### FEATURE: F-FocusCard-2 — provisional record + the completed-unconfirmed card  [x] COMPLETED

*Merged `1f0d93a` 2026-09-09 (PR #47). E on device: "I've run a short sprint, and it seems to be
working correctly." Suite 2,619/0/0 skipped, lint 0/731, app target 26.37% (12,037/45,646).
**One deviation from the design record, approved by sight rather than in words:** the record
said this card shares the collapsed card's "full-bleed flush geometry", but full-bleed was
reversed in block 1 and "flush" only works for the BOTTOM-most furniture — this card stacks
above a running sprint, so it floats at the expanded card's geometry (inset 16, radius 24, all
four corners) and measures 76pt. Evidence: `screenshots/focus-completion-card/`.*

`confirmedAt: Date?` on `CompletedFocusSession` (`confirmed_at`), a `unconfirmedCompletions` array
on the service under a NEW key, and the card: full ring + name + banked time + Confirm. **Only a
NATURAL completion pushes a card** — a manual Stop pushes nothing, which is the discriminator for
the whole feature. Confirm finalises by RE-SAVING (`save(_:id:in:)` is `setData`, a full upsert) and
resets collapse. **Firestore rules need no change and nothing for E to republish** — verified.

### FEATURE: F-FocusCard-3 — the notification-style stack  [x] COMPLETED

*Built 2026-09-09 on `feature/focus-card-3`. Suite 2,637/0 (emulator up, 0 `127.0.0.1:9099`,
0 skipped), lint 0/734, sim + device builds `** BUILD SUCCEEDED **`, app target **26.56%
(12,161/45,782)** — comparable to 26.37% (12,037/45,646) at `1f0d93a`: the denominator moved
because the tree grew by one file, the measurement extent is unchanged. Five red-checks, one at
a time, all five firing on exactly the predicted tests and assertion counts. Evidence:
`screenshots/focus-card-stack/`. **Installed on E's phone; the block CLOSES on E's verdict.***

Newest in front, older peeking behind as edges, three layers drawn, confirm one at a time.
**No "confirm all"** — E ruled it out explicitly, and a call-site test guards its absence.

**Two of E's section-A items were answered before the build, and one CHANGED SHIPPED BEHAVIOUR:**

- The completion card's floating geometry (inset 16, radius 24, all four corners, 76pt) is
  **kept as shipped** — E chose it explicitly rather than by sight, so the stack's peeks inherit
  a settled shape.
- **Confirm now resets collapse only when NO sprint is running.** Block 2 reset it
  unconditionally, which meant confirming an OLD card blew open a NEW sprint's card, undoing a
  collapse the user had just made by hand. Landed as its own commit with its own red-check.

**`FocusCompletionStackLayout` owns the DRAW ORDER, not just the offsets.** The record named the
`ZStack` order as this block's headline trap — get it wrong and the oldest card is in front while
every arithmetic assertion still passes — and that is only true while the order lives in a view
body. `drawOrder(for:)` returns the layers back to front and the trap became an ordinary
assertion.

**The render caught a bug the whole suite could not see.** `.regularMaterial` blurs what is
behind it rather than hiding it, so a stack of full cards ghosted the second card's ring and
summary line through the front one, worst in dark. The layers behind now draw a blank
`FocusCompletionCardEdge` — same shape, material, keyline and 76pt height, no content. The
rejected build is kept in the screenshots folder as the before half of the pair.

### FEATURE: F-FocusCard-4 — the celebration  [x] COMPLETED

*Built 2026-09-11 on `feature/focus-card-4`. Suite **2,663/0** (emulator up, 0 `127.0.0.1:9099`,
0 skipped), lint **0/738**, sim + device builds, app target **26.69% (12,255/45,914)** —
comparable to 26.56% (12,161/45,782): the tree grew by one file, the measurement extent is
unchanged. The call-site guards ran RED on 5 tests / 9 failures as predicted before the
implementation existed; three red-checks afterwards, one at a time, each firing on exactly the
predicted tests. Evidence: `screenshots/focus-completion-celebration/`. **Installed on E's phone;
the block CLOSES on E's verdict.***

A radiating ring burst + a springing checkmark, inside the completion card's ring: the ring's own
stroke scales 1 → 1.6 while fading 0.8 → 0 on a 0.9s easeOut, the tick springs in from 0.6, both
after a 0.3s wait for the card to land. **It ends on the block-2 card E approved** — the settled
pose is the tick alone, and a card revealed by a Confirm or restored by a relaunch opens in it.

- **The haptic keys on `confirmableCompletionCount`**, on `RootBottomOverlay` — NOT on the stack,
  which is inserted in the same update that bumps the count and would miss the first card.
- **One stamp, `latestConfirmableCompletion` (ordinal + record id), written by the push only.**
  The count drives the haptic, the id drives the burst; Confirm and restore leave it alone.
- **Reduce Motion is resolved by the CARD** and handed to the celebration before its `@State`
  exists, so the first frame is the final state — the trap the record names.
- **iOS 16 floor held:** two `withAnimation`s from `onAppear`; no `PhaseAnimator`, `.symbolEffect`,
  `.keyframeAnimator` or `.sensoryFeedback` (a call-site test bans all four).
- Two widget accessors moved to `FocusWidgetPublishing.swift` to keep the service file under 400.
- **Deviation from the record, and why:** the tick is the ring's existing bare `checkmark`, not a
  `checkmark.circle.fill` — the record's glyph predates block 2's ring, and a filled disc inside the
  ring would change the resting card E approved. The burst is what happens TO that card.
- **For E's eye on device:** the 0.3s pre-beat shows a complete ring with no tick. Deliberate (the
  tick lands on a card that has stopped moving), but if it reads as a glitch the lever is
  `FocusCompletionCelebrationMetrics.delay`.

### FEATURE: F-FocusCard-5 — close-out  [x] COMPLETED

*Built 2026-09-11 on `feature/focus-card-5`, after E closed block 4 on device ("the pre-beat
reads fine — go ahead with block 5"). Doc-only: no executable line changed, so the phone build
from block 4 IS this code. **THE FOCUS CARD ARC IS CLOSED.***

- `FocusTimerBar.swift`'s header: the "tapping the bar's task row" line the record named was
  already gone (block 1 rewrote it); what was stale was "inset further than the expanded card"
  (both insets are 16) and "cleared only by Confirm" without block 3's no-sprint-running
  condition. Both corrected.
- `FocusSessionBackingStore.swift`: "append-only in practice" was FALSE since block 2 — Confirm
  re-saves the same `id`. Rewritten to say why the re-save is an upsert and why there is still
  no `update` or delete.
- `FocusSprintPersisting`'s doc now enumerates its four keys and says the celebration cue is
  deliberately NOT one of them.
- **The `OfflineSprintSummaryCard` collision is recorded in the code** (`RootBottomOverlay.swift`
  at the offline card, and the card's own header) as documented and deliberately unfixed — E's
  "keep them separate... queue it".
- The design record gained a postscript table of everything that shipped against it; the record
  itself is untouched, as the rule requires.


## Modern iOS pilot — E's call 2026-09-11 (a FRESH session builds; branches off `main` after the block-0 handoff)

*Prompted by E's "I can't see any of the animations": E's phone runs Reduce Motion ON, every RM
gate in the app is `nil`, so the block-4 burst has never played for E. E's decisions, the design,
the tests and the verification bar are in `handoff/archive/START-HERE-modern-ios-pilot.md` (the approved
plan, verbatim). Two blocks, strictly in order, each its own PR.*

### FEATURE: F-ModernIOS-1-Policy — CLAUDE.md §7 becomes the progressive-enhancement + Reduce Motion policy  [x] COMPLETED

Best available API per site behind `#available` (17/18/26) with a complete 16 path; Reduce Motion
replaces motion with a fade, never removes feedback (house pattern `CaptureFanOverlay.swift:89-96`);
fallback paths compile-only until an older runtime exists, said so in every block report; call-site
tests assert BOTH branches. Delete `testTheCelebrationUsesNothingAboveTheiOS16Floor`, add
`ModernAPIPolicyCallSiteTests.testTheHouseHapticHelperIsTheTwoBranchExemplar`. Suite 2,663 → 2,663.
Detail: the opener, "Block 1".

**Completed 2026-09-11, PR #63 (`0e980e5`).** §7 is 7.1–7.5 as specified, plus the two post-approval
additions (7.5 covers the `apple:*` / `apple-skills:*` plugins; `apple:modernize` does not skip the
gate). The new test reads the four forms IN ORDER inside `haptic(_:trigger:)`, not bare presence.
Red-checked on a committed tree (`} else {` → `} else  {`): full suite 2,663 / 1 failure, exactly
that test. Green: 2,663 / 0 (emulator UP, 0 `9099`), lint 0 / 739, sim build succeeded, app
26.68% (12,255/45,932), byte-identical. E's `MARKETING_VERSION` 1.2 → 1.3 rode along as its own
commit (`4052c52`). Awaiting E's review; block 2 is not cut until then.

### FEATURE: F-ModernIOS-2-Celebration — the pilot: 16 spring / RM cross-fade / iOS 26 draw-on  [x] COMPLETED

`FocusCompletionCelebrationMotion.resolve(reduceMotion:drawOnAvailable:)`; pure types split to
`Focus/FocusCompletionCelebrationPose.swift`; `Pose.geometryPinned`, `.armedInPlace`, `isArmed`,
`opening(plays:motion:)`; `Metrics.checkmarkAnimation(for:)`; `@available(iOS 26.0, *)
FocusCompletionDrawOnTick` behind `if motion == .modern, #available(iOS 26.0, *)`. Card, stack,
overlay and service untouched. Test-first (string tests predicted red 3 / 6), rendered in all three
modes + in situ, evidence `screenshots/focus-completion-celebration-modes/`. **Closes on E's device
verdict with Reduce Motion ON.** Detail: **`handoff/archive/START-HERE-modern-ios-celebration.md`** (archived at the 2026-09-11 close-out), the
live opener written 2026-09-11 at E's request after block 1. It carries the plan's block-2 sections
verbatim, plus two corrections found against the tree: the plan's `.asymmetric(insertion:
.symbolEffect(.drawOn), …)` does not compile (use `AsymmetricTransition(insertion:removal:)`), and
the string tests' red count is 5 failures for the listed assertion set, not 6.

**Completed 2026-09-11 on `feature/modern-ios-celebration` (`bfb1fa3`, `da65027`).** Built as
specified, with the `AsymmetricTransition` form. Deviations, all reported:
- **The string tests read ORDER inside the tick site**, not bare presence: the view's own
  `drawOnAvailable` flag contains `#available(iOS 26.0, *) {`, so the plan's bare-presence pin was
  vacuous. Test 3 also pins `guard pose.isArmed else { return }` and bans `pose == .armed` — the
  line that would have frozen the reduced opening for ever.
- **The class is `FocusCelebrationModernPathCallSiteTests`**, not the plan's 49-character name:
  SwiftLint's `type_name` ceiling is 40.
- **`@MainActor` on the two celebration test classes**, clearing 5 pre-existing and 3 new
  isolation warnings.

Red #1, predicted in writing and observed exactly: `Executed 2672 tests, with 16 failures`, 9 tests.
Red-checks on a committed tree, each predicted by test name and observed exactly: `} else {` →
2,672 / 1; `resolve` ignoring RM → 2,672 / 5 (2 tests); `geometryPinned = true` → 2,672 / 3
(2 tests). Final green 2,672 / 0 (emulator UP, 0 `9099`), lint 0 / 742, sim build succeeded, app
26.75% (12,309/46,014). **The renders found two things the tests cannot** (evidence
`screenshots/focus-completion-celebration-modes/`): the iOS 26 draw-on does NOT wait for the 0.3s
delay (it draws during the card's slide-up; shipped as rendered, per the plan), and the reduced
halo pinned at 1.6 overhangs the 76pt card by ~0.7pt and runs ~7pt behind the summary text at 80%
(E's lever; ≤ 1.25 clears the text). **Closes on E's device verdict with Reduce Motion ON.**
Merged as PR #65 (`a2f20ab`).

**Follow-up, same day — E: "Can you make the animations longer?"** Both fades doubled (halo
0.9s → 1.8s in every mode, reduced tick 0.4s → 0.8s; the factor is Claude Code's pick pending E's
feel), pinned by `testTheFadesRunAtTheLengthEAskedFor`. Red 2,673 / 2 (1 test), green 2,673 / 0,
lint 0. PR #66 (`e1d87d8`); on E's phone 07:32 BST.

**Second follow-up, same day — E named the numbers: "make the halo fade 2.1s and the tick fade
1.1s".** Halo 1.8s → **2.1s**, reduced tick 0.8s → **1.1s**. These are E's values, not a factor, and
the same test pins them. Red predicted and observed 2,673 / 2 (1 test); green 2,673 / 0, 0 `9099`,
lint 0. `40a70e4`; on E's phone 09:06 BST. **The RM-ON verdict is now on this build.**

## The Confirm celebration — E's ask 2026-09-11, record approved the same day (branch `feature/confirm-celebration`, off `main` @ `a07402d`)

*E: "when the user taps "Confirm" on a completed sprint/notification card. There needs to be an
animation that can use up to the full-screen if so, Possibly confetti?" Designed question by
question and by rendered prototype; every decision, number and constraint is in
**`handoff/SESSION-OPENER-confirm-celebration-design.md`** (permanent), evidence
`screenshots/confirm-celebration-prototypes/`. E's review: "R1, R2, R9 (a+b) = Approved"; R3–R8
stand as defaults. Two blocks, strictly in order, each closing on E's device verdict.*

### FEATURE: F-ConfirmCelebration-1 — the engine, the trigger, and every Confirm's confetti + glow + haptic  [x] COMPLETED

- **Room first, own commit:** `FocusSessionService.swift` (394/400) moves methods out to an extension
  file; `RootView.swift` (399/400) moves `startFocus` to `RootView+Doors`.
- **Stamp (R2):** `FocusConfirmation(ordinal:clearedStack:)` published as `latestConfirmation`, written
  only by `confirmCompletion`, only for a record that was in the stack, before `await log`; never
  persisted; `latestConfirmableCompletion` untouched.
- **Engine:** a pure, closed-form confetti model (gravity 520, drag 2.2, fade 0.7 s, tumble, flutter),
  seeded per confirmation ordinal (R5); every Confirm = 120 rain + 100 cannons in the 7 record tokens;
  the StateGo glow (0.32, in 0.3 / hold 0.9 / out by 2.4 s). Live bursts capped at 3, oldest dropped
  (R1); pruned when they end so nothing redraws once they have.
- **Layer (R3):** one `.overlay` in `RootView` after `RootBottomOverlay`'s, before the covers;
  `allowsHitTesting(false)`, `ignoresSafeArea()`, `accessibilityHidden(true)`; `Canvas` in
  `TimelineView(.animation)`, single implementation (§7.1: no tier adds value).
- **Haptic (R4):** `.haptic(.success, trigger:)` on `RootBottomOverlay`, keyed on the Confirm ordinal.
- **§7.2 waiver** written into CLAUDE.md with a pinning call-site test.
- Test-first with a predicted red; red-checks on a committed tree; in-situ renders light + dark;
  device verdict (Reduce Motion ON, which the waiver makes identical to OFF).

**Completed 2026-09-11 on `feature/confirm-celebration`** (`281e151` room, `7f0326a` red, `9314a13`
green). Built as specified. New files:
- `Focus/ConfettiPhysics.swift`
- `Focus/ConfirmCelebrationRecipe.swift`
- `Focus/ConfirmCelebrationOverlay.swift`
- `Focus/FocusSessionService+Notifications.swift`

**Tests:** 35 new, in `ConfettiPhysicsTests`, `ConfettiRecipeTests`, `ConfirmCelebrationTimingTests`,
`FocusConfirmationStampTests` and `ConfirmCelebrationCallSiteTests`.

**Red #1, predicted in writing per test and observed exactly:** `Executed 2708 tests, with 46
failures (4 unexpected)`, 32 tests.

**Red-checks on the committed tree, each predicted by test name and observed exactly:**
- the in-stack guard dropped + the cap removed → 2,708 / 3
  (`testConfirmingACardThatIsNotWaitingCelebratesNothing` 2, `testAFourthQuickConfirmDropsTheOldestBurst` 1);
- the stamp moved below `await log` + `allowsHitTesting(false)` removed → 2,708 / 2
  (`testTheConfirmationStampLandsBeforeTheLogAwait`, `testTheLayerNeverTakesATapAndIsNeverReadOut`).

**Final green:** 2,708 / 0 (emulator UP, 0 `9099`); lint 0 / 751; sim and device builds succeeded;
app 26.87% (12,470/46,405).

**Renders** (`screenshots/confirm-celebration-block-1/`):
- a real `confirmCompletion` sets the celebration off through the real overlay on the real clock,
  two quick Confirms overlap, and everything is pixel-identical to a never-celebrated window once
  it lands;
- ordinal 1's 220 pieces are field-for-field the prototype E chose from.

On E's phone 09:54 BST. **Closes on E's device verdict.**

**Follow-up, same day — E, on the block-1 video: "extend the animation length by 1.2 seconds".**
- **What changed:** the 4.2 s choreography is stretched evenly over **5.4 s** by
  `ConfirmCelebrationQueue.extraLength` / `pace` / `choreographyTime(of:at:)`, and both the frame
  and the glow read that clock. Every piece, path and beat is kept.
- **Tests first:** red predicted and observed 2,710 / 8 (3 tests). A red-check pointing the glow and
  the frame back at raw time failed exactly its 2 named tests.
- **Green:** 2,710 / 0 (0 `9099`), lint 0; device build succeeded; on E's phone 10:26 BST.

### FEATURE: F-ConfirmCelebration-2 — the stack-clearing fireworks and the light-mode dim  [ ] OPEN

14 shells in 9 tokens (single / two-tone / ring-in-ring; big / medium / small; two-shell finale) on
the record's schedule, only when `clearedStack`; `Scrim` at 0.85 in LIGHT appearance only, in 0.35 s,
held to 0.4 s before the last spark, out 0.6 s. Pure model + schedule + dim tests, call-site test
that both play only on a cleared stack, renders light + dark, device verdict. **Not started until E's
verdict on block 1.**
