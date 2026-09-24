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

> **2026-09-18 — the objection below is VOID; the block is still NOT to be started unasked.**
> `F-JournalDoorUnpinned` deleted the "One line about today…" composer bar (E's option 04), so the
> Journal's bottom band no longer holds a field, and the "grow the composer's clearance" paragraph
> further down has nothing to grow. What remains open is E's call on whether the Journal wants a
> search row at all — and, if `F-JournalPencilReachable` puts the pencil in the disc's band (shape
> c), that band is spoken for again. Noted, not started. **E chose (b), the nav bar, so the band stays
> free** — the objection is simply void.
>
> **2026-09-18, later — the objection is BACK, in a new form.** Step 0 of `F-JournalPencilReachable`
> showed E the filled pencil in the toolbar, and E moved it: *"move the filled pencil icon disc down to
> the left-hand side of the FAB Icon"*. So the band left of the disc on the Journal belongs to the
> 42pt pencil disc (`F-JournalPencilDisc`). A search row there would have to share the band with it,
> which is a design question for E, not a layout detail. Still not to be started unasked.
>
> **Built 2026-09-18 (`F-JournalPencilDisc`):** the pencil disc now lives in that band — in
> `RootBottomOverlay.discRow`, between the search slot and the +. The objection is live, not
> hypothetical.

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
**CLOSED 2026-09-11 — E: "i have done the animation checks on my iphone with Reduce Motion ON and OFF and it works correctly in both states."** Both states correct as shipped; the draw-on timing and the 1.6 halo stay.
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

**Device verdict PASSED 2026-09-11 — E: "i have done the animation checks on my iphone with Reduce Motion ON and OFF and it works correctly in both states."**

### FEATURE: F-ConfirmCelebration-2 — the stack-clearing fireworks and the light-mode dim  [x] COMPLETED

14 shells in 9 tokens (single / two-tone / ring-in-ring; big / medium / small; two-shell finale) on
the record's schedule, only when `clearedStack`; `Scrim` at 0.85 in LIGHT appearance only, in 0.35 s,
held to 0.4 s before the last spark, out 0.6 s. Pure model + schedule + dim tests, call-site test
that both play only on a cleared stack, renders light + dark, device verdict.

**Completed 2026-09-12 on `feature/confirm-celebration-2`** (`ff30ddf`/`d68e006`/`9e1154b` red,
`29c6267` green). Built as specified, on the same stretch (E's decision 1): `length(of:)` is
`5.0 / pace` ≈ 6.43 s for a cleared stack, 5.4 s otherwise. New files
`Focus/ConfirmFireworksSchedule.swift`, `Focus/ConfirmFireworksPhysics.swift`,
`Focus/ConfirmFireworksDrawing.swift` (the Canvas ops and `ConfirmCelebrationDim`); a
`ConfettiPhysics.state(of:at:gravity:drag:)` overload at 150 / 2.4 that the confetti's own
`state(of:at:)` now forwards to; the frame draws dim → glow → fireworks → confetti and reads
`colorScheme` for the light-only dim. The per-spark speed hash is `ConfettiRandom` seeded per
(shell, spark); the schedule itself is fixed (E chose those bursts in those places).

**Tests:** 31 new — `ConfirmFireworksScheduleTests` 9, `ConfirmFireworksPhysicsTests` 13,
`ConfirmCelebrationDimTests` 4, +2 in `ConfirmCelebrationTimingTests`, +3 in
`ConfirmCelebrationCallSiteTests`; the waiver pin lists the three new files.
**Red, predicted in writing and observed exactly:** `Executed 2741 tests, with 74 failures
(0 unexpected)`, **31 tests**. **Red-check on the committed tree** (four breakages — fireworks for
every burst, the dim's `clearedStack` filter, `length(of:)` back to 5.4 s, the light gate — predicted
by name): 2,741 / 8 assertions, exactly the **5 predicted tests**.
**Green:** 2,741 / 0 (emulator UP, 0 `9099`); lint 0 / 757; app 27.07 % (12,635/46,678).

**Renders** (`screenshots/confirm-celebration-block-2/`): a real Confirm on the last card fires it
all through the real overlay and leaves 0 pixels behind at 6.65 s light / 6.22 s dark; the four
stills light beside dark; the 6.6 s mp4; a NON-clearing Confirm's frame pixel-diffed against block
1's own rendering (a worktree at `b5fe8c8`): **0 / 1,339,344, light and dark**.

**Device verdict PASSED 2026-09-12 — E: "I've checked your most recent build on my iPhone, and it looks good. It looks as if it's working as as you specified."** (`main @ 9a7b664`, Reduce Motion ON is E's setting.)

## The CTA celebrations arc — E's design, settled 2026-09-11; NOT BUILT (build starts in a fresh session, E's instruction)

*E: "I want to focus on assigning animations such as this one we've just created to other CTA
buttons etc. throughout the app." Designed question by question — twenty-seven answers, seven
recommendations overruled; every decision, number and constraint is in
**`handoff/SESSION-OPENER-cta-celebrations-design.md`** (permanent). E's direction at close:
"YOU MUST NOT BUILD IT IN THIS SESSION" / "You must start building this in a fresh claude code
terminal session." The record's recommendations R-a…R-h are NOT yet ruled on — ask E before block 1.
Eight blocks, strictly in order, each closing on E's device verdict.*

### FEATURE: F-ConfirmCelebration-2 — (see the block above; E's decision 1: the fireworks take the same even stretch, ≈ 6.43 s on a stack-clearing Confirm; built FIRST, E's decision 2)  [x] COMPLETED 2026-09-12 — see the block above; device verdict PASSED

Unchanged in scope from the block above. Adds: `length(of:)` → `5.0 / pace` for a cleared stack;
three files `Focus/ConfirmFireworksSchedule.swift` / `ConfirmFireworksPhysics.swift` /
`ConfirmFireworksDrawing.swift` (each under 400, all on the choreography clock, all added to the
waiver pin's list); a `ConfettiPhysics.state(of:at:gravity:drag:)` overload at 150 / 2.4. Tests:
shell timings, 72/56/40 sparks, inner ring 0.55×, two-tone alternation, 14 shells in 9 real
tokens, last spark 4.79 s, the dim envelope and light-only, 6.43 vs 5.4; call-site: fireworks and
dim draw only for a cleared stack. Evidence `screenshots/confirm-celebration-block-2/` (stills at
0.3 / 1.2 / 2.6 / 4.8 s light + dark, the 6.4 s mp4, an every-Confirm frame pixel-diffed against
block 1: 0 pixels). Device verdict.

### FEATURE: F-CTACelebrations-1 — the haptic tidy and the closure card's spring-in  [x] COMPLETED 2026-09-12 — device verdict PASSED on the FULL path (E: "it feels good, all five work as you described"; E turned Reduce Motion OFF the same day, so the reduced path is verified by injection only)

- **Room first, own commit:** `HomeView.swift:360-399` → `Home/HomeView+Refresh.swift`;
  `HomeMomentumSections.swift:235-329` → `Home/HomeLifeAreasSections.swift`.
- Sorted `.success` on the detail screen too (`CaptureDetailComponents.swift:287`, was `.solid`);
  "Done for now" `.success` (`NudgeDueCard.swift:35`, was `.light`); Save a place `.solid` after the
  write lands (`PlaceEditorView.swift` `save()`); Stop sprint `.light` (`FocusTimerBar.swift:142`).
- `ClosureCelebrationCard` springs in: `.transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))`
  and `withAnimation(reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8))`
  around the three writers of `celebratedTask` (`HomeMomentumSections.swift`); the
  `CaptureFanOverlay` house pattern.
- Tests: `CTAHapticTidyCallSiteTests` — **six** prose tests, not five: the no-bypass guard is a
  separate property from the two RM branches by string, so it is its own test. Predicted red
  6 / 6 tests, observed 6 / 6 (11 assertions); green 6 / 6. Each haptic test is scoped to ONE
  closure, because three of the four files already hold the target feel at a different site that
  must not move. Shipped: the three writers of `celebratedTask` share one `setCelebratedTask`
  rather than each wrapping itself — which is what makes "no writer bypasses the animation" a
  testable property; the guard sweeps the whole app target after a reviewer note, red-checked by
  planting a bare write in another file.
- Evidence `screenshots/cta-celebrations-block-1/`: three rows (before / full / reduced) × six
  frames × light and dark, each tile labelled with its MEASURED second. The sheets cannot resolve
  a 0.9 scale at the opacity the card is first visible at, so the probe MEASURES the rendered
  width: full narrows to 340–346 pt against a settled 370 pt and recovers by ≈ 0.29 s; reduced
  never leaves 369.5–370 pt. Device verdict by feel.

### FEATURE: F-CTACelebrations-2 — the two switches; Celebrations live on Confirm  [x] COMPLETED

- `MomentumPreferences`: `celebrationsEnabled` (true) and `celebrationSoundsEnabled` (false), each
  the FOUR-place edit (stored property, memberwise default, `decodeIfPresent ?? default`,
  `normalized()`). `AppFeedback.celebrationsEnabled(store:)` / `.celebrationSoundsEnabled(store:)`,
  read at fire time. Two Toggles after "Haptics" in `feedbackSection`, ids
  `settingsCelebrationsToggle` / `settingsCelebrationSoundsToggle`, one footer sentence each.
- `ConfirmCelebrationOverlay` gates on `AppFeedback.celebrationsEnabled()` at fire time, so the row
  is never a lie. The sound switch goes live with block 7's player.
- Tests: defaults; pre-existing blobs keep their values; `normalized()` keeps both OFF; the Feedback
  section carries both with ids and writes; the Confirm layer reads the switch at fire time.
  Predicted red 5 / 5. Evidence: the Feedback section light + dark (`RenderPreview`); Confirm with
  the switch off pixel-identical to a never-mounted window. Device verdict.

### FEATURE: F-CTACelebrations-3 — the centre, the shared layer, the four surfaces, Confirm re-routed  [x] COMPLETED 2026-09-12 — device verdict PASSED (E: "it passes, looks exactly the same" — the right answer to a negative test)

- **Room first, own commit:** `RootView.swift:73-93` → `RootView+Furniture.swift`.
- New `ADHD LifeOS/Celebrations/`: `CelebrationRequesting` (kinds, surfaces, outcome, the protocol,
  the inert requester, the two environment keys), `CelebrationBurst` + `CelebrationQueue` (one
  ordinal counter; full-screen cap 3, pop cap 8; lengths; `choreographyTime`), `CelebrationPolicy`
  (**`milestoneCooldown = 5` s — E's testing value, do not "correct" it**), `CelebrationCenter`
  (App-owned `@StateObject`, passed to `RootView` like `authService`; `lastFullScreenAt`; the
  surface stack; `held` full-screens for a self-dismissing surface, released on `surfaceDismissed`,
  dropped after 60 s; the chime hook), `CelebrationMotion` (`.full` for Confirm on ANY setting; else
  `.still` under RM), `CelebrationRecipes` (pop / stillPop / stillField; seven tokens),
  `CelebrationFrame` + `CelebrationStage` (moved from `ConfirmCelebrationOverlay.swift`, which is
  deleted), `CelebrationLayer(surface:)`, `CelebrationPopSource` (`onGeometryChange`, back-deployed
  16.0). `ConfirmCelebrationQueue` → `ConfirmCelebrationClock`; `ConfirmCelebrationBurst` removed.
- Mounts: `RootView` `.overlay { CelebrationLayer(surface: .root) }` at the SAME position; the routine
  cover (`RootView+Doors`), `TaskSearchSurface`, `CapturePromoteSheet`; each presenter's `onDismiss`
  calls `surfaceDismissed`. The Confirm bridge: `.onChange(of: focusService.latestConfirmation)`
  beside the Confirm haptic on `RootBottomOverlay`. The haptic and the stamp are untouched.
- Tests: `CelebrationPolicyTests`, `CelebrationCenterTests` (injected `now`), `CelebrationMotionTests`,
  `CelebrationRecipeTests`, a mount-enumeration test (four mounts, three `onDismiss`es); the six
  `ConfirmCelebrationCallSiteTests` re-pointed, each named in the report; the waiver pin becomes
  "the Confirm files are RM-free AND the resolver returns `.full` for Confirm" (CLAUDE.md §7.2 is
  updated to say so). Predicted red: counted per class. Evidence `screenshots/cta-celebrations-block-3/`:
  the block-1 live-Confirm probe through the centre, pixel-identical after landing; a
  `.routineCover` burst drawn by that layer only; Confirm under injected RM still full. Device
  verdict: Confirm indistinguishable from today; switch off = nothing.
- **Shipped, and the four things that differed from the plan.** (1) The design predicted THREE
  `onDismiss`es; there are **four**, because `CapturePromoteSheet` is presented from both
  `CaptureInboxView` and `CaptureDetailView` — a miscount in the record, not a design decision.
  (2) `CelebrationFrame` takes NO `originOffset`: the layer resolves a pop's global origin into its
  own space in `CelebrationStage`, where the geometry already lives, so the frame stays a pure
  function of scenes + date — which every render probe and preview in this arc depends on.
  (3) The §7.2 waiver pin could not survive "unchanged" literally, because it read the deleted
  overlay; it kept its NAME and E's decision, swapped the overlay for `CelebrationFrame` (RM-free
  because the rendering arrives as a parameter) and gained the resolver-order assertion, which is
  exactly what this block said it would "become". (4) `CelebrationPopSource`, `CelebrationKind.pop`
  and the three new recipes have **no production call site until `-4`/`-5`** — built here because
  this block's file list names them, and named here so the reachability guard is not forgotten.
- Predicted red in TWO parts and both matched: 17 / 23 source-reading tests, then a BUILD failure
  naming every new symbol. 2,757 → 2,810 tests. App coverage 27.05 % → **27.42 %**
  (12,949/47,221); the centre, the policy, the motion resolver, the recipes and the burst are all
  at **100 %**, and what is left at 0 % is view body.

### FEATURE: F-CTACelebrations-4 — the nine mini confetti pops  [x] COMPLETED 2026-09-12 — awaiting E's device verdict (RM off AND RM on — the first block that owes the RM-on pass)

- **Render FIRST:** the pop in situ on a real `TaskRow`, two or three count/spread variants, full
  and still; send them; E picks by looking (E's F6). Then wire the nine sites, each wrapped in
  `CelebrationPopSource` with the pop line INSIDE the same closure as the site's haptic:
  `TaskRow` (circle + swipe, one origin), `TaskDetailFormSections` "Close it", `AreaTaskRow`,
  Best-next-move "Close it", Sorted (triage + detail), Journal it, Create Task (post-success; the
  sheet holds 0.45 s — R-e), Done for now, the routine step.
- Tests: `CelebrationPopCallSiteTests` (one prose test per site; the sheet hold); `TaskRow` "the
  swipe and the circle pop from one origin". Predicted red 11 / 11. Evidence
  `screenshots/cta-celebrations-block-4/`: pops over a row, over the Form row (the root layer beats
  row clipping), inside the routine cover and the search surface; mp4. Device verdict RM ON and OFF.
- **Shipped. E picked variant A ("as designed") from four rendered in situ on a real `TaskRow`, and
  "keep rise-then-fall" for the still pop — so `CelebrationRecipes` and `CelebrationStillField` are
  UNCHANGED and this block is call sites plus one constant.** Room first:
  `CaptureInboxSections.swift` 390 → 270, the Undo section to `CaptureInboxUndoSections.swift` (136).
- **Four ways the build differed from the written plan.** (1) **`TaskRow` does not use
  `CelebrationPopSource`.** The wrapper reports the centre of what it wraps and the swipe lives on
  the whole row, so wrapping enough of the row to catch the gesture would throw the paper from the
  middle of it; it uses the file's other half instead — `.celebrationPopOrigin` on the circle, held
  in `@State`, requested in the shared `close()`. Both close paths still pop from ONE origin, and
  that origin is the circle E approved by looking. (2) **`CreateTaskButton` pops after the await**,
  inside `if succeeded`, because a create can fail and a celebration marks something that happened.
  (3) **R-e's hold is SCHEDULED, not awaited** (`Task { @MainActor in … }`): awaiting it would delay
  the paper rather than the dismiss, because `create(popping:)` is still waiting on `promote` to
  return before it pops. (4) **Thirteen tests, not eleven** — nine moments are ten code sites, plus
  the one-origin rule, the sheet hold and a count guard.
- **The red prediction was wrong the first time and the miss was a real defect, not a bad forecast.**
  Predicted 17 assertion failures, got 20; the three extra were guards that anchored on
  `Button { Haptics.play(…)` and then asserted the haptic was inside the slice, which starts AFTER
  its anchor — they could not have gone green however correctly the site was wired. The haptic is
  now part of the anchor and `assertAnchorIsUnique` stops a guard reading a different button. The
  corrected prediction, 13 / 17, matched exactly.
- **`CelebrationMountCallSiteTests`' open runtime question is CLOSED by this block's evidence.** A
  layer inside a presented cover really does inherit the centre from outside it — 2,761 pixels drawn,
  against a control where a wrong-surface layer draws 0. Both of block 3's probes had injected the
  environment themselves, so nothing had shown it at runtime.
- 2,810 → **2,823** tests. App coverage 27.42 % → **27.29 %** (12,949/47,457): the numerator did not
  move at all and the denominator gained 236, because every line this block adds is inside a SwiftUI
  view body — the structural gap CLAUDE.md already records for 108 files at 0 %.

### FEATURE: F-CTACelebrations-5 — inbox zero, the streak on 7, the daily goal  [x] COMPLETED

- **Room first, own commit:** `CaptureInboxService.swift:266-310` → `CaptureInboxService+Notes.swift`.
- Inbox zero in `CaptureInboxService+Celebrations.swift` after `removeCapture` in `sort`,
  `logToJournal`, `promoteToTask` (not discard — R-a); the list-less doors fetch once. The streak in
  `NudgesService.dismiss` via `NudgeStreak.landsOnSeven(before:after:asOf:)` (exactly 7 — R-b). The
  daily goal in `HomeView`: `ringCount`, `ringSettled`, `DailyGoalTracker`, the per-ACCOUNT day
  marker, `request(.milestone(.dailyGoal), at: ringOrigin)`; the centre plays `.success` for it
  (R-d). Both services take `celebrate:` as a defaulted init parameter from their hosts.
- Tests: `CaptureInboxServiceCelebrationTests`, `NudgesServiceStreakTests`, `DailyGoalTrackerTests`
  (first load never counts; rising across counts once; a lowered goal never counts; undo-and-recross
  refused by the marker; the marker is per account), call-site "the daily goal is observed from Home
  on both the count and the settle flag". Predicted red ≈ 17 tests. Evidence
  `screenshots/cta-celebrations-block-5/`: the milestone over the empty inbox light/dark; the still
  field under RM; a daily-goal burst over the Tasks tab; a downgraded milestone showing only the
  pop. Device verdict — **and E's call on the cooldown** (5 s for testing).

**Six ways the build differed from the block as written, each deliberate:**

1. **E's accessibility answer is "the daily goal only"** (asked at the start, as the register
   required). It announces itself; inbox zero and the streak do not. **But the premise behind
   that answer was partly wrong — see the register §A: the nudge card VANISHES on dismissal, so
   the streak does not leave "7 of 7 days" on screen. Back with E.**
2. **`DailyGoalTracker.observe` takes `DailyGoalRules`, not a bare goal.** The block said "a goal
   lowered under the count"; the two Settings toggles move the ring the same way with one tap, so
   the rules travel with the count and any change to them re-baselines.
3. **`ringSettled` needed a fourth stored flag**, `hasLoadedClearedCaptures`: 0 is both a real
   count and what a failed `try?` leaves, so "has the captures fetch succeeded" could not be read
   off the number.
4. **`CelebrationPopOrigin.onScreen` is new and was not in the plan.** `AppTabContent` parks a
   hidden tab 10,000 pt away and that offset reaches a `.global` reading (measured), so the daily
   goal — the one site that fires from a tab the user is not on — was throwing R-h's fallback pop
   off screen.
5. **`capturesClearedToday` became computed**, and **`cooldownAnchor` answers `now()` while
   anything is held**. Both are `feature-dev:code-reviewer` findings; the second is a defect in
   this block's own §B.00b fix.
6. **Tests: 60 added (2,824 → 2,884), not the predicted ~17**, across seven files plus a
   `RecordingCelebrationRequester` double and a `CelebrationCenterHeldBurstTests` split.

### FEATURE: F-CTACelebrations-PopScale — the pop at the size E chose on device  [x] COMPLETED

E's device pass on `-4` and `-5` PASSED both blocks with Reduce Motion OFF and ON. E then asked for
the pop itself to be bigger, in three messages: *"the scaling of the 'pop' needs to be increased
slightly"*, *"bigger spread too, not just bigger pieces"*, *"maybe slightly increase the amount of
confetti pieces"*.

Four variants rendered in situ on a real `TaskRow` (A as shipped / B 1.3× / C 1.6× / D 2.0×, all
three dimensions moving together); **E picked C**. One constant, `CelebrationRecipes.popScale = 1.6`,
carries size, throw speed and count so they cannot drift apart: `popCount` 12...20 → 19...32,
`stillPopSpread` 48 → 76.8, piece sizes and launch speeds × 1.6.

**The milestone's 120-piece still field is deliberately NOT scaled** — `piece(...)` is shared, so
`sizeScale` defaults to 1 and only the two pop paths pass `popScale`. Pinned by
`testTheMilestonesStillFieldKeepsTheConfirmsOwnPaperSize`, which stayed green through the red-check
that turned every other scale-dependent test red.

Red: naive 1.0 → 2 failures; the constant set to 1.6 but applied NOWHERE → 4 tests / 29 assertions,
which is what proves each dependent test load-bearing. Evidence
`screenshots/cta-celebrations-pop-scale/`, including a measured check that the shipped pop (28
pieces, 5,590 px, 208 pt) agrees with the variant E approved (29 / 6,100 / 208).

**Owes an RM-on device pass** — the still pop is a reduced site and it changed.

### FEATURE: F-CTACelebrations-NoCooldown — E removed the milestone cooldown  [x] COMPLETED

E, 2026-09-13, after living with it on the phone: *"Remove the cooldown entirely."* It shipped at
E's own 5 s testing value (F9), so this closes the question rather than reversing a settled answer.
`CelebrationPolicy.outcome` now takes no clock; `milestoneCooldown`, `lastFullScreenAt` and
`cooldownAnchor` are gone rather than left unread. **R-c goes with it; R-h does not** — the
switch-off fallback pop was never about the cooldown.

**The consequence, and it is E's decision:** two milestones that land together OVERLAP instead of
the second being downgraded — the rule E already approved for quick Confirms, still capped at three
by `CelebrationQueue.fullScreenCap`. Seven tests removed or rewritten, each named in the commit.

### FEATURE: F-CTACelebrations-SwipeOrigin — a swipe pops from the finger  [x] COMPLETED

E recorded the defect on the phone: swiping a task closed threw the confetti off the right of the
screen. **Two correct decisions collided.** `-4` gave the circle and the swipe ONE origin (they
share `close()`; wrapping the row would throw from its middle), and that origin is the CIRCLE's, at
the row's trailing edge — fine at the original throw, off-screen once `PopScale` took it to 208 pt.
Neither block could have seen it alone, no test caught it and no review pass did.

Two origins now, still one `close()`. `TaskRowSwipe.popOrigin(rowFrame:fingerInRow:)` is pure and
tested; the frame is measured on the same view the gesture is attached to so the drag offset is in
both or neither; the finger is resolved BEFORE `dragOffset` resets.
`testTheSwipeAndTheCircleClosePopFromOneOrigin` is REVERSED, not deleted.

### FEATURE: F-CTACelebrations-6 — the routine Completed flow (R1–R5)  [x] COMPLETED

- **Render FIRST:** `PlaceRoutineCongratulationView` light, dark, RM, the switch-off beat; send it.
- `PlaceRoutineCompletedCard` in the next-step slot once nothing is pending and the run is fully
  resolved (done OR skipped); `complete()`: `.success` → `store.end` + `recorder.ended(.completed)`
  → `activity.ended(); DataChangeSignal.post()` → `celebrate.request(.milestone(.routineFinished), at: buttonOrigin)`
  on the cover's OWN layer → the congratulation (display name from the same source Settings' account
  row reads, threaded through `RootView+Doors`; 5.4 s on a full-screen outcome, ≈ 2 s otherwise;
  tap anywhere skips). **`leaveScreen()` no longer ends the run; the background auto-end is
  removed** — leaving keeps a fully-ticked run LIVE (E's R1, reversing the routine-record rule).
  R-f: auto-only / all-skipped runs complete quietly.
- Tests: `PlaceRoutineCompletionTests` (Completed shows only when nothing is pending; leaving no
  longer ends a resolved run; Completed records exactly once; auto-only earns no celebration; the
  view's length follows the outcome; a tap skips), call-site "Completed plays the success feel,
  records, then requests on the cover's own layer", **and every test pinning the old rule updated
  by name** (the routine journey too — erase the simulator afterwards). Evidence
  `screenshots/cta-celebrations-block-6/`: the Completed card; the congratulation with confetti
  (full + still); the Today recovery card showing a live fully-ticked run. Device verdict.

**PLANNED IN FULL 2026-09-13 — see `handoff/START-HERE-cta-celebrations-6.md`.** A planning-only
session put the nine open questions to E, mapped every test the block touches and corrected three
things the design record got wrong. **Do not re-derive it.**

**E's nine answers (five are E's own wording or a reversal of what was offered):**
1. R-f's "completes quietly" = **the congratulation, no confetti, ≈2 s**; the run still ends and
   still records. Same beat as the switch-OFF case.
2. The congratulation carries a **per-step list** under the summary line, naming every step.
3. The Completed card's title is E's own wording: **`"4 of 4 done - Ready to finish?"`**
4. An auto-done step is distinguished by a **word**, not a second glyph.
5. The summary line is **done-of-total, always** ("3 of 4 steps"), so it can never disagree with the
   list beneath it.
6. A long list **shows every step and shrinks to fit** — E: *"showing every step as outlined is
   appropriate"*. No scrolling (it would fight tap-to-skip).
7. The short ≈2 s beat is the **same view, just shorter** — full list, no confetti.
8. Today's card **swaps its button label** when nothing is pending: "Finish routine" /
   "Continue routine".
9. The step list **reuses `PlaceRoutineStepCircle` exactly as the resolved rows draw it** — accent
   circle + `checkmark` for done *and* auto-done, `cardBorder` circle + `minus` for skipped, plus a
   state word. **No `✗`**: the app uses `xmark` only as a Close button.

**Three corrections the plan carries:**
- **The binding ceiling is `type_body_length` 250, not `file_length` 400.** The body is at **235**
  (15 lines of headroom). The `#if DEBUG` preview block is OUTSIDE the body, so moving it buys 61
  *file* lines and **zero** body lines — **both** moves are needed, and it still lands ≈251.
- **A `+Completion.swift` for `complete()` CANNOT WORK** — `private` is file-scoped.
- **The probe recipe is `screenshots/cta-celebrations-block-2/README.md`, not block 3**, and no
  probe code survives anywhere: it is re-implemented from a spec.

**Three booby-traps:** the `store.end` → `record` **adjacency** (nothing between them); the **unique
anchor** `"Button(title) { Haptics.play(.solid)"`; and the **`leaveScreen()` == 5** raw-source count
— which drops to **3, not 4**: one of the five occurrences is inside the `:77-83` COMMENT that C6
rewrites, and C6 also deletes the scenePhase hook. `grep -c` after the edits rather than trusting a
number written in advance.

---

## ⚠ BUILT IN FULL, 2026-09-13 — C1–C9 done, awaiting E's DEVICE VERDICT

**C6–C9 finished in a second session.** Suite **2,958 / 0** (emulator up, 0 `9099` hits), lint
**0 / 801**, sim build green, **both UI journeys green** — the reversed one first run. The block is
on `feature/cta-celebrations-6` behind a PR; nothing is on E's phone yet, and **§7.3's RM-on device
pass is OWED** because C6 adds this block's reduced site (the congratulation's entrance).

**The one thing worth carrying forward, and it is not a layout.** `PlaceRoutineProgress.earnedCelebration`
— E's R-f build default, unit-tested across four shapes — **had no call site**, so the first wiring
of `complete()` threw full-screen confetti over a run of 1 auto step and 3 skips: exactly the run
E's answer 1 says completes quietly. Ten call-site guards, 2,957 unit tests and both journeys were
GREEN while it did. What caught it was looking at the journey's own screenshot. Seventh recorded
instance of this repo's most repeated defect, and the first found by the `screenshots/` practice
rather than by a later block tripping over it.

**Three more things the plan said that turned out otherwise:**
- **The `leaveScreen()` count stayed 5, not 3.** The plan predicted it would drop; the scenePhase
  hook did go, but the congratulation's own tap-to-close replaced it. The plan's real instruction —
  `grep -c` and set the number to what is THERE — is what mattered, not either prediction.
- **No haptic in `complete()`.** The plan's order list opened with `Haptics.play(.success)`, but C5
  had already put it on the Completed button itself, where the press is. A second would double-buzz.
- **Type-body headroom was never the binding constraint it was billed as.** The screen landed
  comfortably inside 250; what actually broke the bar was the TEST files — two call-site classes and
  the UI journey all crossed a length rule and needed splitting.

**E ADDED A FEATURE MID-BLOCK and answered NINE more questions — five reverse something settled,
two of them E's own earlier answers. All nine are built.** E: *"i want to add a small section within
the empty-space on the cards that display detailed data and info about that specific routine that
was run."*

1. "Started" is **BOTH** the crossing (`Arrived`) and the tap (`Started`) — the model holds both and
   they can be forty minutes apart.
2. "Finished" is **BOTH** the last step and the Completed tap — E's own R1 is what makes them differ.
3. The facts are the **total**, the **time per step**, and a **comparison with your usual** (which
   needed a Firestore history fetch threaded into the cover).
4. A long step list **SCROLLS** — **reverses E's answer 6** ("shrink to fit, no scrolling").
5. The view **STAYS UNTIL DISMISSED** — **reverses R5's auto-leave**. `hold(for:)` and `quietBeat`
   are deleted; "Skip" becomes "Close"; **E's answers 1 and 7 now survive only in the confetti
   dimension**, because "shorter" no longer exists.
6. The detail block is **pinned above the scroller** — inside it, a 20-step routine would hide the
   times behind the very scrolling they must survive.
7. The light-mode wash is **0.40**, picked by sight from a rendered ladder; **dark stays 0.14** and
   was never part of the question. Pinned like `peekStep` — do not tidy them into one number.
8. Clocks are **"1:00 pm"** — 12-hour, minutes always, **no seconds** — **reverses E's own
   `hh:mm:ss`**. The locale is deliberately OVERRIDDEN: `en_GB`/`de_DE`/`fr_FR` all default to
   24-hour, and those readers are what E's "MUST" is about.
9. The detail card takes a **done-green border** (it already had a 1pt one — the problem was
   contrast, not absence); "Longer than usual" is **accent blue**, because grey read as an
   afterthought and green read as praise for taking 43 minutes.

Plus, on seeing the render: *"reword the 'Skipped 2m'"* → rows read `Done in 2m` /
`Skipped after 2m` / `Auto` (no number — an auto step always resolves instantly).

**A defect worth remembering: the run being celebrated was in its own fetched history**, so it was
always its own fastest and the verdict was timing-dependent on whether a network write had landed.
Fixed test-first in `7300c36`; `excluding runId:` is required rather than defaulted.

### FEATURE: F-CTACelebrations-7 — the chime  [x] COMPLETED

- `CelebrationSound.swift`: `CelebrationSoundPlaying` (+ inert); one `AVAudioPlayer` from
  `Assets.xcassets/CelebrationChime.dataset` (`.caf` PCM), `.ambient` + `.mixWithOthers` re-asserted
  before EVERY play, never `setActive(false)`; the centre's default player; the sound switch live.
- Candidates: three `sox`-synthesised chimes + one or two ElevenLabs sound-effect generations,
  peak-normalised, sent with `SendUserFile`; **E picks by ear**; the pick into the dataset, the
  candidates into `screenshots/cta-celebrations-block-7/` with the README.
- Tests: the asset resolves; the session is set ambient + mixing before every play; a missing asset
  degrades to silence. Predicted red 3 / 3. Closes on E's pick and a device verdict with music
  playing and the silent switch on.

**DONE 2026-09-13.** E picked by ear — *"'el-a.mp3' is a good Sound effect"* — and passed the
device verdict on both checks: *"both work correctly"* (chime under music without pausing it;
silent when the ring switch is off). Suite **2,975 / 0**, lint **0 / 806**.

**Three things worth carrying out of it:**
- **E RESERVED the runner-up.** *"keep a hold of the sound 'el-b' ... there is likely other
  locations that [it] Could be used."* It lives in `screenshots/cta-celebrations-block-7/candidates/`
  as `.wav` AND a ready-to-ship `.caf`, deliberately NOT in the asset catalog — an asset with no
  call site is dead weight in every build.
- **A green asset test can still not touch the asset.** Every unit test injected `loadAsset`, so
  nothing proved `NSDataAsset(name:)` resolves at runtime; `assetutil` on `Assets.car` proves the
  bytes ship and nothing else. The fix is one test that uses the DEFAULT loader.
- **The Settings footer carried TWO stale claims**, and only one was this block's: the sound
  "does nothing until the chime arrives", and the milestones being "still to come" when all four
  have had call sites since `F-CTACelebrations-4`. Footer prose is checked by no compiler.

### FEATURE: F-CTACelebrations-Surfaces — hold a celebration behind any unknown sheet  [x] COMPLETED

**E's call, 2026-09-13**, answering register §0b (raised by the `apple:hig-reviewer` pass on `-5`
and never closed). Offered "add Quick Capture only", "hold behind any unknown sheet", "accept it"
or "defer", E chose **hold behind any unknown sheet**.

**The problem.** Only four surfaces call `surfacePresented` (root, routine cover, Tasks search,
promote sheet). Every other `.sheet` / `.fullScreenCover` in the app — **Quick Capture**
(`RootView.swift`, arguably the most-opened full-screen surface), Settings, Add Task, the Journal
composer, the focus detail, add nudge, the Life Area / Place / Tag editors — leaves `frontmost`
reading `.root`, so a milestone requested then is drawn on the root layer BELOW the sheet:
invisible, while still marking the day and firing the haptic and the announcement.

**The rule:** a full-screen celebration requested while ANY untracked presentation is up is HELD and
released when it closes — the mechanism `.promoteSheet` already uses (`CelebrationSurface.dismissesItself`
plus the centre's `held` list), and the existing **R-g 60 s drop** applies unchanged.

**The hard part, and it is the whole block: knowing a sheet is up.** iOS hands us no such signal, so
this needs a deliberate seam rather than a guess. That design question is OPEN and is the first
thing the block must settle — do not start by writing the hold.

**DONE 2026-09-13.** Suite **3,001 / 0**, lint **0 / 812**, `** BUILD SUCCEEDED **`.

**The design question, settled first as the spec demanded.** Two designs were put to E — a house
modifier on all 26 `.sheet` / `.fullScreenCover` presenters, or asking UIKit — with the catches,
the misses, the cost and what keeps each honest. **E chose asking UIKit**, and in the same answer
chose that the hold covers alerts, confirmation dialogs and system pickers too, and that a pop is
left alone.

- `CelebrationPresentationProbe.swift`: `PresentationProbing`, the `KeyWindowPresentationProbe`
  that walks `connectedScenes → keyWindow → rootViewController` recursing through `children`, and
  the inert `NothingPresentedProbe` the tests default to.
- `CelebrationCenter`: **`isBlocked` is the one predicate behind both the hold and the release**,
  so they cannot disagree about what "in the way" means. The probe is read only from `.root` — the
  simple form, chosen over reconciling probe DEPTH against `presented.count`, because every other
  tracked surface IS a presented controller and an unconditional read would hold exactly what those
  surfaces mount layers to draw.
- **The release is the price of E's choice, and it was the only real cost.** Tagging presenters
  would have given an exact `onDismiss`; an untracked sheet says nothing when it closes, so the
  centre looks — a watch that runs ONLY while something is held, ticks four times a second and
  cannot outlive R-g's sixty. **R-g is now enforced by TIME rather than by the next dismissal**,
  which behind an untracked sheet would never have come.

**Four things worth carrying out of it:**
- **`F-CTACelebrations-7`'s lesson came back twice in one block, and the second time was sharper.**
  Three green files proved three separate things — the centre holds when a probe says so, the probe
  finds a UIKit presentation, the app gets the real probe — and none of them was the claim. The app
  presents no UIKit modals. So: `CelebrationProbeSwiftUISheetTests` hosts real SwiftUI `.sheet`,
  `.fullScreenCover`, `.alert` and `.confirmationDialog` in a real key window, and
  `CelebrationUnknownSheetCompositionTests` runs the real centre with the real probe over a real
  sheet with only the clock injected. **Ask what exercises the real seam — and then ask whether
  that test is feeding it the real INPUT.**
- **Every one of those tests passed first time, which is not evidence.** Both were mutation-checked
  against the live probe: forced to `false`, 8 of the 11 fail; forced to `true`, exactly the 3
  "reads clear" controls fail. No test survives both, and the control tests are what stop the
  positive ones being vacuous.
- **A measurement that corrected a comment before it shipped.** The walk's recursion was documented
  as "the reason" it recurses; measured, SwiftUI seats a hosted `.sheet` on the ROOT hosting
  controller, so on this SDK the one-line read would have done. The recursion is defensive, the
  comment now says so, and the test keeps it capable.
- **`onDismiss` runs AFTER SwiftUI has torn the sheet down**, so the shipped promote-sheet path
  releases immediately rather than waiting 0.25 s for the watch. That is a fact about SwiftUI, not
  about this app, and `testSwiftUIRunsOnDismissAfterTheSheetIsAlreadyTornDown` pins it — the day it
  changes, a celebration E has already signed off gets slower and nothing else would notice.

~~**Owed: E's device pass.**~~ **PASSED ON DEVICE 2026-09-13** — E, on `main @ 1920536`:
*"you can mark a PASS to 'the celebration hold' checklist item"*. **Nothing is outstanding.**
No `#available` site and no Reduce Motion site is added or changed, so **§7.3's RM-on pass was not
owed** and no `screenshots/` folder is earned (the rule asserts what a test cannot; the hold is
asserted). What tests could not reach is the app's five request sites firing while a real sheet is
up — that was the device check, and it needed the phone to be carrying the build, which it was not
when this was first written (see `F-FocusCard-Corners` below).


### FEATURE: F-FocusCard-Corners — round the collapsed card's bottom corners (E: "Round them", 2026-09-11)  [x] COMPLETED

After the arc. Round the collapsed focus card's BOTTOM corners and give
`FocusBarCardShape.roundsBottomCorners` `animatableData` so the corner morph stops snapping inside
the 350 ms spring. Test-first; render before and after; device verdict.

**DONE 2026-09-13.** Suite **3,008 / 0** (0 × `9099`), lint **0 / 812**, `** BUILD SUCCEEDED **`.

**E's direction was a word; the number came from a render.** Told *"Round them"*, the block put the
collapsed card at 0 / 8 / 16 / 24pt against the real `AppTabBar` and E chose **24 — "match the
top"**, with "leave it square after all" offered explicitly and not chosen
(`screenshots/focus-card-bottom-corners/`). It is spelled as `cornerRadius`, not as a literal 24,
because what E chose was *match the top*.

- `FocusBarCardOutline` builds the silhouette from a top radius and a bottom one, and **both the
  fill and the keyline are cut from it**. That sharing is the point: rounding the fill alone leaves
  the keyline tracing 24pt of a corner the card no longer has. The fill closes the path to get the
  flat bottom run; the collapsed keyline leaves it open to go without, so E's 2026-09-09 *"REMOVE
  the bottom border"* survives the rounding rather than being quietly reversed by it.
- `UIBezierPath(roundedRect:byRoundingCorners:)` is gone — it applies ONE radius to whichever
  corners are selected, fine for a flag and useless for a morph. Radius 0 draws the square corner
  rather than a degenerate arc, because zero is a real state: the floor of the morph.

**Three things worth carrying out of it:**
- **E's pick made the block's own second half inert, and saying so is the point.** The brief asked
  for `animatableData` so the corner would stop snapping mid-spring. With equal radii the two
  states no longer differ and nothing interpolates — **the snap is gone because the DIFFERENCE is
  gone**. The wiring stays (a `Shape` with a continuous parameter should declare it, and the day
  the numbers differ again it morphs), and the code says it is currently inert rather than
  implying a morph that does not happen.
- **The render's first pass had the draw order backwards** — bar over card — and the whole question
  is what shows through the notch where they meet. `RootView` mounts the bar as a `.safeAreaInset`
  (`:203`) and `RootBottomOverlay` as an `.overlay` after it (`:229`), so the card is on top. A
  probe that does not reproduce the app's z-order is answering a different question.
- **Three places said the bottom corners were square and one argued at length that this was the
  only correct answer.** The reasoning was sound and E overruled the conclusion. All three now
  carry both, including the design record's postscript table — the specification above it stays as
  written, which is what that table is for.

~~**Owed: E's device verdict.**~~ **PASSED ON DEVICE 2026-09-13** — E: *"they look okay"*, with two
screenshots filed as `screenshots/focus-card-bottom-corners/02-device-collapsed-light.jpeg` and
`03-device-collapsed-dark.jpeg`. **Nothing is outstanding.** No RM-on pass was owed (§7.3): no
`#available` site is added, and the only Reduce Motion interaction is the existing
`.animation(reduceMotion ? nil : .spring(...))` on the collapse, which this block does not touch.

**A fourth lesson, and it cost E a wasted look rather than a wasted build.** E's first device check
found nothing — *"i cant see any change on my iphone"* — because the phone was still on `eade58a`,
two PRs behind, while BOTH this block and `-Surfaces` had been reported as "owed: E's device
verdict" as though the code were installed. The change was correct the whole time; the corner E
then pointed at as the one they wanted was a render **of the code already on `main`**.
***Owed a device check* and *the code is on E's phone* are different facts** — install as part of
the close-out and write the SHA the phone carries. `device-build-lag` already said "don't leave the
phone behind"; the register's own "device verdict owed" wording is what made it easy to miss, and
both it and the live opener now say which.


### FEATURE: F-LandscapeFabOverlap — the capture disc stops climbing into the header in landscape  [x] COMPLETED

**E's bug, found on the phone 2026-09-16 (iOS 27.0, `560d068`):** in **landscape**, with an
unacknowledged **"Sprint finished while you were away"** card up, the capture disc rendered ON the
Settings gear and the gear could not be tapped (`screenshots/ios27-device-findings/04-…jpeg`).
Handed to this session by `handoff/START-HERE-fab-overlap-and-tab-inset.md` with the cause marked
as a HYPOTHESIS to verify before writing anything. Not an iOS 27 regression.

**Diagnosis (verified by arithmetic, then reproduced in a journey — see the verification note below).**
`RootBottomOverlay` is an `.overlay(alignment: .bottom)` whose one `VStack` holds, top to bottom,
the disc row, the away card, the completion stack and the timer bar, over a 100pt lift
(`bottomFurnitureLift` = 32 gap + 68 bar band). A landscape iPhone 15 Pro has **372pt** of safe
height; the away card measures **186pt**; 372 − 100 − 186 − 8 − 60 puts the disc's top at
**18pt** — inside the header's 40pt gear well (y 8–48). The expanded sprint card alone (148pt)
leaves the disc at 56, eight points clear, which is why "neither alone did it". The hypothesis
was right in kind and wrong in one word: the stack does not overflow the screen, it FILLS it.

**The fix, and the shape it must keep.** The stack is E-reviewed and deliberate: "an active
sprint PUSHES the disc up rather than letting the timer bar occlude the disc's controls". That
invariant is kept in portrait byte for byte. In **compact height** (the landscape iPhone — the
`verticalSizeClass` reading `CaptureFanOverlay` and `LoginView` already use) **with any card up**,
the cards take a column BESIDE the disc instead of above it: the disc keeps its resting corner,
nothing pushes it, nothing covers it, and the gear's column stays clear because the cards column
ends 100pt short of the trailing edge. With nothing up, compact height is the ordinary row, so the
search row on Tasks is untouched. The rule is pure — `RootBottomOverlayLayout.arrangement(
isCompactHeight:hasCards:)` — and the view only asks it.

**Acceptance criteria**
- [x] `RootBottomOverlayLayoutTests` — the bug as arithmetic from production constants and E's
      measurements; the rule over all four inputs; the two named spacings.
- [x] `RootBottomOverlayCallSiteTests` — the overlay reads `verticalSizeClass`, calls the rule,
      builds both arms, the side-by-side arm is bottom-aligned, **and the stacked arm still puts
      the disc row above the cards** (the invariant, pinned by order).
- [x] `LandscapeAwayCardUITests` — the regression camera: away card raised through the app's own
      UserDefaults key (argument domain, `UITestUserDefaultsSeeds.swift`), portrait asserted as the
      control, then landscape: disc ∩ gear = ∅, gear hittable, gear opens Settings, card ∩ disc = ∅.
      **Fails on the unfixed tree** (the reproduction), passes on the fixed one, red-checked by
      reverting the fix.
- [x] Portrait unchanged: `CaptureDiscClearanceUITests` and the sweep's bottom band as before.
- [x] `screenshots/landscape-fab-overlap/` — before/after landscape frames, light and dark, README.
- [x] SwiftLint 0, suite green, sim build green; pasted.

**DONE 2026-09-17.** Suite **3,025 / 0** (3,011 + 14 new; 0 × `9099`, 58 emulator cases), SwiftLint
**0 / 819**, `** BUILD SUCCEEDED **` (37 distinct warnings, unchanged from Phase C; 0 errors),
coverage **27.67% (13,399/48,433)** — numerator +43 on a denominator +76, the layout file and the
overlay's new lines.

**The hypothesis survived, corrected in one word.** The opener said the stack "pushes past the
header"; the arithmetic says it FILLS the screen — 372 − 100 − 186 − 8 − 60 = 18 — and the
journey printed the same sum on the 17 Pro simulator to the point (381 − 100 − 196.7 − 8 − 60 =
17.3; the disc's frame read 17.3). Reproduced BEFORE anything was written: the journey failed at
its landscape assertion on the unfixed tree, with the portrait control passing.

**Why a `Layout` rather than a `switch` between a `VStack` and an `HStack`.** Changing the
container TYPE gives the children new identities, and `FocusTimerBar` owns the sprint detail
sheet's `@State` — a rotation with that sheet open would have dismissed it. `RootBottomOverlayArrangement`
is a `Layout` (iOS 16.0, no gate) whose arrangement is a property; the geometry is delegated to
`RootBottomOverlayLayout` so the numbers on screen are the numbers the tests hold.
`testTheOverlayDoesNotSwitchContainerTypesOnTheArrangement` pins the choice.

**RED / GREEN / red-check, all pasted in the session.** RED: the test target did not compile —
25 distinct errors, 21 of them `cannot find 'RootBottomOverlayLayout' in scope`. GREEN: 14 / 0 in
the two new classes. Red-check with `RootBottomOverlay.swift` reverted to `main`'s, one regression,
predicted before running: the call-site class **3 / 5 failed** (`ReadsTheVerticalSizeClass`,
`AsksTheRule`, `ContainerIsTheArrangementLayout` — exactly the three that read the overlay's use of
the rule; the two that read the Layout file stayed green, as predicted) and the 9 pure tests stayed
green; the journey failed on the landscape assertion with the disc back at y 17.3. Restored with
`git checkout --`; final journey PASSED on **26.5 light and 27.0 dark**, disc at y 222.

**Two harness facts worth more than the fix:**
- **The away card can be raised at launch without a production seam**: `-focus.sprint.unacknowledgedCompletion
  "<hex>"` in `launchArguments` lands in the UserDefaults argument domain as `Data` (the old-style
  plist spelling), and `restorePersistedSprint()` reads it through the store it uses in production.
  Verified on macOS's CoreFoundation first, then by the card appearing. `UITestUserDefaultsSeeds.swift`.
- **The AutoFill "Save Password?" sheet cost one false failure**: the second run's portrait control
  read the gear as un-hittable with frames identical to the passing run's, 70 s after sign-in on a
  simulator slowed by a concurrent SwiftLint. The next run's sweep logged the dismissal. The control
  now sweeps with the sweep harness's 5 s wait and polls hittability, attaching the hierarchy on a
  miss. **Do not run anything CPU-heavy beside a UI run.**
- `app.screenshot()` lied on the rotated simulator again (F-LandscapeFix's finding); the evidence
  frames are host-side `simctl io screenshot` polls while the test holds each pose.

**No RM-on device pass is owed (§7.3):** no `#available` site and no reduced-motion site is added
or changed; the three `.animation(reduceMotion ? nil : …)` modifiers are untouched.

**Owed: E's device verdict on the side-by-side arrangement** — the card bottom-left, the disc in
its corner (`screenshots/landscape-fab-overlap/README.md`, "Open, for E on the phone").

**E's device verdict, 2026-09-17 ~06:00 — NOT passed as it stands, and it became a block.** E ran a
sprint in landscape (`screenshots/landscape-fab-overlap/16–17`) and answered: *"it needs to have
some margin space added BELOW the card bottom-left AND ABOVE the NAV tab menu bar."* Measured: the
expanded card already sits 33pt above the bar, but the COLLAPSED bar sits on it (the 2026-09-09
flush drop). Asked, E narrowed it to the collapsed bar, **in portrait too**, lined up with the disc.
See **`F-CollapsedBarLift`** below. The side-by-side arrangement itself was not questioned.


### FEATURE: F-TabBarPillInset — the resting pill's inset, E's pick from rendered options  [x] COMPLETED

**E's call (2026-09-17, in chat, after looking at the four rendered options):** *"regarding the
pill inset I think that padding 12 is the right choice for now."* The options and the two catches
(12 off-grid; 16 breaks the SE floor) are in `screenshots/tabbar-pill-inset-options/README.md`;
the why is round 4 of `handoff/SESSION-OPENER-tabbar-select-pill-design.md`.

**The change:** `AppTabBarMetrics.floatingPaddingHorizontal` 4 → **12**, and nothing else on the
bar. The scrolled chip inherits it (one card in both states). Off §2's grid by E's explicit
waiver — the second, beside `peekStep = 14` — recorded in CLAUDE.md §2.

**Acceptance criteria**
- [x] `testTheCardsInnerPaddingIsTheValueEChoseByLooking` pins 12 and says why (RED at 4 first).
- [x] `testRestingSlots_clearTheTouchTargetFloorBesideTheWidestPillOnTheSE` moves to 44.6 and
      still clears §3's 44 (RED at 4 first: 47.8 ≠ 44.6).
- [x] Red-check: constant back to 4 → exactly those two fail; constant at 16 → the pin AND the
      floor's `>= 44` fail. One regression at a time.
- [x] CLAUDE.md §2 names the second waiver; the design record carries round 4.
- [x] A render of the SHIPPED tree (not the probe) in the options folder, and the build on E's phone.
- [x] SwiftLint 0, suite green, sim build green; pasted.

**DONE 2026-09-17.** RED at 4: exactly the two predicted (47.8 ≠ 44.6; 4 ≠ 12), 29 green. GREEN
31 / 0. Red-check one regression at a time, after the commit: **back at 4 → the same two**; **at
16 → the two tests, three assertions** (43.0 ≠ 44.6, 43.0 < 44, 16 ≠ 12); restored with
`git checkout --`. Suite **3,026 / 0** (0 × `9099`), SwiftLint **0 / 819**, `** BUILD SUCCEEDED **`
(37 distinct warnings, unchanged; 0 errors), coverage 27.67% (13,399/48,433) — a constant moved,
no line count did. Shipped tree rendered (`tabbar-pill-inset-options/08–11`). **Owed: E's look at
12 on the phone** (installed with this close-out). No RM-on pass: no motion site touched.

**E's device verdict, 2026-09-17: PASSED** — *"regarding the pill at 12 - i think it looks
perfect."* Nothing outstanding.


### FEATURE: F-FanCardsFade — the sprint cards fade out while the capture fan is open  [x] COMPLETED

**E's finding (2026-09-17 03:44, six device frames, `screenshots/landscape-fab-overlap/09–12`):**
with a card up — the live Confirm card or the away card — opening the capture fan drew the card
crisp ABOVE the fan's scrim, and in portrait the away card hid the LINK and TASK tiles so two of
the five capture kinds could not be tapped. **E's call, verbatim: *"Fade the cards out while the
fan's open."*** (Option A of the three put to E; the arc's anchoring stays as it is — moving the
arc's origin up with a pushed-up × risks the top tiles going off the top edge, the clipping the
landscape fan exists to avoid; a separate question for E if the resting-corner origin bothers
them once the cards are gone.)

**Why it happened, from the code:** `RootView` mounts `RootBottomOverlay` as a later `.overlay`
than the fan, deliberately, so the disc (the fan's ×) stays crisp and tappable — the cards rode
above the scrim with it; and `CaptureFanOverlay` anchors its tiles to the screen's bottom-trailing
corner, the disc's RESTING spot, so a card that pushes the disc up puts the tiles under itself.

**The change, and its shape.** `RootBottomOverlayLayout.cardsPresence(fanIsOpen:)` — opacity AND
hit-testing together (an invisible card that still took the tap would be the same bug with better
lighting) — applied to the cards column as `.opacity` + `.allowsHitTesting`, **never an `if`**:
removal would collapse the column and drop the × into its corner the instant the fan opened,
moving it from under the thumb. The whole column fades — away card, Confirm stack AND the running
timer bar — because the fan is momentary and one rule beats three. Reduce Motion: the same fade on
`.default` (§5's one exception; the geometry never moves, so §7.2's opening-pose rule is met by
construction).

**Acceptance criteria**
- [x] `RootBottomOverlayLayoutTests` — open → (0, no touches); closed → (1, touches). RED first.
- [x] `RootBottomOverlayCallSiteTests` — the overlay asks the rule, modifies the cards with
      `.opacity(` and `.allowsHitTesting(` inside the container, and never gates them on `if`.
- [x] `FanOverAwayCardUITests` — portrait, away card up: open the fan; TASK and LINK (inside the
      card's frame, asserted) become hittable; Got it does NOT take touches; the disc's frame is
      unchanged by the opening; dismiss → Got it back. **Fails on the unfixed tree.**
- [x] Red-check by reverting the view; frames into `screenshots/landscape-fab-overlap/`.
- [x] SwiftLint 0, suite green, sim build green; pasted. RM-on device pass: **owed** — this block
      ADDS a reduced site (the fade under Reduce Motion), so E looks at it with RM on and off.

**DONE 2026-09-17.** RED: the test target did not compile — 2 distinct errors, both
`type 'RootBottomOverlayLayout' has no member 'cardsPresence'`. GREEN: **17 / 0** in the two
classes. Journey on the fixed tree **PASSED**: the disc's frame identical before and after the
fan opened (318, 475.3), TASK (314, 602) and LINK (301, 524) both inside the card's frame
(16, 543–740) and both hittable, Got it not hittable, card back on dismiss. **Red-check with the
overlay reverted to `main`'s, after the commit:** the call-site guard failed (one test, its three
assertions — the rule, `.opacity(`, `.allowsHitTesting(`), the pure tests stayed green as they
should, and the journey failed on exactly *"Fan open: the TASK tile behind the away card cannot
be tapped"* — the bug E photographed, reproduced by the same test that now passes. Restored with
`git checkout --`. Suite **3,029 / 0** (0 × `9099`), SwiftLint **0** (two line-length wraps in the
journey after the first run; re-run green on the final tree), `** BUILD SUCCEEDED **` (37
distinct warnings, unchanged; 0 errors), coverage 27.66% (13,404/48,461). Frames:
`screenshots/landscape-fab-overlap/13–15`.

**The whole column fades — the running timer bar too.** One rule beats three, the fan is
momentary, and a sprint's controls under a modal picker are not controls anyone reaches for.
Said here so nobody reads the timer bar's absence under the fan as a bug.

**Owed to E (two looks, one toggle):** the fade on the phone with Reduce Motion OFF, then ON —
this block ADDS a reduced site (§7.3's rule), so the reduced fade needs device time. And the
verdict on the arrangement itself. Verified paths line: **fade: run on sim + E's phone (RM off,
pending); Reduced: run on sim (injected by the `.default` branch) — NOT yet on device.**

**E's device verdict, 2026-09-17: PASSED, Reduce Motion OFF AND ON** (E: *"Right, Reduce Motion OFF
and ON"*). Verified paths, final: **fade: run on sim + E's phone (RM off). Reduced: run on sim
(injected) + E's phone (RM on).**

**One claim above is now SUPERSEDED by E's next call:** "never an `if`: removal would collapse the
column and drop the × into its corner the instant the fan opened, moving it from under the thumb".
Dropping the × into its corner is exactly what E then CHOSE (shape B, `F-FanXAtRest` below),
because a × that stays pushed up lands on a tile. The opacity-not-`if` shape still stands, for a
different reason (see that block). This paragraph stays as the record of why it read that way on
the day.

---

## E's three calls from the 2026-09-17 device looks — three blocks, built back to back

**Written 2026-09-17 by the session that collected E's looks. It built NOTHING, at E's
instruction:** *"I suggest that any building happens in a fresh Claude code terminal session."*
**E's pacing call for these three: build all three back to back WITHOUT stopping for review
between them, then ONE install and ONE set of phone looks** (E chose *"All three, one install"*
over the standing stop-after-each rule). Each block still gets its own branch, TDD, red-check,
PR and pasted output. Evidence for all three: `screenshots/landscape-fab-overlap/16–21` and its
README's two 2026-09-17 device sections (**the measurements are done; do not re-derive them**).

Recommended order: the × first (E called it a bug), then the bar lift, then the celebration hold.
The first two both edit `RootBottomOverlay`'s neighbourhood and do not conflict: block 1 moves the
disc ROW inside the Layout, block 2 removes an `.offset` inside `FocusTimerBar`.

### FEATURE: F-FanXAtRest — the × drops to its resting corner while the capture fan is open  [x] COMPLETED 2026-09-17

**The bug (E's GIF, `…/21-…gif`, and frame 19).** In portrait, any card in the bottom column
(the running sprint's bar, a Confirm card, the away card) pushes the capture disc up. When the fan
opens, the disc becomes its ×, but `CaptureFanOverlay` places the tiles from the safe area's
bottom-trailing corner (the disc's RESTING spot), so the × lands on whichever tile sits at the
pushed height. The tiles are 78pt apart, so ANY push collides:

| what is up | push | × lands on (15 Pro) |
|---|---|---|
| collapsed sprint bar | 68pt (measured, frame 19) | **TASK**, centres 9pt apart |
| Confirm card | 84pt (measured, the GIF) | **TASK**, 7pt |
| expanded sprint card | 156pt (arithmetic) | **LINK**, ~16pt |
| away card | 194pt (arithmetic) | between **PHOTO** and **LINK** |

E: *"The cause of the drifting FAB 'x' icon seems to be when there is an unresolved notification
such as a completed sprint."* Right about the effect. The cause is any card: frame 19 shows it with
a RUNNING sprint, before any notification existed. Landscape is unaffected, because the cards sit
beside the disc there (`F-LandscapeFabOverlap`).

**E's call (2026-09-17, chosen over A "move the arc up with the ×" and "render both first"):**
**B, *"× drops to its corner"*.** While the fan is open the × sits at its resting corner, and the
arc stays exactly as designed. The accepted cost: the × moves 68–194pt down from under the thumb as
the fan opens.

**Why the resting corner is correct, in numbers** (all from the safe area's bottom-trailing
corner, which both the fan's `GeometryReader` and the bottom overlay measure from): the resting ×
centre is 54pt from trailing (`CaptureDiscMetrics.edgeMargin` 24 + 30) and 130pt from the bottom
(`AppSearchRowMetrics.bottomFurnitureLift` 100 + 30, confirmed on the phone: centre y 688 on an
818pt safe bottom). The nearest tile, TASK at (57, 207), is 77pt away, and a tile (radius 31) and
the disc (radius 30) need 61pt. Every slot clears.

**The shape, as the collecting session worked it out (verify, do not trust):**
- **Pure rule:** `RootBottomOverlayLayout.frames(_:in:discRow:cards:fanIsOpen:)`. While the fan is
  open, the disc row's frame moves to the bottom line (`y = bounds.maxY − discRow.height`), and the
  cards' frames stay unchanged. It is a no-op in `.besideTheDisc` (already on the bottom line) and
  with an empty column (bounds height == disc row height). `sizeThatFits` is unchanged: the
  invisible cards still take their space, so nothing else reflows.
- **`RootBottomOverlayArrangement` gains `fanIsOpen`**, passed into `frames`. `RootBottomOverlay`
  builds it as `RootBottomOverlayArrangement(arrangement: arrangement, fanIsOpen: isFabOpen)`.
- **Animation:** it rides the existing `withAnimation(reduceMotion ? nil : .spring(…))` around
  `isFabOpen.toggle()`, since a `Layout` property change animates inside that transaction. **Under
  Reduce Motion the × moves with no animation**, the same as the disc's existing push when a sprint
  starts (`.animation(reduceMotion ? nil : …, value: focusService.isActive)`), which is §7.2's
  continuous re-layout case. It still CHANGES what the reduced path shows, so an **RM-on device
  pass is owed** (§7.3).
- **The cards keep the opacity + hit-test fade, never an `if`**, for a reason that is now the
  honest one: removing them would destroy `FocusTimerBar`'s `@State` (the detail sheet, the Stop
  confirmation) and swap the fade for a removal transition. The old reason ("the × stays where the
  + was") is reversed by this block.
- **The search row on Tasks rides down with the disc**, because it is in the same row. Look at it
  on Tasks with a sprint running before calling the block done.

**Tests that must be REVERSED, not deleted (the reversed-test habit, names and messages too):**
- `RootBottomOverlayCallSiteTests.testTheCardsFadeUnderTheFanByOpacityAndKeepTheirLayout`: keep the
  opacity / `allowsHitTesting` / no-`if` guard, and rewrite its rationale (see above).
- `FanOverAwayCardUITests`: `XCTAssertEqual(disc.frame.midY, discBeforeOpening.midY, …, "The disc
  moved when the fan opened")` becomes: the disc's `maxY` is on the column's bottom line (≈ the away
  card's `maxY`), AND every tile's centre is ≥ 61pt from the ×'s centre. **On the unfixed tree the
  distance assertion fails** (the × is 194pt up, on PHOTO/LINK). That is the red.
- Doc comments that say the × stays put: `RootBottomOverlay.swift` (the fade's comment) and
  `RootBottomOverlayLayout.cardsPresence`'s doc.

**Acceptance criteria**
- [x] `RootBottomOverlayLayoutTests`, RED first: stacked + cards + fan open → disc row on the bottom
      line, cards' frame unchanged; stacked + no cards + fan open → identical to closed;
      `.besideTheDisc` + fan open → identical to closed. *(RED: 13 compile errors. Plus the bug as
      arithmetic over the four card heights — 60/76/148/186 all land the closed × within 61pt of a
      tile, TASK for the collapsed bar — and the open × at rest for each.)*
- [x] A PIN (it passes on today's tree; mutation-check it both ways): every `CaptureFan.slots`
      centre is ≥ 61pt from the resting × centre, so a future arc or lift change cannot silently
      put a tile under the ×. *(Both fans, portrait and landscape. `CaptureFan.tileDiameter` named so
      the pin reads a production number. Mutation: TASK `fromBottom` 207 → 170 fails it at 40.1pt.)*
- [x] `RootBottomOverlayCallSiteTests`: the overlay passes `fanIsOpen: isFabOpen` to the Layout; the
      Layout passes `fanIsOpen` into `frames`; the reversed fade guard. *(Plus two the spec missed:
      the container's `.animation(value: isFabOpen)` — the scrim and tile pick set `isFabOpen` bare,
      so without it the × SNAPS back up — and the disc row's `.zIndex(1)`, whose effect inside a
      custom `Layout` is proved by render in `RootBottomOverlayDrawOrderTests`, with a control.)*
- [x] `FanOverAwayCardUITests` reversed as above. **Fails on the unfixed tree, passes on the fix.**
      *(RED: "the × (centre (348, 505)) sits on the PHOTO tile, 35.3pt apart". GREEN: × at y 680–740.
      Plus `SprintBarFurnitureUITests`, the Tasks look as an assertion, with a seeded PAUSED sprint:
      wiring cut → "sits on the TASK tile, 9.49pt apart" (E's frame 19: 9pt); fixed → the search row
      and the × drop together 612 → 680 and return.)*
- [x] Red-check by reverting the Layout after the commit; count the failures; restore with
      `git checkout --`. *(Mutation A, the fan ignored everywhere: exactly the 6 predicted cases.
      Mutation B, the disc always at rest: exactly the 2 predicted. Restore proven by a green run.)*
- [x] Evidence folder with a README: portrait fan open over a card, before and after.
      *(`screenshots/fan-x-at-rest/`, incl. 15 fps crops showing a real tween with the × in front.)*
- [x] SwiftLint 0, suite green, sim build green, all pasted. Verified paths line. **RM-on device pass
      owed** (with E's one set of looks at the end).

### FEATURE: F-CollapsedBarLift — the collapsed sprint bar stops dropping onto the tab bar  [x] COMPLETED 2026-09-17

**E's call, three answers, verbatim (2026-09-17):**
1. Landscape verdict: *"I think at this point, it needs to have some margin space added BELOW The
   card bottom-left AND ABOVE The NAV tap menu bar."*
2. Shown the measured frames (the expanded card already 33pt above the bar; the collapsed bar ~1pt,
   sitting on it) and asked which card: **the collapsed bar.**
3. Where: **"Portrait too."** This **reverses the flush drop** E chose on 2026-09-09 (*"Drop it
   flush to the tab bar"*) and kept through `F-FocusCard-Corners` (*"the flush drop STAYS"*). It
   was offered as landscape-only (recommended) and E chose both.
4. How much: *"Line up with the Disc, But when there are multiple cards being displayed, then
   maintain the alignment."*

**What that means in the geometry (the collecting session's reading; say it in the report):** the
drop is purely visual. `FocusTimerBar` applies `.offset(y: isCollapsed ?
FocusBarMetrics.collapsedOffsetY : 0)`, which is +32, and deliberately not padding, so the LAYOUT
frame has always sat on the disc's line. Removing the offset puts the collapsed bar's bottom on the
same line as the expanded card and the resting disc: `bottomFurnitureLift`, 32pt above the bar.
Nothing else moves: the disc, the Confirm stack and the column's frame are all laid out from the
un-offset frame. **"Maintain the alignment with multiple cards"** then holds by construction. A
Confirm card above the collapsed bar sits the column's 8pt above it (today, visually, 8 + 32 =
40pt). In landscape the column is bottom-aligned with the disc row (`frames(.besideTheDisc)`), so
the bar's bottom lands exactly on the disc's. In portrait the disc is ABOVE the column, so "line up
with the disc" can only mean the disc's resting line. Say that explicitly.

**Consequences that follow from E's call (not new design; name each in the report):**
- **The bottom keyline comes back.** E removed it on 2026-09-09 only because the card sat on the bar
  (*"REMOVE the bottom border on the collapsed card tab"*: a hairline at the join read as a seam).
  With no join, a card outlined on three sides looks unfinished. Stroke the full outline in both
  states. `FocusBarCardBorder.omitsBottomEdge` then has no caller that passes `true`, so **delete
  the parameter** (the dead-shared-component pattern) rather than leave it always false. Check
  whether `FocusBarCardBorder` then collapses into a plain `strokeBorder` of `FocusBarCardShape`.
- `FocusBarMetrics.collapsedBottomLift` / `collapsedDrop` / `collapsedOffsetY` exist only for the
  drop. Delete them, or reduce them to the one statement the new rule needs. Do not leave a named
  zero.
- The bottom corner radius stays 24 (E's "match the top"), and `animatableData` stays inert.
- **Check the scroll clearance:** the bar now floats 32pt higher. Confirm the last row of a
  scrolled screen still clears it (the clearance reads layout frames, which do not move, but
  verify on the sim rather than assuming).

**Tests that pin the drop and must be REVERSED:** `FocusBarGeometryTests` (≈ lines 40–100: the
collapsed lift == `AppTabBarMetrics.rowHeight`, `collapsedDrop == −gapAboveTabBar`,
`collapsedOffsetY == gapAboveTabBar`; ≈ line 229, `omitsBottomEdge: collapsed`) and
`FocusBarCollapseCallSiteTests` ≈ line 88 (the source contains `FocusBarMetrics.collapsedOffsetY`).
Read each test's doc comment before rewriting: several carry E's words, and those words need a
"reversed 2026-09-17" note, not a silent edit.

**Acceptance criteria**
- [x] RED first: the collapsed bar's bottom lift equals the expanded card's (the disc's line); the
      outline is closed in both states; a call-site guard that `FocusTimerBar` applies no collapse
      offset.
- [x] The pinning tests above reversed, with their E quotes kept and annotated. *(RED: 4 compile
      errors on `FocusBarMetrics.bottomLift`. Reversed in place, names too: flush → on the disc's line;
      flush in both bar states → the margin in both bar states; the drop's sign → the drop's metrics are
      gone; no bottom keyline → keyline back; radius-0 no run → radius-0 closes; the offset guard → no
      vertical offset or negative padding. Plus a keyline guard: `cardShape.strokeBorder(` and no
      `FocusBarCardBorder`/`omitsBottomEdge` left. `FocusBarCardBorder` deleted; three drop metrics
      reduced to `FocusBarMetrics.bottomLift`.)*
- [x] Rendered evidence in BOTH orientations, collapsed bar alone AND with a Confirm card above it:
      the before/after gap, measured, in a README.
- [x] Red-check (restore the offset → the new tests fail, count them); restore. *(Offset + metric +
      an open `stroke`: exactly the 3 predicted cases, 4 assertions. Restore proven 3,040 / 0. And the
      journeys, RED on `main` @ `ad4f3ee`: bar 32pt off the disc's line and 0pt above the tab bar in
      both orientations, alone and under a Confirm card; GREEN: 0 and 32, Confirm button → bar 56 → 24.
      `screenshots/collapsed-bar-lift/`.)*
- [x] SwiftLint 0, suite green, build green, pasted. RM: the collapse animation's
      `reduceMotion ? nil` is untouched (height and position re-layout). If it is touched, the RM-on
      pass is owed. Say which in the report.

### FEATURE: F-FanHoldsCelebration — a full-screen celebration waits while the capture fan is open  [x] COMPLETED 2026-09-17

> **E NARROWED THIS BLOCK in the build session, 2026-09-17, and the two answers govern it.** Frame 20
> (`IMG_8521`) was NOT a request made while the fan was open: its fireworks are a stack-clearing
> Confirm (`CelebrationLayer` draws fireworks only for `clearedStack`), the only Confirm caller is the
> card's button (not hittable under the fan), and the × sat at rest (no card up). E confirmed it: the
> screenshot was taken after E had confirmed the sprint, so the celebration was ALREADY PLAYING when
> the fan opened. Walked through today / replay-after-close / hold-new-only, **E chose "Only hold new
> requests"** — a celebration already playing keeps playing over the fan, exactly as in that frame —
> and **"Same 60s rule"** for waiting behind the fan. So this block changes what a celebration ASKED
> FOR while the fan is open does; in practice that is the daily goal or the 7-day streak landing in
> the background (a Confirm cannot be tapped under the fan).


**The evidence (frame 20, `IMG_8521`):** a 30-second sprint ended while the fan was open, and a
full-screen celebration (fireworks and confetti) played OVER the open fan, dimming the tiles.
**E's call (2026-09-17, over "play over the fan, as now"): *"Wait until the fan closes."***

**Why it happens today:** `F-CTACelebrations-Surfaces` holds a full-screen celebration while
`CelebrationCenter.isBlocked`, the ONE predicate behind both the hold and the release. It knows
tracked surfaces (`frontmost.dismissesItself`) and asks UIKit (`KeyWindowPresentationProbe`) about
anything presented. The fan is neither: it is a SwiftUI overlay in `RootView`, gated on
`@State isFabOpen`, so no probe can see it.

**The shape to start from (verify first):** `RootView` TELLS the centre, e.g.
`.onChange(of: isFabOpen) { celebrationCenter.… = $0 }`, and `isBlocked` also holds while the fan
is open (at `.root`). Release needs no new wiring: the hold watch polls every 0.25s
(`holdPollInterval`) and releases when `isBlocked` clears. **Read `-Surfaces`' R-g** (enforced by
TIME) and say what happens to a burst held through a long fan session. **Picking a tile opens a
composer**, and the probe takes over the hold from there. Check the gap between `isFabOpen = false`
and the composer's presentation, so a held burst cannot slip out in between. **Pops are not held**
by `-Surfaces` (`outcome == .fullScreen`), which E chose then. Keep that, and say so. Find which
request fired in frame 20 and confirm it resolves `.fullScreen`.

**Acceptance criteria**
- [x] `CelebrationCenter` unit tests, RED first: fan open → a full-screen request is held; fan closes
      → the next hold-watch tick plays it; a pop is not held; fan open AND closed with nothing held →
      nothing plays.
- [x] A call-site guard that `RootView` feeds `isFabOpen` to the centre (without it, a perfect centre
      holds nothing: the dead-component pattern).
- [x] Red-check; restore. *(RED: 16 compile errors. Mutation A, the fan ignored in the predicate
      and the wiring: exactly the 8 predicted cases. Mutation B, the "replay" shape E rejected (cut
      playing bursts on open): exactly the 1 predicted — the pin on E's choice. Restore proven
      3,053 / 0. `CelebrationCaptureFanHoldTests` (10) + `CelebrationCaptureFanCallSiteTests` (3).
      The composer gap is closed by construction: `RootView` reports `isFabOpen || composerKind !=
      nil`, so the flag never reads clear before UIKit presents the composer; frame 20's request was
      a stack-clearing Confirm, which resolves `.fullScreen`; pops stay unheld.)*
- [x] SwiftLint 0, suite green, build green, pasted. No reduced site touched, so no RM-on pass owed.
      Say why.

**After all three:** ONE device install (`device-build-lag` recipe). **The phone's profile expires 2026-09-17T19:25:02Z (20:25 BST).** After that the
app will not open until it is reinstalled. A build before expiry ships the same dying profile, and one after it should
re-issue via `-allowProvisioningUpdates`. If the build log says `No Accounts`, E signs in to Xcode., then ONE message asking E for: (1) the × at its corner with a
sprint running, portrait, including on Tasks; (2) the collapsed bar's new margin, portrait AND
landscape, alone and under a Confirm card; (3) a sprint ending while the fan is open (the
celebration waits); (4) the × move with **Reduce Motion ON** (block 1's reduced path).

### FEATURE: F-FurnitureGap24 — the bottom furniture drops 8pt: 32 → 24 above the tab bar  [x] COMPLETED 2026-09-17

**E's device look on the three blocks (2026-09-17, four screenshots, portrait, light and dark):**
the × fix PASSED (*"your fixes to the FAB Icon were successful"*); the collapsed bar's new margin
(32pt, measured ≈34 off E's frame) — *"please reduce it slightly."*

**E's two answers:** move **everything together** (disc, search row and cards stay aligned; offered
"only when a card is up", which would have broken the landscape alignment) — and **24pt**, the smallest
on-grid step (offered 16 and "render options first"). So `AppSearchRowMetrics.gapAboveTabBar` 32 → 24:
`bottomFurnitureLift` 100 → 92, `bottomClearance` follows (content floors drop 8 with the disc).

**The accepted cost, named for E's look:** 32 was measured to centre the disc on the Journal tab's
"One line about today" composer (centre 700.5; the disc at 698). At 24 the disc's centre lands ~706 on
an iPhone 15 Pro, ~5.5pt off.

- [x] RED: `testTheGapAboveTheTabBarMatchesEsMarking` reversed and renamed
      `testTheGapAboveTheTabBarIsTheValueEChoseOnDevice` (24), E's 2026-09-03 marking kept → 1 failure.
- [x] GREEN; the one predicted knock-on — the landscape arithmetic that pinned E's y-16 measurement at
      the old lift — derived from the lift and annotated rather than retyped. Docs that said "32pt" updated.
- [x] Pins unaffected, re-checked by the suite: the × pin (resting × now 122pt up; TASK 85pt away),
      every card height still lands the CLOSED × on a tile, the landscape stack still reaches the gear.
- [ ] **Owed: E's device look** — the bar margin at 24 (portrait + landscape), the disc with nothing up,
      the Journal tab's composer alignment. No reduced or `#available` site touched.

## E's Journal-door call from the rendered options — two blocks, the second in a fresh session

**Written 2026-09-18 by the session that rendered the options. It built NOTHING** — E's standing
rule (`build-in-a-fresh-session`, E's call 2026-09-17). Evidence: `screenshots/journal-door-options/`
and its README (**the measurements are done; do not re-derive them**).

**E's brief, verbatim (2026-09-17):** the "One line about today…" bar *"currently gets in the way and
aesthetically unattractive and reduces viewing space on the Journal page"*. Asked whether the
ugliness was the BAR or the shared `composerFooterSurface()` treatment it wears, E answered **"The
bar — its bulk and position"**, so the shared footer treatment is UNTOUCHED and four other screens
keep it. Shown five rendered options, E chose **"option '04'"** — **nothing pinned; the header
pencil is the door** — and then: *"in a fresh claude code terminal session, I think that we should
spend some time making the current new journal entry icon (in the top-right-hand corner of the
screen) MORE visable and EASIER to interact with."*

**Read the two blocks as one arc. Block 1 REMOVES the only persistent door; block 2 is what makes
that safe.** The recommending session's reservation, recorded because it did not go away when E
chose: the pencil lives inside the scrolling `LazyVStack` (`JournalTimelineSections.swift:25-27`)
and the nav bar is hidden (`JournalView.swift:120`), so **once scrolled there is no door at all** —
writing a line becomes tab-re-tap then pencil. E's follow-up addresses exactly this, so **build both
in the same fresh session, block 1 first**, rather than shipping 1 alone.

### FEATURE: F-JournalDoorUnpinned — the pinned "One line about today…" bar goes; the pencil is the door  [x] COMPLETED 2026-09-18 — awaiting E's device look

**What E chose, in numbers** (measured on the rendered frames, `screenshots/journal-door-options/`):
content visible at rest goes **y 705 → 812, +107pt**; the reserved band goes **164pt → 160pt**, so
this is a look-and-feel win, **not** a scroll-reach win — say so in the report rather than claiming
space the change does not buy.

**The shape (verify, do not trust):**
- Delete `composerBar` and its `.safeAreaInset(edge: .bottom)` (`JournalView.swift:126`, `:279-310`),
  including the private `captureDiscClearance` copy at `:277` and the trailing padding at `:305`.
- **Journal must now join every other screen and call `.captureDiscClearance()`** on the timeline
  (`JournalTimelineSections.swift`). Without it the last row lands unreachable under the disc — the
  defect `Theme.swift:232-237` describes. This is why frames 02-04 carry it.
- **The pencil MUST reach §3's 44pt floor in THIS block**, because this block is what makes it the
  only door. It is `.frame(width: 40, height: 40)` (`JournalView.swift:202`) — under the floor
  today. The house pattern for "44pt target, smaller visual" is `AppTabBarMetrics.slotHitOverflow`
  (`AppTabBarPresentation.swift:212-219`). `JournalAllActivityButton.swift:24` is the identical
  40×40 and sits beside it; grow both or say why not.
- The caption (`:300-302`) dies with the bar. It was **355.6pt of text in 285pt of space** — two
  lines on every iPhone — and `LogComposerView.swift:295` already states the same rule at the moment
  it applies. No information is lost.

**Tests that must be REVERSED, not deleted (names and messages too):**
- `AppTabBarCallSiteTests.testEveryTabLevelPinnedBarAsksForTabBarClearance` (`:57-69`) — drop the
  `("Journal/JournalView.swift", "composerBar")` pair, leaving `CaptureInboxView`. Its doc comment
  cites the Journal caption as the bug the helper prevents; keep the history, annotate it.
- `CaptureDiscClearanceCallSiteTests` — `:31-35` explains Journal's ABSENCE from the clearance list
  ("a dead 84pt gap"); that reason is now void. Reverse it and **add
  `Journal/JournalTimelineSections.swift` to the enumerated list** (`:53-72`).
  `testTrailingClearanceStillReadsTheMetricDirectly` (`:126-140`) names JournalView's own
  `captureDiscClearance` copy, which this block deletes.
- **Do NOT delete the two stale doc comments — ANNOTATE them.** `AppSearchScope.swift:88-95` and
  `AppSearchRowMetricsTests.swift:41-53` both name this bar as the capture disc's alignment
  reference and carry E's 2026-09-03 words. `gapAboveTabBar = 24` is E's approved number and does
  **not** change; what changes is that its stated rationale no longer exists. Record that, keep the
  history. **Do not re-tune `gapAboveTabBar` or `CaptureDiscMetrics.edgeMargin`.**

**Acceptance criteria**
- [x] RED first: a call-site guard that `JournalTimelineSections` calls `.captureDiscClearance()`
      and that `JournalView` no longer pins `composerBar`; a geometry test that the pencil's hit
      target is ≥ 44×44. **RED observed: 4 tests / 8 assertions**, each for the intended reason.
- [x] The four tests above reversed in place, E's quotes kept and annotated "reversed 2026-09-18".
- [x] Red-check by restoring the bar; count the failures; restore with `git checkout --`.
      **Bar restored from `8a8b96e` + the pencil's identifier deleted: 4 tests / 8 assertions red,
      exit 65; restored from `d1b3601`, 32/0 green.**
- [x] Evidence folder + README: the Journal at rest, light and dark, before and after.
      `screenshots/journal-door-unpinned/` — plus scrolled-to-end, which is the clearance's proof.
- [x] SwiftLint 0, suite green, build green, all pasted. No `#available` or reduced site touched, so
      **no RM-on pass is owed** — say why in the report. **3,057 / 0; lint 0 / 826.**
- [x] **`F-Search-3-Journal` (`TODO-CLAUDE-CODE.md:2600-2625`, "⚠ RECONSIDER FIRST") is unblocked by
      this block** — its entire objection was that this band already held a field. Note it; do not
      start it. *(Noted in its block, 2026-09-18.)*

**Built 2026-09-18, and where it departs from the shape above — both deliberate:**
- **A real 44pt frame, not the `slotHitOverflow` trick.** The overflow exists so a target does not
  grow a CONSTRAINED container; the header row is already taller than 44 (caption + `.largeTitle`),
  so growing costs no layout, and E's word was "grow". Both circles read one metric,
  `JournalHeaderMetrics.controlSize` (its own file, so a red-check that restores the old views still
  compiles). `JournalHeaderControlsTests` holds the value, the readers and the pencil's door.
- **`+96pt`, not `+107pt`.** At E's phone's real 34pt home-indicator inset the bar was 96.3pt tall,
  so that is what came back; the options rig had no inset. Reserve 164 → 160, as specced.
- Three more production comments said "the two screens that pin furniture" (`AppTabContent`,
  `RootView`, `AppTabBar`) — annotated "one since 2026-09-18" rather than left to rot.

### FEATURE: F-JournalPencilReachable — restore the nav bar; the pencil is a filled-accent toolbar button  [~] SUPERSEDED IN PART 2026-09-18 — Step 0 ran and E revised the shape → build `F-JournalPencilDisc` (the next block), NOT this plan

> **Read `F-JournalPencilDisc` below instead of building this.** Step 0 ran on 2026-09-18
> (`screenshots/journal-pencil-step0/`). The filled pencil splits (b)'s capsule. Shown that, E kept
> the nav bar and the eye, and moved the pencil down beside the + as a 42pt disc. This block stays as
> the record of E's first choice and of the plan Step 0 tested. The facts it asked Step 0 to settle
> are settled in the next block, and its re-tap risk turned out REAL.


**E's call, 2026-09-17, verbatim:** *"making the current new journal entry icon (in the top-right-hand
corner of the screen) MORE visable and EASIER to interact with."* E asked for this in a fresh session.

**The problem is TWO problems, and the second is the one that bites.** *Visible* — a
`Color("LabelSecondary")` glyph on `Color.cardSurface` inside a hairline circle reads as quiet chrome
next to a `.largeTitle.bold()` "Journal". *Reachable* — it is 40×40 (under §3's floor, fixed in block
1) **and it scrolls away entirely**, because the header is the first child of the `LazyVStack` and
the nav bar is hidden. After block 1 it is the only door, so **persistence is the substance of this
block and mere styling would not deliver what E asked for.**

**UNBLOCKED 2026-09-18 — E chose by looking.** Shown the three shapes rendered at rest and scrolled
(`screenshots/journal-pencil-options/`, sheets 00/01) and three pencil treatments (sheet 02), E answered:
- Shape: **"(b) Restore a nav bar"** — over (c) the disc's band, which was recommended, and (a).
- Treatment: **"Filled accent"** — over the recommended accent glyph, and quiet.

What E saw in (b) (`11`–`14` in that folder): a system large title "Journal" at rest with the eye and
the pencil in a toolbar capsule top right; scrolled, an inline title with the capsule and content
fading softly beneath (iOS 26 soft scroll edge). The summary line ("0 CLOSED · 8 WRITTEN…") moved under
the large title as the first content row. **E was told** the cost: Journal becomes the only one of the
four title-drawing tabs (Today, Areas, Tools, Journal) on the system bar, and the bar looks different
below iOS 26.

**Built in a FRESH session — E's call, 2026-09-18** (asked mid-plan: *"Did you remember that we need
to do building in a fresh session?"*). The approved plan is below; nothing of it was written.

#### Step 0 — one throwaway probe build BEFORE any test (it decides the code's shape and the test list)

**E has not seen "filled accent" INSIDE a toolbar**: sheet 02 was the header circle, and render (b) had
a blue GLYPH on shared glass. So, with the render harness and the one-build static-switch trick
(temporary edits, reverted — memory `full-screen-render-harness`):
- **(i) Is an iOS 26 tier real?** The same toolbar with the pencil as `.borderedProminent` vs
  `.glassProminent`, light + dark. WWDC25 guidance is that the system renders `.borderedProminent` in a
  toolbar as tinted prominent glass. **Pixel-identical → one style, NO `#available`, no enum, no §7.4
  call-site test**, and the report says "26 tier considered, not added: the system already renders the
  floor API as prominent glass" (§7.1's filter). Different → the two-tier shape under Decisions.
- **(ii) The combination E will actually get:** `ToolbarItemGroup` (the grouping E judged) with the eye
  plain and the pencil filled — does the prominent item split the shared capsule into two pills?
- **If (ii) differs materially from the capsule E chose, send E one before/after image and confirm the
  combination** (`show-dont-describe-geometry`) — a confirm, not a re-ask of the shape.

#### Decisions — defaults, each to be stated in the report (verify, do not trust)

1. **"Filled accent" in a system toolbar.** Floor: `.buttonStyle(.borderedProminent)` +
   `.buttonBorderShape(.capsule)` — filled accent, native on iOS 16. A separate iOS 26 `.glassProminent`
   tier ONLY if Step 0 (i) shows it differs. No 17 tier either way (`.circle` adds nothing visible over
   capsule for a square glyph — say so, §7.1's filter).
2. **The eye moves to the toolbar too** (as in the render E chose), plain style. ON = `eye` + accent
   tint; OFF = `eye.slash` in `.secondary` — **deliberately**: toolbar glyphs default to the accent tint,
   which would make the eye look ON when it is OFF. State rides on the glyph + `.isSelected`; haptic,
   label, hint unchanged. Not prominent, so the pencil is the only filled blue.
3. **The system large title replaces the drawn "Journal".** §1's `.tracking(-0.5)` cannot reach the
   system title without a global `UINavigationBarAppearance`; E chose this by looking at exactly that
   render. Report it as a §1 departure.
4. **Placement `.topBarTrailing`** — already used ungated in `SettingsView.swift:82`, so it compiles at
   the 16.0 target. Pencil trailing-most: "the top-right-hand corner" E named.

#### Implementation (TDD — failing tests first)

- **New `Journal/JournalComposeButton.swift`**: `Button { action() } label: { Image(systemName:
  "square.and.pencil") }`, `.accessibilityLabel("Write an entry")`,
  `.accessibilityIdentifier("journalComposeButton")`, the filled style, `#Preview` light + dark inside a
  `NavigationStack` toolbar. *Only if two tiers:* `enum JournalComposeProminence { glass, bordered;
  resolve(glassAvailable:) }` taken as a PARAMETER (§7.2's shape), so the floor can be RUN on 26.5.
- **`JournalView.swift`**: `.toolbar(.hidden, for: .navigationBar)` (`:120`) → `.navigationTitle("Journal")`,
  `.navigationBarTitleDisplayMode(.large)`, `.toolbar { ToolbarItemGroup(placement: .topBarTrailing) {
  JournalAllActivityButton … .accessibilityIdentifier("journalAllActivitySwitch"); JournalComposeButton {
  isPresentingComposer = true } } }`. `header` becomes the summary line only. File header comment: the
  door is the toolbar pencil.
- **`JournalAllActivityButton.swift`**: drop the circle chrome; glyph-only label per decision 2.
- **Delete `Journal/JournalHeaderMetrics.swift`** — nothing reads it once both circles leave the header
  (the dead-component pattern, memory `dead-shared-component-pattern`). Move its history into the
  reversed test's doc comment.
- **Annotate, don't delete:** `Tools/ToolsView.swift:89` ("a tab root that draws its own title (Today,
  Areas, Journal)"); `TabNavigationCallSiteTests`' "this app's tab roots hide theirs on purpose".

#### Tests to REVERSE in place (names, messages, "reversed 2026-09-18" history)

- `JournalHeaderControlsTests` (block 1's): `testTheHeaderControlsMeetTheTouchFloor` → the header draws
  no hand-sized circles, both controls are system toolbar items (§3 by the system);
  `testBothHeaderCirclesAreSizedByTheSharedMetric` → both controls live in the nav-bar toolbar
  (`.navigationTitle("Journal")`, `ToolbarItemGroup(placement: .topBarTrailing)`, no
  `.toolbar(.hidden…)`); `testThePencilStillOpensTheComposer` → adapted to `JournalComposeButton`.
- New: the pencil is `.borderedProminent` (+ the §7.4 both-branches test and the pure `resolve` test
  ONLY if two tiers); the eye's OFF glyph is `.secondary`, not accent.
- Stay green untouched: `RoutineRecordSurfacesCallSiteTests` (`journalAllActivitySwitch` stays in
  `JournalView.swift`), `TabNavigationCallSiteTests`.

#### Acceptance criteria

- [x] Step 0 rendered and its two answers recorded; E confirmed the combination if (ii) differed.
      **Ran 2026-09-18.** (i) Pixel-identical, so there is no 26 tier. (ii) The group SPLITS. E did
      not confirm the split: E moved the pencil to the disc band. The re-tap was also probed: the large
      title stays COLLAPSED. See `F-JournalPencilDisc`.
- [ ] RED first, counted; GREEN; commit; red-check by restoring block-1 `JournalView.swift` +
      `JournalAllActivityButton.swift` from `main`, count, `git checkout HEAD --`, rebuild green.
- [ ] SwiftLint 0; full suite (documented command, `OS=26.5`); build — all pasted. Targeted runs with
      `-enableCodeCoverage NO` (coverage post-processing hung once on 2026-09-18).
- [ ] **UI journeys, deliberately** — the identifiers move from content into the nav bar:
      `JournalJourneyUITests`, `RoutineRecordJourneyUITests`, foreground, emulator up — then
      `xcrun simctl erase` that simulator in the same command, before any unit run.
- [ ] Evidence `screenshots/journal-pencil-navbar/` + README (rig: `journal-door-unpinned`): at rest +
      scrolled, light + dark; the floor render if two tiers; **scrolled → `coordinator.reselect(.journal)`
      → the large title RE-EXPANDED.** The re-tap is `proxy.scrollTo(TabRootScrollAnchor.id, anchor:
      .top)` (`TabNavigation.swift`), which is the known risk with large titles — if it stays collapsed,
      fix before landing. Gate: disc centre 696.5 unchanged.
- [ ] "Verified paths" line (§7.3) if an `#available` site ships. No reduced site is added or changed
      (the title collapse is the system's) → **no RM-on pass owed**; say why.
- [ ] Land via PR; **install BOTH blocks on E's phone in one build** (profiles to 2026-09-24),
      force-relaunch, THEN ask for the look — with the two carried looks on the same install.

**Whatever the shape:** §3's 44pt floor, §1's hierarchy, §4's tokens only, and an
`accessibilityLabel` ("Write an entry" today). If a reduced or `#available` site is touched, the
**RM-on device pass is owed** (§7.3).

### FEATURE: F-JournalPencilDisc — the nav bar stays (eye alone); the pencil is a 42pt gradient disc beside the +  [x] COMPLETED 2026-09-18 — E's device look PASSED 2026-09-18 (RM off "All passed", RM on "All faded, passed")

**This REPLACES the build plan of `F-JournalPencilReachable` above**, whose Step 0 ran on 2026-09-18
and put the combination in front of E, as that block required. E answered by changing the shape.
The block above is kept, marked superseded, because it is the record of what E chose first and why.
Evidence: `screenshots/journal-pencil-step0/` and its README (**the measurements are done — do not
re-derive them**).

**E's answers, verbatim, 2026-09-18** (shown `00-toolbar-options-27.jpg`: before = (b) as rendered;
A = the spec as written; B = recommended):
1. Asked whether the split is right (a filled item cannot share (b)'s one capsule: iOS draws the eye in
   its own glass circle and the pencil as a separate blue disc): *"move the filled pencil icon disc
   down to the left-hand side of the FAB Icon. make the filled pencil disc inline with the FAB icon"*.
2. Details: **"B (Recommended)"**. The eye is OFF in the label colour (black/white), as E saw in (b),
   and ON in accent. The pencil glyph is white in both modes (the house `AreaPalette.work.onColor`,
   as on the + disc and the "Filled accent" swatch E chose).
3. **"Keep the nav bar"**: the large title stays, with the eye ALONE top right in its glass circle, in
   B's colours.
4. **"48pt (Recommended)"**: the pencil disc is 48pt, centred on the + disc's line,
   `AppSearchRowMetrics.rowSpacing` (16pt) to its left. **E then revised it mid-session:
   *"decrease the size of the filled pencil disc from 48pt to 42pt"*. 42 is the number.**
5. The pill (shown `03`–`05`): **"1 · Follows the pill (Recommended)"**, i.e. 68% translucent with
   the +. At rest, from the same question: **"Match the + gradient"**, i.e. `CaptureDeep` → accent,
   over the flat accent the frames show.
   **Then, shown the 42pt gradient disc with and without the + disc's glow (`06`):** *"Can you reverse the DIRECTION that the gradient on the pencil disc currently points in? And use the same glow as the +. So the pair are twins with halos, But with the pencil disc's Background colour gradient direction different."*
   So: the SAME two colours with the direction REVERSED (accent at the top → `CaptureDeep` at the
   bottom), and the + disc's glow, shrinking with the pill exactly as the + disc's does.
6. **"Hand off to fresh session (Recommended)"** (E's standing rule, `build-in-a-fresh-session`).

**What E has now seen, and what E has NOT.** Seen: B's toolbar at rest and scrolled, light and dark,
eye OFF and ON; the pencil disc beside the + at rest, and pilled three ways (`03`–`05`), **at 48pt
and flat accent, both since revised**; and the 42pt disc with the + disc's gradient, with and
without its glow (`06`). NOT seen: **the REVERSED gradient with the glow — the final look**, the disc
with a sprint card up, in landscape, while the fan is open, or on a tab switch. **The build
session renders those to VERIFY them. If one shows something E has not decided (the disc lands on a
card, a tile or the gear), STOP and ask. Do not improvise a design answer.**

#### What Step 0 established (facts; do not re-derive)

- **`.borderedProminent` and `.glassProminent` render pixel-identically in a toolbar** on 26.5 and
  27.0: 0 differing pixels over the full 1179×2556 frame, light and dark, at rest and scrolled. One
  26.5 run showed ≤3/255 per channel in the scrolled frames, spread over every glass region including
  the title: backdrop-sampling noise. **Moot for the pencil, which has left the toolbar.** It means
  the glass circle the eye now wears is the system's on every tier, with nothing to gate.
- **A prominent item splits a `ToolbarItemGroup`.** The group and two separate `ToolbarItem`s render
  pixel-identically.
- **In DARK mode iOS draws a prominent item's glyph BLACK** (0,0,0 on 60,131,246) on both runtimes. A
  `.foregroundStyle` on the label overrides it. Also moot now, since the disc is ours, not the system's.
- **On 26/27, toolbar glyphs default to the LABEL colour, not accent.** The old decision 2 ("toolbar
  glyphs default to the accent tint, which would make the eye look ON when it is OFF") is true only
  below 26, where classic bars tint with accent. So the OFF eye is set to `.primary` EXPLICITLY. That is
  E's B, and the same code is also correct on 16–18.
- **THE TAB RE-TAP DOES NOT BRING THE LARGE TITLE BACK — the spec's named risk is real.** Measured
  with the real `JournalView` in the render rig (`02-retap-large-title-27.jpg`); identical on 26.5
  and 27.0, light and dark:

  | re-tap after scrolling 420pt | nav bar | content offset | verdict |
  |---|---|---|---|
  | at rest (baseline) | 106pt | −168 | large title |
  | R0: shipped `proxy.scrollTo(TabRootScrollAnchor.id, anchor: .top)` | **54pt** | −116 | **collapsed** |
  | R1: iOS 18 `ScrollPosition.scrollTo(edge: .top)` | **54pt** | −116 | **collapsed** |
  | R2: UIKit `setContentOffset(y: −168)`, no animation | 106pt | −168 | large title, holds |
  | R3: the same, `animated: true` | 106pt | −168 | large title, holds |
  | R4/R5: offset written to `−adjustedTop − bounds.height`, then layout | 106pt | **−168** | the overscroll comes to rest at the EXPANDED top by itself |

  **R4/R5 are the useful finding.** An overscroll written with no finger on the glass settles at the
  large-title top, so the fix can FIND that top rather than hard-code the 52pt band (which grows with
  Dynamic Type).
- **Tasks is not a control for this.** Its `ScrollView` sits under a filter row, UIKit never links it
  to the bar, and its title never collapses at all (106pt at 420pt scrolled). The re-tap fix must
  leave it, and the four hidden-bar tabs, exactly as they are.

#### Decisions — defaults, each stated in the report (verify, do not trust)

1. **The re-tap fix, iOS 26+ only; floor = the shipped `proxy.scrollTo`.** The mechanism depends on
   how an overscroll with no finger down settles. That was verified on 26.5 and 27.0 only. On 16–18 a
   bar that stretches with the overscroll could leave the page displaced by a whole screen, which is
   worse than a collapsed title. So this is §7.1's DEGRADED shape: 26+ restores the large title; the
   floor lands the content at its top under an inline title — plainer, not absent. Say so in the
   "Verified paths" line.
2. **Starting shape:**
   - `tabRootScrollAnchor()` gains a background `UIViewRepresentable` locator. It walks `superview`s
     to the enclosing `UIScrollView` (the anchor sits on the content root INSIDE the scroll view, so
     the first ancestor is the vertical one, never the chips' horizontal one) and hands it to a handle
     `TabRootModifier` owns and passes down through the environment.
   - On a top-level re-tap: write `y = −adjustedContentInset.top − bounds.height` without animation,
     `window.layoutIfNeeded()`, read `expandedTop = −adjustedContentInset.top`.
   - **If that is not above the plain top, restore the offset and run the shipped `proxy.scrollTo`
     untouched.** That is every tab but the Journal.
   - Otherwise, under Reduce Motion, set `expandedTop` directly. With motion, restore the offset,
     then `setContentOffset(expandedTop, animated: true)`: UIKit's own scroll-to-top animation, the
     status-bar tap's, proved by R3. **§5 note for the report:** that is not the house spring, because
     SwiftUI cannot address an offset above the content's top.
   - The decision is a pure function (e.g. `plan(plainTop:expandedTop:reduceMotion:)`), tested
     once (§7.4).
3. **The pencil disc.**
   - A new `JournalComposeDisc`: a **42pt** `Circle` filled with the + disc's two colours with the
     direction REVERSED, per E: `LinearGradient([Color("CaptureDeep"), .accentColor])` from
     `.bottom` to `.top` (the + runs `.top` → `.bottom`). Share the COLOURS with `CaptureDiscLabel`
     so the pair cannot drift, and let the direction be the one thing that differs. A test holds
     both directions, so a later "tidy" that makes them match fails.
   - `square.and.pencil` at `.title3.weight(.semibold)` in `AreaPalette.work.onColor`. Verify it
     reads at 42.
   - **The + disc's glow, per E ("twins with halos")**: accent at 0.5, radius 12, y 8 at rest, and
     0.3 / 6 / 4 while pilled, on the same curves as the +. Share the values with `CaptureDiscLabel`
     rather than retyping them. This is E's call over §5's soft-shadow default, for the same reason
     the + has it.
   - A `ButtonStyle` that presses to 0.97 (§3).
   - **§3: 42 < 44.** So the hit target takes the house `AppTabBarMetrics.slotHitOverflow` shape:
     `max(0, (minimumTouchTarget − diameter) / 2)` = 1pt of negative padding around the
     `contentShape`. The LAYOUT stays 42, so the 16pt visual gap and the centre line do not move,
     while taps land within 44.
   - Label "Write an entry". **Identifier `journalComposeButton`, kept**: the journeys find it by
     that, and it moves from `JournalView` to the overlay.
   - A named metric holds E's 42, with E's words. A test holds the value AND that the hit target
     reaches 44.
   - `#Preview` in light and dark.
4. **Where it lives.** `RootBottomOverlay.discRow`, between the search-row slot and the disc
   (`RootBottomOverlay.swift`, the `HStack` in `discRow`).
   - It shows only when `selectedTab == .journal` and the Journal is at its root. That mirrors the
     search row's rule (hidden when a door is pushed), computed in `RootView+Furniture.swift`
     (`RootView.swift` sits at the 400-line bar).
   - The tap has to reach `JournalView`'s private `isPresentingComposer` and its `journalService`.
     Use a request counter in the `TabNavigationCoordinator.reselect` shape; JournalView's
     `onChange` presents the sheet.
5. **The pill: E's "Follows the pill".** While `showsPill`, the disc's opacity is
   `CaptureDiscMetrics.pillOpacity` (0.68, E's dial), read from that metric and never retyped.
   - Its SIZE stays 42. The pill is 60×48, so the pair stays on one line.
   - It rides the + disc's own curves: the spring on the shrink, the 0.9s `easeOut` regrow
     (`CaptureDiscLabel`'s asymmetric animation), and `nil` under Reduce Motion exactly as the + does.
     Share the expression, so the two can never be out of step.
6. **While the fan is open the disc fades and stops taking touches WITH the cards**
   (`RootBottomOverlayLayout.cardsPresence`). E's `F-FanCardsFade` is the precedent that non-capture
   furniture steps aside for the fan. `F-FanXAtRest` drops the disc row to its resting line while the
   fan is open, and the disc rides in that row: render it and check that no tile lands on it.
7. **Appearing and leaving (tab switch, push, pop) is a transition, so it is a REDUCED SITE.** With
   motion it gets the spring the search row uses. Under Reduce Motion geometry is pinned and only
   opacity travels (§7.2, `CaptureFanOverlay.swift:89-96`), never `nil`. **The RM-on device pass is
   owed** for this and for the re-tap's reduced branch.
8. **The header.**
   - `.toolbar(.hidden, for: .navigationBar)` (`JournalView.swift:120`) becomes
     `.navigationTitle("Journal")` + `.navigationBarTitleDisplayMode(.large)` +
     `.toolbar { ToolbarItem(placement: .topBarTrailing) { JournalAllActivityButton … } }`.
     `.topBarTrailing` is ungated in five files at 16.0.
   - `header` becomes the summary line alone.
   - `JournalAllActivityButton` becomes glyph-only: OFF `eye.slash` in `.primary`, ON `eye` in
     `Color.accentColor`. Label, hint, haptic and `.isSelected` are unchanged.
   - **§1 departure, for the report:** `.tracking(-0.5)` cannot reach the system title without a
     global `UINavigationBarAppearance`. E chose this by looking.
9. **Delete `Journal/JournalHeaderMetrics.swift`**: nothing reads it once both circles leave the
   header (memory `dead-shared-component-pattern`). Its history moves into the reversed test's doc
   comment.
10. **`F-Search-3-Journal` gets an objection back, in a new form.** The band left of the disc on the
    Journal is now the pencil's. Note it in that block; do not start it.

#### Tests — REVERSE in place (names, messages, "reversed 2026-09-18" history)

- **`JournalHeaderControlsTests`** (block 1's):
  - `testTheHeaderControlsMeetTheTouchFloor` → the disc's hit target is ≥ 44 (42 + the 1pt overflow each side), and the eye is
    a system toolbar item.
  - `testBothHeaderCirclesAreSizedByTheSharedMetric` → the eye lives in the nav-bar toolbar
    (`.navigationTitle("Journal")`, `ToolbarItem(placement: .topBarTrailing)`, no
    `.toolbar(.hidden…)`).
  - `testThePencilStillOpensTheComposer` → the disc's tap reaches `isPresentingComposer` through the
    request.
- **New tests:**
  - the disc is mounted in `discRow` ONLY for the Journal at root (a call site, not just a view);
  - the eye's OFF style is `.primary`, not accent and not `.secondary`;
  - the re-tap's pure `plan` function;
  - the §7.4 call-site test: `#available(iOS 26.0, *) {`, `} else {`, `proxy.scrollTo`;
  - **a hosted-window behavioural test**: the Step 0 rig, committed. It is RED on the shipped
    re-tap (bar 54pt) and GREEN with the fix (106pt), and skipped below 26.
- **Must stay green; check each:**
  - `RootBottomOverlayLayoutTests`: the disc row grows by 64pt on the Journal only. Re-run the
    landscape arithmetic;
  - `RootBottomOverlayDrawOrderTests`, `AppSearchCallSiteTests`, `CaptureDiscPillCallSiteTests`;
  - `RoutineRecordSurfacesCallSiteTests`: `journalAllActivitySwitch` stays in `JournalView.swift`;
  - `TabNavigationCallSiteTests`: annotate its "tab roots hide theirs on purpose";
  - `ToolsView.swift:89` ("a tab root that draws its own title (Today, Areas, Journal)"): annotate
    it.

#### Acceptance criteria

- [x] RED first, counted. GREEN. Commit. Then red-check by restoring block 1's `JournalView.swift`,
      `JournalAllActivityButton.swift`, `TabNavigation.swift` and `RootBottomOverlay.swift` from
      `main`. Count the failures, `git checkout HEAD --`, rebuild green.
      **RED, three cycles:** the disc + header 16 tests / 51 assertions; the re-tap 7 / 11 (the
      hosted test red at **54pt / −116**, Step 0's bug); the HIG-review fixes 2 / 2. All exit 65.
      **Red-check** (the four files + `RootView` + the resurrected `JournalHeaderMetrics` from
      `main`, `CaptureDiscLabel` too; `TabNavigation`'s re-tap and anchor surgically reverted,
      keeping the request API so the test target compiles): **16 tests / 27 assertions red**, exit
      65 — the hosted six failing cleanly on "Bar 0.0pt". Restored from `0b91ab6`: 115 / 0.
      **Mutation** of the plan (never hand back to the shipped scroll): the hidden-bar control and
      the plan's three negatives fall (7 assertions); the stub RED was the other direction. No
      plan or control test survives both. The at-rest, short-scroll and no-refresh tests pass both
      ways — guards, not discriminators.
- [x] SwiftLint 0; full suite (documented command, `OS=26.5`); build. All pasted. Targeted runs use
      `-enableCodeCoverage NO`. **Lint 0 / 831. Suite 3,085 / 0 (was 3,057) — re-run on the final
      tree `061dbaa`. App coverage 29.72% (14,442 / 48,593). `** BUILD SUCCEEDED **`.**
- [x] **UI journeys, deliberately:** `JournalJourneyUITests` and `RoutineRecordJourneyUITests`,
      foreground, emulator up, then `xcrun simctl erase` in the same command.
      `RenderHarnessUITests`' landscape sweep also taps `journalComposeButton`.
      **On 27.0: Journal journey PASSED (179s), routine-record journey PASSED (487s; the eye as a
      toolbar item). The landscape sweep FAILED — at the capture fan's Note tile on Today, before
      it reaches the Journal — and fails IDENTICALLY on `main` @ `aec558a` (462s), so it predates
      this block (register). Its Journal step was run on its own instead (a temporary test,
      reverted): landscape → tap `journalComposeButton` → pad → submit, PASSED (342s).** Each run
      erased its simulator in the same command.
- [x] Evidence folder `screenshots/journal-pencil-disc/` + README (rig: `journal-pencil-step0`).
      Render: rest and scrolled/pilled, light and dark; a sprint card up; landscape; the fan open;
      **scrolled → `coordinator.reselect(.journal)` → the large title RE-EXPANDED (bar 106)**.
      Gate: the + disc's centre is unchanged (696.5). **Measured 696.0 on both runtimes (the
      constants predict 696.0; 696.5 was a looser threshold); the pencil 42 × 42 on the same line,
      gap 16.0. Landscape by really rotating the test host's scene. Nothing lands on a card, a tile
      or the gear.**
- [x] "Verified paths" line (§7.3) for the re-tap gate:
      `26 path: run on sim 26.5 + 27.0; 16 path: the shipped proxy.scrollTo; OS-level COMPILE-ONLY`.
      **Reduced: the re-tap's reduced branch run on sim (injected); the disc's appear/leave and fan
      fades under RM are code-only here — NOT on device until E's RM-on pass.**
      **Now (2026-09-18): `26 path: run on sim 26.5 + 27.0 + E's phone (RM off). Reduced: run on
      sim (injected) + E's phone (RM on)`. E toggled Reduce Motion ON for the pass.**
- [x] Land via PR. **Install blocks 1 + 2 on E's phone in ONE build** (profiles to 2026-09-24),
      force-relaunch, THEN ask for the look, with the carried looks on the same install. The
      RM-on pass covers the disc's appear/leave, the re-tap, and the capture fan.
      **Landed (PR #160, `654012f`); installed together and relaunched. E's look, one message:
      RM OFF "All passed", RM ON "All faded, passed", landscape Note tile "Composer opened" (so
      the sweep's failure is the test's). E's frames: `screenshots/journal-pencil-disc/19–24`.**

**Built 2026-09-18, and where it departs from the plan above — each one deliberate:**
- **E answered the one gap in the spec:** the disc shows on the Journal at its top level *loaded or
  not* — *"Always on the Journal (Recommended)"* — since saving never depended on the timeline.
- **The row grows 58pt, not 64** (the spec's figure was 48 + 16). Landscape cards column 58pt
  narrower; the sprint card still fits (`14`/`15`).
- **The request counter lives on `TabNavigationCoordinator`** (`requestJournalEntry()`), and the
  Journal listens through its own modifier, `onJournalEntryRequest`, so `JournalView`'s whole body
  is not re-evaluated on every depth report. `RootView.swift` is at 398.
- **The appear/leave curve rides on the TRANSITION** (`.opacity.animation(…)`), not on a
  row-level `.animation(value:)`, so on a Tasks ↔ Journal switch the search row's own (`nil`)
  animation is untouched.
- **`CaptureDiscFace`** (new, `Theme/`) holds the twins' colours, directions, halo and pill curves;
  `CaptureDiscLabel` reads it, pixel-identical (block 1's gate still 696.0).
- **The re-tap test asserts the SETTLED page.** Its first cut polled "bar > 100" and passed on the
  bug: a per-frame probe showed the shipped spring overshoots ~6pt, the bar pops to 106 for ~0.25s,
  then collapses back to 54 as it settles. Step 0's finding holds; the probe explains why it hides.
- **Two HIG-review findings applied** (a read-only `apple:hig-reviewer` pass): `accessibilityHidden`
  while the fan is open (hit-testing does not stop VoiceOver's activate), and the glyph's Dynamic
  Type capped at `.accessibility1` so it cannot outgrow the 42pt circle. The same VoiceOver gap on
  the CARDS predates this block (`F-FanCardsFade`) — register.
- **The re-tap never probes a page whose nav bar is hidden** (the advisor's catch, applied
  test-first: the hidden-bar control saw 2 offset writes, now 0). The probe's overscroll is visible
  to `AppScrollOffsetObserver`'s KVO, so a floating tab bar would have read an un-float then a
  re-float on the four hidden-bar tabs. **Residual:** Tasks shows a bar, so it is still probed
  (and handed back — its title never collapses); for E's look.
- **§5 note:** the re-tap's motion path is UIKit's own animated scroll-to-top, not the house spring:
  SwiftUI cannot address an offset above the content's top. **§1 note:** the system large title
  cannot take `.tracking(-0.5)` without a global appearance; E chose it by looking.

---

## The ADHD UX audit's seven arcs — E's decisions, 2026-09-19; NOTHING BUILT

**Written by the audit's third session, which collected the decisions and built nothing** (E's
`build-in-a-fresh-session` rule, and E's Decision A on 2026-09-19: *"Specs here, then hand off"*).
**Each arc is built in a FRESH session, one arc at a time, stopping after each block for E's review.**

**Where every decision comes from.** `handoff/SESSION-OPENER-adhd-ux-audit-design.md` is the design
record: E's ten opening answers, then rounds 1–10 with every option label and E's own words. The
evidence is `handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md` (findings §A–§M) and the boards
`screenshots/adhd-ux-audit/52`–`68`, whose README says what each one proves.

**How to read the quotes below.** They are quoted from the DESIGN RECORD. Where the record marks a
line "E, verbatim" the words are E's own; everything else is the record's wording of a decision E
made by choosing a labelled option. When a block needs E's exact words, read the round in the record
rather than trusting a paraphrase here.

**The build order E chose, and the proposal for the rest.** E chose the first arc: *"C · Nothing
lost first (Recommended)"*. The rest is a proposal, and E may reorder it:

| order | arc | what it is | depends on |
|---|---|---|---|
| 1 | **C · Nothing lost** | the undo capsule, drafts to the inbox, Recently Deleted, tags | — |
| 2 | **D · The composer** | one composer both doors, L3 on the keyboard, the Anytime row | C |
| 3 | **E · Today** | one card, the weekly chain, Next step, Week review | C, D |
| 4 | **F · The sprint** | heads-up, Live Activity, six controls, Focus screen, calendar | — |
| 5 | **A · Copy and colour** | round 8's words, round 9's colour jobs, jargon, footers | after C–F, so the words are written once |
| 6 | **B · Accessibility** | targets, AX3 layouts, VoiceOver, the audit test plan | after the layouts settle |
| 7 | **G · Places, sheets, refresh, Fresh Start** | one sheet, Save at the bottom, tap twins, refresh | D, E |

**Two schema notes, both verified against `firestore.rules` this session rather than assumed:** the
rules have NO field-level validation (63 lines, collection-level owner CRUD), so neither the
`next_step` field (arc E) nor soft delete (arc C) needs a rules change. The record's earlier "E
republishes" line for `next_step` was wrong, and is corrected here. E still republishes if a block
chooses to add the optional hardening rule that arc C names.

**Every build session logs its progress** (E's instruction, 2026-09-19, because this runs across many
sessions): `handoff/ADHD-AUDIT-BUILD-LOG.md` is the thread — a row per block and an entry per
session — and it carries the six-step close-out contract each session owes before it ends. Read the
live `handoff/START-HERE-*` opener first, then that log.

**What every block owes, on top of its own criteria** (CLAUDE.md): tests first; a red-check that
restores the old code and counts the failures; SwiftLint, the full suite and the build pasted;
`screenshots/<folder>/` with a README when the result was settled by looking; an `apple-design`
review when anything visible changes (§7.6); E's Reduce-Motion-on device pass when a reduced site is
added or changed (§7.3); and a "Verified paths" line when an `#available` site is touched (§7.1).

**The gaps the audit did NOT spec** (E's Scope C list, in the register): the leave-by countdown,
wake-event routines, a Lock Screen accessory widget, a daily notification cap, journal edit and
delete, and the points/levels/badges arc E asked for after the audit.


---

## Arc C — Nothing lost

The first arc E builds from the audit (design record, "Decision A and the build order": *"C ·
Nothing lost first"* — Recommended, chosen). It holds the audit's data-loss Criticals (TASKS-01,
CAPT-01) and builds the undo capsule every later arc reuses. Four blocks, in order: C1 the capsule
+ every task close; C2 drafts to the inbox + autosave; C3 Recently Deleted for tasks/captures; C4
tags in Recently Deleted (needs C3's schema). **No block in this arc has landed; all code below is
read as of the audit, `feature/adhd-ux-audit-rounds-3`.**

---

### FEATURE: F-C1-UndoCapsule — one undo capsule, in the disc row, for every task close  [x] COMPLETED

**What E chose.** Round 1: *"Every close (the circle, a full swipe, Today's hero) shows the same
undo, which stays until the user's next action; after that, closing is final again. This RETIRES
the earlier addendum 'closing is one-way' … as far as the undo moment goes."* Round 2, verbatim:
*"'Option 1.' But the 'bottom bar' Needs A visual overhaul"* — Option 1 is one bottom bar
everywhere, above the tab bar, clear of the disc, 48pt, the standard ↶, naming what it undoes.
Round 2b: shape **"A · Capsule in the disc row"** (board `54`, frames
`screenshots/adhd-ux-audit/round-2b-undo-bar/`) — *"It sits exactly where the search row is, left
of the + disc. Nothing moves and nothing stacks... On Tasks it stands in for the search row until
the next action... a 48pt Undo capsule tinted like the tab bar's selected pill... the standard ↶
symbol, a glyph plus words naming what happened, a stacked layout at accessibility sizes, and a
haptic on appear and on Undo."* **Reading "one bottom bar everywhere" (E's Option 1) onto the code — the spec session's reading, NOT
E's words:** the capsule replaces the inbox's current bottom undo bar
(`Capture/CaptureInboxUndoSections.swift`, the compliant pattern UNDO-2 to reuse) and Home's
in-place close card, so there is one shape everywhere. Round 9 (§M, RM-02): *"The inbox's undo …
bars slide in on every triage with no Reduce Motion read … This is §7.2's 'appears' case: a fade,
per `CaptureFanOverlay`. It rides into round 2b's undo capsule build."*

**Where it sits (read, not inferred).** The disc row is ONE shared `HStack` mounted once, app-wide
— `RootBottomOverlay.discRow` (`ADHD LifeOS/RootBottomOverlay.swift:189-228`), built with
`AppSearchRowMetrics.rowSpacing` (16pt, `Theme/AppSearchScope.swift:80`) between an optional
leading control and the capture disc. Today it holds `AppSearchRow` only when
`searchScope.placeholder != nil` (Tasks alone — `AppSearchScope.swift:48-56`,
`bottom-search-arc.md`) or `JournalComposeDisc` when `showsJournalCompose`. `RootBottomOverlay`
already reads `@Environment(\.celebrate)` (`RootBottomOverlay.swift:51`) for exactly this reason:
it is mounted above every tab and needs an app-wide signal, not a per-screen one. **The capsule is
a THIRD optional occupant of this same slot**, so "it sits where the search row is" is literally
this `HStack`, not a description.

**Five close surfaces at four code sites, three named in the record, two found by reading the
code.** Every one below carries the same "closing is one-way" (F-V3-Tasks-rebuild, E's addendum)
comment or its close paraphrase — eight comment sites in total — and the record's retirement
covers all of them: it names `TaskRow.swift:14` and `Tasks/MomentumTaskContext.swift`'s comment by
name, which already reaches past the three enumerated surfaces (circle, swipe, Today's hero) into
the task-DETAIL close button that uses `MomentumTaskContext.closeButtonLabel`:

1. **Tasks tab, tap-circle + full swipe** — `Tasks/TaskRow.swift:14` ("No reopen: a closed row's
   check is display-only (E's addendum — closing is one-way)"), `:126` ("Display-only: closed is
   closed"). Both paths funnel through `TaskRow.close(poppingFrom:)` (`:49-54`), which calls
   `Haptics.play(.taskClose)`, `celebrate.request(.pop, at:)`, then `onClose()`. `onClose` is wired
   in `Tasks/TaskListView.swift:215` to `TasksService.close(_:)`
   (`Tasks/TasksService.swift:75-91`, its own doc comment: "One-way since F-V3-Tasks-rebuild …
   there is no reopen").
2. **Home hero close** — `Home/MomentumScoreboardViews.swift:266-284`, the `homeCloseTaskButton`,
   wired to `HomeMomentumSections.closeTask(_:)` (`Home/HomeMomentumSections.swift:248-259`),
   which sets `celebratedTask` and shows `ClosureCelebrationCard` (`:313-369`) — the in-place card
   the record retires by name. `undoClose(_:)` (`:261-269`) already calls
   `taskDetailClient.updateStatus(id:status:.open)` — **reopening already works**; only the UI
   shape is wrong.
3. **Task detail's own Close button** — `Tasks/TaskDetailFormSections.swift:90-119` ("Closing is
   one-way since F-V3-Tasks-rebuild (E's addendum): … No Reopen"), the `taskDetailStatusToggle`,
   calling `service.close()` → `TaskDetailService.close()` (`Tasks/TaskDetailService.swift:101-112`,
   "One-way close … a done task never reopens"). Uses `MomentumTaskContext.closeButtonLabel`
   (`Tasks/MomentumTaskContext.swift:22-26`) — the exact comment the record names.
4. **Life Area detail's task tick** — `LifeAreaDetail/AreaTaskRow.swift:8-9` ("Closing is one-way
   (F-V3-Tasks-rebuild, E's addendum) — a done row's tick is display-only"), the tick button
   (`:52-67`), wired to `LifeAreaDetailView.closeTask(_:)` (`:161-176`, same comment), which also
   calls `taskDetailClient.updateStatus(id:status:.done)`.

   Surfaces 1, 2 and 4 all end at the same underlying write:
   `FirebaseManager+Tasks.swift:29-38`'s `setTaskStatus`, via either `TasksClientAdapting.setStatus`
   (`FirebaseTasksClientAdapter.swift:35-39`) or `TaskDetailClientAdapting.updateStatus`
   (`FirebaseTaskDetailClientAdapter.swift:42-48`). **Reopening (`.open`) is not new capability** —
   `TaskCompletionStamp.applying` (`Tasks/TaskModels.swift:100-105`) already clears `completedAt`
   on reopen, and the adapter's own comment says reopening "must not even request a [location]
   fix" — this path was built for Home's existing undo and is reused, not invented.

**Surface 4 (Life Area detail) is not named in the record's "circle, swipe, Today's hero" list.**
Recommend including it anyway — it carries the identical retired comment and the identical write —
but say so plainly in the build report rather than silently expanding scope; see Step 0 below.

**The capsule's home — new code, sized to fit.** `RootView.swift` is 398 of SwiftLint's 400-line
ceiling (verified: `wc -l` = 398) with a `@StateObject celebrationCenter` pattern already proven to
fit at the **App** level instead: `ADHD_LifeOSApp.swift:188` builds `CelebrationCenter` once and
`RootView` takes it as `@ObservedObject var celebrationCenter: CelebrationCenter`
(`RootView.swift:15`), injected via `.environment(\.celebrate, celebrationCenter)`
(`RootView.swift:273`). **Do the same for the new model** — build it once in
`ADHD_LifeOSApp.swift` beside `celebrationCenter`, inject one `.environment(\.recentAction, …)`
line in `RootView.body` (mirroring `:273`), and let `RootBottomOverlay` read it directly
(`@Environment`) exactly as it already reads `\.celebrate` — no new RootView state, no new
RootView wiring beyond the one environment line.

**Recording a close — reuse `CelebrationRequesting`'s shape, not `@Environment` inside a plain
`ObservableObject`.** `TasksService`, `HomeMomentumSections` (an extension on the View `HomeView`)
and `TaskDetailService` cannot read `@Environment` from a non-View method. The house answer already
exists: `CaptureInboxService` and `NudgesService` take `celebrate: any CelebrationRequesting =
InertCelebrationRequester()` as a constructor default (`Capture/CaptureInboxService.swift:100,116`,
`Nudges/NudgesService.swift:31,36`), and the VIEW reads `@Environment(\.celebrate)` and threads it
in. **All four close button sites are Views, but only three route through `CelebrationPopSource`**
(`Celebrations/CelebrationPopSource.swift:29-32`, which reads `@Environment(\.celebrate)`
internally) — `MomentumScoreboardViews.swift:266`, `TaskDetailFormSections.swift:93`,
`AreaTaskRow.swift:51`. **`TaskRow` is the one site that deliberately does NOT** —
`TaskRow.swift:42-44` says why in its own comment ("the wrapper reports the centre of whatever it
wraps, and the swipe lives on the whole row"): it reads `@Environment(\.celebrate)` directly
(`:34`) and uses `.celebrationPopOrigin` instead. Both shapes are Views, so both can read a second,
new environment key the same way — the natural build is a sibling read added at each of the four
sites, firing right beside the existing `celebrate.request(.pop, at:)` / `.celebrationPopOrigin`
and `Haptics.play(.taskClose)` — not a change to `TasksService`/`TaskDetailService`'s data-layer
methods at all.

**The capsule is optimistic, same as the write it reports.** `TasksService.close(_:)`
(`TasksService.swift:80-91`) flips the local task and regroups BEFORE the network write lands, and
only reloads from the server if the write fails. The capsule should appear on that same optimistic
edge, not wait for the write to confirm — and Undo tapped after a failed, already-reverted write is
simply a no-op (the reload already restored `.open`). Say this explicitly so the build session does
not invent a separate "pending" state for the capsule.

**Home's retirement — in scope for THIS block, not Arc E's.** `celebratedTask`,
`setCelebratedTask(_:)`, `closeTask(_:)`, `undoClose(_:)`, `ClosureCelebrationCard` and
`momentumLeadSection`'s `if let celebrated … else bestNextMoveSection` conditional
(`Home/HomeMomentumSections.swift:12-40,239-269`, `MomentumScoreboardViews.swift:313-369`) are ALL
retired: once close routes through the shared capsule, Home's lead section has no reason to hold
its own celebration state — it recomputes `bestNextMoveSection` immediately (the closed task drops
out of `homeService.openTasks` on the next `load()`, same as it does today after Undo). **Arc E
(round 5a, "H1 · Start first, Close quiet") is a separate, later redesign of the hero's buttons and
states — this block only removes the close-card mechanism and must not pre-empt Arc E's shape.**
**Confirmed dead with it:** `MomentumScoreboard.celebrationLine` (`Home/MomentumScoreboard.swift:299`)
and `.nextButtonLabel` (`:315`) have exactly one call site each — `HomeMomentumSections.swift:24,29`
— building the retired card's text. Delete both and their tests too (the
`dead-shared-component-pattern` memory: seven prior instances, always found by grep, never by the
tests that were still passing on the dead code).

**The capsule's shape, from the record.** 48pt height (round 7: "48pt for anything that starts,
closes, adds, undoes, ends or saves" — **not** `AppSearchRowMetrics.fieldHeight` (44), a
deliberately different, taller metric for this one control; a stacked layout at accessibility
sizes (do not `.frame(height: 48)` unconditionally); tint `Color.accentColor.opacity(...)` at
`AppTabBarMetrics.chipTintLight` (0.12) / `chipTintDark` (0.20) — `Theme/AppTabBarPresentation.swift:223-224`,
read exactly as `Theme/AppTabBar.swift:58-64` composes it; `arrow.uturn.backward` (↶); a haptic on
appear and on Undo (`.haptic(_:trigger:)`, never `.sensoryFeedback` directly — §7.1). Reduce
Motion: fade in, not slide — house pattern `Capture/CaptureFanOverlay.swift:89-97` (`scaleEffect`/
`offset` pinned to final geometry when `appeared || reduceMotion`, only `opacity` free, RM
animation `.default`).

**Two gaps board `54` never rendered — say so, don't guess.** Board 54 covered Tasks, Inbox and a
running sprint, not these two:
- **Journal already has THREE occupants of this row when writing is possible: the pencil disc
  (`JournalComposeDisc`, 42pt) + 16pt + the capture disc.** The record's "on Tasks it stands in for
  the search row" has a direct analogue here — default assumption: the capsule DISPLACES the
  pencil disc while it shows (mirroring how it stands in for Tasks' search row), leaving the
  capture disc alone. This is the tightest width the capsule will ever be drawn at and needs its
  own render, default size AND AX3.
- **Compact-height landscape** (`RootBottomOverlayLayout`, `RootBottomOverlay.swift:20-27,80-90`):
  with a card up (a running sprint, an away summary) the arrangement puts the cards BESIDE the disc
  row rather than above it, and the disc row "takes its own width" (`:186-188`). A capsule in that
  arrangement, sprint running, has never been rendered — add it to the evidence list rather than
  assuming the portrait shape ports over unchanged.

**One slot, one occupant, last-writer-wins across kinds — a real behaviour change, stated
explicitly.** Today, `CaptureInboxService.lastTriageAction` (`Capture/CaptureInboxService.swift:146`)
survives unrelated navigation and is only cleared by `undoLastTriageAction()` or a new triage
(`CaptureInboxService+Triage.swift:103-111`). Once the capsule is the ONE shared slot, **a task
close spends a pending triage undo and vice versa** — closing a task after sorting a capture loses
the capture's undo silently. This is what "one bottom bar everywhere" implies and the record does
not flag it as a cost; say so in the build report. `CaptureInboxUndoSections.undoHeaderButton`
(`:120-136`, the header-arrow safety net) is a second, independent affordance for the SAME
`lastTriageAction` — decide whether it now reads the shared model too (recommended, so it does not
go stale the moment a task closes elsewhere) or is retired with the bar; either is defensible, note
which was chosen.

**No `#available` site.** The tint is the tab bar's existing accent wash, not a Liquid Glass
material — no new `if #available` gate, so no "Verified paths" line is owed; say why in the
report. The RM-on device pass IS owed (§7.3): this is a NEW reduced site (the capsule's
appear-fade) and a CHANGED one (the inbox's undo bar loses its `.move(edge: .bottom)` slide,
RM-02's fix).

**Tests that must be REVERSED, not deleted:**
- `ADHD LifeOSTests/CTAHapticTidyCallSiteTests.swift:109-126`,
  `testTheClosureCardSpringsInAndCrossFadesInsteadUnderReduceMotion` — string-matches
  `HomeMomentumSections.swift` for `.transition(reduceMotion ? .opacity : .scale…)`, the spring/RM
  pair, and `withAnimation(closureCardAnimation)`. All three strings are deleted with the card;
  retarget this test to the CAPSULE's own file and its RM fade (the `CaptureFanOverlay` shape),
  not delete it — it is CLAUDE.md §7.4's "both branches by string" guard and the capsule needs one
  just as much as the card did.
- `ADHD LifeOSTests/CTAHapticTidyCallSiteTests.swift:136-169`,
  `testEveryWriteToTheCelebratedTaskGoesThroughTheAnimatedSetter` — sweeps every app source file
  for bare `celebratedTask = ` writes and requires exactly one, inside `setCelebratedTask`. Once
  `celebratedTask` is deleted entirely this test's own `Self.appCode`/`Self.closure` helpers will
  throw "missing" rather than fail cleanly — retarget it to whatever single recording method the
  new capsule model exposes (the same "exactly one writer, and it is the animated one" guarantee),
  don't just delete it.
- `ADHD LifeOSUITests/SignedInJourneyUITests.swift:307-323` (inside
  `testCapturesTab_sortsACaptureIntoAnAreaAndTakesItBack`) — asserts `app.buttons["Undo"]` and
  references `app.otherElements["captureInboxUndoBar"]` by name in its failure message. If the
  capsule uses a new container identifier this message (and possibly the lookup, if
  `captureInboxUndoBar` stops existing as an element) needs updating — reversed, not deleted; the
  journey's assertions (Undo exists, tapping it restores the capture) must still pass.
- `Tasks/TaskModels.swift`/`TasksServiceMutationTests.swift` and
  `MomentumTaskContextTests.swift`'s "closing is one-way" DOC COMMENTS (not test bodies — grepped,
  no test asserts the ABSENCE of undo) should be annotated "retired 2026-09-19, see F-C1" rather
  than left to read as still true, per the house convention (`F-JournalDoorUnpinned`'s stale-comment
  annotation, not deletion).
- **None found by grep** for a UI or unit test asserting no-undo on `taskCheckbox-`,
  `homeCloseTaskButton`, `taskDetailStatusToggle` or `lifeAreaDetailTick-` — the gap is real but
  unassessed by any test today, so none of those four sites has a test to reverse; each needs a
  NEW test (RED first) instead.

**Acceptance criteria:**
- [ ] RED first: a call-site/behaviour test per surface that closing shows the capsule and Undo
      reopens the task (all four/five sites), plus the two reversed `CTAHapticTidyCallSiteTests`
      above (RED against the current `celebratedTask` code).
- [ ] Red-check: restore the pre-block code (`git checkout --`), count failures, restore again.
- [ ] SwiftLint 0, full suite green, build green — all three pasted verbatim.
- [ ] `screenshots/undo-capsule/` + README: Tasks (light/dark/AX3), Home, Life Area detail, the
      Capture Inbox's migrated bar, the "one slot, last-writer-wins" collision (close a task right
      after sorting a capture), **Journal at default size and AX3 (capsule vs pencil disc, the
      tightest width)**, and **compact-height landscape with a sprint card up** — all "settled by
      looking" per CLAUDE.md's screenshots filter (a live rule applied to real data/geometry).
- [ ] `apple-design` review owed (§7.6) — every one of these sites becomes visible/behavioural.
- [ ] RM-on device pass owed (§7.3) — new site (capsule appear-fade) + changed site (inbox bar's
      slide removed). No `#available` site touched, so no "Verified paths" line — say so.
- [ ] No `firestore.rules` change — this block is UI + an existing, already-permitted status write.

**Dependencies:** none upstream (this is the arc's first block); C2, C3 and C4 all reuse this
capsule's visual design for their own bars, so they depend on this block landing first.

**Step 0 — ANSWERED by E, 2026-09-19, before the hand-off. Do not re-ask:**
1. **Surface 4, Life Area detail's tick → INCLUDE it.** E: *"Yes, every close gets the undo
   (Recommended)"*. Same action, same undo, wherever it happens.
2. **The inbox's `undoHeaderButton` → KEEP IT**, as a second route reading the SAME undo as the
   capsule, so it can never go stale. E chose this over the recommendation to retire it.
3. **Nudge "Done for now" → INCLUDE it as a fifth capsule kind.** E: *"Yes, a nudge dismiss gets
   the capsule (Recommended)"*. It needs the new `unmarkFired` write described above. A 7-day nudge
   celebration that already fired is not un-fired.
4. **Journal's disc row → the capsule STANDS IN FOR THE PENCIL** while it shows, full width, exactly
   as it stands in for Tasks' search row (board `54`). The + disc never moves, and the pencil
   returns after the next action. So the "tightest width" case below does not arise; render it
   anyway as evidence.
5. **The cross-kind collision was NOT asked.** It follows from E's own "one bottom bar everywhere",
   so the build report NAMES the consequence (a task close spends a pending capture undo) rather
   than re-opening the decision.


**Built 2026-09-20, and where it departs from the spec.** Suite **3,130 / 0**, SwiftLint **0 / 842**,
build green. Everything E answered in Step 0 shipped as answered: all five close surfaces including
the Life Area tick, the inbox header ↶ kept and repointed at the shared slot, the nudge dismiss as a
fifth kind with its new `unmarkFired` write, the Journal capsule standing in for the pencil, and the
cross-kind collision named rather than softened.

**Five departures, each deliberate:**

1. **The reversal reports whether it landed** — `RecentAction.undo` is `() async -> Bool`, not
   `-> Void`, and the centre puts the offer BACK on `false`. The spec did not ask for this, and
   without it the block would have silently dropped a promise the Capture Inbox already made:
   *"nothing happened, so the offer still stands"*. For "Journal it" that is a safety argument —
   a failed restore deliberately leaves the journal entry alone because it is the only copy of the
   thought left, so the user has to be able to try again. Every reversal is `@discardableResult ->
   Bool` now, including the two the spec described as `Void`.
2. **The capsule WRAPS the disc row's leading band rather than joining it.** The spec called it "a
   THIRD optional occupant of this same slot". As a sibling it would have shown beside the search
   row and pushed the + disc off the row; as a wrapper it stands IN FOR the band, which is what E
   actually asked for, and it gives the outgoing occupant the same fade the capsule arrives on
   (§7.2's disappears case, which the spec did not name).
3. **`RecentActionCenter` is injected from `ADHD_LifeOSApp`, not from `RootView.body`.** The spec
   said "inject one `.environment(\.recentAction, …)` line in `RootView.body`", but RootView is at
   398 of SwiftLint's 400-line ceiling and holding the object needs a property plus its comment.
   Two lines in the App, zero in RootView. Also **two** environment keys, not one: `@Environment`
   does not subscribe to an `ObservableObject`, so the drawing side takes the object and hands it
   to an `@ObservedObject` child — `CelebrationLayer`'s shape exactly.
4. **`CaptureInboxService` and `NudgesService` take the recorder as a settable `var` wired by their
   host in `.task`**, not as an `init` parameter like `celebrate`. Both are `@StateObject`s built
   in an `init`, where an `@Environment` value is not available, and threading it through RootView
   hits (3)'s ceiling. Pinned by `UndoCapsuleCallSiteTests`.
5. **`CaptureTriage.confirmation(for:sortedInto:lifeAreas:)` was DELETED**, replaced by
   `areaLabel(id:in:)`. It built the retired bar's whole sentence ("Skipped — it'll come back
   round") because that bar had one line; the capsule carries the subject underneath, so the verb
   is `RecentActionKind.verb`'s job. The degrade-to-the-bare-verb rule survived. Its three tests
   went with it, recorded in place rather than silently dropped. `MomentumScoreboard.celebrationLine`
   and `.nextButtonLabel` were deleted with the closure card, and their four tests with them.

**Two things found by looking, not by a test** — both fixed in the block:
- **The Undo button truncated to "Un…"** beside a two-line subject (first simulator render). SwiftUI
  compresses whichever child will give, and the child that gave was the one control that must never
  be ambiguous. `.layoutPriority(1)` + `.fixedSize`, pinned by name.
- **The capsule arrived silently for VoiceOver** (`apple-design`, `voiceover.md › Best practices`).
  It is the last element on screen and on Tasks it replaces the search row, so both halves of what
  happened were out of reach. It now posts an announcement in the action's own words.

**And one found by reading the coverage report:** `UndoCapsuleMotion.appearance` sat at 0% — the
two-branch guard matches its SOURCE, which proves the branch is written and never that it resolves.
§7.4 wants both, so it has an ordinary unit test now. All four non-view files in `Undo/` are at 100%.

**Owed to E, and NOT done in this session:** the device look, and the **Reduce-Motion-on device
pass** (§7.3) — this block adds a reduced site (the capsule's appear-fade) and changes one (the
inbox bar's `.move(edge: .bottom)` slide is gone). Reduced: run on sim (injected) + unit-tested;
**NOT on device**. No `#available` site was touched, so no "Verified paths" line is owed; the one
tier considered (`AccessibilityNotification.Announcement`, iOS 17+) was declined because it adds
only a priority. No `firestore.rules` change: soft delete is arc C3's, and this block's writes are
the already-permitted task status and nudge stamp fields.


**E's HEIGHT ROUND, 2026-09-20 — after the block had landed.** E looked at the evidence folder and
marked a band on `02-…-EDITED.jpg`: *"the UndoCapsule must be made smaller in height, it looks ugly
with the UndoCapsule at the same height as the FAB Icon."* Measured: the red lines are **45.3pt**
against a capsule drawn at **74pt** and a 60pt capture disc.

45pt could not hold the shape E approved on board `54` — the verb line, the gap and two lines of
`.callout` subject are ~62pt of text before padding, and the Undo pill's own 48pt floor was taller
than the whole band. So four shapes were rendered on the real Tasks screen from one build
(`screenshots/undo-capsule-height/`) and **E chose "two lines, a size smaller"**: board 54's
arrangement kept, verb `.footnote` → `.caption2`, subject `.callout` → `.footnote` and ONE line.
The card is **44pt**, which is also §3's touch floor and the search row's own height — it stands in
that slot, so matching it is deliberate rather than a coincidence.

**E also chose the Undo control's trade by name — *"Yes — draw 32, tap 44"*.** The pill is drawn at
32pt and its hit area is grown back to §3's 44pt with the tab bar's own negative-padding trick
(`AppTabBarMetrics.slotHitOverflow`). **This overrides round 7's "48pt for anything that … undoes"
for this one control**, and only for it: round 7's number was written for a control that owns its
space, and this one now sits inside a 44pt band. The two tests that pinned 48 were REVERSED, not
deleted, and the one that matters now asserts the drawn height plus its overflow still reaches 44 —
a test that only checked the drawn size would pass on a build where the target shrank with it.

**Two harness traps cost a render round each, and both are the same trap:** a switch the app never
received. `-undoShape-oneLine` is swallowed because a leading `-` makes iOS expect a value after
the key; `xcodebuild`'s own environment does not reach the TEST RUNNER, which is what silently
defeated the AX3 pass earlier in this block too. Every run photographed the default and measured an
identical 74pt. The fix both times: **one test method per variant** — a method name cannot be
swallowed.


**E's SHAPE ROUND, 2026-09-20 — the FIRST device look, and it sent the shape back. BUILT 2026-09-20 — see "Built, and where it departs from the spec" at the end of this section.**
`main` @ `3f7932c` went onto E's phone (build, install and launch clean in one WIRELESS pass — the
phone was never disconnected, whatever the opener said). E ran both passes.

**The Reduce-Motion-ON pass PASSED** — E: *"Passes your request requested checks"*. **That discharges
the §7.3 RM-on pass F-C1 owed.** E's frames also settled two things on hardware that no test reaches:
`IMG_8565`→`IMG_8566` is task detail with the capsule, then the same screen with "Close it" back and
the capsule gone — the reversal landing against real Firestore; and `IMG_8562` is the capsule
recorded on Today still standing on the Capture Inbox tab, which is the one-slot design working.
Both are in `screenshots/undo-capsule-redesign/`'s README as the round's provenance.

**The Reduce-Motion-OFF look sent the shape back, verbatim:** *"Bringing back a second line is smart.
I also recommend that we remove the blue chip background colour behind the "Undo" Button and increase
the corner radius of the entire UndoCapsule card."*

**Eight shapes were rendered on the real Tasks screen (and over the Capture Inbox's dense content)
from one build** (`screenshots/undo-capsule-redesign/`), each closing a named seeded task so the
second line had something to do, and each in a test method of its own asserting its own
accessibility identifier. **E chose in TWO rounds, and the second round overturned part of the
first — read both.**

**Round 1 — E, by looking:** *"from the images you've made Option C, 'Fully rounded' looks the
best"*. Then, asked the two open axes: the Undo control's horizontal padding **reclaimed 16 → 0**,
and **"up to two lines"** over a steady 59pt — chosen with the 59-vs-60 tension named, because 59pt
sits level with the 60pt capture disc and that is close to the *"same height as the FAB Icon"* E
rejected at 74.

**Round 2 — that exact combination had never been rendered, so it was, and the measurement
contradicted the reason for the third pick.** With the padding reclaimed the subject column holds
roughly **12–14 characters per `.footnote` line**, so BOTH seeded titles wrap: "Take a 10-minute
walk" breaks to *"Take a 10- / minute walk"* and the card is **59pt either way**. "Up to two lines"
therefore behaves like "always two lines" for any realistic task title, and the 44pt fallback E
picked it for is only reachable for something as short as a nudge label. (The earlier `upToTwo`
frame measured 52.7pt because it KEPT the 16pt padding, so its narrower column made
`.minimumScaleFactor(0.8)` shrink the text. The two decisions interact, which is exactly why the
combination had to be rendered rather than reasoned about.)

**59pt is near the floor for that arrangement** — `.caption2` verb (~13) + 4pt gap + two `.footnote`
lines (~36) + 8pt padding ≈ 61 — so there is no comfortable ~50pt two-line shape. The choice was
therefore binary, and E chose by looking at `00-board-the-height-choice-D.jpg`:

### THE FINAL SHAPE — build exactly this

- **Fully rounded** — a `Capsule(style: .continuous)`, not a radius number.
- **No chip** behind the Undo control.
- **`undoHorizontalPadding` reclaimed, 16 → 0** (deleted, not zeroed — see the reversed test).
- **ONE line, and the card stays 44pt.** E chose *"44pt, one wider line"* over the 59pt two-line
  shape **after** being shown that the second line costs 15pt for every task title. The reclaimed
  32pt is spent widening the single line instead: the frame reads *"Capture three things on…"*
  where the shipped shape reads *"Capture three thi…"*.

**So E's original *"bringing back a second line is smart"* is SUPERSEDED by E's own later look, and
this is the one thing in the round most likely to be mis-built.** Do not add a second line. The
second line was a means to the truncation problem; the padding reclaim solved more of that problem
at no height cost, and E chose the height. `subject` keeps `.lineLimit(1)` — unchanged from what
ships today — and `minHeight` stays 44.

**Contrast IMPROVES, and this is not a licence to touch the colour arc.** Computed from the
colorsets, the Undo label goes **3.38 → 3.93:1** light and **3.48 → 4.47:1** dark once it sits on
`cardSurface` instead of the 12%/20% accent wash. Both still fall short of `accessibility.md`'s
4.5:1 for 16pt text. The 3.38/3.48 pair reproduces the register's existing figures exactly, which is
what validates the method. **Round 9's "Leave it to the colour arc" holds — record it, fix nothing.**

**What the build does.** The round-scoped files are already GONE from `main` (`UndoCapsuleVariant.swift`
and `UndoCapsuleRedesignRenderUITests.swift` were removed in the close-out, and `UndoCapsule.swift`
was restored byte-identical to its shipped state) — so the build starts from the SHIPPED capsule and
applies four changes to `UndoCapsule`/`UndoCapsuleMetrics`:
1. the card's background and border become `Capsule(style: .continuous)`. **`strokeBorder` needs
   `InsettableShape`, which `AnyShape` is NOT** — that bit the render build. `Capsule` itself is
   insettable, so branching on a real shape rather than erasing avoids the problem entirely.
2. the `chipTint` background goes, and `chipTint` with it if nothing else reads it.
3. `undoHorizontalPadding` is DELETED — from the constant AND from `spacings`.
4. **nothing else.** The subject's `lineLimit(1)`, `minHeight` 44, `undoDrawnHeight` 32,
   `undoHitOverflow` 6 and every spacing are unchanged.

**Tests that must be REVERSED, not deleted** (`ADHD LifeOSTests/UndoCapsulePresentationTests.swift`):
1. `testItWearsTheSearchRowsCornerRatherThanANewNumber` — the capsule no longer inherits
   `AppSearchRowMetrics.fieldCornerRadius`. Its reasoning ("a second radius beside the row it
   replaces would read as a different control in the same slot") is what E overruled by looking, and
   the replacement should say so and assert the card is a `Capsule`.
2. `testEveryCapsuleSpacingIsOnTheGrid` — **this FAILS rather than lapses, and it is why the constant
   is deleted rather than zeroed.** `spacings` sweeps for membership of {4, 8, 16, 24} and 0 is not
   in it. Removing `undoHorizontalPadding` keeps the guard honest; adding 0 to the grid would
   quietly widen a rule protecting every other value.
3. `testTheDrawnControlFitsInsideTheCardWithItsPaddingToSpare` still passes (32 + 8 ≤ 44) — check,
   do not assume.

**The test that must be KEPT and STRENGTHENED** —
`testTheUndoControlIsDrawnSmallerThanItsTapTargetAndTheTargetIsStillFortyFour`. This is
`apple-design`'s one Medium finding on the round (`buttons.md › Best practices`: *"a button needs a
hit region of at least 44x44 pt"*): with the chip gone **nothing on screen shows the tap target any
more**, so this assertion stops being a double-check and becomes the only guard. `undoDrawnHeight` 32
and `undoHitOverflow` 6 are now pure layout/target mechanism rather than a visible pill.

**A test worth ADDING:** the subject is wider than it was, and the reason is a deleted constant. A
test that pins "the Undo control spends no horizontal padding" would catch someone reinstating it
while tidying — which is exactly the shape of change that would silently undo E's decision.

**What is NOT owed.** No `#available` site is touched, so no "Verified paths" line. **No RM-on device
pass**: the shape round changes geometry and fill only — `UndoCapsuleMotion` is untouched — and
F-C1's RM-on pass has already PASSED on E's phone. No `firestore.rules` change.

**Still owed when it is built:** re-render `screenshots/undo-capsule/` at the chosen shape (its
README already carries a re-render note from the height round; this is the second), and the two
landscape frames still suffixed `-PRE-HEIGHT-ROUND` are now two rounds stale. **Both done — see
below.**

### Built 2026-09-20, and where it departs from the spec

All four changes landed exactly as specified — `Capsule(style: .continuous)`, no chip,
`undoHorizontalPadding` DELETED from the constant and from `spacings`, `lineLimit(1)` and
`minHeight` 44 untouched. **No second line.** Suite **3,137 / 0**, SwiftLint **0 / 843**, build
green.

**ONE departure, and E made it: the card's radius is CAPPED at `minHeight / 2`.**

The spec said `Capsule(style: .continuous)`, "not a radius number", and that is what was built and
rendered first. **Then the stacked accessibility layout was rendered at the new shape for the first
time — and no frame in the whole redesign round had ever been taken above the default text size.**
A `Capsule` takes its radius from half the card's height. At the default 44pt that is a harmless
22. At Accessibility XL the stacked card measures **194.3pt**, so the caps grow to **97.2pt** and
the curve eats the corners the content sits in:

- the completion glyph was drawn **59.0pt** outside the card's own fill;
- the ↶ Undo control — the one affordance this whole feature exists for — **30.3pt** outside it.

Measured off the render, and the method was validated against a known value first: the middle row
reads 17.0pt against the 16pt `horizontalPadding` it should be.

E was shown both shapes rendered on the real Tasks screen at Accessibility XL and **chose the cap**.
**It is not a compromise on what E approved at the shape round**: `min(height, minHeight) / 2` is 22
at 44pt — the capsule's own radius — and the two builds' renders came back **byte-identical over the
capsule band (max channel delta 0, zero differing pixels across 1206×175)**. The cap changes the
accessibility layout and nothing else, and it is a CEILING rather than a fixed corner, so a card
shorter than the floor is still fully rounded.

`UndoCapsuleCardShape` is a concrete `InsettableShape` (the spec's own warning: `strokeBorder` needs
one and `AnyShape` is not) that asks `UndoCapsuleMetrics.cardCornerRadius(forHeight:)` rather than
deciding anything itself.

**The lesson generalises, and it is this block's third instance of the same one:** a combination has
to be RENDERED, not reasoned about. The height round found it when two of E's picks interacted; the
shape round found it when the winning variant did not exist at design time; this found it because
every frame E ever chose from was at one text size. **When a shape's geometry is DERIVED from its
content's size, the accessibility layout is a different shape — render it before calling the round
closed.**

**Tests, beyond the four the spec named.** `testTheContentsOwnCornerSitsOnTheCardAtEveryHeightTheLayoutCanTake`
samples the drawn path at the glyph's own corner across four heights, so E's break is pinned as
geometry rather than as a radius number; mutated back to a true capsule it fails at 100, 194.3 and
260pt and PASSES at 44, which is the control. `testTheBorderInsetsItselfInsideTheFillAndTheInsetsAccumulate`
pins what `strokeBorder` relies on. Both were added because the shape dropped
`UndoCapsuleMetrics.swift` from 100% to 58.33% — `path(in:)` and `inset(by:)` are pure functions
SwiftUI alone was calling.

---

### FEATURE: F-C2-DraftsToInbox — unsent text goes to the inbox; Cancel becomes Close; task detail autosaves  [x] COMPLETED

**What E chose.** Round 2: *"Unsent text → 'Inbox catches it'. A composer closed with text files it
into the Capture Inbox as a note. A bar, 'Kept in your inbox · Reopen', stays until the next
action."* Also round 2, stated as carried by every option: *"Task detail's blocking 'Discard
changes?' becomes autosave with swipe-back restored. And Cancel becomes 'Close', because
`sheets.md` says Cancel means 'without saving'."* Q4 (opener): *"When a composer containing typed
text is swiped down, silently save as a draft / quick capture item in the background — never block
with a modal and never lose user input."*

**The three composers today, all read:**
- `Capture/QuickCaptureView.swift` — presented as a `.fullScreenCover` (`RootView.swift:254-263`),
  so swipe-down is already impossible; **Cancel discards silently**: `Button("Cancel") { dismiss()
  }` at `QuickCaptureView.swift:129`. MODAL-1/CAPT-01, sim-verified (findings §E: "Book the dentist
  before Friday" gone on reopen, no prompt).
- `Tasks/TaskCreateView.swift` — presented as a real `.sheet(isPresented:)`
  (`Tasks/TaskListView.swift:123-130`), so swipe-down IS live and undefended (no
  `.interactiveDismissDisabled`, no `.onDisappear` hook); **Cancel discards**: `Button("Cancel") {
  dismiss() }` at `TaskCreateView.swift:73`.
- `Journal/LogComposerView.swift` — text lives on `@ObservedObject var journalService:
  JournalService` (`:12`, `journalService.composerBody` bound at `:52`), not a local `@State`, so
  it already survives Cancel/swipe WITHIN the session (JournalService outlives the view — every tab
  stays mounted). It is lost only when the app quits (JRNL-01, in-memory only). **Cancel**:
  `Button("Cancel") { dismiss() }` at `LogComposerView.swift:117`.

**The shape.** On Cancel/Close (and, for `TaskCreateView`, on a swipe-down caught via
`.onDisappear` or `.interactiveDismissDisabled(true)` plus a custom close button — a `.sheet`'s
swipe cannot otherwise distinguish "empty, discard silently" from "typed, must file first"):
1. If the primary text field is non-empty, create a `.note` capture via the existing
   `CaptureClientAdapting.createCapture(_:NormalizedCreateCaptureInput)` seam
   (`Capture/CaptureClientAdapting.swift:65-66`, already used by
   `CaptureInboxService+Create.swift:15`) with that text as the capture's content.
2. Show the capsule (F-C1) with "Kept in your inbox · Reopen" instead of dismissing silently.
3. Relabel the Cancel button "Close" on all three composers (a copy-only change, but it rides this
   block since it is carried by the same E decision).

**Accepted costs — name these in the build report so nobody invents a richer draft type:**
- Only the PRIMARY text field is caught. Task composer metadata (due choice, area, place, notes,
  tags) and Journal's type/energy/mood chips are dropped when filed as a plain `.note` — matching
  what a fan-opened Task capture already looks like in the inbox, not a richer draft object.
- `QuickCaptureView`'s voice and photo kinds are NOT "typed text" and are unaffected by this block
  (no swipe-down exists for them either, since it is a full-screen cover).
- **`JournalService.composerBody` must be cleared when filed**, or the text exists twice (once as
  a filed capture, once still sitting in the service for the next time the composer opens).

**New dependency wiring, since neither composer holds what it needs today:** `TaskCreateView` holds
only `TaskCreateClientAdapting` (`:19`); `LogComposerView` holds no capture client at all. Both need
a `CaptureClientAdapting` threaded in from their presenting screens
(`TaskListView.swift:123-130`, `LifeAreaDetail/LifeAreaDetailView.swift:111`,
wherever `LogComposerView` is presented) the same way `QuickCaptureView` already takes one
(`QuickCaptureView.swift:38-39`).

**Task detail autosave (MODAL-4, TASKS-08).** Delete the discard gate entirely:
`showDiscardAlert`, the `.alert("Discard changes?", …)` block (`Tasks/TaskDetailView.swift:42,109-116`),
`attemptBack()`'s dirty check (`:150-157`) and `.navigationBarBackButtonHidden(true)` (`:103`) —
restoring the system back button and its swipe-back gesture. In its place, autosave on field change
(debounced or on-blur — build session's call), reusing the existing `performSave()`
(`Tasks/TaskDetailFormSections.swift:264` onward) and `TaskDetailDirtyState`
(`TaskDetailView.swift:161-183`) machinery that already computes what changed; the visible "Saved"
confirmation (`showSavedConfirmation`, `:43,90-96`) already exists and needs no new UI, only a new
trigger.

**Tests that must be REVERSED, not deleted:**
- Any unit/UI test asserting `taskDetailDiscardChangesButton` / `taskDetailKeepEditingButton`
  (`TaskDetailView.swift:111,113`) exist or fire — grep found the identifiers only in the view
  file itself; **none found by grep** in `ADHD LifeOSTests/` or `ADHD LifeOSUITests/` for either
  identifier, so there is nothing to reverse for the alert's removal beyond the identifiers going
  away (verify again at build time — a UI journey may reach this screen incidentally).
- `.navigationBarBackButtonHidden(true)` / swipe-back-disabled — **none found by grep** for a test
  asserting swipe-back is disabled; nothing to reverse, but a NEW test should assert swipe-back now
  works (§7.4 needs one).
- Cancel-discards-silently: **none found by grep** for a unit test on `QuickCaptureView`'s or
  `TaskCreateView`'s Cancel button specifically discarding text (the CAPT-01/MODAL-1 findings were
  established by sim-drive and code-reading, not by an existing test) — RED-first coverage is new,
  not reversed.

**Acceptance criteria:**
- [ ] RED first: for each composer, typed text + Close/swipe → a `.note` capture with that content
      exists in the inbox and the capsule shows "Kept in your inbox · Reopen"; task detail: edit a
      field, back out with no Save tap, reload → the edit persisted; swipe-back pops the screen.
- [ ] Red-check, restoring pre-block code; count failures; restore with `git checkout --`.
- [ ] SwiftLint 0, suite green, build green, pasted.
- [x] COMPLETED `screenshots/drafts-to-inbox/` + README: each composer typed-then-closed, the
      inbox afterward, and task detail's swipe-back working. **Produced 2026-09-22**, one session
      late — 33 frames (light / dark / AX3) from `DraftsToInboxRenderUITests`.
- [ ] `apple-design` review owed (§7.6) — new bar state, new copy, restored system chrome.
- [ ] RM-on device pass owed only if this block adds/changes a NEW reduced site beyond reusing
      F-C1's capsule as-is; if the capsule component itself is untouched, say none is owed here
      and point to F-C1's pass.
- [ ] No `firestore.rules` change (captures already have full owner CRUD, §Architecture; this
      writes ordinary `.note` captures through the existing seam).

**Dependencies:** F-C1 (the capsule and its "kept in your inbox" bar shape).

### Built 2026-09-20, and where it departs from the spec

Suite **3,174 / 0**, SwiftLint **0 / 853**, build green, **`SignedInJourneyUITests` +
`JournalJourneyUITests` run deliberately and PASSED 6/6** — the opener's own lesson, since UI tests
are skipped in the standard run and this block relabels three controls.

**Four departures, all deliberate.**

1. **A spec CORRECTION, found by reading the tree.** `QuickCaptureView` is presented **twice**: as a
   `.fullScreenCover` from the capture disc (`RootView.swift`) *and* as a `.sheet` from the Capture
   Inbox (`CaptureInboxView.swift:124-129`). The spec's *"presented as a `.fullScreenCover` … so
   swipe-down is already impossible"* is true of one route only. `.onDisappear` covers both, which
   is part of why it was the right hook.
2. **`.onDisappear`, and `.interactiveDismissDisabled` was NOT needed** (Step 0 answer 2 asked for
   this preference and for the report to say which was used). A half-swipe that springs back never
   calls it, so a cancelled dismissal files nothing *by construction* rather than by a guard.
3. **Autosave fires on LEAVING, not on field change.** The spec offered "debounced or on-blur —
   build session's call". Both were rejected for a measured reason: `service.save` sets
   `state = .loaded(updated)`, which `TaskDetailView`'s own header comment records as tearing down
   the Form and *"resetting its scroll to the top"*. Saving per blur would yank the user's scroll
   position every time they moved between fields. The explicit Save button and its "Saved" toast
   stay for anyone wanting the edit confirmed before walking away. **Accepted cost:** edits are
   still lost if the app is killed with the screen open and nothing left.
4. **The capsule's control is no longer always "Undo".** E asked for *"Kept in your inbox ·
   Reopen"*, and Reopen is not a reversal, so `actionLabel`/`actionSystemImage` became properties
   of `RecentActionKind`. `RecentAction.undo` keeps its name and `Bool`; what broadened is the
   meaning — "the offered action landed". The five existing kinds still answer "Undo" verbatim,
   which `SignedInJourneyUITests` depends on.

**Accepted costs, named so nobody invents a richer draft type:** only the PRIMARY text field is
caught (task metadata and journal chips are dropped, and a filed draft is an ordinary `.note`);
voice and photo captures are untouched; and **filing a draft SPENDS whatever undo was pending**,
since the capsule is one slot — the same cost E already accepted for the close/triage collision.

**The one acceptance criterion this block missed was MET on 2026-09-22**, a session late:
`screenshots/drafts-to-inbox/` now holds 33 frames (light / dark / AX3) and a README, produced by
`ADHD LifeOSUITests/DraftsToInboxRenderUITests` against the shipped build (no app code changed —
`git diff 4917955 bc2827e` touches `handoff/` only). **Four things it caught that the block's own
green suite could not:**

1. **The Journal has no compose control at all while a capsule is pending** — the capsule stands in
   for the pencil disc, so the first run failed with *"The journal composer never opened"*. The
   documented intent of one-bar-everywhere, but THIS block made it common: before, only a close or
   a triage made a capsule; now any composer closed on text does. Recorded for E, not re-tuned.
2. **Reopen lands on a PUSHED screen, not a sheet** (`CaptureInboxView`'s `navigationDestination`)
   — 45s of a harness waiting for a sheet that never existed, and had it not, the still-pushed
   detail would have been on the stack when the inbox frame was taken.
3. **`F-C1`'s radius cap holds for the wider "↗ Reopen" control at AX3** — glyph, verb, subject and
   the control all inside the card's fill. This was the open question `F-C1`'s Critical implied and
   only a render at that text size could answer.
4. **The selected Captures tab truncates to "Captu…" when badged**, already at 80% scale, because
   the badge overlay takes width from the same pill. Filed drafts are what make the state common.
   A register candidate — §7.5: a review may name the tension, never re-tune the bar.


**Step 0 — ANSWERED before the hand-off. Do not re-ask:**
1. **"Reopen" → opens the filed capture in the Capture Inbox** (option B). E: *"Open it in the inbox
   (Recommended)"*. It is composer-agnostic and survives arc D's composer unification unchanged.
2. **The swipe-down mechanics are the BUILD's call, not E's** (settled by the spec session): prefer
   filing the draft when the sheet has ACTUALLY gone, so a swipe keeps dismissing as it does today.
   A cancelled swipe must not file anything — prove that in a test. Reach for
   `.interactiveDismissDisabled(true)` plus a visible Close only if the dismissal hook proves
   unreliable, and say in the report which was used and why.

---

### FEATURE: F-C3-RecentlyDeleted — soft delete for tasks and captures; one row in Tools  [x] COMPLETED

**What E chose.** Round 2: *"Where Recently Deleted lives → 'One row in Tools'"* (not context, not
Settings), *"Kept 30 days"* (stated as the default; E did not object). *"Tasks + Captures + Tags"*
(tags are C4). *"Places, nudges and place actions keep confirm-then-permanent delete (Q10)."*
"Journal delete goes to the gaps list" — out of scope here.

**Today's hard deletes, all read:**
- `Tasks/TaskDetailView.swift:117-129` — `confirmationDialog("Delete this task?", …)` →
  `performDelete()` (`TaskDetailFormSections.swift:215-219`) → `TaskDetailService.delete()`
  (`TaskDetailService.swift:114-124`) → `TaskDetailClientAdapting.deleteTask`
  (`TaskDetailClientAdapting.swift:19`) → `FirebaseTaskDetailClientAdapter.deleteTask`
  (`:51-53`) → `TaskDetailBackingStore.deleteTask` (`TaskDetailBackingStore.swift:17`) →
  `FirebaseManager+Tasks.swift:41-43`, `delete(id:from: .tasks)` — a real document delete.
- `Capture/CaptureDetailView.swift:107-119` — `confirmationDialog("Discard this capture?", …)` →
  `service.discard(capture:)`. (Read the equivalent `FirebaseManager+Captures.swift` delete before
  building — not re-read for this spec; same generic `delete(id:from:)` shape is expected.)

**Firestore rules — verified, not assumed.** `firestore.rules:55-59` already grants the owner full
`read, write` on `tasks` and `captures` (both are in the generic
`collection in ['tasks', 'life_areas', 'tags', 'captures', …]` allow). **A `deleted_at` field needs
NO new allow rule** — the owner can already write it. Do not invent a rules diff to satisfy
CLAUDE.md's "schema change → rules change" line by fiat; write the true state instead:
*"rules verified unchanged against firestore.rules:55-59; RECOMMENDED hardening —
`request.resource.data.deleted_at <= request.time`, so a client cannot pre-date its own purge
window — added if the build session agrees, and E republishes regardless of whether anything
changed, per house policy of confirming rules stayed correct."*

**The Firestore null-query trap (read from `FirebaseManager+Tasks.swift`'s existing `fetchWhere`
shape, generalised).** A soft-delete filter written as `whereField("deleted_at", isEqualTo:
NSNull())` matches ONLY documents where the field is explicitly present and null — every EXISTING
task/capture (field absent entirely) would be excluded from every list. **Do not query for
"not deleted"; fetch as today and filter live-ness client-side**, via a small pure helper (e.g.
`SoftDelete.isLive(deletedAt:asOf:)`) applied after `fetchTasks()`/`fetchAllTasks()`/etc. return.
Enumerate every read path that must apply it (grepped): `FirebaseManager+Tasks.swift`'s
`fetchTasks()`, `fetchTaskDetail(id:)`, `fetchOpenTaskSummaries()`, `fetchTasks(lifeAreaId:)`, and
the captures equivalents in `FirebaseManager+Captures.swift` (not enumerated here — read at build
time), plus `RootView`'s capture-inbox badge count (`captureInboxCount`,
`RootView.swift:53,277-279`). **A call-site test must pin the full list**, on the model of
`AppTabBarCallSiteTests`/`CaptureDiscClearanceCallSiteTests` (F-C1's neighbours) — a read path
added later without the filter is exactly the failure mode those tests exist to catch.

**Restore and permanent-delete, from the record's round 7 rule.** Restore is a 48pt VISIBLE button
("anything that undoes" is a key target) — never swipe-only, which is the exact GEST-2 finding this
arc is fixing elsewhere. A permanent "Delete forever" gets its own confirm (Q10: friction is
allowed "executing permanent deletions").

**The Tools placement — a row/section, not a third bento card.** `Tools/ToolsCatalog.swift:24-77`
pins exactly two `Entry` values by test (`ToolsCatalogTests`, per its own doc comment at `:14-23`
and `:20-23`); a third door is "a decision rather than a drift." E said "row," and the app already
has a non-card precedent for exactly this: `ToolsRoutinesSection` (E's 2026-09-05 call, "a headed
SECTION … not a card" — `ToolsView.swift:15-18,72-79`). **Follow that shape, not
`ToolsCatalog`'s.** One caveat: `ToolsRoutinesSection` is gated `@available(iOS 17.0, *)`
(`ToolsView.swift:77`) because the screen it opens is; Recently Deleted has no such dependency and
must stay reachable on the 16.0 floor (§7.1) — do not copy the `#available` gate along with the
shape.

**Tests that must be REVERSED, not deleted:**
- `ToolsCatalogTests` (file not yet read in full — grep confirms it exists and pins the two-`Entry`
  count per `ToolsCatalog.swift:23`'s own comment): if Recently Deleted is added as a THIRD
  catalog `Entry` instead of a section, this test fails and must be reversed to expect three; if it
  is added as a section (recommended, matching Routines), this test is untouched — verify which at
  build time and say so.
- Any test asserting `TaskDetailService.delete()` / `deleteTask` performs a real Firestore
  document delete (searched by call chain above, not yet grepped by name — grep
  `deleteTask\(id:\)` test usages before building) needs reversing to assert a soft-delete write
  instead.
- **None found by grep** for "Recently Deleted" anywhere in `ADHD LifeOSTests/` or
  `ADHD LifeOSUITests/` — this is entirely new surface.

**Acceptance criteria:**
- [ ] RED first: deleting a task/capture soft-deletes it (document still exists, `deleted_at` set,
      excluded from every enumerated read path); the Tools row lists it; Restore clears
      `deleted_at` and the item reappears everywhere it should; a 30-day-old soft-deleted item is
      purged by whatever mechanism Step 0 settles.
- [ ] Red-check, restore, count failures, restore code.
- [ ] SwiftLint 0, suite green, build green, pasted.
- [ ] `screenshots/recently-deleted/` + README: the Tools row (empty and with items), a soft-deleted
      task absent from Tasks but present in Recently Deleted, Restore bringing it back.
- [ ] `apple-design` review owed (§7.6) — a new screen and a new list state.
- [ ] RM-on device pass: owed only if the new screen/capsule reuse adds a reduced site beyond
      F-C1's; if it draws with plain `List`/`Form` rows and no new animation, say none is owed and
      why.
- [ ] **`firestore.rules` — verified unchanged against `:55-59`; if the hardening rule (Step 0) is
      added, E republishes.** Say which happened.
- [ ] A call-site test enumerating every read path the soft-delete filter must reach (see above),
      so a later collection/query addition cannot silently leak deleted items back in.


### COMPLETED 2026-09-22 — eight cycles over two sessions

**Every acceptance criterion is met.** The three cycles below landed first and were deliberately
INERT; the writes, the screen, the purge, the capsule kinds and the copy fix followed in the
second session. Suite **3,253 / 0**, SwiftLint **0 / 878**, build SUCCEEDED, coverage **29.87%
(14,953/50,068)**, `screenshots/recently-deleted/` filed with 20 frames and a README, and the
`apple-design` review is in the block report.

**Two findings the review surfaced went to E and came back as decisions** (2026-09-22):
1. **Both delete confirmations are GONE.** `alerts.md › Best practices`: *"Avoid displaying alerts
   for common, undoable actions, even when they're destructive."* Both existed BECAUSE delete was
   irreversible and this block ended that. "Delete forever" keeps its confirm — the same rule read
   the other way.
2. **"Discard" became "Delete" on captures.** One action had three names (menu, capsule,
   destination); "Recently Deleted" is the anchor because Photos, Notes and Files all use it.

**Two strings written in this block went dead the moment the confirms did** —
`softDeleteReassurance` and `captureDiscardMessage`, caught by grep, removed with a note in their
place. The 30-day rule is still taught by the Tools caption and the empty state, but no longer at
the moment of the delete: E's accepted cost.

**One measured Critical, fixed without touching the held palette.** Delete Forever's `StateRisk`
label was **4.21:1** on `CardSurface` in light, under the 4.5:1 required below 18pt. The row's
button is now `.secondary`; `action-sheets.md` puts destructive prominence on the SHEET, which
the confirm provides.

**Landed, each RED→GREEN→commit with the RED observed first:**
1. `RecentlyDeleted/SoftDelete.swift` — `isLive`, `isPurgeable`, `retention`, `SoftDeleteError`.
2. The stamp on `TaskItem`, `TaskDetail`, `TaskSummary` (snake_case) and `Capture` (camelCase).
3. `Firebase/FirebaseManager+SoftDelete.swift` — `SoftDeletable`, `live(_:)`, `requireLive(_:)`,
   applied to all NINE read paths, with `SoftDeleteCallSiteTests` pinning their COUNTS.

**Three departures from the spec, all deliberate:**

1. **`SoftDelete.isLive` takes no `asOf`.** The spec proposed `isLive(deletedAt:asOf:)`; the clock
   cannot change that answer — an item with a stamp is not live whether or not its 30 days have
   run — and a parameter no test can make matter hides which question is being asked. The clock
   belongs to `isPurgeable` alone.
2. **The hard delete KEEPS its name.** `deleteTask`/`deleteCapture` stay as the irreversible
   operation (for the purge and "Delete forever"); the new `softDeleteTask`/`softDeleteCapture` are
   what the screens will call. Re-pointing an existing method name at different behaviour is the
   silent-semantics trap.
3. **The `firestore.rules` hardening the spec offered is DECLINED**, and the reason is worth
   keeping: `request.resource.data.deleted_at <= request.time` would be checked against the
   CLIENT's clock (the `completedAt` precedent), so a phone running a minute fast could not delete
   anything at all. What the rule prevents is a user pre-dating their own purge window — their own
   documents, their own loss. **Rules verified unchanged against `firestore.rules:55-59`**: the
   owner already has full write on `tasks` and `captures`, so a `deleted_at` field needs no new
   allow rule. E republishes to confirm nothing changed, per house policy.

**Two facts established by reading, for whoever finishes this:**
- **`deleteCapture` does NOT clean up Storage media** (`FirebaseManager+Captures.swift:60` is a
  plain document delete), so photo and voice captures ALREADY orphan their media on delete today.
  Soft delete does not change that and the purge will orphan it exactly as today does.
  Pre-existing, out of scope, named so it is not mistaken for something this block introduced.
- **`ToolsCatalog` and `ToolsCatalogTests` are UNTOUCHED** by the section route, verified by
  reading `ToolsCatalog.swift` — it pins the CARD count only, and Recently Deleted is a section.

**Dependencies:** F-C1. Confirm with the build session whether the capsule ITSELF appears on
delete ("Task deleted · Undo," ahead of the persistent 30-day list) — see Step 0 below.

**Step 0 — ANSWERED by E, 2026-09-19. Do not re-ask:**
1. **The purge runs in the app, on launch.** E: *"The app, when you open it (Recommended)"* — a
   `.task` after first render, clearing anything older than 30 days, with an injectable clock. The
   accepted cost, stated in the question: nothing is purged while the app is never opened. A server
   function stays available as later hardening.
2. **Deleting shows the capsule too.** E: *"Yes, show the capsule too (Recommended)"* — "Task
   deleted · Undo" at the moment of the delete, on top of the 30-day list.

---

### FEATURE: F-C4-TagsRecentlyDeleted — tags in Recently Deleted; hidden links, restore-to-everywhere, merge  [x] COMPLETED

**What E chose, verbatim (round 2):** *"Tasks + Captures + Tags (If A recently deleted tag is
restored, What happens to Items that previously had this tag? … Can the tag be restored to the
original photo capture it was assigned to?)"* — answered same day: *"Tag restore → 'Back on every
item'. While a tag sits in Recently Deleted, its `tag_ids` links stay on the items, hidden (no chip,
no filter). Restore brings it back on every task and capture it had. The links are stripped only at
the 30-day purge. A same-name tag created meanwhile is merged on restore (the Tag Editor's existing
merge)."*

**Today's hard delete, read.** `FirebaseManager+Tags.swift:86-106`, `removeTagEverywhere(_:
replacingWith:)`: batches every `tasks`/`captures` document with the tag id in its `tag_ids` array,
rewrites each array to drop it (or swap in a replacement, for merge), THEN
`batch.deleteDocument(collection(.tags).document(tagId.uuidString))` — delete and unlink happen in
ONE atomic batch today. `TagEditorDetailView.swift:117` (`"Delete Tag"` alert) →
`TagEditorService.delete(tag:)` (`TagEditorService.swift:105`) is the call site;
`FirebaseTagEditorClientAdapter.swift:61` calls `removeTagEverywhere(id, replacingWith: nil)` for a
plain delete and `:51` calls it with a replacement id for MERGE — this merge path is exactly what
"restore, merged into the same-name survivor" must reuse.

**The shape.** Deleting a tag must now do LESS than it does today, not more:
1. Write `deleted_at` on the tag document only. **Do not touch any `tag_ids` array** — every
   task/capture keeps the id, which is what "hidden, not stripped" means.
2. Everywhere a tag chip is rendered or a tag filter is offered, skip tags whose `deleted_at` is
   set — this is a filter at the SAME read layer C3 built (`SoftDelete.isLive`), applied to
   `fetchAllTags()`/`fetchTagsForTask(taskId:)` and wherever the filter menu's tag list is built.
3. **Restore** clears `deleted_at`. Because step 1 never touched `tag_ids`, every item that had the
   tag shows it again with no further writes — "back on every item" is a property of NOT deleting
   the links in the first place, not a restore-time re-attachment.
4. **Merge on restore**: if a tag with the SAME NAME was created while the original sat deleted,
   restoring must not produce two live tags with one name. Reuse `removeTagEverywhere(originalId,
   replacingWith: newTagId)` exactly as today's merge does (`FirebaseTagEditorClientAdapter.swift:51`)
   — except restore's caller already knows both ids and the "replacing" direction is the NEW tag
   winning (since it has live usage the user built during the deletion window), then hard-delete
   the original (it contributed nothing further once merged).
5. **Purge, at 30 days**: THIS is where `removeTagEverywhere(id, replacingWith: nil)`'s existing
   batch (strip `tag_ids` from every referencing item, delete the tag doc) finally runs, on a
   still-deleted tag — the exact call that happens immediately today.

**Tests that must be REVERSED, not deleted:**
- Any `FirebaseManager+Tags.swift`/`FirebaseTagEditorClientAdapter` test asserting `deleteTag`/
  `removeTagEverywhere(_:replacingWith: nil)` strips `tag_ids` SYNCHRONOUSLY on delete (grep
  `removeTagEverywhere` test usages before building — not yet enumerated here) must be reversed:
  a plain delete no longer strips anything; only the 30-day purge does. The merge-path call
  (`replacingWith: someId`) is UNCHANGED behaviour and any test on IT should still pass as-is.
- **None found by grep** for "Recently Deleted" + "tag" together — new surface, RED-first.

**Acceptance criteria:** — all met 2026-09-22; see the block report and
`screenshots/recently-deleted-tags/README.md`. **One finding is RECORDED RATHER THAN FIXED and is
E's call: the Undo capsule is MOUNTED but INVISIBLE in the Tag Editor**, because Settings is a
`.sheet` presented from Today and the capsule lives in `RootBottomOverlay` beneath it. So the
delete E chose a capsule FOR currently shows nothing at the moment it happens — which is the
option E did not choose. Frame `01-deleted-and-the-capsule-offers-undo`; register §A.
- [x] RED first: deleting a tag hides it (no chip, no filter entry) but leaves every item's
      `tag_ids` untouched (assert the array is unchanged, not just that the tag "looks" gone);
      restoring shows the tag again on every item that had it with zero additional writes; a
      same-name tag created during the deletion window causes restore to merge (reusing
      `removeTagEverywhere(_:replacingWith:)`) rather than producing two live tags; the 30-day
      purge strips `tag_ids` and hard-deletes, matching today's immediate-delete behaviour exactly
      but deferred.
- [x] Red-check, restore, count failures, restore code.
- [x] SwiftLint 0, suite green, build green, pasted.
- [x] `screenshots/recently-deleted-tags/` + README: a tag deleted (chip gone from a task that had
      it), the Recently Deleted row showing the tag, restore bringing the chip back, and the merge
      case if it can be driven on the seeded emulator account.
- [x] `apple-design` review owed (§7.6) only if this block changes any VISIBLE surface beyond what
      C3 already built (the same Recently Deleted list, one more row kind) — if it is a pure data-
      layer change riding C3's UI, say so and name C3's review as covering it.
- [x] RM-on device pass: not owed unless a new reduced site is added — expected to be none; say so.
- [x] **`firestore.rules` — verified unchanged** (tags are in the same generic owner-CRUD allow,
      `firestore.rules:57`); no new field-level restriction is implied by this block beyond C3's.

**Dependencies:** F-C3 (the Recently Deleted screen, the `SoftDelete` read-filter helper, and the
purge mechanism Step 0 settles there — tags reuse all three rather than inventing their own).

**Step 0 — ANSWERED by E, 2026-09-19. Do not re-ask:**
1. **Restore ASKS which tag survives.** E: *"Ask which one survives (Recommended)"* — reuse the Tag
   Editor's existing merge choice (`TagEditorPresentation.mergeAlertMessage`) at restore time, so
   the user picks the name and colour that wins. One extra tap, no silent merge.

---

## Arc D · The task composer

Source: `handoff/SESSION-OPENER-adhd-ux-audit-design.md` rounds 6, 7, 7b, 10b; findings §I, §J, §L
(`handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md`); boards `60`, `61`, `64`
(`screenshots/adhd-ux-audit/README.md`); the throwaway probe
`scripts/audit/probes/AuditComposerLayoutProbe.swift.txt` (real tokens/sizes for L3 — never build
against a probe file, it does not compile in the app target).

**Dependency for all three blocks: Arc C ("Nothing lost") lands first** (Decision A, design record
line 573-579: *"C · Nothing lost first ... it holds the audit's data-loss Criticals (CAPT-01,
TASKS-01), and it builds the undo capsule the later arcs reuse"*). Arc C also owns Q4's "Cancel →
Close" rename and the silent-draft-save on swipe-down (CAPT-01). **D does not re-implement either —
it reuses whatever Arc C ships for a composer's leading header control and its dismiss behaviour.**

Today there are TWO task composers with unrelated code: `Tasks/TaskCreateView.swift` (Tasks tab "+"
and `LifeAreaDetail/LifeAreaDetailView.swift:111-117`'s "Add to `<area>`") and
`Capture/QuickCaptureView.swift`'s `kind == .task` path (the capture disc's fan tile,
`RootView.swift:254-263`, and the same-shaped widget door, `RootView+Doors.swift:26-30`). Round 6
merges them into one: **`TaskCreateView` becomes the composer every door opens**, so the split below
is content (D1), then layout (D2), then the Tasks-board fallout (D3).

---

### FEATURE: F-D1-ComposerBothDoors — one composer, both doors, and the settled content  [x] COMPLETED

**What E chose:**
- **Doors → "One composer, both doors"** (round 6). *"The Tasks '+' and the disc → Task open the
  SAME composer."*
- **Content → E, verbatim (round 6):** *"C1 AND THE C3 chips. I want The options 'Not yet', 'Today',
  'Tomorrow', 'Pick a date' - BUT I want the Chips to be tappable, so that the drop-down options that
  are shown in C1 can be accessed."* Reading, confirmed at round 6b: **a title field; four tappable
  "when" chips (Not yet · Today · Tomorrow · Pick a date); and C1's area and time pop-up chips
  (menus, not sheets). The next step — tags, place and notes — live on the task**, not the composer.
- **A new task's date → "No date + an 'Anytime' row"** (round 6): *"New tasks have no date unless
  one is picked."* Retires CAPT-02 (forced `dueDate = startOfDay(now)`) and TASKS-03 (the vanishing
  undated task) — the Anytime row itself is D3.
- **Area "None" default label** — round 10b's rename list ties this composer's own no-selection
  label to "None" directly (not "Decide later"): *"'Decide later' and 'No life area' → 'None', as in
  the round 7b composer (... `Tasks/TaskCreateView.swift:141`)."*
- **Round 7's "36pt look, 44pt reach"** does not apply here — the composer's own chips stay 48pt
  (round 6's own line under round 7's targets section).

**The shape (verify, do not trust):**
- **Strip to the settled content.** `TaskCreateView.swift:49-52` (`areaSection`, `placeSection`,
  `notesSection`, `tagsSection`) currently renders all four plus the due chips. Delete
  `placeSection`, `notesSection`, `tagsSection` and their state (`TaskCreateService.swift:19,23-32`
  — `notes`, `atPlaceId`, `places`, `tagsState`, `selectedTagIds`, `newTagName`, `loadPlaces()`,
  `loadTags()`, `addNewTag()`, `toggleTagSelection()`, and the `attachTags` call in `createTask()`,
  `:127-133`). All three already have a home: `Tasks/TaskDetailFormSections.swift:142` (notes),
  `:164-167` (`TaskAtPlacePicker`, same component), `:179-182` (tags) — the task edits them right
  after creation.
- **This ripples into the protocol, not just the service.** `TaskCreateClientAdapting.swift`
  declares `fetchTags`/`createTag`/`attachTags` alongside `createTask`; grep confirms
  `TaskCreateService.swift` is their ONLY caller in the app. Once tags leave the composer,
  `FirebaseTaskCreateClientAdapter.swift:20-26,52-56`'s matching implementations become
  unreachable in production — the `dead-shared-component-pattern` this project has hit seven times
  before. **The build session must decide prune-or-keep and say which in the report**, not
  discover it as an unexplained coverage drop. Pruning also means reversing (not deleting)
  `FirebaseTaskCreateClientAdapterTests.swift:72-110` (`testAttachTags_*`, `testCreateTag_*`,
  `testFetchTags_*`) and `FakeTaskCreateClientAdapting.swift`'s matching stub methods.
- **Area moves from `ComposerAreaChips` (a chip flow) to a Menu**, matching round 6b's "area and
  time pop-up chips (menus, not sheets)". Reuse the `Menu { Button ... } label: { LabeledContent
  or a bordered leaf }` shape from `Home/LifeAreaPicker.swift:47-71` and
  `Tasks/TaskAtPlacePicker.swift:31-51` (both already default their no-selection row to "None",
  `TaskAtPlacePicker.swift:26-28`) — **do not reuse `ComposerAreaChips`** (`Theme/ComposerChips.swift`
  stays exactly as is; it is still used by `Journal/LogComposerView.swift` and
  `Capture/CaptureInboxSections.swift`).
- **Add a "Time" menu — the effort/duration field, currently missing from `TaskCreateService`
  entirely.** `QuickCaptureView.swift:31` (`taskEffortSeconds = 900`) and
  `QuickCaptureComponents.swift:139-173` (`effortSection`/`effortChip`, values 900/1800/3600s,
  "15 min"/"30 min"/"1 hr") is the existing behaviour to port, as a Menu instead of three chips.
  Wire the WRITE the way `TaskCreateService.createTask()` already handles its own secondary write
  (`TaskCreateService.swift:127-133`, the `attachTags` failure path) — **not** the way
  `QuickCaptureView.saveTask()` does it (`QuickCaptureView.swift:224-249`), which puts the
  follow-up `updateTask` inside the SAME `do` as the create call: a failed secondary write there
  surfaces as `taskErrorMessage` for a task that already exists, and a user-driven retry would
  duplicate it. Instead: create succeeds → `createdTask` is set and `createTask()` returns `true`
  regardless of what happens next; the `updateTask(id:payload:)` call (setting
  `TaskUpdatePayload.focusDurationSeconds`) happens after, and on failure sets `warningMessage`
  ("Task created, but couldn't save its time") the same way the tag-attach failure does today —
  keep `warningMessage`/`taskCreateWarningMessage` (`TaskCreateView.swift:53-58`), it gains this as
  its new (only) source once tags are gone. Do not add the field to
  `NormalizedCreateTaskInput`/`TaskCreateValidation.swift`, which stay untouched. This means
  `TaskCreateView` needs a `taskDetailClient: TaskDetailClientAdapting` alongside its existing
  `client:`. Both current call sites already hold one: `TaskListView.swift:19` and
  `LifeAreaDetail/LifeAreaDetailView.swift:21` — thread it through their existing
  `TaskCreateView(...)` calls (`TaskListView.swift:125-130`,
  `LifeAreaDetailView.swift:111-117`). `preselectedLifeAreaId` (`TaskCreateView.swift:23,29`, which
  seeds `service.lifeAreaId`) must keep seeding the new Area Menu's initial selection, so
  `LifeAreaDetailView.swift:114`'s "Add to `<area>`" door keeps landing pre-filed.
- **Both doors.** `RootView.swift:254-263`'s `.fullScreenCover(item: $composerKind)` presents
  `QuickCaptureView(client: captureClient, kind: kind, ...)` for every kind including `.task`. Branch
  it: `.task` presents `TaskCreateView`, everything else keeps `QuickCaptureView`. `TaskCreateView`
  takes `lifeAreas: [LifeArea]` as a plain array today (`TaskCreateView.swift:15,22`) — the Tasks tab
  and `LifeAreaDetailView` both already hold one, but `RootView` does not. Give `TaskCreateView` the
  same self-fetch pattern `QuickCaptureView` already has for its own areas
  (`QuickCaptureView.swift:141-148`, via a `homeClient: HomeClientAdapting?`) so `RootView` can pass
  `homeClient: homeClient` (already held there, `RootView.swift:258`) with no `lifeAreas` array, while
  the two existing callers keep passing their already-loaded array unchanged. `CaptureFan.slot(for:
  .task)` (`Capture/CaptureFan.swift`) is UNCHANGED — the tile stays; only what it opens changes.
  `AppDeepLink.captureComposer(let kind)` (`RootView+Doors.swift:26-30`) routes through the same
  `composerKind`, so the widget door is fixed by the same branch — no separate change needed there.
  **Named, not decided:** the fan/widget door keeps presenting it as a `.fullScreenCover`, the Tasks
  tab and Area detail keep presenting it as a `.sheet` — same view, two chromes, inherited from
  today and unchanged by this block. Say this in the report so it reads as intentional rather than
  an inconsistency the build session introduced.
- **Scope fence:** the Tasks toolbar "+" itself — its 27×36 hit box growing to 48×48 and its
  missing "New task" VoiceOver label (round 7 / findings §M) — is Arc B's (accessibility), not D's.
  `TaskListView.swift:114-122` is read-only for this arc.
- **Delete the now-dead `.task` path inside `QuickCaptureView`/`QuickCaptureComponents.swift`**,
  since kind is never `.task` at either of its two call sites once the above lands
  (`RootView.swift:255`, now branched away; `CaptureInboxView.swift:118`, which never passed `.task`
  to begin with — its `kind:` defaults to `.note`). Delete: `isTaskKind`
  (`QuickCaptureView.swift:59`), `taskEffortSeconds`/`taskErrorMessage` (`:31,33`), `effortSection`
  (`QuickCaptureComponents.swift:139-150`) and `effortChip` (`:152-173`), `saveTask()`
  (`QuickCaptureView.swift:214-250`) and the `if isTaskKind { return await saveTask() }` branch in
  `save()` (`:202`). **Leave `CaptureComposerCopy`'s `.task` arms alone**
  (`Capture/CaptureFan.swift:86,96,106-107,117`) — `CaptureKind.task` still exists (the fan tile,
  and any capture already stored with kind `.task`), so the switch must stay exhaustive;
  `.title(for: .task)` is still read by `Capture/CaptureInboxSections.swift:18` for an inbox row's
  kind label. This is not new dead code the block introduces, only code that stops being reachable
  through one caller — say so in the report rather than "cleaning" the enum.
- **Regression to flag, not silently absorb:** for one block, the fan/widget door goes from
  QuickCaptureView's 4-control quick composer (title, effort chips, area chips, tags) to
  TaskCreateView's stripped form (title, when-chips, Area menu, Time menu) — still today's vertical
  layout, not yet L3 (that is D2). Screenshot both states so the "no forced date" win is visible
  even though the visual polish is still one block away.

**Tests that must be REVERSED, not deleted:**
- `ADHD LifeOSTests/TaskDueChoiceTests.swift` — unaffected by content (pure due-date mapping, no
  area/time/notes fields). Confirm it stays green; nothing to reverse here.
- `ADHD LifeOSTests/CaptureFanTests.swift:67,69` (`CaptureComposerCopy.ctaLabel/footer(for: .task)`)
  — stays green (pure function, untouched). Note in the report that these now test code no view can
  reach, per the point above; do not delete or "fix" them.
- `ADHD LifeOSUITests/SignedInJourneyUITests.swift:29-60`
  (`testCreateTask_fromTasksTab_appearsInList`) — asserts the title field and submit button
  (`taskCreateTitleField`, `taskCreateSubmitButton`, both must survive unrenamed) and that the
  created task appears under the **Open** filter (`TaskGrouping.groupTasksByLifeArea`, unaffected by
  D3's Anytime fold). Its comment at `:49-51` ("the composer creates the task undated, and the
  default Momentum board deliberately excludes undated tasks") stays TRUE after D1 alone — ANNOTATE
  it rather than reverse it now; D3 is what makes an undated task visible on Momentum too, and that
  block's own report should revisit this comment.
- `LifeAreaPicker.swift:18-19`'s doc comment (*"Preserved verbatim per site: 'None' (Task Create /
  Detail / Capture triage)..."*) is stale today (Task Create currently uses `ComposerAreaChips`, not
  this component) and becomes true again once D1 lands. ANNOTATE, do not treat as a test.
- `ADHD LifeOSTests/TaskCreateServiceTests.swift` — 9 tests exist. **These have real coverage to
  reverse, not none**: `testCreateTask_success_withExistingTagSelected_attachesTag` (`:29`),
  `testCreateTask_success_withNewlyCreatedTag_createsAndAttachesTag` (`:49`),
  `testAddNewTag_matchingExistingTagName_selectsExistingTagInsteadOfCreating` (`:70`),
  `testCreateTask_taskTagsInsertFailure_taskStillConsideredCreated_warningSurfaced` (`:110` — this
  is the exact "secondary write fails, warningMessage, task still counts as created" shape the Time
  write must copy) and `testLoadTags_failure_setsFailedState` (`:143`) all test tag behaviour this
  block deletes from the composer. Reverse or delete each depending on the prune-or-keep call above,
  and write its Time-menu equivalent (e.g.
  `testCreateTask_focusDurationUpdateFailure_taskStillConsideredCreated_warningSurfaced`) either way.
- `ADHD LifeOSTests/FirebaseTaskCreateClientAdapterTests.swift:72-110`
  (`testAttachTags_attachesEveryTagToTheTask`, `testAttachTags_withNoTags_writesNothing`,
  `testCreateTag_returnsTheExistingTagOnANameMatch`, `testFetchTags_returnsTheTagCollection`) and
  `ADHD LifeOSTests/FakeTaskCreateClientAdapting.swift`'s matching stubs — reverse or delete
  together with the protocol decision above; do not leave one side pruned and the other not.
- `ADHD LifeOSTests/TaskCreateAtPlaceTests.swift` — covers `atPlaceId`/`places`, also deleted by
  this block; read it before deciding reverse-vs-delete, same call as the tag tests.
- Grep for `"Decide later"`, `taskCreateLifeAreaPicker`, `taskCreatePlaceholder` turned up nothing
  beyond the files above.

**Acceptance criteria:**
- [x] RED first — **15 of 23 tests failed (66 assertion failures + 1 thrown)** against a compile-only scaffold, so the
      count was real rather than a compile error. The 8 that passed are guards on behaviour that
      already held; the one that passed vacuously (`writesNoTime`) was then proven by mutation.
- [x] The reversed/annotated items updated in place, with the round quoted. **Prune-or-keep → PRUNED**:
      `fetchTags`/`createTag`/`attachTags` left the protocol, adapter, backing store, both fakes and
      both previews; `testTheCreateSeamNoLongerCarriesTags` is the reversal. `TaskCreateAtPlaceTests`
      was SPLIT (its 5 validation/adapter tests stay; the 3 `testService_*` went). The journey's
      undated-task comment at `SignedInJourneyUITests.swift:49-51` stays TRUE after D1 and was left
      for D3, as specced. `LifeAreaPicker`'s "None (Task Create)" doc comment ANNOTATED.
- [x] Red-check: restoring the three files from `9da589f` is a COMPILE failure (3 distinct errors,
      all the pruned seam), reported as such. Three compiling mutation batches instead: disc branch
      reverted + "None"→"Decide later" + Time write deleted → **6 tests / 9 assertions**; the two
      Time-write traps (follow-up inside the create's `do`, a write on a failed create) → **2 / 5**.
- [x] SwiftLint, the full suite and the build all pasted in the block report.
- [x] `screenshots/composer-both-doors/` + README — 12 frames, before/after, light/dark. **Its first
      after-run caught a Critical every other gate missed**: the Area menu's tap target was
      338 × 20.3pt inside a card drawn 48pt tall. Fixed; the harness now asserts ≥ 48pt.
- [x] `apple-design` review — in the block report and `handoff/ADHD-AUDIT-BUILD-LOG.md`.
- [x] RM-on device pass: none owed — no `#available` site, no appear/disappear animation.
- [x] No `#available` site touched → no "Verified paths" line owed.
- [x] No `firestore.rules` change.

**Build notes (2026-09-23):** Time defaults to **15 min, always written** — every board E approved
reads "15 min" and the fan already wrote 900. The named consequence: tasks from the Tasks "+" door
used to be `focusDurationSeconds = nil` and are now 900, which moves them in
`MomentumScoreboard.bestNextMove`'s effort ranking (nil sorted last). The composer branch lives in
`RootView+Doors.swift` (`composer(for:)`) because the branch tipped `RootView.swift` over 400 lines.

**Dependencies:** Arc C lands first (undo capsule + Cancel→Close + draft-save — D1 reuses whatever
header control Arc C ships rather than inventing its own). D2 depends on D1 (same file). D3 is
independent of D1/D2 but reads better after D1 (screenshots of a title-only "Not yet" task will show
it in the Anytime row).

---

### FEATURE: F-Floor18 — raise the minimum iOS from 16 to 18, everywhere  [x] COMPLETED 2026-09-24

**What E chose (2026-09-23, in chat, after `F-D1` merged):** *"iOS 18, before F-D2 — write the spec
block. I need you to also Analyse and look everywhere else that the minimum floor of iOS 16 is within
this repo and correct it - To ENSURE that iOS 16 floor has been ACCURATELY BEEN CORRECTED TO A
MINIMUM Apple iPhone Operating System VERSION OF iOS 18."*

Chosen over iOS 17 because it excludes the SAME hardware (iPhone XS/XR and newer run both; iPhone
8, 8 Plus and X stop at 16 and are lost at ANY floor ≥ 17) and unlocks more. The app is not public,
so no current user is stranded; the cost is future reach alone. **Ordered BEFORE `F-D2`** so that
block never builds the iOS 16.0–16.3 date-popover path its Step 0 question 2 exists to decide.

**This is a global sweep, like arcs A and B: never run it beside another block.** Every inventory
below was MEASURED on 2026-09-23 against `main @ d85b18a`, not estimated. Re-run the greps before
starting and reconcile any difference; the tree may have moved.

#### What the compiler proved (2026-09-23, a throwaway worktree built at BOTH floors)

- **An 18.0 floor builds GREEN** (`** TEST BUILD SUCCEEDED **`, all four targets).
- **It adds exactly 35 warnings, all one kind:** `'onChange(of:perform:)' was deprecated in iOS
  17.0`, in 23 app-target files (none in the widget or the tests). Seven are in `Home/HomeView.swift`,
  four in `RootView.swift` and three in `TabNavigation.swift`; the rest are one or two each.
- **It removes 5 warnings:** the test targets' `ld: building for iOS-simulator-16.0, but linking
  with dylib … XCTest … which was built for newer version 17.0`.
- **The ~1,790 Swift-concurrency warnings are PRE-EXISTING** and identical at both floors. They are
  NOT this block's and must not be "fixed" in it.
- **THE TRAP: Swift does NOT warn about a redundant `#available` check against the deployment
  target.** It only flags a check made redundant by an enclosing `@available`. So the compiler
  cannot find a missed gate. The inventory below is the only list, and a tree-walking test (below)
  is the only thing that keeps it complete afterwards.

#### 1. The build settings — six values, all in `ADHD LifeOS.xcodeproj/project.pbxproj`

| where | today | after |
|---|---|---|
| Project level, Debug + Release (the APP and the UI tests inherit it; neither sets its own) | 16.0 | **18.0** |
| `ADHD LifeOSTests`, Debug + Release | 16.0 | **18.0** |
| `FocusTimerWidgetExtension`, Debug + Release | 16.1 | **18.0** |

**One number from now on.** "The deployment target is not one number" (CLAUDE.md, Architecture
notes) stops being true, and saying so is part of this block. Keep
`CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE`: it is what keeps the remaining iOS 26 gates
load-bearing.

#### 2. The Swift gates — every one below 18 goes, and only those

Measured with `grep -rnE "(#available|#unavailable|@available)\(iOS(ApplicationExtension)? 1[4-7]"`
over `ADHD LifeOS/` and `FocusTimerWidget/`: **~95 annotations in 43 non-test files.**

- **Trivially-true gates (delete the check, keep the body):** `ADHD_LifeOSApp.swift:74` (iOS 14),
  `Focus/NotificationCenterFocusNudgeAdapter.swift:45` (15), `Tasks/TaskSearchSurface.swift:226` (16.0).
- **ActivityKit, 16.1 / 16.2** — `@available(iOS 16.1, *)` on the attributes, components, presenters
  and Live Activity views (`FocusActivityAttributes`, `FocusActivityComponents`,
  `RoutineActivityAttributes`, `RoutineLiveActivity`, `RoutineActivityState`,
  `RoutineActivityKitPresenter`, `FocusActivityKitMirror`, `FocusSprintIntents`), and the
  `#available(iOS 16.2, *)` content/staleDate splits in `FocusActivityKitMirror` (3),
  `RoutineActivityKitPresenter` (3), `FocusSprintIntents` (1) and `FocusTimerWidgetLiveActivity:98`.
  **Delete the pre-16.2 branches outright** (the old `ActivityContent`-less API), not only the check.
  `FocusActivityKitMirror.swift:167`'s `guard #available(iOS 16.1, *) else {…}` and `RootView+Doors.swift:69`
  lose their inert fallbacks; read the memory note "the inert one keeps the type total" and decide
  whether the inert presenter type is still needed by TESTS (it may be — say which).
- **App Intents, 16.4:** `Shortcuts/LifeOSAppIntents.swift:104` (`AppShortcutsProvider`).
- **iOS 17, the "Degraded" sites** (a modern and a floor rendering of the same thing; keep the
  modern branch, delete the `else`):
  `Theme/Haptics.swift:96,119` (**keep `.haptic(_:trigger:)` as the house API** — §3 prescribes it
  and ~every interactive view calls it — its body becomes `.sensoryFeedback` alone and the UIKit
  performer goes), `Capture/VoiceCaptureRecorder.swift:74`, `Settings/SettingsPreferenceSections.swift:220`,
  `Focus/FocusActivityKitMirror.swift:180`, `FocusTimerWidget/FocusStatsWidget.swift:282`,
  `FocusTimerWidget/FocusTimerWidgetLiveActivity.swift:70,153,171` (the interactive sprint buttons,
  `FocusSprintControls`, become unconditional) and `FocusSprintIntents.swift:41,57`.
- **iOS 17, the "Absent" feature — Places and the routine screen — becomes universal.** Delete every
  `@available(iOS 17.0, *)` in `Places/` (54 across 21 files), `Tools/ToolsRoutinesSection.swift`
  (4), `Tools/ToolsCatalog.swift`, `Tools/ToolsView.swift` (gates at `:81,102,204`) and
  `RootView+Doors.swift:131,163`. **Delete the flags that announced the absence:**
  `ToolsView.placesSupported`, `ToolsCatalog.available(placesSupported:)`'s parameter (the catalog
  just lists Places), and `PlaceTriggerEventHandler`'s injected `routineScreenAvailable` (`:63`).
  Rewrite, don't just delete, the comments that explain the gate
  (`ToolsView.swift:77`, `ToolsCatalog.swift:67`, `ToolsRoutinesSection.swift:18`,
  `RecentlyDeleted/ToolsRecentlyDeletedSection.swift:12`).
- **The iOS 26 gates STAY — 3 sites** (`Focus/FocusCompletionCelebration.swift` ×2,
  `TabNavigation.swift`, plus the `@available(iOS 26.0, *)` types in `FocusCompletionCelebration`
  and `TabRootLargeTitleReTap`). Their `else` branches now mean **iOS 18–25**, not 16–25. §7.1's
  two-branch rule still governs them in full.
- **The 35 deprecated `onChange` spellings** (the compiler's list): move each to the two-parameter
  form (`{ _, newValue in … }`) or zero-parameter form. **Behaviour must not change**: the old form
  passes the NEW value, so `{ foo($0) }` becomes `{ _, new in foo(new) }`, never `{ old, _ in }`.

#### 3. The tests — reverse deliberately, never delete a guard to make it pass

- **Call-site tests that PIN the floor branch** (§7.4: "a test that asserts only the modern branch
  stays green on a build that dropped the floor"). The floor they pinned is the thing this block
  removes, so each is REVERSED to pin its absence, with E's words quoted:
  `ModernAPIPolicyCallSiteTests` (the `.haptic` 17-gate + `else` + UIKit performer),
  `ToolsPageCallSiteTests`, `ToolsRecentlyDeletedCallSiteTests`, `ToolsCatalogTests` (its
  `placesSupported: false` cases), `RoutineActivityCallSiteTests`, `RoutineHandlerHarness`,
  `PlaceRoutineHandlerGuardTests` and `RoutineRecordSiteTests` (the `routineScreenAvailable: false`
  injection), plus the `@available(iOS 16.1/17.0, *)` annotations on
  `FocusActivityCheckpointMarkTests`, `FocusActivityContentStateTests`, `RoutineActivityTests`,
  `FocusSprintIntentsTests` and `ToolsCatalogTests`.
- **Call-site tests that pin an exact one-parameter `onChange` spelling** — they break the moment
  the deprecation is fixed, and must be updated in the SAME commit:
  `AppSearchCallSiteTests:79`, `CelebrationCaptureFanCallSiteTests:20`,
  `ConfirmCelebrationCallSiteTests:64`, `CelebrationMilestoneCallSiteTests:125,129`,
  `JournalHeaderControlsTests:99`.
- **`FocusCelebrationModernPathCallSiteTests`** keeps every assertion (the 26 gate stays); only its
  comments' "iOS 16–25" become "iOS 18–25".
- **NEW, and the reason this block can claim "everywhere":**
  1. `DeploymentFloorTests.testEveryTargetIsAtTheIOS18Floor` — read `project.pbxproj` and assert
     every `IPHONEOS_DEPLOYMENT_TARGET` is `18.0` (and that there are exactly six), so a target
     added later at the Xcode default cannot slip under.
  2. `DeploymentFloorTests.testNoAvailabilityCheckBelowTheFloor` — walk `ADHD LifeOS/` and
     `FocusTimerWidget/` (comment lines stripped, the `*CallSiteTests` way) and fail on ANY
     `#available`/`#unavailable`/`@available` naming iOS 1–17. This is the guard the compiler does
     not provide. **Red-check both** by planting one `#available(iOS 17.0, *)` and one 16.0 target.

#### 4. The documents — correct what GOVERNS; leave what RECORDS

**Governing (rewrite in this block, in the same PR as the code):**
- **`CLAUDE.md`**: Architecture notes' first bullet (one number, 18.0); §7's title and preamble ("The
  iOS 16 floor…"); §7.1 ("always ship a complete iOS 16 branch" → the branch below the gate is the
  18 path; the Absent/`placesSupported` example goes, since no feature is absent any more); §7.3
  (the one-runtime claim is already stale — this machine has 26.5 AND 27.0 — and the "16 path"
  sample line becomes an 18 one); §7.4's "16 path" wording; §7.5's precedence line ("the **iOS 16.0
  deployment target**") and both skill-conflict bullets that say "this project is iOS 16.0" /
  "a complete 16 path"; the `OS=26.5` line's "floor-side runtime" comment. **Every other "16" in
  that file is a SPACING token (16pt), not the floor — do not touch those.**
- **`TODO-CLAUDE-CODE.md`, OPEN blocks only:** `F-D2` (delete Step 0 question 2 and every 16.0–16.3
  / 16.4 path; its Liquid Glass gate's floor branch is now the 18 path), `F-F2` (the 17 gate and the
  "16.1–16.x floor" line go — the Lock Screen button is universal), `F-F5` (EventKit becomes
  `requestFullAccessToEvents` alone, the `requestAccess(to:)` branch and the legacy
  `NSCalendarsUsageDescription` key are no longer needed), `F-A3` (its "inside the existing
  `@available(iOS 17.0, *)` gates" — they will be gone), `F-A4` ("target the 16.0 floor"), `F-G1`,
  `F-G3` ("Places is already/stays `@available(iOS 17.0, *)`"), `F-G2`, `F-G4`, `F-G5` ("16.0 floor
  untouched"). **Completed blocks are records: do not edit them.**
- **`handoff/OPEN-ITEMS-REGISTER.md`**, live sections only: §A's "install an older simulator
  runtime" row becomes **"install the iOS 18 simulator runtime"** (the one runtime that would let
  the floor path RUN, not only compile); §B's modern-API inventory ("free at 16.0" / "needs 17+")
  re-sorted against 18; a §D launch-note row naming the excluded hardware.
- **Memory** (`~/.claude/projects/…/memory/`): `firebase-backend-state` ("app 16.0, widget 16.1"),
  `ios27-arc` ("The 16.0 deployment target does NOT move"), `tools-tab-and-custom-bar` ("Tools must
  handle Places being absent on 16"), `place-actions-arc` (the 16.4 provider), `location-services-spec`
  ("project target STAYS 16.0"), `modern-ios-pilot`, and a NEW `ios-18-floor` memory with E's words.
- **The live opener** for `F-D2`.

**Records (do NOT rewrite — they say what was true when written):** `TODO-ARCHIVE.md`,
`handoff/archive/`, every `SESSION-OPENER-*` (permanent design records), every
`screenshots/*/README.md` ("16 path: compile-only" was a true claim that day), completed TODO
blocks, and dated register history. CLAUDE.md's "Keep everything, forever" is the rule. Where a
record states a rule that is now false, the governing doc above says so; the record is not edited.

**Nothing outside the app moves:** the capture Shortcut, `scripts/`, `functions/`, `firebase.json`
and `.swiftlint.yml` hold no floor reference (checked).

#### 5. What E sees, and what is owed

- **On E's phone (iOS 27) nothing looks different** — every branch E has ever seen is the one that
  stays. So: **no `apple-design` review owed** (no visible change), **no RM-on pass owed** (no
  reduced site changes; the 26 gates' reduced paths are untouched), and say both in the report.
- **A device smoke launch IS owed**, because the widget, the Live Activities and the App Intents all
  change targets: install, open the app, start and end a sprint (Live Activity), add the widget.
  Install BEFORE asking.
- **"Verified paths" line, required** — every remaining gate is iOS 26, so it reads: *"26 path: run
  on sim 27.0 + E's phone. 18–25 path: run on 26.5 by injection; OS-level behaviour on 18
  COMPILE-ONLY unless the iOS 18 runtime is installed."* Never write "works on iOS 18" without it.
- **App Store consequence, for the register's §D:** iPhone 8, 8 Plus and X can no longer install.

**Acceptance criteria:**
- [x] RED first: `DeploymentFloorTests` (both tests) failing on today's tree, counted.
- [x] Six `IPHONEOS_DEPLOYMENT_TARGET = 18.0` and no other value; the built app's `Info.plist`
      shows `MinimumOSVersion 18.0` for the app AND the widget (`plutil -p`, pasted).
- [x] Zero availability annotations below iOS 18 in `ADHD LifeOS/` and `FocusTimerWidget/` (the new
      test, plus the grep pasted); the three iOS 26 gates intact with their `else` branches.
- [x] Zero `onChange` deprecation warnings: `grep -c "deprecated in iOS 17" <build log>` = 0, pasted.
- [x] `placesSupported`, `available(placesSupported:)` and `routineScreenAvailable` gone; Places and
      routines reachable with no flag.
- [x] Every test in §3 reversed or updated in place with the reason quoted — none deleted to pass.
- [x] Red-check: plant a 17 gate and a 16.0 target → count the failures → restore with
      `git checkout --`.
- [x] SwiftLint, the full suite, the build — and the widget and UI-test targets BUILD — all pasted.
- [x] Every governing document in §4 corrected; every record untouched (`git diff --stat` over
      `handoff/archive/`, `screenshots/`, `TODO-ARCHIVE.md` and `SESSION-OPENER-*` is EMPTY — paste it).
- [x] A final repo-wide grep for `iOS 16|16\.0 floor|16 path|16\.1` over the GOVERNING set returns
      only spacing tokens and dated history, each explained in the report.
- [x] Device smoke launch on E's phone (installed first); "Verified paths" line; no `firestore.rules`
      change. *(Installed wirelessly and LAUNCHED 2026-09-24 at `442db4e`, `MinimumOSVersion 18.0` app + widget; the sprint / Live Activity / widget steps are E's — see register edition 80.)*

**Dependencies:** none before it; **`F-D2` waits for it.** Build it in a fresh session from the
live opener.

---

### FEATURE: F-D2-ComposerKeyboardLayout — L3 rides the keyboard; AX3 falls back; the Date segment  [ ] NOT STARTED

> **`F-Floor18` has LANDED (2026-09-24): the minimum is iOS 18.** This spec's floor lines were
> rewritten in place by that block. Its former Step 0 question 2 (a popover floor path for
> 16.0–16.3) is gone — `presentationCompactAdaptation` (16.4) is below the floor — so **Step 0 is
> ONE question**, and the `#available` site here is the iOS 26 Liquid Glass container alone.

**What E chose:**
- **Layout → "L3 · Rides on the keyboard"** (Recommended, round 7b). *"The title owns the page.
  Every choice and Add sit in one bar just above the keyboard: the four 'when' segments on top; Area
  | Time | Add below, with Add trailing."* Measured: **with the keyboard up the bar spans
  406–518pt of the 874pt screen** (L1 sat at 252–364pt, L2 at 282–440pt).
- **The Date segment → "Text, then the date"** (Recommended, round 7b). *"It reads 'Date' in
  LabelPrimary like its neighbours, with no calendar glyph. Once a date is picked, Date becomes the
  selected segment and shows that date ('Fri 26')."* This closes all three `apple-design` findings on
  it (findings §L): a glyph+text mix (`segmented-controls.md › Content`), an action segment inside a
  selection control, and accent meaning both "selected" and "opens a picker"
  (`color.md › Best practices`).
- **At AX3, carried in the option E chose:** the bar cannot share the screen with the keyboard —
  L3 falls back to L1's stacked form (choices scroll under the title, Add stays pinned).
- **Also carried in the option:** opening Area, Time or the date picker must NOT dismiss the
  keyboard, "or the bar drops 336pt and jumps back (research §3.2). A test pins it." Findings §L
  calls this **unverified**: *"SwiftUI `Menu`'s effect on the first responder was not checked here."*
- **Platform notes (findings §L, quoted as build instructions):** the bar rides the keyboard through
  `safeAreaInset(edge: .bottom)`, "which is the floor" (18); `ToolbarItemPlacement.keyboard` "is a
  single row, too small for L3's two"; the container "takes Liquid Glass behind `#available`" on 26+
  and a standard material below (the 18–25 path); the when-choice picker "is a popover or menu,
  never a sheet (Q4)", through `presentationCompactAdaptation(.popover)`, which is below the 18
  floor and needs no gate (the findings' "floor path on 16.0–16.3" predates `F-Floor18`).

**The shape (verify, do not trust):**
- **The probe is the exact geometry and tokens to build from** (never import it —
  `scripts/audit/probes/AuditComposerLayoutProbe.swift.txt` is a `.txt` file outside the target on
  purpose). Its `toolbar` case (`:247-271`) is L3: a bare `Text` title (not `ComposerTextBox` — L3's
  title is `.title2.weight(.semibold)`, `:131-134`, boxless), then a bottom `VStack` of
  `WhenSegments()` (`:57-93`, one bordered container, 4pt internal gaps, `ChoiceChipButtonStyle`-like
  selection) over `Area | Time | Add` (`:260-264`, 8pt inset for the compact menus, `compact: true`
  so "15 min" doesn't wrap — noted in findings §L and the round 7b log as a real bug already found
  and fixed once).
- **Keep the `NavigationStack` and its toolbar — do not draw the probe's custom `Header()`
  (`:151-168`).** The probe's header (a hand-drawn 48×48 "Close" capsule, no nav bar) is geometry
  for the boards, not a component to import; `TaskCreateView` today gets its title and leading
  control from `.toolbar` (`:70-79`, `.cancellationAction` + `.principal`). Round 7's "All to 48×48
  ... in their standard places" reads as the toolbar control growing to 48×48 in place, not a
  redraw. The leading control's BEHAVIOUR and LABEL are Arc C's (Close, not Cancel; draft-save on
  dismiss) — D2 only makes it 48×48 in whatever chrome Arc C leaves it in. Say which you built,
  since the probe and the current code disagree and only one can ship.
- **Build it as `TaskCreateView.swift`'s existing `.safeAreaInset(edge: .bottom) { footerBar }`
  (`:69`), replaced.** The current `footerBar` (`:250-275`) is the file this becomes; the current
  due-chip row (`dueSection`, `:90-112`) moves INTO the bar as the top half of the new one. This is a
  same-file redesign, not a new screen.
- **File-length budget:** `TaskCreateView.swift` is 304 lines today. Adding the keyboard bar, the
  AX3 fallback and two Menu leaves will clear the 400-line bar comfortably on its own — split the
  bar into its own file (e.g. `Tasks/TaskComposerKeyboardBar.swift`) rather than letting
  `TaskCreateView.swift` grow past it.
- **`.keyboardDismissal()` is already applied by both callers** (`TaskListView.swift:131`,
  `LifeAreaDetailView.swift:118`) and puts a "Done" button in a `.keyboard`-placement toolbar row —
  a row the probe never drew, and one that will sit UNDER this new bar (SwiftUI keyboard-placement
  toolbars render above the software keyboard, same as `safeAreaInset(edge: .bottom)` does, so the
  two stack). **Verify at build time whether that row moves the bar off E's approved 406–518pt** —
  render it for real before claiming the approved numbers, and say in the report whether the Done
  row survives.
- **The Liquid Glass gate is a new `#available(iOS 26, *)` site** — there is no existing
  `.glassEffect`/`GlassEffectContainer` call anywhere in the app target to copy from (checked; the
  only hit is a comment, `Celebrations/CelebrationFrame.swift:22`). Follow §7.1: the 26+ branch is
  `.glassEffect(...)` on the bar's container, the 18–25 branch is `Material.bar`/`.ultraThinMaterial`
  (the same surface `Theme/ComposerChips.swift:190-197`'s `ComposerFooterSurface` already uses for
  every other composer footer) — both branches carry the same information (a bar that reads as
  raised above the page).
- **Reduce Motion:** if the when-segments' selection just recolours in place (no `matchedGeometry`
  slide), this block adds no reduced site — say so and skip the RM-on pass. If a sliding selection
  indicator is added instead, that IS an "appears/moves" site under §7.2 and both the fade and the
  RM-on device pass (§7.3) become owed; decide before building, don't discover it after.
- **The Date popover has ONE path.** `presentationCompactAdaptation(.popover)` (16.4) is below
  the 18 floor, so the popover never adapts to a sheet and Q4 ("Maximum 1 sheet deep") is met on
  every OS without a decision. (Before `F-Floor18` this was a Step 0 question about 16.0–16.3.)

**Step 0 — ask E (ONE question; findings §L's second was voided by `F-Floor18`):**

**1. Does the Date popover offer a time, or only a day?**
Today's `.custom` picker is `[.date, .hourAndMinute]` (`TaskCreateView.swift:99-106`), and
`TaskDueChoice.choice(for:)` (`TaskDueChoice.swift:48-54`) already treats anything other than exact
midnight as `.custom`. E's chosen segment shows a DAY ("Fri 26"), with no visible time. Options:
1. **(Recommended) Date-only** — `displayedComponents: [.date]`. Nothing is lost: a task's precise
   due time can already be set afterward on the detail screen
   (`Tasks/TaskDetailFormSections.swift:135-138`, same `[.date, .hourAndMinute]` picker). Keeps the
   segment's "Fri 26" honest — there is no hidden time to contradict it.
2. Keep `[.date, .hourAndMinute]` in the composer too, and change the segment to show the time as
   well once one is picked ("Fri 26, 3pm") — more information, but crowds the segment and drifts
   from "text, then the date" as chosen.
3. Keep `[.date, .hourAndMinute]` but the segment still shows only the day — silently drops
   information the user just entered, which is worse than not offering it.
If E does not answer before the build session, build option 1 and say so in the report rather than
guessing at option 2 or 3's exact wording.

*(The former question 2 — the Date popover on iOS 16.0–16.3 without `presentationCompactAdaptation`
— was VOIDED by `F-Floor18` and removed; nothing below the floor exists to decide.)*

**Tests that must be REVERSED, not deleted:**
- `ADHD LifeOSTests/TaskDueChoiceTests.swift:69-74` (`testTitles_areTheChipCopy`) —
  `XCTAssertEqual(TaskDueChoice.custom.title, "Pick a date")` must become `"Date"`, per round 7b's
  "reads 'Date' ... with no calendar glyph." Reverse with a comment citing round 7b.
- `TaskDueChoice.swift:11-13`'s doc comment ("`custom` keeps whatever is already chosen ... a
  precise moment is what `custom`'s picker is for") — ANNOTATE if Step 0 resolves to date-only: a
  "precise moment" is no longer what the composer's picker offers; the detail screen is.
- Grep for `"Pick a date"` and `taskCreateDueDatePicker` elsewhere in
  `ADHD LifeOSTests`/`ADHD LifeOSUITests`: **none found** beyond the file above.

**Acceptance criteria:**
- [ ] RED first: a pure test that `TaskDueChoice.custom.title == "Date"`; a call-site test (the
      `*CallSiteTests` string-read pattern, §7.4) asserting the `if #available(iOS 26, *) { ... }
      else { ... }` pair exists around the bar's material; a test/assertion (unit or UI) that the
      title field keeps focus (or the bar keeps its keyboard-up height) while the Area/Time menu or
      the date popover is open. Count RED failures.
- [ ] `TaskDueChoiceTests.swift` reversed in place, round 7b quoted.
- [ ] Red-check: restore the pre-block `TaskCreateView.swift`, count failures, restore forward.
- [ ] SwiftLint, the full suite and the build all pasted.
- [ ] `screenshots/composer-l3-layout/` + README: keyboard up/down, light/dark, AX3 fallback, and
      the Date segment before/after a pick — matching board `64`'s naming
      (`<layout>-<up|down>-<L|D|A>.jpg` convention from `round-7b-composer-layouts/`).
- [ ] **`apple-design` review owed** (§7.6) — re-run over the SHIPPED view (not the probe); confirm
      the three findings §L cites against the Date segment (glyph+text mix, action-inside-selection,
      dual-meaning accent) are actually closed, and check the AX3 fallback and the 12pt-bezel-gap
      note (§L "Low", accepted as-is per the record).
- [ ] **RM-on device pass:** owed only if a sliding selection indicator was added — state which,
      per the shape section above.
- [ ] **"Verified paths" line, required** (an `#available` site is touched):
      `26 path (Liquid Glass container): run on sim + [E's phone / sim-only, say which].`
      `18–25 path (standard material): code run on 26.5 by injection; OS-level behaviour
      COMPILE-ONLY — no 18 runtime installed.`
- [ ] **Device check owed** — the record calls the keyboard-stays-up behaviour "also a phone check";
      confirm on E's phone that opening Area, Time and the date popover does not drop the keyboard.
- [ ] No `firestore.rules` change.

**Dependencies:** D1 (same file, same composer). Arc C for the leading header control.

---

### FEATURE: F-D3-TasksAnytimeRow — the "Anytime · N" row on the Momentum board  [ ] NOT STARTED

**What E chose:**
- Round 6: *"The Tasks board gains one collapsed 'Anytime · N' row at the bottom: the tail stays
  folded, but a new task is visible where it was added."*
- Round 8b (settling scope, so this block does not widen b11's exclusion by accident): *"Undated
  tasks already live in Anytime, and future-dated tasks are untouched."* **Anytime is the undated
  bucket only** — tasks due beyond tomorrow stay off the Momentum board entirely (E's b11 call,
  `MomentumTaskBuckets.swift:8-9`, unchanged).

**The shape (verify, do not trust):**
- `MomentumTaskBuckets.swift:81-102` (`bucket(for:)`), line 94: `guard let due = task.dueDate else {
  return nil }` — "Undated tasks belong to the Open filter, not the board." Change this one guard to
  `return .anytime` instead of `nil`. Add `case anytime` to the `Bucket` enum (`:16-19`) with
  `title: "Anytime"` (`:21-27`) — placed LAST in the enum so `Bucket.allCases` (`:43`) naturally
  renders it at the bottom, after Closed today. Leave the beyond-tomorrow branch (`:101`,
  `return nil`) untouched — that is the tail that stays folded, per the round 8b quote above.
- `headerToneAssetName(customId:)` (`:72-79`): add no case for `"momentum-anytime"` — it falls
  through to `default: return nil`, the plain secondary voice, matching round 9's "quiet, no colour"
  direction for anything that isn't due-now/tomorrow/closed.
- **Render it collapsed by default, using the existing house pattern.**
  `Theme/CollapsibleSectionHeader.swift` is already shared by Home's life-areas fold
  (`Home/HomeLifeAreasSections.swift:84-110`, `@AppStorage("home.lifeAreasCollapsed")`,
  `HomeView.swift:70`) and Journal's day sections. `TaskListView.swift:180-202` (`taskList(groups:)`)
  currently renders every group with a plain `Text(group.lifeAreaName).pinnedSectionHeader()`
  header (`:191-193`); special-case `group.customId == "momentum-anytime"` to use
  `CollapsibleSectionHeader` instead, with `summary: nil` (the title "Anytime · N" already carries
  the count, per `MomentumTaskBuckets`'s `"\(bucket.title) · \(members.count)"` format,
  `:47`), and gate `rowCard(for: group)` behind the expanded state. Add
  `@AppStorage("tasks.anytimeCollapsed") private var anytimeCollapsed = true` to
  `TaskListView` — default TRUE (collapsed), unlike Home's fold which defaults expanded, because
  round 6's own words are "the tail stays folded."
- `rowCard(for:)`'s `showsSprintStart` (`TaskListView.swift:207`, `group.customId ==
  "momentum-dueToday"`) already keys off `customId`, so Anytime rows correctly get no ▶
  sprint-launcher by construction — no change needed there, just confirm it in a test.
- This reuses the exact shape round 8b's "Set aside · N" row (Arc G, Fresh Start) will need later —
  D3 should land first so Arc G can copy its pattern rather than invent a second one.

**Tests that must be REVERSED, not deleted:**
- `MomentumTaskBucketsTests.swift:56-65` (`testGroup_excludesLaterAndUndatedTasks`) — currently
  asserts `groups.map(\.lifeAreaName) == ["Due today · 1"]` for `[task("Undated"), task("Later",
  dueDaysFromNow: 3), task("Today", dueDaysFromNow: 0)]`. Reverse to assert **both** `"Due today ·
  1"` and `"Anytime · 1"` are present, **and that "Later" still produces nothing** — the point of
  the test is now "undated is visible, beyond-tomorrow is not," not "both are excluded." Rename it
  (e.g. `testGroup_undatedGoesToAnytime_laterStaysExcluded`) and keep the b11 citation.
- `MomentumTaskBucketsTests.swift:9-12` (file header) and `MomentumTaskBuckets.swift:7-9` (file
  header) both say "the long tail (later / undated) is deliberately NOT here" — ANNOTATE both:
  undated no longer belongs to that sentence; later still does.
- `testGroup_bucketsByDueness_inFixedOrder` (`:40-54`) and `testGroup_bucketIdsAreDistinct`
  (`:112-124`) stay green as written but should each GAIN an undated task in their fixture so the
  fourth bucket's ordering (last) and distinct id are pinned by a passing assertion, not merely
  untested.
- `SignedInJourneyUITests.swift:49-51`'s comment (already flagged in D1) — this is the block where
  it stops being simply true. Re-read it here: the created undated task now ALSO appears, folded,
  under Momentum's new Anytime row — the test still finds it via the Open filter (unaffected,
  `TaskGrouping.groupTasksByLifeArea`), so the assertions themselves do not need to change, only the
  comment.
- Grep for `"Anytime"`, `momentum-anytime`, `anytimeCollapsed` in
  `ADHD LifeOSTests`/`ADHD LifeOSUITests`: **none found** — this is new ground, not existing coverage
  to reverse beyond the two files above.

**Acceptance criteria:**
- [ ] RED first: `testGroup_undatedGoesToAnytime_laterStaysExcluded` written to fail against
      today's code (asserts `"Anytime · 1"` present); a view-level or snapshot test that the Anytime
      section starts collapsed and that `showsSprintStart` is false for it. Count RED failures.
- [ ] The reversed/annotated tests above updated in place, round 6 and round 8b quoted.
- [ ] Red-check: restore `MomentumTaskBuckets.swift`/`TaskListView.swift` from the pre-block commit,
      count failures, restore forward.
- [ ] SwiftLint, the full suite and the build all pasted.
- [ ] `screenshots/tasks-anytime-row/` + README: Momentum board with the row collapsed (showing only
      the "Anytime · N" header), expanded, and a freshly-added undated task appearing in it —
      light/dark. This is exactly the kind of "a live rule applied to real data" a unit test cannot
      show (CLAUDE.md, "Visual evidence").
- [ ] **`apple-design` review owed** (§7.6) — a new section header row appears on a screen already
      reviewed multiple times in this audit (findings §I, §G). Route through `hig-lookup.md` (§7.6
      step 2) for a disclosure/collapsible header rather than guessing a page name, and confirm the
      chevron direction matches `Theme/CollapsibleSectionHeader.swift:20-22`'s stated convention
      (points AT the hidden content, not at the gesture).
- [ ] **RM-on device pass: none owed.** `CollapsibleSectionHeader` carries no motion of its own
      (a static chevron glyph, no slide/fade) — confirm this stays true rather than assuming it.
- [ ] No `#available` site touched → no "Verified paths" line owed.
- [ ] No `firestore.rules` change (bucketing is client-side only).

**Dependencies:** None on D1/D2 technically (pure `MomentumTaskBuckets` + `TaskListView` change),
but land it after D1 if practical — D1's screenshots are more convincing with an Anytime row to put
the new title-only task into. Arc G ("Set aside · N", round 8b) depends on this block's shape.

---

## Arc E · Today (the Home tab) — build specs

Source: `handoff/SESSION-OPENER-adhd-ux-audit-design.md` Rounds 3, 5a, 5b, 8, 8b; findings §G
(HOME-01…12) and §K (the ideas), `handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md`. Boards `55`, `56`,
`59`; frames `screenshots/adhd-ux-audit/round-5-hero/`; the saved probe
`scripts/audit/probes/AuditHeroRenderProbe.swift.txt`.

**Build order: E1 → E2 → E3 → E4 → E5.** E3 is load-bearing; E1/E2 are its inputs, E4/E5 build on
what E3 leaves behind. **E3 also depends on arc C** (the shared undo capsule).

---

### FEATURE: F-E1-WeeklyChain — the weekly active-day chain, goals off until set, and the gain-framed Close button  [ ] NOT STARTED

**What E chose.** Round 3, *"Streaks → 'Weekly chain + auto repair.'"*: *"A week 'counts' once the
user is active on N days they choose. One missed week a month is repaired automatically. The other
two streaks go: the closing streak '6 days/Best is 6' and the focus '2 Day Streak'. The nudge 'best
2' goes too."* Round 5b: *"Weekly streak N → '3 days' (the default; changeable in Settings)"* and
*"What counts as an active day → 'Anything that moves life on'. Closing a task, finishing a sprint,
writing a journal line, or sorting a capture."* Round 3, *"Preset goals → 'Off until you set one.'
No ring and no percentage until the user chooses a goal in Settings. This covers the daily close
goal (5) and the daily focus goal (30m)."* Round 8b: *"'Close it — makes today count'"* — shown
only while today has no activity yet, otherwise plain "Close it", *"the gamification principle
framed as a gain toward the weekly chain, never a loss."* Round 8 follow-up: *"the game layer
already chosen IS the game layer... Every screen may show what was done; none tallies what was
missed."*

**The shape (verify, do not trust).**
- `Home/MomentumScoreboard.swift:23-41` `streak(tasks:)`, `:220-242` `bestStreak`, `:246-253`
  `streakLine` — task-closure-only, daily, no repair. Round 8b sends these three lines "with the
  scoreboard" (E3 deletes it); this block replaces the underlying model.
- `Home/MomentumPreferences.swift:30,44-51` — `dailyGoal: Int` (default 5) and
  `focusDailyGoalMinutes: Int` (default 30) are always-on; per HOME-10 nobody ever chose either.
  Make both `Int?` (`nil` = not set); `normalized()` and the hand-written `Codable` (`:84-158`)
  pass `nil` through. **On decode, an existing install's stored 5/30 becomes `nil` too** — nobody
  chose those defaults, so there is nothing to preserve; say this in the report, it is not a Step
  0. Add `weeklyActiveDayGoal: Int` (default 3, range 1...7). `showStreaks` stays as the field/
  toggle name, relabelled in Settings to gate the CHAIN's display rather than a daily streak —
  stated default, not a new switch.
- **`Home/DailyGoalTracker.swift:34` `DailyGoalRules.goal: Int`, and `HomeView+DailyGoal.swift:61`
  `observeDailyGoal()`, both consume `dailyGoal` and must accept `nil` — no goal set means no
  crossing, so F7's full-screen celebration cannot fire.** This is a model-level change owned here;
  E3 separately owns moving the celebration's screen ANCHOR once the ring itself is deleted.
- `Tasks/MomentumTaskContext.swift:12-28` — `Context.streak` and
  `closeButtonLabel(streak:) -> "Close it — keeps a N-day streak"`. Replace with
  `closeButtonLabel(hasCountedToday: Bool) -> "Close it — makes today count"` / `"Close it"`, and
  `Context.hasCountedToday: Bool` in place of `streak`. Two call sites need the new input:
  `Home/HomeMomentumSections.swift:329-334` (`MomentumTaskContext.build(...)`) and
  `Tasks/TaskListView.swift:151`. `build(...)` should accept a precomputed `hasCountedToday: Bool`
  from the caller — neither call site holds captures or journal data to derive it itself.
- No existing fetch spans more than "today" for captures (`HomeMomentumSections.swift:284-295`
  `refreshClearedCaptureCount()`) or reads journal at all from Home.
  `Journal/JournalClientAdapting.swift:28` `fetchLogs() async throws -> [Log]` returns everything
  unfiltered — the same "fetch all, filter client-side" shape `closedThisWeek` already uses on
  `allTasks`. `HomeView`'s `journalClient` (`JournalClientAdapting?`) is already held; plumb
  `fetchLogs()` through it, `nil` client degrading to "no journal signal" like every other input.
- Widget-target line: `FocusTimerWidget/FocusStatsWidget.swift:218` reads `dailyGoalMinutes` on a
  **separate compiled target** (`membershipExceptions`, per CLAUDE.md) — flag it, goals-off must
  reach it too.
- New pure type (`WeeklyActiveChain`, or an extension on `MomentumScoreboard`):
  `isActiveDay(tasksClosed:sessions:capturesCleared:journalLines:on:)` plus a chain-length + repair
  function. **The repair window ("one missed week a month") is a stated default of a rolling
  4-week window**, not a calendar month — the record left only N open, not the repair period.
- Settings (`Settings/SettingsPreferenceSections.swift:15-50` `momentumSection`): add a Stepper for
  `weeklyActiveDayGoal` (1...7) beside the existing one, reusing the `onEditingChanged`/`.selection`
  haptic pattern (`:26-31`). **The `dailyGoal`/`focusDailyGoalMinutes` Steppers (`:17-40`,
  `:98-118`) bind directly to `Int` today — `Int?` breaks that binding, so this block must also
  change the row, not defer it:** a Toggle ("Set a daily goal" / "Set a daily focus goal") that
  reveals the Stepper only once set, off by default. This is squarely E1's, since it is the model
  change's own compile dependency.

**Tests that must be REVERSED, not deleted.**
- `MomentumScoreboardTests.swift:60-106` `testStreak_*` (six sub-tests) — reverse to the chain's
  active-day rule.
- `MomentumScoreboardV3Tests.swift:39-79` `testBestStreak_*`, `testStreakLine_*` — same model.
- `MomentumTaskContextTests.swift:39-56` `testCloseButtonLabel_statesTheStreakConsequence`,
  `testCloseButtonLabel_withoutAStreak` — reverse to the two `hasCountedToday` states. `:111`
  `testBuild_respectsTheStreakToggle` — reverse to the chain-display toggle.
- `MomentumPreferencesTests.swift:15-22` `testDefaults_matchTheConceptsSeed`,
  `testNormalized_clampsTheGoalIntoTheSupportedRange` — reverse for `Int?` and the new range.
- None found by grep for `FocusStatsWidget` in the widget's own test target — say so.

**Acceptance criteria**
- [ ] RED first: reversed tests above, red-checked by restoring old code, failures counted.
- [ ] SwiftLint, full suite, build all pasted.
- [ ] No `apple-design` review owed beyond the two new/changed Settings rows (Toggle + Stepper,
      matching the existing pattern) — run it on those rows only, say why nothing else qualifies.
- [ ] No `#available`/Reduce Motion site touched — no Verified-paths line, no RM-on pass owed.
- [ ] `firestore.rules`: none — everything here is local (`MomentumPreferences`, `UserDefaults`)
      and derived from data already fetched.

**Dependencies:** none upstream. E3 and E4 both consume `weeklyActiveDayGoal`, the chain function,
and the goals-off model.

---

### FEATURE: F-E2-NextStepField — the task's "Next step" field  [ ] NOT STARTED

**What E chose.** Round 5a: *"Next step → 'A "Next step" field.' One optional line on a task,
editable from the card and from task detail. Time comes from the task's stored sprint length
(`focus_duration_seconds`). It is a Firestore change, so E republishes the rules."*

**The shape (verify, do not trust).**
- `Tasks/TaskModels.swift:15-59` `TaskItem` — add `var nextStep: String?`, default `nil` (the
  `atPlaceId`/`placeId` pattern already there).
- `Home/HomeModels.swift:64-99` `TaskSummary` — add `let nextStep: String?`, default `nil` in the
  memberwise init (`:75-95`), and a `CodingKeys` case `nextStep = "next_step"` beside
  `lifeAreaId = "life_area_id"` (`:99`).
- `Tasks/TaskDetailModels.swift:8-27` `TaskDetail` — what `TaskDetailFormSections.swift:74`'s
  `titleAndStatusSection(for task: TaskDetail)` reads and `:39` stages (`notes = task.notes ?? ""`)
  — add `var nextStep: String?` and a `CodingKeys` case `nextStep = "next_step"` beside
  `lifeAreaId = "life_area_id"` (`:61-70`). `FirebaseManager+Tasks.swift:16` `fetchTaskDetail`
  decodes it straight through `getDocument(as: TaskDetail.self)` — Codable carries the wire field
  once the key exists; no separate backing-store change needed.
- `Tasks/TaskDetailModels.swift:117-133` `TaskUpdatePayload` — add `var nextStep: String??`
  (nested-optional like `notes`); include it in `isEmpty` (`:130-132`).
- `Firebase/FirestoreFieldPayloads.swift:29-47` `taskUpdate(_:)` — add
  `setNullable(payload.nextStep, forKey: "next_step", in: &fields)` beside the `notes` line (`:36`),
  keeping the file's own snake_case convention for tasks (`:19`).
- **`firestore.rules` — verified, not assumed: no change needed.** `firestore.rules:56-60` grants
  owner CRUD on the whole `tasks` document by collection name; there is no per-field allowlist in
  the file. Say this in the report rather than asking E to republish a no-op.
- `TaskDetailFormSections.swift:142` already has `TextField("Notes", text: $notes, axis: .vertical)`
  — add a matching "Next step" row beside it, staged the same way until Save (`:120-124`'s footer
  rule). The card-side editing is E3's job once the card exists.
- `MomentumScoreboard.effortLabel(seconds:)` (`:189-193`) needs no change — it already reads
  `focus_duration_seconds`.

**Tests that must be REVERSED, not deleted.** None found by grep for `nextStep`/`next_step` — new
surface. Add fresh: a `FirestoreFieldPayloadsTests` present/absent-under-other-key pair (the house
convention the file's tests already run for `life_area_id`), a `TaskUpdatePayload`
`isEmpty`/nested-optional pair, and a `TaskSummary` decode test tolerating an absent key (the shape
of `ActiveGoalSelectionTests.swift:61` `testTaskSummaryDecoding_readsHeroFields_...`).

**Acceptance criteria**
- [ ] RED first: the new field/payload/decode tests, run red before the field exists.
- [ ] SwiftLint, full suite, build all pasted.
- [ ] `apple-design` review owed for the new Task Detail row (Dynamic Type, VoiceOver label,
      `writing.md` capitalisation for the row title).
- [ ] No Reduce Motion site — none owed.
- [ ] **"firestore.rules changes; E republishes" does NOT apply here** — state the verification
      above in the report instead.

**Dependencies:** none upstream. E3's card-side editing needs this block's model + payload work
done first.

---

### FEATURE: F-E3-OneCardToday — Today collapses to one card, a "then" list, and nothing else  [ ] NOT STARTED

**What E chose.** Round 3, *"Structure → 'C · One next thing.' Today shows ONE card, then a short
'then' list, and nothing else."* *"At a place, the live routine takes the slot; elsewhere the hero
does (480pt, half a screen)."* *"Life areas leave Today (the Areas tab has them), and so does the
inbox peek."* Round 5a, *"H1 · Start first, Close quiet"*: one prominent "Start N min" (56pt,
accent), "Close it" a quiet green-tinted button below it, a pin toggle (44pt) in the corner, the
title, the next-step line, chips for time and area, and the shrinking time bar (idea 8) when a
commitment is ahead. The suggested state adds "Not this one" (idea 3). *"At AX3 the card is taller
than the screen, so the build needs a COMPACT AX3 card with Start above the fold."* Round 5a,
*"What wins the one slot → 'Leave-by first.' Leave by (inside 30 min) > live routine > paused
sprint (Resume) > pinned task > suggestion... Due nudges sit at the top of the 'then' list with a
bell."* Round 5b, *"'Not this one' → 'Back in the list, not re-suggested today.'"* Round 5b, *"Week
review door → 'Both.' ... '✓ 3 done today · Week review ›', AND a row sits at the top of the Areas
tab."* Round 1 (already settled, governs Close): *"Closing a task → 'Undo until next action'. Every
close (the circle, a full swipe, Today's hero) shows the same undo... This RETIRES the earlier
addendum 'closing is one-way'."*

**The shape (verify, do not trust).**

*Leaves `HomeView.swift`'s body (`:326-366`):*
- `todayHeader` stays. `arrivalAndRoutineCards` — see Step 0 below; do not delete unresolved.
- `scoreboardSection` (`MomentumRingCard`) — deleted, per round 8b "goes with the scoreboard".
  **The F7 daily-goal celebration's screen anchor moves with it**: once a goal is set (E1),
  `celebrationPopOrigin`/`ringOrigin` (`HomeView.swift:97`) moves from the ring to the new
  done-today line (below) — with no goal set there is no crossing to celebrate at all.
- `momentumLeadSection` — its `celebratedTask != nil` branch (`ClosureCelebrationCard` swap,
  `HomeMomentumSections.swift:13-42`) is **retired by Round 1** for arc C's shared undo capsule
  (Dependencies). Its `else` branch (`bestNextMoveSection`) becomes the H1 card, built from the
  slot-order winner. The suggestion tier still falls through `MomentumScoreboard.bestNextMove` to
  `ActiveGoalSelection.topTask` (`ActiveGoalSelection.swift:16-33`, HOME-1) — that fallback and
  `ActiveGoalSelectionTests` are unchanged. **The finished-sprint Confirm (`CelebrationCenter`,
  full-screen) is a separate, UNCHANGED mechanism — "Keep Confirm" — do not conflate it with
  `ClosureCelebrationCard`'s retirement.**
- `lifeAreasSection`/`lifeAreasHeader`/`reorderList`/`moveArrangeAreas`/`isArranging`/
  `arrangeAreas`/`lifeAreasCollapsed` — deleted; delete `Home/HomeLifeAreasSection(s).swift`
  outright. `Areas/AreasView.swift` already renders the grid and has its own reorder door (`:143-
  146`) — AREAS-03 already counted four routes to reorder areas, so this is simplification. Check
  `Home/AreaMomentumList.swift` for other call sites before deleting it too.
- `dueNowSection` (`HomeMomentumSections.swift:159-192`) — its bordered-card wrapper goes; its rows
  (minus the headline task) become the plain "then" list.
- `nudgesSection` (`HomeAccessoryStrips.swift:161-227`) — due nudges move into the "then" list, top,
  with a bell, keeping `NudgeDueCard`/`onDismiss`. The **manager door** (`nudgesDoorCard`,
  `:238-336`, → `NudgesView`) has nowhere left on Today — see Step 0.
- `inboxPeekCard`/`inboxPeekRow` — deleted with `Home/HomeInboxPeek.swift`'s view-facing helpers
  (verify its pure `countLine`/`overflowLine`/`handledLine` have no other caller first).
- `closedToday`/`MomentumClosedTodayCard`, `closedWeekChartSection`, `weekReviewRow`,
  `FocusAnalyticsSection(...)` — deleted from `HomeView.swift`. `weekReviewRow`'s door survives in
  a new shape below; the two charts are E4's.

*New:*
- `HomeTodayCard.swift` (keep `HomeView.swift` under its 400-line budget the way
  `HomeMomentumSections`/`HomeAccessoryStrips` already split it): the slot-order resolver
  (leave-by absent until arc F lands — build the site with a `nil` input; live routine from
  `liveRoutineRun`; paused sprint from whatever exposes "paused, N min in" on `FocusSessionService`
  — verify the field exists before assuming it; pinned task from the pin store below; suggestion
  from `bestNextMove`), the H1 card (reusing `MomentumChip`/`MomentumSolidButtonStyle`/
  `MomentumBorderedButtonStyle`/`ClosureRing` from `MomentumScoreboardViews.swift` — those stay;
  only `MomentumRingCard` and `ClosureCelebrationCard` are retired), the pin toggle, "Not this one".
- **Pin storage: recommend `UserDefaults`, per-uid-keyed**, the `Nudges/NudgeFirstRunMarker.swift`
  pattern (`"today.pinnedTaskId.<uid>"`) — device-local, consistent with `lifeAreasCollapsed`
  (`HomeView.swift:70`). The record flagged Next-step as a Firestore change and was silent on pin;
  this is the stated default, not a Step 0 — name the Firestore alternative (`pinned_task_id` on
  the profile doc) in the report if E wants it to sync devices.
- **"Not this one": the same house pattern**, a per-uid, per-day `UserDefaults` set of skipped IDs
  (inject `asOf now: Date` for a test to roll the day).
- **AX3 compact card:** gate on `@Environment(\.dynamicTypeSize).isAccessibilitySize` — existing
  site pattern in `Theme/AppTabBar.swift` / `Capture/CaptureRowView.swift`.
- `MomentumTaskContext.Context.hasCountedToday` (E1) feeds the H1 card's Close copy exactly as
  Task Detail's, so the two never disagree.
- `Home/HomeWeekReviewRow.swift:12-32` `weekReviewRow` — copy becomes *"✓ N done today · Week
  review ›"*, N from E1's active-day count; still pushes `weekReviewDestination`.
- A second door on `Areas/AreasView.swift` (`:134-154`, near `header`), reusing
  `MomentumWeekReview.build`/`WeekReviewSummaryCounts` as `HomeWeekReviewRow.swift:34-49` does —
  verify `AreasService` already exposes the equivalent task/history data before assuming a straight
  port.
- `HomeView.swift:277,361` `publishWidgetSnapshot` (via `HomeView+Refresh.swift`) derives the Home
  Screen widget's Active Goal from the same selection the hero uses — under pin semantics it must
  publish the slot-order WINNER (pinned beats suggestion), or the widget and the app disagree.

**Step 0 — ask E (nudges reachability):** `grep -rn "NudgesView(" "ADHD LifeOS/"` returns exactly
one production call site, `HomeAccessoryStrips.swift:216`, reached only through Today's nudges
door, which Structure C removes. Options: (a) the manager door becomes its own "then"-list row; (b)
it moves to Tools, beside the Routines section CLAUDE.md already documents there; (c) a corner well
on the card, like Settings' gear. **Recommend (b)** — keeps the "then" list to tasks and due
nudges. Must be resolved before building; Nudges must not become unreachable.

**Step 0 — ask E (the arrival card vs. "one next thing"):** `HomeRoutineCard.swift:90-115`
`arrivalAndRoutineCards` shows the live-routine card AND the place-arrival card together, by E's
explicit 2026-09-04 veto of suppressing either (`:103-111`, *"i want it shown"*). Round 5a's slot
order names "live routine" but never the arrival card, and Structure C is "ONE card". Options: (a)
the pair together count as "the one card" when present, unchanged; (b) the arrival card's tasks
fold into the "then" list instead of a second card; (c) the arrival card is suppressed after all,
reopening E's veto. **Recommend (a)** — smallest change, keeps the veto intact.

**Tests that must be REVERSED, not deleted.**
- `HomeLifeAreasSectionTests.swift` — becomes an ABSENCE assertion, not a deletion; verify Areas
  tab doesn't call the pure `collapsedLine`/`showsArrangeControl` logic before retiring the enum.
- `CelebrationPopCallSiteTests.swift:59` `testHomesBestNextMoveCloseItButtonPops` — pop source
  moves from `BestNextMoveCard` to the H1 card; reverse the reference, keep the pop.
- `CelebrationMilestoneCallSiteTests.swift:100,115-146,190,209-223` — assert
  `HomeMomentumSections.swift` by name (`onRingOrigin:`, the ring's toggle read, the daily-goal
  ask-site). Re-point at the new done-today line's origin and whichever file hosts it — the "asked
  from exactly one place" guarantee must survive the move, not be dropped.
- `CTAHapticTidyCallSiteTests.swift:109-153` (`...SpringsInAndCrossFadesInsteadUnderReduceMotion`,
  `...EveryWriteToTheCelebratedTaskGoesThroughTheAnimatedSetter`) — read the retired
  `celebratedTask`/`setCelebratedTask`/`closureCardAnimation` machinery; reverse once arc C's own
  Reduce-Motion-fade is known. This is a Reduce-Motion site changing hands, not disappearing — the
  RM-on device pass is owed on its new home.
- `HomeRoutineCardCallSiteTests.swift:25-26` reads `HomeMomentumSections.swift` for the arrival
  card's refresh wiring — reverse if that builder moves into `HomeTodayCard.swift`.
- UI: `SignedInJourneyUITests.swift:193,207` (`homeMomentumRing`, `homeNudgesSection`),
  `CaptureDiscClearanceUITests.swift:67` (`homeWeekReviewRow`) — reverse to the new identifiers
  once both Step 0s are answered.

**Acceptance criteria**
- [ ] RED first: reversed tests + new slot-order/pin/"Not this one" tests, red-checked, counted.
- [ ] SwiftLint, full suite, build all pasted.
- [ ] `screenshots/today-one-card/` + README: light/dark, default and AX3, suggested state with
      "Not this one", pinned state, paused-sprint Resume state.
- [ ] `apple-design` review owed — cite `layout.md` (HOME-03's ~50-numbers scroll),
      `typography.md`/AX3 (HOME-01), `buttons.md › Style` (HOME-08, H1 has exactly two).
- [ ] RM-on device pass owed for the close-from-hero feedback (arc C's capsule) and any new
      appear/pin-toggle transitions — name each site; do not claim "verified on E's phone" unless
      E actually toggled Reduce Motion ON and said so.
- [ ] No `firestore.rules` change from this block alone (pin/"not this one" are local) — say so.

**Dependencies:** E1, E2. **Arc C** must land first — this block retires `ClosureCelebrationCard`'s
Undo/Next swap for arc C's shared capsule. Both Step 0s must be answered before this block starts.

---

### FEATURE: F-E4-WeekReviewConsolidation — one bar chart, the Areas door, the streak-copy removals  [ ] NOT STARTED

**What E chose.** Round 3, *"Charts → 'One bar chart in Week review.' Keep the Mon–Sun bars and
drop the 7-day trend line (its smoothing drew values below zero). Both charts come off Today."*
Round 8b: the three day-streak lines (`MomentumScoreboard.swift:246-252`) — *"They go with the
scoreboard. The weekly chain speaks through Week review and the done-today line."*

**The shape (verify, do not trust).**
- `Focus/FocusAnalyticsSection.swift:46-63` on Today hosts the two named charts: the Monday–Sunday
  `WeeklyFocusSummaryWidget` and the rolling `ProductivityTrendChart` (catmullRom, HOME-09's
  overshoot). **Verified false alarm:** `Tasks/TasksFocusWeekSection.swift` matched the same grep
  only in a doc-comment reference; it renders its own `WeekBarStrip`, never the trend chart.
- `Home/WeekReviewView.swift:91-111` `barsCard` already renders a bar chart — but of task
  **closures**, over a **rolling** window, not the **focus-minutes, calendar Mon–Sun** chart named.
  Adding the widget as-is would leave two bar charts, contradicting "one".

**Step 0 — ask E:** which bar chart survives. (a) the Mon–Sun focus widget (minus the trend line)
replaces `barsCard`; closures stay as text (`headline`/`dopamineWins`/`quietLine` already do this)
— the record names Mon–Sun specifically, which only this widget is; (b) one new chart plots both
closures and focus minutes, Mon–Sun; (c) drop `FocusAnalyticsSection` entirely, nothing moved,
since Week Review already has "a bar chart". **Recommend (a).** Whichever wins, it must shed its
`currentStreak` stat (HOME-04, a fourth streak reading), its minutes/hours toggle (one of HOME-09's
"3 toggles"), and gate its goal bar on `focusDailyGoalMinutes` actually being set (E1).
- `HomeWeekReviewRow.swift:34-49` `weekReviewDestination` already threads `homeService`/
  `nudgesService` data into `WeekReviewView` — extend with session data for whichever chart wins.
- Delete `MomentumScoreboard.swift:246-253` `streakLine` once nothing calls it (E1 already replaced
  its Task Detail consumer).

**Tests that must be REVERSED, not deleted.**
- `MomentumWeekReviewTests.swift:58-69` `testBuild_dayBarsCoverSevenDays` — reverse if `barsCard`
  survives under (a)/(b); delete only under (c).
- `MomentumWeekChartsTests.swift:47-71` `testClosedPerDay_*` — input was Today's chart
  (`HomeMomentumSections.swift:76`, deleted in E3); reverse to absence or delete with the function.
- `FocusAnalyticsTests.swift` — check for `ProductivityTrendChart`/`rollingDays` coverage; reverse
  to assert the trend-line path is gone.
- None found by grep for `WeeklyFocusSummaryWidget` inside `Home*Tests`.

**Acceptance criteria**
- [ ] RED first, red-checked, failures counted.
- [ ] SwiftLint, full suite, build all pasted.
- [ ] `screenshots/week-review-one-chart/` + README, light/dark.
- [ ] `apple-design` review owed — cite `charting-data.md › Designing effective charts` (HOME-09)
      and `› Best practices` against the finished single chart.
- [ ] No Reduce Motion site touched by the consolidation itself; if the goal bar gains an appear
      animation, name it and its RM path explicitly instead.
- [ ] No `firestore.rules` change — everything here is derived/display.

**Dependencies:** E1 (goal-off gating), E3 (Today no longer hosts these charts or the `weekReviewRow`
line this block's copy sits beside).

---

### FEATURE: F-E5-EveningFirstThing — evening "tomorrow's first thing" prompt  [ ] NOT STARTED

**What E chose.** Round 3, idea list, E verbatim: *"Add 1, 3, 4, 5, 6, 7, 8, 9, 10"* — idea 6,
*"Evening 'tomorrow's first thing'. After a set hour, the card asks which then-list item goes first
tomorrow. That pre-decides the morning."* The record is explicit this idea's shape is unresolved:
*"its shape details are NOT decided (which hour, the default, and whether it pins)."*

**The shape (verify, do not trust).** Reuses E3's pin mechanism — "pre-deciding the morning" reads
as writing tomorrow's chosen task into the same pin store, read back as tomorrow's slot-order
winner. No new model beyond a trigger hour and an answered-today marker (`NudgeFirstRunMarker`'s
per-uid `UserDefaults` shape, keyed by date instead of a boolean).

**Step 0 — ask E, before any code:**
1. **The hour** — fixed (e.g. 18:00), Settings-configurable, or device-signal-derived (no such
   read exists today, so out of scope)? Recommend fixed default + Settings override.
2. **Does answering it pin?** Recommend yes — it is the simpler model and matches idea 6's own
   text; "no" would need a second, independent suggestion field alongside the pin.
3. **Unanswered behaviour** — reappear every evening, or drop after one dismissal? Recommend:
   reappear until answered or the "then" list is empty.

**Do not build past Step 0 in this block.** Once answered, this is a state variant of E3's card,
not a new screen — write the shape/tests/acceptance list in a follow-up pass.

**Tests that must be REVERSED, not deleted.** None found by grep for "tomorrow"/"evening" — new
surface, no prior implementation.

**Acceptance criteria**
- [ ] Step 0 answered by E before any other checkbox here is attempted.
- [ ] (Deferred) RED-first tests, SwiftLint/suite/build pasted, `screenshots/` + README,
      `apple-design` review, RM-on pass if a new transition is added.
- [ ] `firestore.rules`: none anticipated if pin-only; revisit if Step 0 answer 2 goes the other way.

**Dependencies:** E3 (the pin store and the card this extends). Blocked on Step 0.

---

## Arc F — the focus sprint (build specs)

Source: `handoff/SESSION-OPENER-adhd-ux-audit-design.md` rounds 4a/4b/4c + the round-4 carry-overs,
round 10b's Details renames; `handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md` §H (FOCUS-01–11, LA-01–04),
§C (widgets/LA/notifications), §M (RM-01, A11Y-06); boards `57`/`58`, frames
`screenshots/adhd-ux-audit/round-4c-sprint-controls/`; the deleted probe
`scripts/audit/probes/AuditSprintControlsRenderProbe.swift.txt` (never re-add it to the test
target — it is `.swift.txt` on purpose).

Build order: after arc C (Decision A, the audit close-out). Within F: **F2 depends on F1** (the
Live Activity's `ContentState` carries the checkpoint fields F1 retires — building F2 first would
touch the same wire type twice). **F4 depends on F1 and F3** (the Focus screen mounts the same
six-control block F3 builds for the card). F5 is independent of F1–F4 but edits `TaskDetailView.swift`,
which arcs A/B/C also touch — land it after those to avoid conflicts. Arc E's "leave-by" card and
shrinking time bar (round 3, idea 8/1) **consume** F5's calendar-read seam; F5 does not depend on
arc E.

## Test triage — three kinds, not two

The brief asks for tests "reversed, not deleted". Two subsystems here (checkpoints/cadence) are not
being changed, they are being **retired** — there is nothing to reverse them to, because the
behaviour they assert no longer exists. Every block below sorts its tests into:
- **(a) reverse** — the surface stays, the assertion flips (a string, a control set, an identifier).
- **(b) delete** — the concept is retired; name the file, cite the design-record line as the WHY,
  and delete the whole file rather than gutting it into a shell.
- **(c) must stay green, unmodified** — named because a naive sweep could catch it by accident.

## Every block below owes (not repeated per block)

- [ ] RED first; a red-check that restores the deleted/changed code and counts the failures, then
      restores from git.
- [ ] SwiftLint 0, the full suite, and the build — real pasted terminal output, not a summary.
- [ ] `apple-design` review (§7.6) — every block in this arc changes something a person sees or
      feels.
- [ ] A `screenshots/<folder>/` + README for anything settled by looking (named per block below).
- [ ] No `firestore.rules` change unless a block says otherwise (none in this arc changes the
      rules file itself — F5's new field sits inside the existing generic per-user allow).
Only genuine deltas — a required RM-on pass, a `#available` Verified-paths line, a device check —
are called out per block.

### FEATURE: F-F1-HeadsUpReplacesCheckpoints — the 5-minute heads-up replaces mid-sprint checkpoints  [ ] NOT STARTED

**The largest block in the arc, and it is genuinely one unit, not five.** `FocusActivityAttributes.ContentState`
(`FocusTimerWidget/FocusActivityAttributes.swift:18`) is compiled into **both** the app and the
widget target — ActivityKit matches an Activity across processes by this type — so the checkpoint
fields cannot be retired on one side only. If the build session judges this too large for one
reviewable unit, splitting into **F1a** (subtraction: delete the checkpoint/cadence subsystem
app-wide, red-check = restore the deleted files and count failures) and **F1b** (addition: the
heads-up, pure-logic TDD) is sanctioned — say so in the report rather than silently trimming scope.

**What E chose:** round 4a, **"Heads-up replaces checkpoints"** — *"ONE alert at 5 minutes left: in
the app a haptic, a soft sound and the ring changing colour; when away, a notification. The
mid-sprint checkpoints go, with the 'In-Sprint Nudges' stepper, `FocusNotificationPlanning.checkpoint`,
the checkpoint dots and caption, 'Flow calibration' (`Focus/FocusModels.swift:107`) and the Nudge
cadence card."* Carried by E's own Q2 answer: *"Timer + Current Task + Primary Actions (+5m / End)
ONLY... Include a subtle, non-intrusive 5-minute remaining heads-up notification/haptic transition."*

**The shape — what retires (delete the file/region, delete its tests, no reverse):**
- `Focus/FocusCadenceEditorCard.swift` (whole file) — the "Nudge cadence" card
  (`:27-34` `LabeledContent`/`Label("Nudge cadence", ...)`), its editor, Apply.
- `Focus/FocusCadenceDraft.swift` (whole file) — the draft type the editor above stages.
- `Focus/FocusNudgeCadence.swift` — `enum FocusNudgeCadence` (`:19-48`) and its `checkpoints(forDurationSeconds:)`.
  Keep `FocusSessionLogging` (`:14-16`) and `FocusNudgeCadence.standardDurationSeconds` if
  `FocusSprintConfiguration.defaultDurationSeconds` still reads it, or fold that one constant in.
- `Focus/FocusModels.swift`: `FocusSession.nudgeCheckpoints`/`triggeredCheckpointIndices` (`:21-25`),
  `advance(toRemaining:)`'s checkpoint-crossing return (`:70-79` — keep the method, drop what it reports),
  `replanCheckpoints(to:)` (`:81-98`), `checkpointPrompt(index:total:)` (`:100-113`, **"Flow
  calibration" is `:107`**) — this is the whole `enum FocusCheckpoints` (`:196-244`) too:
  `evenlySpaced`, `interval`, `replanned`. Keep `minimumIntervalSeconds`/`minimumDurationForCheckpoints`
  only if another site still floors a duration on them (check before deleting).
- `Focus/FocusSprintPresentation.swift`: `enum FocusCheckpointDotState` (`:62-112`, incl. the raw
  `.green` at `:88` — tell arc A its colour-job list loses this site and
  `FocusTimerWidget/FocusActivityComponents.swift:115`, both dying with the dots, not fixed by a
  colour swap).
- `Focus/SprintRingGeometry.swift` — the dot-on-dial maths, now unused.
- `Focus/FocusTimerBarContent.swift`: `checkpointDots` (`:258-274`), the dial import in `sprintRing`
  (`:202` `.overlay(checkpointDots)`), the `titleColumn`'s checkpoint `Group` (`:237-249`, incl.
  "No checkpoints this sprint"/"✓ All N checkpoints reached"), the `checkpointBanner` param/row
  (`:27`, `:86-92`).
- `Focus/FocusSessionService.swift`: `checkpointBanner` (`:26`), `cadence` (`:54`), `updateCadence(_:)`
  (`:223-232`), the checkpoint-prompt lines in `syncNow()`/`tick()` (`:330-333`, `:348-351`).
  `start(...)`'s `cadence:` parameter goes; keep the method's other params.
- `Focus/FocusNudgeCadence.swift:50-61` `FocusSessionService.start(plan:)` — drop the `cadence:` arg.
- `Focus/FocusSprintConfiguration.swift`: `maximumNudgeCount`, `clampNudgeCount`, `resolvedNudgeCount`
  (`:16,30-37`); `FocusSprintPlan.nudgeCount` (`:45,55,64,79,95`) and its two `nudgeCount:`
  constructor args.
- `Tasks/TaskFocusPlanSection.swift`: `nudgeCountRow` (`:212-217`, **the "In-Sprint Nudges"
  stepper**), `cadencePreview`/`cadenceTimeline` (`:227-272`), the `checkpoints` computed prop
  (`:46-48`), the footer's "chime and haptic pulse" copy (`:62-65`). The `nudgeCount: Binding<Int>`
  parameter and its two call sites (`Tasks/TaskDetailView.swift:164`,
  `Tasks/TaskDetailFormSections.swift:48`) go with it — `TaskFocusPlanSection` keeps only the
  launch row, the preset chips and the fine-tune stepper.
- `Tasks/TaskModels.swift:26,50,64,77` / `Tasks/TaskDetailModels.swift` (three structs, `:19,39,54,67`,
  `:91,103,112`, `:126,132`) / `Home/HomeModels.swift:73,84,94,102` — the `nudgesCount`/`nudges_count`
  field on every task-shaped type. **Leave the Firestore field alone** (stop writing it; a document
  that already has `nudges_count` keeps it — harmless dead data, no `firestore.rules` change, no
  migration). `Firebase/FirestoreFieldPayloads.swift:44-45` stops emitting the key.
  `Tasks/TaskUpdateValidation.swift:71-77` drops its clamp branch.
- `Focus/FocusWidgetPublishing.swift:45` and `FocusTimerWidget/FocusWidgetSnapshot.swift:146,212-219`
  (`FocusCheckpointCopy.summary`) and `FocusTimerWidget/FocusSprintWidgetSection.swift:58` — the
  Home Screen static widget's "N nudges"/"N of M checkpoints" text (§C: "medium shows '15m sprint ·
  N nudges'"). Grep `FocusCheckpointCopy` and `checkpointSummary` for the rest; this is a third
  surface beyond the app and the Live Activity and it is easy to miss.
- `FocusTimerWidget/FocusActivityAttributes.swift:18` `ContentState`: drop `checkpointCount`,
  `checkpointsReached`, `checkpointSeconds` and `checkpointMarks(isComplete:)`/`checkpointSummary(isComplete:)`
  (`:83-112`); update the hand-written `Codable` (`:159-186`) to match — an Activity is swept at
  every launch (`FocusActivityKitMirror.init`, `+FocusActivityKitMirror.swift:48`), so there is no
  live cross-update Activity to keep decodable, unlike `CompletedFocusSession.confirmedAt`'s trap.
  `FocusTimerWidget/FocusActivityComponents.swift`: delete `FocusSprintProgressTrack`'s `markers`
  (`:63-81`) and `FocusCheckpointMarker` (`:91-124`); keep `fill` (the progress bar itself stays —
  it just draws no dots) and `FocusCheckpointCaption` only if F2 finds another use for it (likely
  not — delete alongside).
- `Focus/FocusActivityMirroring.swift:12-30` `FocusActivitySnapshot`: drop `checkpointCount`,
  `checkpointsReached`, `checkpointSeconds`.
- `Focus/FocusSprintPersistence.swift:13-79` `PersistedFocusSprint`: drop `nudgeCheckpoints`,
  `triggeredCheckpointIndices`, `cadenceCount`, `cadenceIntervalSeconds`, the `cadence` computed
  prop. **Write a test that decodes an OLD-shaped JSON blob** (one written by the current code,
  with those four keys present) through the NEW slimmed `Codable` struct and asserts it still
  restores — `JSONDecoder` ignores unrecognised keys by default, so this should pass, but it is the
  one persistence seam nobody has verified empirically and a live mid-sprint update must not lose
  the sprint.
- `Focus/FocusCompletionCard.swift:40-53` — the finished-card summary appends "· N checkpoints".
  `checkpointsReached` will always be `0` going forward (Firestore's `CompletedFocusSession.checkpointsReached`,
  `FocusModels.swift:126`, **stays in the struct, decodable, just never non-zero for a new
  record** — same optional-tolerance rule as `confirmedAt`, `:139-145`). Cut the checkpoints clause
  from the copy entirely rather than leaving a guard that can never fire.

**What's added (pure logic first, TDD):**
- A single fired-once flag replacing the whole checkpoint array — e.g. `FocusSession.hasFiredHeadsUp: Bool`,
  set the moment `remainingSeconds` crosses 300s (mirrors `advance(toRemaining:)`'s existing crossing
  detection at `FocusModels.swift:72-79`, now reporting one crossing instead of N).
- `ScheduledFocusNotification.Kind` (`FocusNotificationPlanning.swift:10-13`): replace `.checkpoint(index:)`
  with `.headsUp`; `FocusNotificationPlanning.plan(session:deadline:now:)` (`:47-82`) schedules it at
  `deadline - 300s` instead of the checkpoint loop, only when `remainingSeconds > 300` at plan time
  (see Step 0 below for the ≤5-minute sprint case).
- In-app effect on the crossing: haptic `.light`, the soft sound (Step 0), and the ring recolouring
  to `Color("StateWarn")` for the remainder of the sprint (stated default — it is the token this
  app already uses for time-pressure on these surfaces, e.g. `FocusTimerBarContent.swift:240`'s
  "Next checkpoint" text; E may overrule). Wire it the way `checkpointBanner` used to: a published
  flag `FocusSessionService` sets in `tick()`/`syncNow()` when the crossing fires, read by
  `FocusTimerBarContent.sprintRing`'s `arcStyle` and by a `.haptic(_:trigger:)` call.

**Tests — (a) reverse:** `FocusNotificationPlanningTests.swift` (`testPlan_schedulesEveryCheckpointStillAhead`
etc., `:41-116`) → heads-up scheduling. `FocusSprintPresentationTests.swift:74-98`
(`testDotState_*`) → delete with `FocusCheckpointDotState`; `:18-63` (`testHeroAction_*`) **stay
green, untouched** (Home's hero, not this arc — see the note below). `FocusSessionServiceCadenceTests.swift`
(all 8, `:44-134`) → delete or replace with heads-up-crossing tests on the same seams
(`syncToWallClock`, `tick`). `TaskFocusPlanSection`'s preview/host — no test file found by grep for
"TaskFocusPlanSection"; check the UI journeys (`SprintSeedHarness`-adjacent) for a launch-row
assertion that stages `nudgeCount`.

**Tests — (b) delete, file and why:** `FocusCheckpointsTests.swift` (16 tests, pure cadence maths,
retired). `FocusCadenceReplanTests.swift` (10 tests, `replanCheckpoints` retired).
`FocusCadenceDraftTests.swift` (13 tests, the editor's draft type retired). `FocusActivityCheckpointMarkTests.swift`
(16 tests, `FocusActivityCheckpointMark`/`checkpointMarks` retired). `SprintRingGeometryTests.swift`
(4 tests, the dot-on-dial maths retired). Each deletion cites round 4a's "Heads-up replaces
checkpoints" as the why in its own commit-adjacent comment or the block report — not silently.

**Tests — (c) must stay green:** `FocusSprintPresentationTests.testHeroAction_*` (`:18-63`) — Home's
`ActiveGoalSprintState` titles ("Start Session"/"Session Active"/"Session Paused",
`FocusSprintPresentation.swift:34-36`) are arc E's hero, already superseded by round 5a's "H1 · Start
first" redesign; F1 must not touch them even though the file also holds the (deleted)
`FocusCheckpointDotState`. `FocusModels.swift`'s `CompletedFocusSession` Codable round-trip tests
(`FirestoreDocumentCoderTests.swift`, `FirebaseFocusSessionAdapterTests.swift`) — `checkpointsReached`
stays a decodable field; these must still pass unmodified.

**Step 0 — ask E:**
1. **The heads-up sound.** `Celebrations/CelebrationSound.swift` is scoped in its own header to
   "full-screen celebrations only" with its switch OFF by default, and E's round-1 words were that
   sounds are a first-class ADHD grounding cue. Three options: (a) reuse `CelebrationSoundPlayer`
   and its existing "Celebration sounds" switch (cheapest, but broadens what that switch controls
   and it defaults off, which is not "essential" grounding); (b) a new switch, own default
   (recommend **ON**, since Q2 called the heads-up itself, not just celebrations, a first-class
   sound cue); (c) always-on, no switch (simplest, but breaks the house pattern that every sound in
   the app is a toggle). Recommend (b).
2. **A sprint ≤5 minutes.** The presets include 30s/1m/2m/5m (`FocusSprintConfiguration.presetDurationsSeconds`).
   A heads-up fired at "5 minutes left" on a 5-minute-or-shorter sprint fires at or before 0s.
   Recommend: no heads-up below a floor (e.g. `durationSeconds > 300`), silently — the finished
   notification is enough warning on something that short.
3. **+5m after the heads-up already fired.** Does a Custom/+5m extension re-arm a fresh 5-minutes-out
   heads-up, or does the flag stay spent for the rest of the sprint? Recommend: stays spent — one
   alert per sprint, matching Q2's "ONE alert", not one per extension.

### FEATURE: F-F2-LiveActivityFiveMinuteOnly — the Live Activity: `+5m` only, `.widgetURL`, the minimal Island  [ ] NOT STARTED

**Depends on F1** (touches the same `ContentState`).

**What E chose:** round 4a, **"+5m only; End in the app"** — *"One control. Ending early happens in
the app, where its confirm lives... This retires the Live Activity's unconfirmed Stop (LA-01) and
its ~34pt Pause/Stop pair."* And: *"a tap opens the sprint (a `widgetURL`, LA-03), and the minimal
Dynamic Island shows the time left (LA-04)."* Pause is retired from the Lock Screen too — round
4a's Pause bullet: *"'Keep Pause in the app.' The in-app set is Pause · extensions · End."* (the
Lock Screen's set is `+5m` alone, stated separately). §3's 44pt floor applies "within the height
cap" (widget's own note, `FocusTimerWidgetLiveActivity.swift:168`, ~38pt is the LA's own precedent
for a control that must live inside 160pt).

**The shape:**
- `FocusTimerWidget/FocusTimerWidgetLiveActivity.swift:171-203` `FocusSprintControls`: replace the
  `Pause`/`Stop` `Button(intent:)` pair with one `Button(intent: ExtendFocusSprintIntent())` reading
  "+5m", styled like the removed Pause tint (`Color.sprintAccent`) — no `StateRisk` colour left on
  this surface, since Stop is gone. Delete the `.tint(Color("StateRisk"))` line (`:194`).
- `FocusTimerWidget/FocusSprintIntents.swift`: delete `PauseResumeFocusSprintIntent` (`:41-55`) and
  `StopFocusSprintIntent` (`:57-70`); add `ExtendFocusSprintIntent: LiveActivityIntent` calling a
  new `FocusSprintIntentActions.extend: (() async -> Void)?` (`:20-23`'s pattern). Keep
  `endAllActivities()` (`:26-38`) — the orphan sweep still runs at launch.
- `ADHD LifeOS/Focus/FocusActivityKitMirror.swift:180-193` `withLiveActivityMirroring`: replace the
  `pauseResume`/`stop` closure wiring with one for `extend`, calling `service.addSeconds(300)`
  then `mirror.waitForPendingUpdates()` — same shape as the two it replaces.
- `.widgetURL` (LA-03): add `.widgetURL(URL(string: "adhdlifeos://widget/focus/sprint"))` (or a
  distinct host) to both the Lock Screen view and the Island's tappable region — the exact site the
  routine LA uses at `FocusTimerWidget/RoutineLiveActivity.swift:27,127`
  (`.widgetURL(URL(string: RoutineActivityAttributes.deepLink))`). Route it in
  `ADHD LifeOS/AppDeepLink.swift:12-52`: today `.focusWidget` (path `[]`) does nothing but land on
  Home (`:37`, comment "Nothing to do... which is what the widget shows") — that is wrong for a
  tap that should open the sprint. Add a case, e.g. `.focusSprintScreen`, routed by a new path
  segment, and give it `requiresSignedInUI = true` (`:29-38`) so a cold launch holds it in
  `RootView.pendingWidgetLink` (`RootView.swift:56`) until the tabs mount
  (`RootView+Doors.swift:85-98`).
  - **Naming constraint, name it rather than solve it:** the sprint's detail-sheet presentation
    flag (`isPresentingDetail`) is local `@State` on `FocusTimerBar`
    (`ADHD LifeOS/Focus/FocusTimerBar.swift:45`), and `testTheRowIsNoLongerItsOwnDoor`
    (`ADHD LifeOSTests/FocusBarCollapseCallSiteTests.swift:175-188`) asserts **exactly one** writer
    of `isPresentingDetail = true` in that file. `RootView+Doors.openWidgetDoor` cannot reach that
    local state directly. Two options for the build session: (i) lift the flag onto
    `FocusSessionService` (already `@ObservedObject` in `FocusTimerBar`) so both the card's gesture
    and the widget door write the same published property, updating the call-site test's "exactly
    one writer" claim to name the service instead of the view; or (ii) route the widget door to
    `selectedTab = .today` (where the card lives) and rely on the card being on-screen — cheaper,
    but does not "open the sprint", only the tab it lives on. Recommend (i); it is what LA-03
    actually promises.
- Minimal Dynamic Island (LA-04): `FocusTimerWidgetLiveActivity.swift:83-90` `minimal:` currently
  shows only the emoji (or a checkmark when complete). Add the countdown —
  `FocusCountdownReadout(state:isComplete:timerMaxWidth:)` (`FocusActivityComponents.swift:129-160`)
  already exists and is reused by `compactTrailing`; give the minimal slot a narrow `timerMaxWidth`
  (the compact slot uses 56) rather than inventing new formatting.
- Delete the checkpoint caption row from both presentations
  (`FocusTimerWidgetLiveActivity.swift:57-76` bottom region's `FocusCheckpointCaption`, `:143-156`
  Lock Screen's matching `HStack`) — F1 already deletes the type; this block's job is only to
  confirm the layout reads correctly with one fewer row (the `+5m` button now sits where
  Pause/Stop did, beside nothing).

**Tests — (a) reverse:** `FocusSprintIntentsTests.swift` (all 6, `:63-123`) — Pause/Resume and Stop
recorder tests become one Extend recorder test (`installRecordingActions`, `:55-59`); keep the
"cold-launch sweeps orphans" shape (`:97-115`) pointed at the new intent.
`RoutineActivityCallSiteTests.swift`'s pattern (not this file, a sibling to write) becomes the model
for a new `FocusActivityCallSiteTests.swift` asserting: no `Button(` for Pause/Stop remains in
`FocusTimerWidgetLiveActivity.swift`, exactly one `Button(intent: ExtendFocusSprintIntent())`, and
the `.widgetURL(` line exists on both presentations (mirroring `testTheActivityCarriesNoButtons`,
`RoutineActivityCallSiteTests.swift:96-105`). `AppDeepLinkTests.swift` (`:18-80`) — add a test for
the new route beside `testWidgetTap_routesToTheWidgetDestination` (`:18`) and
`testWidgetDoors_mustBeHeldForTheSignedInUI` (`:70`).

**Tests — (c) must stay green:** `FocusActivityContentStateTests.swift` — re-read after F1's field
removal; whatever remains (deadline/pause/isCompleted logic) must still pass untouched by F2.

**Acceptance criteria — deltas beyond "Every block owes" (F1 and F2 both, F1's suite run needs the
emulator up or an accepted skip since `Firebase*` schema tests are in the reversed/stays-green set):**
- [ ] `screenshots/focus-sprint-heads-up/` (F1: ring recolouring + notification, light/dark) and
      `screenshots/focus-live-activity-v2/` (F2: Lock Screen + both Island tiers, light/dark).
- [ ] No `#available` site touched: `FocusSprintControls` is ungated since `F-Floor18` (its old
      iOS 17 gate and the display-only 16.x branch are gone), so the Lock Screen button is universal
      and no "Verified paths" line is owed — say so.
- [ ] No Reduce Motion site is added or changed by F1/F2 (the ring's colour change is a state swap,
      not a spring) — say so; no RM-on device pass owed here (it is owed in F4, RM-01).
- [ ] F1's persisted-sprint decode test (above) is pasted as its own result, not folded into "suite
      green" — it is the one empirical check for the update-mid-sprint trap.

### FEATURE: F-F3-CardControlsV2 — the card's six controls ("V2 · two rows"), haptics by meaning, the timer size  [ ] NOT STARTED

**Depends on F1** (the card currently renders checkpoint dots on the ring, `FocusTimerBarContent.swift:202`
— already deleted there).

**What E chose:** round 4c, **"V2 · two rows"** — *"The four time buttons sit on top (+30 sec · +1
min · +5 min · Custom, text only); big Pause and End sit below. Card 222pt, against 148pt today. At
AX3 the time row wraps to 2×2. The collapsed card keeps Pause only. The focus screen uses the same
two-row block, taller (56pt). At accessibility sizes the card's ring grows (128pt) and sits above
the title."* Extensions, E verbatim (round 4b): *"Instead of five controls, Add a sixth control,
allowing the user to enter a custom time extension."* Round 4 carry-overs (stated defaults, E may
overrule): timer grows from `.caption2` (11pt) to `.callout` monospaced semibold; haptics differ by
meaning through `.haptic(_:trigger:)`/`HapticFeel` — start `.solid`, Pause/Resume `.selection`, each
extension `.light`, End (after its confirm) `.solid`, the heads-up `.light` (F1), finished keeps
`.success`.

**Measured-number check, do not trust without re-measuring:** the record says the timer sits "on
the 70pt ring". The real card's expanded ring is `FocusBarMetrics.expandedRingSize = 64`
(`ADHD LifeOS/Focus/FocusBarCollapse.swift:243`) — 70 was the throwaway probe's `MockRing` default
(`AuditSprintControlsRenderProbe.swift.txt:186`), not the shipped constant. Render the real 64pt
ring with the new controls before treating 222pt as settled; if it reads short, that is a
legitimate reason to re-render for E rather than silently growing the ring to 70 unasked.

**The shape:**
- `ADHD LifeOS/Focus/FocusTimerBarContent.swift`: `expandedBody`'s control `HStack`
  (`:99-125`, today three buttons + Spacer + Stop) becomes two rows: a 4-up row
  (`+30 sec`/`+1 min`/`+5 min`/`Custom`, text-only per the record, using `controlButton`'s pattern
  at `:276-295` but without `.labelStyle(.titleAndIcon)` glyphs) and a 2-up row (`Pause`/`End`,
  full-width, `MomentumBorderedButtonStyle`/`MomentumSolidButtonStyle`-weight per board 58 rather
  than the current 44pt-tall `controlButton`). Add `onExtend` callers for `60` (new, "+1 min") and
  a `onCustom: () -> Void` opening the Focus screen's inline stepper (F4). Rename `focusBarStop` →
  `focusBarEnd` (identifier and label) — see F4's "End is the stop word everywhere".
  `testTheExpandedOnlyControlsAreGatedOnTheFlag` (`FocusBarCollapseCallSiteTests.swift:190-206`)
  currently asserts `focusBarAdd30`/`focusBarAdd5m`/`focusBarStop` exist — reverse to the six new
  identifiers (`focusBarAdd30`, `focusBarAdd1m`, `focusBarAdd5m`, `focusBarCustom`, `focusBarPause`,
  `focusBarEnd`), keep the "gated on `!isCollapsed`" and "chevron leaves the collapsed card"
  assertions unchanged.
- **Collapsed card is UNCHANGED by this block** — ring + emoji + title + Pause only
  (`collapsedBody`, `:58-82`). Confirm `testTheExpandedOnlyControlsAreGatedOnTheFlag`'s collapsed-body
  assertions (`:207-` onward) still pass; do not let a card-height change leak into the collapsed
  state.
- The countdown text (`sprintRing`, `:193-198`): `.font(.caption2.monospaced().weight(.bold))` →
  `.font(.callout.monospacedDigit().weight(.semibold))`. `A11Y-06` (§M): add
  `.accessibilityAddTraits(.updatesFrequently)` here (`:197`, the finding's own citation) — a
  countdown that changes every second should not spam VoiceOver's "value changed" announcements.
- Extend `FocusBarMetrics` (`FocusBarCollapse.swift:171-`) with the new card height (measure the
  real render rather than hand-copying 222), and an accessibility-size ring diameter (128, per the
  record) — mirror the existing `expandedRingSize`/`collapsedRingSize` pattern (`:243-244`) with a
  third tier gated on `dynamicTypeSize.isAccessibilitySize`, matching the probe's
  `MockCard.body` branch (`AuditSprintControlsRenderProbe.swift.txt:203-214`).
- Haptics: `FocusTimerBar.swift` already fires `.light` on grabber/collapse (`:186`) and `.light`
  on Stop's confirm (`:150`) — reuse `.haptic(_:trigger:)` triggers per control rather than
  `Haptics.play` calls buried in closures, matching the house rule in `Theme/Haptics.swift:79-84`.
  Start (`.solid`) is `RootView+Doors.swift:19` `startFocus(_:)` — already `.success` today
  (`Haptics.play(.success)`); the record calls for `.solid` at start — **conflict to name in the
  report**: `Theme/Haptics.swift:36-39` documents `.taskClose`/success as "the celebratory success
  feel", and start already uses it deliberately (comment: "the success haptic the web fires on
  start"). Recommend keeping `.success` at start (existing, deliberate, and `.solid` is defined as
  "a committed write landed" — a sprint starting is closer to §HapticFeel's `.success` case, "a
  completion worth marking... starting a sprint" is literally `Theme/Haptics.swift:22`'s example).
  **This is a discrepancy between the design record's stated default and existing, deliberate,
  documented behaviour — flag it in the report rather than silently changing either.**

**Tests — (a) reverse:** `FocusBarCollapseCallSiteTests.testTheExpandedOnlyControlsAreGatedOnTheFlag`
(above). `FocusBarGeometryTests.swift` — re-read for hard-coded 148pt/three-button assumptions and
update to the new metrics. `CTAHapticTidyCallSiteTests.testStoppingASprintBuzzesWhenTheConfirmationIsAcceptedRatherThanWhenItIsRaised`
(`:89-107`) — string-matches `"Button(FocusStopConfirmation.confirmTitle, role: .destructive) {"`;
if `FocusStopConfirmation` is renamed (F4), this citation must move with it.

**Acceptance criteria — deltas:**
- [ ] `screenshots/focus-card-v2/` — light/dark/AX3, expanded and collapsed, the real 64pt ring
      (not the probe's 70pt); board 58 chose from renders, so the real card owes its own look.
- [ ] **RM-on pass:** none of F3's own changes touch a Reduce Motion site (the ring's per-second
      spring is already gated, `FocusTimerBarContent.swift:203-206`) — say so, UNLESS the new
      accessibility-size layout adds a transition (e.g. the ring moving above the title), in which
      case it needs a reduced path and the pass is owed.
- [ ] Device check on E's phone: haptics by meaning (record says so explicitly), and thumb reach
      across two rows of small buttons — neither is simulator-verifiable.

### FEATURE: F-F4-FocusScreenAndDetails — "Focus screen + Details", the inline stepper, "End" everywhere, round 10b's renames  [ ] NOT STARTED

**Depends on F1 and F3** (mounts F3's control block; F1 has already stripped the checkpoint
timeline/cadence card this file used to show).

**What E chose:** round 4b, **"Focus screen + Details"** — *"A big ring with the time left, the
task title, and the controls pinned at the bottom (Q8). One 'Details' row reveals the timeline and
session stats... the grabber stops stealing taps from the title."* **Ending a sprint → "End"** —
*"The word is End everywhere, and the confirm reads 'End sprint?'. 'Close it' only ever means 'the
task is done'."* Round 4c: **"Inline stepper"** — *"Custom opens a row on the focus screen: − N min
+ · Add. Tapping Custom on the card opens the screen with that row ready. Whole minutes, no
keyboard, no second sheet."*

**The shape:**
- `ADHD LifeOS/Focus/FocusSprintDetailView.swift` is the file to rebuild, not just edit — its
  current `sprintContent(_:)` (`:63-77`) stacks a checkpoint banner, a 236pt ring, identity, the
  full timeline card, the cadence editor and the controls, all in a scrolling `LazyVStack` — this
  is exactly FOCUS-01/02's "≈14 regions... 12 before any control" and Q8's "scroll with content".
  New shape: ring + title pinned near the top (no scroll needed for them), F3's control block at
  56pt (record's number) pinned at the bottom via `.safeAreaInset(edge: .bottom)` (the house
  pattern for a keyboard-adjacent bottom bar is round 7b's L3, `layout.md`'s "Adaptability" citation
  in findings §L — same technique, no keyboard here but same reason: controls must not scroll away),
  and ONE "Details" disclosure row between them that reveals `FocusSprintTimelineCard` (trimmed by
  F1 to its two remaining phase cards) below the fold.
- The `checkpointBanner(_:)` function (`:138-145`) and its call (`:66-68`) are gone with F1.
- `statusRow(_:)` (`:99-108`) is **dead code today** — grep confirms it, defined but never called in
  `sprintContent`. Either delete it outright or, if the rebuilt screen wants a status line, wire it
  in with F4's renamed copy ("Sprint paused"/"Sprint active" rather than "Session paused"/"Active
  focus sprint" — the "session"→"sprint" rename, scoped to this file, not Home's hero).
- `identity(_:)` (`:111-125`)/`countdown(_:)` (`:149-181`) — keep the ring
  (`ClosureRing(progress:size:lineWidth:arcStyle:)`, `:151-157`), **but gate its spring** the way
  `FocusTimerBarContent.sprintRing` already does (`.transaction { if reduceMotion { $0.animation =
  nil } }`, `FocusTimerBarContent.swift:205-207`) — **this is RM-01**, findings §M: *"The sprint
  sheet's 236pt ring springs every second under Reduce Motion... `nil` is correct. It rides into
  round 4b's Focus screen build."* This is a REQUIRED Reduce Motion fix, not optional.
- **`"1 of 15 min logged"` → `"1 of 15 min done"`** (`:167`, round 10b, exact string match, cite it
  verbatim in the diff).
- Extend chips (`:205-217` `extendChips`) — retired; F3's control block replaces them (no separate
  "+1/+5/+10 min" row distinct from the card's own extension buttons — one set of extension
  controls, not two different ones as today's FOCUS-04 finding names).
- `controls(_:)` (`:219-270`) — retired in favour of F3's shared block. The green "Close it ✓"
  button that actually stops the sprint (`:236-243`, FOCUS-03) is deleted; its job is now the
  shared block's "End" button, tinted `StateRisk` like the card's, with the SAME
  `FocusStopConfirmation`-style dialog (rename the type/copy — see below).
- **"End" everywhere:** rename `FocusStopConfirmation` (`FocusSprintPresentation.swift:136-147`) —
  suggest `FocusEndConfirmation` for symbol/string consistency, though the design record only
  requires the DISPLAYED words to change (`title` "Stop this sprint?" → "End sprint?",
  `confirmTitle` "Stop sprint" → "End sprint"; `cancelTitle` "Keep going" stays). If renamed, update
  `CTAHapticTidyCallSiteTests.swift:92`'s source-string match (F3 already flags this dependency).
- **Round 10b's Details renames** (`FocusSprintTimelineCard.swift`, post-F1's trim to two phase
  cards): `"Deep entry"` → `"Getting started"` (`:202`); `"Sprint target"` title/value/caption
  combo → `"Length 15 min · saved when it ends"` (`:212-214` — this is a re-word of the title AND
  caption together, not a single string swap; keep the value's `FocusTimeFormatting.human(seconds:)`
  call, just change what wraps it). The "Cadence" phase card (`:206-210`) is deleted by F1 (nothing
  to rename — no cadence exists any more); if round 10b's silence on it reads as "keep it", that is
  a Step 0, but the more consistent reading is deletion, since its content (`"N checkpoints"`) is
  gone.
- **The inline stepper** ("− N min + · Add", whole minutes, no keyboard, no second sheet): new row
  on the Focus screen, shown when Custom is tapped (from the card or from the screen itself). Stated
  default (E may overrule): opens seeded at the task's own configured sprint length rounded to the
  nearest minute, range 1–60. `−`/`+` are 48×48pt buttons (Q7's "key targets" bar) either side of a
  `Text` showing "N min"; "Add" commits via `service.addSeconds(_:)` and dismisses the row. This is
  new UI with no existing file — house pattern to copy: `Focus/FocusCadenceEditorCard.swift`'s
  now-deleted `Stepper` + preset-chip shape is the closest precedent for "adjust a number inline,
  no sheet", even though the type itself is retired.
- The grabber (FOCUS-10): `FocusTimerBar.swift`'s own grabber (`:168-182`) is unaffected — FOCUS-10
  is about the SHEET's drag handle overlapping the title inside `FocusSprintDetailView`'s presentation,
  which is a `.sheet` default grabber, not a custom view. Check whether `.presentationDragIndicator(.visible)`
  or a custom top inset is what is actually overlapping (grep for `.presentationDragIndicator` — none
  found by an initial grep, so the default system grabber is likely the culprit; adding
  `.padding(.top, ...)` to the title so it clears the system indicator's hit region is the likely
  fix, verified by the build session against the real sheet, not assumed here).

**Tests — (a) reverse:** `FocusSprintPresentationTests.swift:101-127` (`testStopConfirmation_*`) —
reverse to "End sprint"/"Stop sprint"→"End sprint" wording, update the symbol name if renamed.
Round-10b string tests: grep for `"1 of 15 min logged"`, `"Deep entry"`, `"Sprint target"`,
`"Logged on finish"` across `ADHD LifeOSTests/` — none were found by this session's greps (all
`0` hits), meaning **no existing test currently pins these exact strings**; write new ones rather
than reversing.

**Tests — (b) delete:** any test exercising `FocusCadenceEditorCard`/`FocusSprintTimelineCard`'s
checkpoint track (grep `focusCheckpointPin`, `focusCheckpointInspector`, `focusCadence*` — none
turned up a dedicated view-level test file by name in this session's sweep, but `FocusSessionServiceCadenceTests.swift`
already listed under F1 covers the service side).

**Acceptance criteria — deltas:**
- [ ] `screenshots/focus-screen-details/` — the ring, Details collapsed/expanded, the inline
      stepper, light/dark/AX3.
- [ ] **RM-01 is a required fix here, and the RM-on device pass (§7.3) IS owed**: E must look at
      the rebuilt Focus screen with Reduce Motion ON and confirm the ring no longer re-springs
      every second. State both the sim-injected and the device pass in "Verified paths".
- [ ] Sentence-case copy throughout new/renamed strings (round 10b, X-CAPS — "End sprint", not "End
      Sprint").

### FEATURE: F-F5-CalendarBlockTime — calendar access (read + write) and "Block time for a task"  [ ] NOT STARTED

**Independent of F1–F4.** Touches `Tasks/TaskDetailView.swift`, which arcs A/B/C also edit — land
after those. Nothing here exists in the codebase today: `grep -rn "EventKit\|EKEventStore"` over
`ADHD LifeOS/` returns zero hits, so this is new, not a reversal.

**What E chose:** round 4b, verbatim: *"Yes - add BOTH read-AND-write capabilities."* Round 4c:
**"Block time for a task"** — *"From a task, the user picks a free slot and it becomes an event; the
event opens the task. The app writes ONLY to its own 'ADHD LifeOS' calendar and never edits or
deletes the user's existing events. The purpose string says exactly that."* Build notes from round
4b: *"Read + write is FULL calendar access: `requestFullAccessToEvents` on 17+,
`requestAccess(to: .event)` on the 16 floor (§7.1)... asked in context, never at launch."* —
**the floor half of that is void since `F-Floor18`**: `requestFullAccessToEvents` (17) is below the
18 floor, so it is the ONLY request and needs no gate.

**The shape — this is mostly new construction, so cite the seams to reuse rather than existing
lines to edit:**
- **Permission seam:** follow `Focus/FocusNotificationPlanning.swift:88-97`'s
  `FocusNotificationScheduling` convention — a narrow `CalendarAccessing` (or similarly named)
  protocol with a real `EKEventStore`-backed implementation and a fake for tests, per CLAUDE.md's
  "Adapters depend on a per-feature protocol, never on the concrete SDK type directly" rule (the
  Firebase-adapter rule, generalised — same reasoning applies to any system SDK singleton).
  `Settings/NotificationCenterAuthorizationReader.swift` /
  `Settings/NotificationAuthorizationReading.swift` is the second precedent (an OS-permission
  reader with its own protocol seam).
  `EKEventStore().requestFullAccessToEvents { granted, error in }` — ungated, one path
  (`F-Floor18`; the `requestAccess(to: .event)` floor branch is no longer needed).
- **Info.plist purpose strings** — add beside the existing pattern in
  `ADHD LifeOS.xcodeproj/project.pbxproj:622-627` (and the duplicate Release block `:665-670`):
  `INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription` (the full-access key; the legacy
  `NSCalendarsUsageDescription` was only read below iOS 17 and is not needed at the 18 floor).
  The string must say the app writes only to its own calendar and
  never touches the user's existing events (round 4c's exact promise) — do not reuse the location
  string's tone (`:623-624`) verbatim, write one for calendars specifically.
- **"Privacy-manifest line"** (round 4b's phrase): this repo has **no `PrivacyInfo.xcprivacy` file
  at all** (checked, zero hits for `xcprivacy`/`NSPrivacyAccessedAPICategory` anywhere in the
  project) — none of the app's existing permissions (camera, location, microphone, photos, speech)
  have one either. EventKit is not on Apple's current Required-Reason API list, so this is likely
  satisfied by the Info.plist purpose strings alone. **Confirm this during the build** (Apple's
  list changes) rather than trusting this spec — if a manifest entry turns out to be required,
  it is new ground for this project and worth flagging to E regardless.
- **The app's own calendar:** create-if-missing an `EKCalendar` named "ADHD LifeOS" under
  `EKEventStore.defaultCalendarForNewEvents`'s source (or the first writable local/iCloud source),
  store its `calendarIdentifier` (UserDefaults, device-local — same tier as
  `UserDefaultsFocusSprintStore`, not Firestore). All writes target this calendar only; never call
  any EventKit method against a calendar the app did not create.
- **A new task field** to remember which event a task is blocked to (so "the event opens the task"
  works both ways): e.g. `calendarEventId: String?` on `TaskItem`/`TaskDetailModels` — follow the
  existing optional-field convention (`focusDurationSeconds`, `:22` in `TaskModels.swift`) and the
  snake_case tasks convention (`calendar_event_id` in `FirestoreFieldPayloads.swift`, beside
  `nudges_count`'s old spot). The generic `collection in [...]` allow in `firestore.rules` already
  covers a new field on an existing per-user document — **no `firestore.rules` change, no E
  republish**, confirm this reading during the build rather than asserting it as fact.
- **Deep link, so "the event opens the task" is real from the system Calendar app too:** a URL
  scheme in the created `EKEvent`'s `.url` or `.notes` pointing back into the app
  (`adhdlifeos://task/<uuid>` — check whether a task-opening deep link already exists; this
  session's reading found only the widget/auth cases in `AppDeepLink.swift`, so a task route is
  likely new and belongs in this block too).

**Tests — none found by grep** for "EventKit", "EKEventStore", "Calendar" (feature sense) in
`ADHD LifeOSTests/` — this is new-feature TDD from a blank slate, not a reversal. Write the
permission-seam tests against a fake first (mirroring `FakeFocusActivityMirroring.swift`'s shape),
then the "creates the calendar once, never twice" test, then the free-slot/event-creation logic as
pure functions over a supplied list of busy periods (no EventKit call in the pure test).

**Acceptance criteria — deltas:**
- [ ] UI-level EventKit calls are effectively unverifiable on the sim without a signed-in Calendar
      account — say so, and rely on the seam tests plus a device check.
- [ ] `screenshots/calendar-block-time/` once Step 0 below is answered and a design exists to
      photograph (not owed until then).
- [ ] Device check on E's phone: the real permission dialog, a real calendar write, and "tap the
      calendar event, land on the task" — none of this is simulator-verifiable.
- [ ] No `#available` site touched (the permission request has one path at the 18 floor) — no
      "Verified paths" line owed, say so.
- [ ] Confirm the `firestore.rules` reading above empirically before claiming "no rules change".

**Step 0 — ask E (this whole block is gated on it):** round 4c names WHAT calendar write means
("pick a free slot, it becomes an event") but there is **no rendered design and no chosen option**
for the slot-picker UI itself — unlike every other block in this arc, which points at a board E
already chose from. Per `CLAUDE.md`'s `build-in-a-fresh-session` memory and §7.6 ("check each
option against `apple-design` before design options go to E"), this needs a Step 0 render pass —
2–3 slot-picker shapes (e.g. a list of "Today 14:00–14:30 free", a mini day-timeline with tappable
gaps, or a simple duration-then-earliest-slot one-tap) — **before** this block is built, not
inside it. Recommend: the build session stops after the permission seam and the calendar-creation
logic (both fully spec'd and TDD-able right now) and hands the picker UI to a Step 0 render pass,
the same shape `round-7b-composer-layouts` used for the composer.

---

## Arc A — Copy and colour jobs

Source: `handoff/SESSION-OPENER-adhd-ux-audit-design.md` rounds 6, 8, 9, 10a, 10b; findings in
`handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md`. Pure copy/colour-token edits — **no schema, no new
palette values** (Q6; round 9 routed ALL contrast to the held colour arc — do not touch contrast).
Four blocks, build in order (A2 depends on A1's rename landing first at one shared line; A4 depends
on A3's Appearance-footer edit landing first). Each is one reviewable unit.

---

### FEATURE: F-A1-WordsAndStats — round 8's words: "Still open", the header count, quiet areas, inbox stats  [ ] NOT STARTED

**What E chose** (round 8 + follow-up, `SESSION-OPENER-adhd-ux-audit-design.md:378-422`):
- *"Still open"* (Recommended) replaces "Overdue" on rows. *"Where the row sits in the list must
  say that, and the build owns it."*
- *"Remove it; the rows say it"* (Recommended): "12 OPEN · 2 OVERDUE" → "12 open"; "0 OVERDUE" never
  prints.
- *"Neutral 'last closed Tue', no colour"* (Recommended) for quiet areas.
- *"Framed as progress"* (Recommended): section re-headed "This week" (was "INBOX HEALTH"); its bars
  + *"2 sorted · 7 captured this week"* lead with what was DONE; header reads *"5 to sort"*, no
  longer orange; gone: the age line and *"decide or bin them"*; the S1 counterweight "survives,
  reframed done-first."

**The shape (verify, do not trust):**

*1. "Still open"*
- `Tasks/TaskRowPresentation.swift:72` `if dueDay < today { return "Overdue" }` → `return "Still open"`.
- `LifeAreaDetail/AreaTaskRow.swift:92` `parts.append("Overdue")` → `parts.append("Still open")`.
  (This view's `metaLine` re-derives the same overdue/due-today logic inline rather than calling
  `TaskRowPresentation` — not this arc's job to consolidate, flag it in the report.)
- E's carried note requires the ROW POSITION to say a task was due earlier, since the word alone no
  longer does. `Tasks/MomentumTaskBuckets.swift:104-118` `sorted(_:)` sorts by priority then effort
  then insertion order, with no due/overdue distinction. **Overdue must be the PRIMARY sort key, not
  a same-priority tiebreak** — a tiebreak leaves a P2 task due last Tuesday sitting below every P1
  due today, which says nothing about it being overdue (E's "must say that" requirement, unmet).
  Thread `today`/`calendar` into `sorted(_:today:calendar:)` (called from `group`, `:44-51`, which
  already has both in scope) and sort `(!isOverdue, priority, effort, index)` — every overdue task
  first (in priority order among themselves), then every due-today task (in priority order).
  `testGroup_withinBucket_priorityThenShortestEffort` (`:97-108`) stays green either way — its
  fixtures are all due today, none overdue.

*2. Header count*
- `Tasks/MomentumTaskBuckets.swift:56-68` `headerLine` — drop the `overdue` computation and the
  `" · N overdue"` suffix: `return "\(open.count) open"`.

*3. Quiet areas*
- `Home/MomentumScoreboard.swift:257-295` — collapse the two "quiet" branches (`gap >= 7` "quiet all
  week", `gap > 3` "quiet since \(weekday)") into one neutral phrase using the house day-format
  switch already at `Tools/ToolsRoutinesCatalog.swift:188-207` (`lastRunPhrase`: `EEE` under 7 days,
  `MMMd` at/after): `"\(closedThisWeek) of \(total) closed — last closed \(phrase)"`, tone `.plain`.
  Delete the `.quiet` case from `AreaStatusTone` (`:257`).
- `Home/AreaMomentumList.swift:82-88` and `Areas/AreasComponents.swift:181-187` `statusColor` — drop
  the now-invalid `case .quiet: return Color("StateWarn")` branch (compiler forces this once the
  case is gone).

*4. Inbox stats*
- `Capture/CaptureInboxSections.swift:119` `Text("Inbox health")` → `Text("This week")`.
- `Capture/CaptureInboxSections.swift:126` `Text("Captured this week: \(health.captured). Cleared:
  \(health.cleared).")` → `Text("\(health.cleared) sorted · \(health.captured) captured this week")`.
- `Capture/CaptureInboxSections.swift:129-134` — delete the `sittingLine` block (the StateWarn
  "Four are still sitting here…" text) entirely.
- `Capture/CaptureInboxSummary.swift:120-128` — delete `sittingLine(count:)` (now unused).
- `Capture/CaptureInboxSummary.swift:52-66` `weeklyCounterweight` — reorder/reword to
  `"\(cleared) sorted · \(captured) captured this week"`.
- `Capture/CaptureInboxSummary.swift:34-43` `oldestLine` — **keep the function.** It has a SECOND
  consumer the design record doesn't name: `CaptureInboxSections.swift:22-28` builds the top
  decision card's age chip from it. Remove only the header's own call site,
  `CaptureInboxSections.swift:233-238` (the `oldestLine` `Text` under the breakdown line).
- `Capture/CaptureInboxSections.swift:204-222` `summaryHeader`'s big-count block — keep the
  two-`Text` shape (count + word), change `"left"` → `"to sort"`, change the count's
  `.foregroundStyle(Color("StateWarn"))` to a neutral label colour (`Color("LabelPrimary")`).

**Step 0 — ask E:** does the top capture card's age chip ("18 hours old",
`CaptureInboxSections.swift:22-28`, built from the SAME `oldestLine` function) also go, under the
"none tallies what was missed" principle? Options: **(a) keep it** — it names a fact about the ONE
item in front of you, not backlog pressure, and the record's "Gone" bullet only names the header's
age line; **(b) remove it too**, for full consistency with "framed as progress." Recommend (a).

**Stale doc comments to ANNOTATE, not delete** (history, per house convention): `MomentumTaskBuckets.swift:54-55`
("4 open · 1 overdue" — the header's old shape); `MomentumScoreboard.swift:108` ("input to the
'quiet since …' clause"); `CaptureInboxSections.swift:111-112` ("the backlog said out loud in
warn" — no longer warn-toned) and `:231-232` (the M5 ageing-counterweight comment, which now
describes only the top-card chip, not the header).

**Tests that must be REVERSED, not deleted:**
- `TaskRowPresentationTests.swift:40-53` `testMetaLine_open_areaPriorityAndDuePhrase` — line 51
  `"💼 Work & Career · P1 · Overdue"` → `"… · Still open"`.
- `TasksV3PresentationTests.swift:29-38` `testHeaderLine_countsOpenAndOverdue` — `"3 open · 1
  overdue"` → `"3 open"`.
- `TasksV3PresentationTests.swift:42-50` `testHeaderLine_singularAndClean` — `"1 open · 0 overdue"`
  → `"1 open"`; `"0 open · 0 overdue"` → `"0 open"`.
- `MomentumScoreboardV3Tests.swift:110-118` `testAreaStatusLine_quietSinceNamesTheWeekday` — text
  becomes `"1 of 2 closed — last closed Sun"` (5-day gap, `EEE`), tone `.plain`.
- `MomentumScoreboardV3Tests.swift:120-127` `testAreaStatusLine_quietAllWeekWhenTheGapOutrunsTheWindow`
  — text becomes `"0 of 2 closed — last closed Aug 5"` (9-day gap, `MMMd`; mirror
  `ToolsRoutinesLastRunTests.swift:79`'s `"last run Aug 19"` convention), tone `.plain`.
- `CaptureInboxSummaryTests.swift:41-54,58-68,71-78,82-89` — 4 `testWeeklyCounterweight_*` tests
  pin `"N captured · M cleared this week"`; reorder/reword to `"M sorted · N captured this week"`.
- `CaptureWeekCounterweightTests.swift:37-49` `testLoad_populatesTheWeekCounterweightLine` —
  `"1 captured · 1 cleared this week"` → `"1 sorted · 1 captured this week"`.
- `CaptureInboxHealthTests.swift:56-70` `testSittingLine_speaksSmallNumbersAsWords` — **delete**
  (function gone); update the class doc comment (`:9-10`) which still names "the sitting line."
- Not touched (function survives): `CaptureInboxSummaryTests.swift:129-155`
  `testOldestLine_readsHoursThenDays`, `testOldestLine_nilWhenNothingIsWaiting`.
- None found by grep for: "Inbox health" (view body only), the new "to sort"/neutral header colour
  (view body only, no unit test reads `.foregroundStyle`).

**Acceptance criteria**
- [ ] RED first: apply the reversed tests above against today's code; a red-check that restores the
      pre-change files and counts the failures (expect the ~9 reversed assertions plus the new
      overdue-sort test).
- [ ] New test: `MomentumTaskBucketsTests` — overdue-before-due-today at equal priority (verify
      `testGroup_withinBucket_priorityThenShortestEffort`, `:97-108`, still passes unchanged — its
      fixture has no overdue tasks).
- [ ] SwiftLint 0, full suite green, build green — paste the real output.
- [ ] `screenshots/` folder: Tasks tab (Still open + overdue-first ordering, no header count),
      an Area card (neutral "last closed"), Capture Inbox ("This week", "5 to sort" non-orange) —
      light + dark. README per house standard.
- [ ] `apple-design` review owed (§7.6) — four visible copy/behaviour changes. Cite `writing.md`
      and `color.md › Best practices` (StateWarn no longer means "quiet area").
- [ ] No `#available` site touched; no Reduce Motion site touched — RM-on pass not owed, say so.

**Dependencies:** none upstream. A2 depends on this block's rename of "Inbox health" → "This week"
landing first (A2 recolours that same line).

---

### FEATURE: F-A2-ColourJobs — round 9's four colour jobs  [ ] NOT STARTED

**What E chose:** *"Approve all four"* (Recommended), `SESSION-OPENER-adhd-ux-audit-design.md:463-474`.

**The shape (verify, do not trust):**

*Job 1 — blue off non-tappable labels* (record names TOMORROW, "WHERE DOES THIS LIVE?", "THEN";
the same X-COLOR finding, §I, also names "INBOX HEALTH" — include it as the same defect, now
"This week" after A1):
- `Tasks/MomentumTaskBuckets.swift:70-79` `headerToneAssetName` — `"momentum-tomorrow": "AccentColor"`
  → `nil` (the doc comment at `:71` already says "`nil` keeps the plain secondary voice"; the caller,
  `Tasks/TaskListView.swift:274-277`, already falls back to `Color("LabelSecondary")` on `nil`).
- `Capture/CaptureInboxSections.swift:79-81` `Text("Where does this live?")…foregroundStyle(Color.accentColor)`
  → `.foregroundStyle(.secondary)`.
- `Capture/CaptureInboxView.swift:344-346` `Text("Then")…foregroundStyle(Color.accentColor)` →
  `.foregroundStyle(.secondary)`.
- `Capture/CaptureInboxSections.swift:119-121` "This week" (renamed by A1) →
  `.foregroundStyle(.secondary)`. **Verify A1 has landed and the string reads "This week", not
  "Inbox health", before touching only the colour here.**

*Job 2 — raw `.green`/`.orange`/`.red` → StateGo/StateWarn/StateRisk:*
- `Settings/NotificationPermissionState.swift:70-75` `tint` — `.green`(×3 cases) → `Color("StateGo")`;
  `.orange` → `Color("StateWarn")`; `.red` → `Color("StateRisk")`; `.unknown: .secondary` unchanged.
  Rewrite the doc comment at `:67-68` ("adaptive system colours… per §4") — the record says *"E
  chose consistency over that reading."*
- `Focus/WeeklyFocusSummaryWidget.swift:138,141` — both `.green` → `Color("StateGo")`.
- `Focus/FocusSprintPresentation.swift:88` `FocusCheckpointDotState.color`, `.reached: return .green`
  → `Color("StateGo")`.
- `FocusTimerWidget/FocusActivityComponents.swift:115` (widget target) `fillColor`, `.reached: return
  .green` → `Color("StateGo")`.
- **Dependency/verify first:** round 4a (arc F) retires the mid-sprint checkpoint dots ("Heads-up
  replaces checkpoints"). If arc F lands first, `FocusCheckpointDotState` and its widget mirror may
  already be deleted — confirm both still exist before editing; if gone, this job is only the first
  two sites.

**Step 0 — ask E (or take the recommendation):** the brief says "spec SHARING the colorset (target
membership) rather than copying." That does not fit the code: the app and the widget extension keep
**two separate asset catalogs** (`ADHD LifeOS/Assets.xcassets`, `FocusTimerWidget/Assets.xcassets`),
and the widget's catalog already independently duplicates ~40 colorsets, including `StateGoVivid`,
`OnStateGo` and `StateRisk` — just not plain `StateGo`. There is no Swift-file-style "membership
exception" mechanism for asset catalog entries. **Recommend:** copy `StateGo.colorset` verbatim
(light `#0AA84E` / `0x0A 0xA8 0x4E`, dark `#30D158` / `0x30 0xD1 0x58`, from
`ADHD LifeOS/Assets.xcassets/StateGo.colorset/Contents.json`) into
`FocusTimerWidget/Assets.xcassets/`, matching the app's existing duplication pattern — this copies
an EXISTING value into a second catalog, not a new one (Q6 intact). Add a drift-guard test that
reads both `Contents.json` files from disk and asserts they are byte-for-byte equal, so a future
colour-arc edit to one catalog is caught rather than silently drifting. **Alternative, not
recommended:** merge the two catalogs into one shared target-membership catalog — a colour-arc-scale
restructure, out of scope while that arc is HELD.

*Job 3 — "Nudges Due" flame neutral:*
- `Home/DailySummaryView.swift:219-232` `metricStrip` — the "Nudges Due" `DailyMetricCard`'s
  `tint: Color("StateRisk")` (`:223`) → `Color("LabelSecondary")` (neutral; matches round 8's
  "last closed" neutral choice). "Open Tasks" (StateGo), "Life Areas" (AreaAdminVivid) and "Ideas
  Offloaded" (StateWarn) are untouched — not part of this job.

*Job 4 — disabled "Sorted" reads as disabled beside enabled "Skip":*
- `Capture/PrimaryActionButtonStyle.swift:126-155` `SortedButtonStyle` — its not-ready face is
  pixel-identical to Skip's `MomentumBorderedButtonStyle` (`Home/MomentumScoreboardViews.swift:62-78`):
  same `.callout.weight(.medium)`, same `Color("LabelSecondary")` foreground, same
  `strokeBorder(Color.cardBorder, lineWidth: 1)`, same 48pt / 14pt radius. Add
  `@Environment(\.isEnabled) private var isEnabled` and dim the whole not-ready face, e.g.
  `.opacity(isEnabled ? 1 : 0.45)` — no new colour token (Q6), matches the standard iOS
  dimmed-disabled-control convention. (`isEnabled` and `isReady` are always equal at the one
  call site, `.disabled(!isReady)` in `CaptureInboxSections.swift:198` — reading the
  environment is fine, but the style could equally key off the `isReady` parameter it already
  has; say which the build chose.) **Pre-empt the apple-design review:** a dimmed DISABLED
  control is exempt from the 4.5:1 text-contrast bar (WCAG 1.4.3 excludes inactive UI
  components) — name this in the report so it is not mistaken for a colour-arc finding.

**Tests that must be REVERSED, not deleted:** none found by grep — no test asserts `.tint` on
`NotificationPermissionState`, `.color` on `FocusCheckpointDotState`, or any `.foregroundStyle`
literal in the view files above.

**New tests (RED first, nothing to reverse):**
- One string-based call-site test (the `ModernAPIPolicyCallSiteTests` pattern: read source from
  disk, assert absence of a token) covering all four job-2 files — this is the only way
  `FocusTimerWidget/FocusActivityComponents.swift` gets checked at all, since it is NOT one of the
  five widget files compiled into the unit-test host (CLAUDE.md coverage section) and so cannot be
  exercised by a normal `XCTAssertEqual`.
- `FocusCheckpointDotState` (app side): `XCTAssertEqual(FocusCheckpointDotState.reached.color,
  Color("StateGo"))`.
- The `StateGo.colorset` drift-guard test above.
- `MomentumTaskBuckets.headerToneAssetName(customId: "momentum-tomorrow")` → `XCTAssertNil` (was
  `"AccentColor"` in `TasksV3PresentationTests.swift:53`, reversed here, not in A1).

**Acceptance criteria**
- [ ] RED first (the reversed `headerToneAssetName` assertion plus every new test above); red-check
      restoring pre-change files, count failures.
- [ ] SwiftLint 0, full suite green, build green (app target AND `FocusTimerWidgetExtension`) —
      paste real output.
- [ ] `screenshots/`: Tasks (TOMORROW grey), Capture Inbox ("Where does this live?", "Then", "This
      week" all non-blue), Week review (neutral flame), Capture Inbox top card (disabled Sorted vs
      Skip) — light + dark. The Live Activity / Dynamic Island checkpoint dot needs a DEVICE or
      widget-preview capture, not a simulator screenshot of the app.
- [ ] `apple-design` review owed (§7.6) — cite `color.md › Best practices` ("avoid the same colour
      meaning different things" — StateRisk no longer doubles as "neutral metric" and "danger").
- [ ] No `#available` site touched; no Reduce Motion site touched — RM-on pass not owed, say so.

**Dependencies:** lands after F-A1 (job 1's fourth site). Verify against arc F before job 2's
checkpoint-dot sites (see note above).

---

### FEATURE: F-A3-JargonCapitals — round 10b's words, round 6's fan copy, the missed inbox line  [ ] NOT STARTED

**What E chose:** *"Approve all"* (jargon, round 10b), *"Tasked"* (Promoted rename), *"Sentence case
everywhere"* (capitals), *"Captures wait here to be sorted"* (the missed item), *"Drop the
explanations"* (round 6). `SESSION-OPENER-adhd-ux-audit-design.md:303-322,518-565`.

**Excluded — owned elsewhere, do not touch here:**
- Focus sprint Details strings ("Deep entry", "Sprint target 15m · Logged on finish", "1 of 15 min
  logged") — `Focus/FocusSprintTimelineCard.swift:202,212`, `Focus/FocusSprintDetailView.swift:167`
  — **arc F**.
- The Close button's "makes today count" (`Tasks/MomentumTaskContext.swift:27`) and Today's streak
  lines (`Home/MomentumScoreboard.swift:246-252`, `Home/MomentumScoreboardViews.swift:145-176`) —
  **arc E**.
- Today's inbox-peek copy (`Home/HomeAccessoryStrips.swift:55`) leaves with the inbox peek — **arc E**.
- The Settings Notifications card's ~310pt gap (SET-01) and its missing in-place "Allow
  notifications" button (SET-02), and Tasks' "0 open" loading state (TASKS-07) — layout/behaviour
  fixes named in round 10a but not copy — **arc G**. (F-A4 edits this same card's FOOTER text; say
  in that block's report that the layout fix is separate and unblocked either order.)

**The shape (verify, do not trust):**

*Round 6 — drop the explanations:*
- `Capture/CaptureFanOverlay.swift:36-46` — delete the subtitle
  `Text("Pick how it arrived. Everything goes to the inbox — you decide what it is later.")` block.
  Keep the title `Text("What just landed in your head?")`.
- `Capture/QuickCaptureView.swift:115` — delete
  `Label(CaptureComposerCopy.footer(for: kind), systemImage: "lock")`.
- `Capture/CaptureFan.swift:100-109` — delete `CaptureComposerCopy.footer(for:)` (now unused). This
  also resolves CAPT-04 (fan said "everything goes to the inbox," the Task tile's footer said
  "skips the inbox" — both sentences are gone).

*Jargon renames (file:line, current → new):*
- `Places/PlaceEditorView.swift:248-252` footer: "…one of the \(PlaceMonitoringCapacity.limit)
  monitoring slots iOS gives the whole app…nudge only fires when this place has open At-Place
  tasks." → "…iOS lets the app watch \(PlaceMonitoringCapacity.limit) places…a nudge only fires
  when there are open tasks for this place." (keep the interpolated constant, do not hardcode
  "20"; the phrasing avoids repeating "this place… this place").
- `Places/PlaceActionsSection.swift:108-112` footer: "…it uses a monitoring slot, like a nudge…" —
  align to the same "watch places" phrasing; no second verbatim string is in the record — propose,
  flag as build-verified starting point.
- "session" → "sprint": `Home/MomentumScoreboardViews.swift:290` ("Start session"/"Start another
  session"); `Home/MomentumScoreboard.swift:212` (`"1 session"`/`"\(count) sessions"`);
  `Focus/FocusSprintPresentation.swift:34-36` `ActiveGoalSprintState.title` ("Start Session"/
  "Session Active"/"Session Paused"). **`ActiveGoalSprintState` has ZERO call sites in the app
  target** (grepped) — the live Home hero button reads `showsStartSession`/`onStartSession`
  (`MomentumScoreboardViews.swift:285-296`) directly, not this enum. It is dead code (the
  recurring "dead shared component" pattern). Rename it anyway, per "everywhere," and say so in
  the report — this may also be entirely rebuilt by arc E's round-5a hero redesign ("Start N min").
  Also `Home/MomentumScoreboardViewsPreviews.swift:30` `"1 session · 12 min today"` (a `#Preview`
  fixture literal, not production copy — update for consistency).
- "To triage" → "To sort": `Capture/CaptureInboxService.swift:30` (`Filter.title`);
  `Capture/CaptureInboxSummary.swift:23` (`headline`'s `.unprocessed` branch — dead code today,
  see A1's summaryHeader note, but rename for consistency); `Capture/CaptureInboxSummary.swift:150`
  (`doorLine`, "waiting to triage" → "waiting to sort").
- "Promoted" → "Tasked": `Capture/CaptureInboxService.swift:32` (`Filter.title`);
  `Capture/CaptureInboxSummary.swift:27` ("N promoted"/"Nothing promoted yet" → "N tasked"/"Nothing
  tasked yet" — a consequential rename found by grep, not verbatim-named in the record, needed so
  the tab's header agrees with its own segment label); `Capture/CaptureRowComponents.swift:286`
  (`CapturePromotedChip`'s `Label("Promoted", …)` → `"Tasked"`; the struct's own name is now stale —
  flag only, do not rename the type in a copy-only arc).
- "Decide later" / "No life area" → "None": `Capture/QuickCaptureComponents.swift:188`;
  `Tasks/TaskCreateView.swift:141` (this file may be folded into arc D's unified composer — the
  rename still applies to today's code); `Theme/ComposerChips.swift:256,271` (both are `#Preview`
  blocks only, not production call sites — update for consistency); `Journal/LogComposerView.swift:168`.
- "Workshop" goes: `Tools/ToolsView.swift:108-118` — delete the `Text("Workshop")` line entirely,
  leaving only `Text("Tools")` as the large title.
- Append-only line: `Journal/LogComposerCopy.swift:13` `footer` — "Entries are append-only — saved
  means saved." → "Entries can't be changed after saving." (the record notes this line itself goes
  once journal editing ships — a gaps-list item, not this arc's job).
- Settings appearance jargon: `Settings/AppearancePreference.swift:49` `.system` case — "Follows
  your device. The palette carries light and dark variants for every token." → "Follows your
  device." (drop the second sentence; do not move it behind a disclosure — after this edit every
  case is already ≤1 sentence, so A4 owes this footer nothing further).

*Sentence case (X-CAPS):*
- `Capture/CaptureFan.swift:117` `ctaLabel(for: .task)`: "Add to Today" → "Add to today".
- `Tasks/TaskDetailView.swift:112`: "Keep Editing" → "Keep editing".
- `Tasks/TaskDetailView.swift:122`: "Delete Task" → "Delete task".
- `Tasks/TaskDetailFormSections.swift:194`: "Delete Task" → "Delete task".

*The missed item:*
- `Capture/CaptureInboxView.swift:283-293` `emptyMessage`, `.unprocessed` case (`:285-287`):
  "Nothing waiting to be triaged. Anything you capture lands here first, so your head doesn't have
  to hold it." → "Captures wait here to be sorted."

**Tests that must be REVERSED, not deleted:**
- `CaptureFanTests.swift:63-80` `testComposerCopy_perKindVoice` — delete the three
  `CaptureComposerCopy.footer(for:)` assertions (`:68-79`, function removed); change line 67's
  `"Add to Today"` → `"Add to today"`.
- `FocusLoggedTodayTests.swift:46-53` — line 51 `"1 session today"` → `"1 sprint today"`.
- `FocusLoggedTodayTests.swift:54-63` — line 62 `"2 sessions · 35 min today"` →
  `"2 sprints · 35 min today"`.
- `FocusLoggedTodayTests.swift:85-91` — line 90 `"1 session · 1 min today"` →
  `"1 sprint · 1 min today"`.
- `FocusSprintPresentationTests.swift:18-24,26-33,36-43` — three `testHeroAction_*` tests pin
  `"Start Session"`/`"Session Active"`/`"Session Paused"` → `"Start Sprint"`/`"Sprint Active"`/
  `"Sprint Paused"`.
- `CaptureInboxSummaryTests.swift:93-99` `testHeadline_countsWhatIsWaiting`,
  `testHeadline_singularAtOne` — `"3 to triage"`/`"1 to triage"` → `"3 to sort"`/`"1 to sort"`.
- `CaptureInboxSummaryTests.swift:110-114` `testHeadline_onThePromotedTab_describesWhatWasTriaged`
  — `"3 promoted"`/`"1 promoted"`/`"Nothing promoted yet"` → `"3 tasked"`/`"1 tasked"`/`"Nothing
  tasked yet"`; rename the test to `…describesWhatWasTasked` if the build session agrees.
- `CaptureSortAndUndoTests.swift:279-282` `testDoorLine_countsWhatIsWaiting` — `"3 waiting to
  triage"`/`"1 waiting to triage"` → `"…waiting to sort"`.
- `LogComposerCopyTests.swift:22-28` `testGuidanceAndFooter` — `"Entries are append-only — saved
  means saved."` → `"Entries can't be changed after saving."`.
- None found by grep for: "Decide later", "No life area", "monitoring slots", "At-Place tasks",
  "Workshop", "WORKSHOP" (source spells it "Workshop"), "Delete Task", "Keep Editing" (beyond the
  one CaptureFanTests hit above), "Nothing waiting to be triaged" (only a UI-test existence check
  on `captureInboxEmptyState`, never its text), `AppearancePreference`'s `.explanation` text
  (`AppearancePreferenceTests.swift` tests mapping/storage only).

**Acceptance criteria**
- [ ] RED first: apply every reversed assertion above; red-check restoring pre-change files, count
      failures (expect ~11 reversed assertions + 3 deleted).
- [ ] SwiftLint 0, full suite green, build green — paste real output.
- [ ] `screenshots/`: capture fan (no subtitle), a Note/Task composer (no footnote), Places editor +
      actions footers, Capture Inbox segments ("To sort · Sorted · Tasked"), empty inbox line,
      Settings Appearance row, a task detail's Delete/Keep-editing alert — light + dark.
- [ ] `apple-design` review owed (§7.6) — cite `writing.md › Best practices` (one capitalisation
      style per element type) and `buttons.md › Content`.
- [ ] No `#available` site touched — copy-only edits on `PlaceEditorView`/`PlaceActionsSection`,
      which carry no gate since `F-Floor18`; no "Verified paths" line is owed. No Reduce Motion site
      touched — RM-on pass not owed, say so.

**Dependencies:** none upstream (independent of A1/A2). A4 depends on this block's Appearance-footer
edit landing first.

---

### FEATURE: F-A4-Footers — round 10a: one sentence, the rest behind "More about this"  [ ] NOT STARTED

**What E chose:** *"One sentence, the rest behind 'More about this'"* (Recommended),
`SESSION-OPENER-adhd-ux-audit-design.md:514-516`: *"Each Settings footer, and Tools' empty Routines
card, becomes one plain sentence. The full text sits behind a 'More about this' disclosure
(SET-03, TOOLS-01)."*

**The shape (verify, do not trust):**

New shared component (no house pattern exists — grepped, zero `DisclosureGroup`/"More about" hits):
a small `FooterWithDisclosure(lead: String, more: String)` view for reuse across every footer below.
**Verify a `DisclosureGroup` (or an inline expand `Button`) actually renders correctly inside a
`Form`'s `footer:` closure** and that its trigger meets the 44pt floor (§3); if it renders oddly,
fall back to a plain row inside the `Section` body instead of the `footer:` slot. **This IS a new
Reduce Motion site, definitely, not conditionally** — `DisclosureGroup` animates its expand/collapse
by default. Name which §7.2 case it is (an "appears" reveal of the "more" text, so the reduced path
should fade the revealed content per `CaptureFanOverlay.swift:89-96`'s house pattern, geometry
pinned, opacity the only thing that travels) and gate it behind `accessibilityReduceMotion`.

Footers to shrink (current text unchanged as the "more" content; propose a one-sentence lead —
build session verifies the exact wording):
- `Settings/SettingsView.swift:137-145` Notifications footer (2 sentences) — lead: "This shows
  whether iOS currently allows reminders for tasks and nudges."
- `Settings/SettingsPreferenceSections.swift:81-92` "What counts as momentum" footer (4 sentences)
  — lead: "These switches change what counts toward your streak and charts."
- `Settings/SettingsPreferenceSections.swift:138-147` Focus footer (2 sentences) — lead: "The daily
  goal drives the focus charts and widget ring."
- `Settings/SettingsPreferenceSections.swift:223-245` Feedback footer (≈150 words / 17 lines, SET-03,
  the clearest case) — lead: "These control the app's own sounds, haptics, and location use."
- `Settings/AccountDeletionSection.swift:32-39` Delete Account footer — see Step 0 below.
- `Tools/ToolsRoutinesCatalog.swift:71-82` `EmptyReason.body` (35-word body, TOOLS-01) — `.noPlaces`
  lead: "Add a place first."; `.noQualifyingPlaces` lead: "Give a place \(thresholdPhrase) tap-steps
  to make it a routine." `Tools/ToolsRoutinesSection.swift:239-242` (`emptyCard`) needs the
  disclosure added to its `Text(reason.body)` line.

**Not touched:** `SettingsView.swift:112-117` Appearance footer — F-A3 already reduces
`current.explanation` to one sentence per case; nothing is left to hide.
`ToolsRoutinesCatalog.NudgesOffFooter` (`:46-52`) — a different banner (shown only when Arrival
nudges is off), not the empty-Routines card the record names; its exact text is pinned by
`ToolsRoutinesCatalogTests.swift:276-287` and must not change here.

**Step 0 — ask E:** the Delete Account footer's current text is a single safety-critical warning
("This cannot be undone.") embedded in an itemised list of what gets erased. Should the one-sentence
lead keep "This cannot be undone" always visible (never behind the disclosure), with only the
itemised list ("tasks, life areas, journal, captures, nudges, and focus history") folded away?
Recommend **yes** — hiding an irreversibility warning behind a disclosure on a destructive action is
the kind of thing `modality.md`/`buttons.md` guidance on destructive actions warns against; lead:
"Permanently deletes your account. This cannot be undone."; more: the itemised list.

**Tests that must be REVERSED, not deleted:** none found by grep — no existing test pins the exact
footer body text for any Settings section, `AccountDeletionSection`, or (per `testEveryEmptyStateIsFinishedCopy`,
`ToolsRoutinesCatalogTests.swift:231-243`) the exact `EmptyReason.body` string; that test only
asserts non-empty and that the two cases differ, so shrinking `.body` is safe as-is.

**New tests (RED first):**
- `ToolsRoutinesCatalogTests.swift`: each `EmptyReason` has a short `.body` (one sentence — assert
  it, e.g., contains at most one `.` other than inside "…") and a non-empty `.moreBody`/equivalent
  that still contains the original longer text (so nothing is silently lost — the exact original
  strings currently pinned nowhere, so pin them HERE as the "more" content).
- Equivalent short assertions for each new Settings footer's lead + full text, wherever the strings
  move into a testable `enum`/`struct` (recommended over bare `Text` literals, so this block leaves
  a testable seam behind it — flag if the build session decides bare literals are enough).

**Acceptance criteria**
- [ ] RED first: the new tests above fail against today's code; red-check restoring pre-change
      files, confirm failures are for the intended reason.
- [ ] SwiftLint 0, full suite green, build green — paste real output.
- [ ] `screenshots/`: every touched footer collapsed and expanded, light + dark — this is a NEW
      interaction pattern, so "settled by looking" applies in full.
- [ ] `apple-design` review owed (§7.6) — this adds a new UI primitive; check `sheets.md`/
      `layout.md` guidance on progressive disclosure and confirm the disclosure trigger meets the
      44pt floor (§3) and reads correctly to VoiceOver (a single combined element, not "More about
      this" plus a chevron as two).
- [ ] No `#available` site touched (`DisclosureGroup` is far below the 18 floor, no gate
      needed). **This block DOES add a new Reduce Motion site** (the disclosure's reveal) — a
      reduced-path render (sim, injected) is required, and because it is a new/changed reduced
      site, **the RM-on device pass (§7.3) is owed**: ask E to look at one expanded footer with
      Reduce Motion on and off.

**Dependencies:** lands after F-A3 (Appearance footer). Independent of F-A1/F-A2.

---

## Arc B — Accessibility. Five blocks, one reviewable unit each.

Source: `handoff/SESSION-OPENER-adhd-ux-audit-design.md` rounds 7, 7b, 9; `handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md`
§M (`apple-skills` ios `ui-review`+`accessibility-audit`), §G (Today/Areas `apple-design`), §L (composer); boards
`62`, `64`, `65`, `66`. Every `file:line` below was read in the current tree.

**Cross-arc boundaries (do not build these here):** arc F owns `.updatesFrequently` and RM-01 (sprint ring) — both
sit inside the card/sheet rebuild rounds 4b/4c replace. Arc E owns the rest of §G's HOME-01 and Home's layout
around `arrangeButton`. Arc C owns RM-02 (undo bar) and the undo capsule. Arc D owns the composer's own 48pt
chips (`Theme/ComposerChips.swift`). Arc G owns GEST-3's ↑/↓ actions and the LA's +5 min target. **No block in B
touches an `#available` site**, so none carries a "Verified paths" line unless said otherwise.

---

### FEATURE: F-B1-TouchTargets — round 7's target sizes: 48pt actions, 44pt reach on 36pt chips  [ ] NOT STARTED

**What E chose (Round 7, board `62`, "measured from the accessibility tree on the 18 Pro"):**
- *"Key targets → 'Actions that change things'. 48pt for anything that starts, closes, adds, undoes, ends or saves,
  and for each sheet's primary button. 44pt for navigation and filtering."*
- *"Filter and tag chips → '36pt look, 44pt reach' (Recommended was 44pt visible)... The composer's own chips stay
  48 (round 6)."*
- *"Corner controls → 'All to 48×48' (Recommended was 44). The Settings gear (40), Back (36), the composer's Close
  (77×36), the Tasks '+' (27×36) and Journal's 'All activity' (38×36)."* Stated default: LA's +5 min ≥44pt — owned
  by arc F, name only.

**Shape — corner controls to 48×48:**
- `Home/HomeAccessoryStrips.swift:387-395` `headerIconWell` (`.frame(width: 40, height: 40)`, behind `settingsButton`
  at `:377-383`) and `Areas/AreasView.swift:177-185` `iconWell` (identical, behind `areasSettingsButton` at
  `:167-173`) — raise both to 48 (§G HOME-02/AREAS-02: "iconWell 40×40 on both tabs").
- `Tasks/TaskDetailView.swift:148-159` `backButton` — native `ToolbarItem(.navigationBarLeading)` wrapping
  `Label("Back", systemImage:...)`, no explicit frame; board `62` measured 36×36. Grow via the label's own padding
  and re-measure per board `62`'s method on 27.0 — a native leading bar item takes no `.frame()` directly.
- `Capture/QuickCaptureView.swift:128-130`, `Tasks/TaskCreateView.swift:72-74` — both
  `ToolbarItem(.cancellationAction) { Button("Cancel"){dismiss()} }`, board `62`'s "composer's Close (77×36)". Same
  native-bar-item ceiling as Back.
- `Tasks/TaskListView.swift:114-122` — toolbar `Image(systemName:"plus")`, no `accessibilityLabel`, board `62`'s
  "27×36". Add `.accessibilityLabel("New task")` here too (shared with B3 — whichever lands second only checks it
  survived).
- `Journal/JournalAllActivityButton.swift:18-32` — glyph-only `ToolbarItem`, board `62`'s "38×36"; comment at
  `:9-13` already says the chrome is the system's, same ceiling as Back.
- **Not this one:** `Home/DailySummaryView.swift:296-299` and `Home/HomeAccessoryStrips.swift:104-114` are 40×40 /
  36×36 decorative glyph TILES, no `Button` — round 7's list is the five above only.

**Shape — filter/tag chips, keep 36pt visible + add 44pt reach:**
- `Tasks/TaskListView.swift:253-270` `filterChip`, `Tasks/TaskDetailChipsRow.swift:137-159` `tagChip` (its `:158`
  already has the `"Remove tag \(name)"` label pattern B3 reuses), `Journal/JournalView.swift:228-246` `filterChip`,
  `:250-271` `areaChip` — all `.frame(minHeight: 36)` + `.contentShape(Capsule())`, which covers only the visible
  capsule.
- **House pattern:** `Theme/AppTabBarPresentation.swift:212-219` `AppTabBarMetrics.slotHitOverflow` — negative
  vertical padding around the `contentShape` so the tap region reaches 44 without the visible chip growing. Apply
  the same idea to all four chip functions.
- **Not this block:** `ChoiceChipButtonStyle` call sites (Journal energy/mood, Home tone, `TaskCreateView.swift:127`,
  `CapturePromoteSheet.swift:132-142`, `FocusCadenceEditorCard`, `NudgeScheduleEditor`) are round 6/7b's "composer's
  own chips stay 48" family — arc D's, wherever its new composer subsumes them.

**Tests that must be REVERSED, not deleted.** Grepped both test targets for `settingsButton`, `areasSettingsButton`,
`taskDetailBackButton`, `taskCreateButton`, `frame(width: 40`, `minHeight: 36`, and the four chip function names:
every hit taps by identifier (`SignedInJourneyUITests.swift:75-78`, `AccountNameJourneyUITests.swift:82`,
`IOS27CompatSweepUITests.swift:121`, `UITestSession.swift:196-204`, `LandscapeAwayCardUITests.swift:51`) — **none
found by grep for a pinned frame-size or geometry assertion.** Growing these frames breaks no test.

**Acceptance criteria**
- [ ] RED first: for the two `iconWell`s, the repo's live house shape for "one metric, several
      readers, both pinned" — `JournalComposeDiscMetrics` (diameter + `slotHitOverflow`-derived
      overflow) plus `JournalHeaderControlsTests.swift`'s pattern of a value test AND a source-read
      call-site test proving each reader uses the constant (NOT `JournalHeaderMetrics`, which
      `F-JournalPencilDisc` deleted 2026-09-18 once nothing read it — cite the current type). For
      the three native toolbar items and the four chip functions: an XCUITest reading the
      accessibility-tree frame (board `62`'s method) asserting ≥48×48 / ≥44×44.
- [ ] Red-check by restoring the old frames; count failures; restore with `git checkout --`.
- [ ] SwiftLint 0, full suite green, build green, all pasted.
- [ ] `screenshots/touch-targets-48/` + README: light/dark, all ten sites, before/after, board `62`'s boxed-overlay
      style.
- [ ] `apple-design` review owed (§7.6) — every control is visible and interactive.
- [ ] No `#available` site touched; no RM-on pass owed (no motion here).
- [ ] Report which of the three native-toolbar controls cannot reach 48×48 within the system's own bar-item
      chrome — do not silently accept a smaller number.

**Dependencies:** none. Land first among B's blocks — B2 also touches `Tasks/TaskDetailChipsRow.swift`'s neighbour,
`Tasks/TaskRow.swift`.

---

### FEATURE: F-B2-AX3Layouts — task rows stack, sign-in segments grow, no mid-word breaks, metric labels wrap  [ ] NOT STARTED

**What E chose (Round 9, board `65`, "Approve, but keep Areas in 2 columns"):**
- *"Approved: at accessibility sizes, task rows stack (the title wraps in full, the meta sits under it, ▶ and ○
  stay trailing)."*
- *"Approved: the sign-in segments grow; they are AUTH-01 and the only route to Create account."*
- *"Approved: no button breaks mid-word ('Arran/ge'; icon only if needed)."*
- *"Approved: metric labels wrap to 2 lines (A11Y-09)."*
- *"Kept: the Areas grid stays 2 columns at every size (AREAS-01 is E's call). Names wrap inside the cards instead
  of truncating."*

**Shape — task rows stack:**
- `Tasks/TaskRow.swift:82-149` (`rowContent`) and `LifeAreaDetail/AreaTaskRow.swift:21-72` — both one
  `HStack(spacing: 8)`: effort chip + title(`.lineLimit(2)`)/meta(`.lineLimit(1)`) `VStack`, then trailing ▶/○/✓.
  §M's "what works" names them as a pair; fix both.
- **House pattern:** `Capture/CaptureRowView.swift:45-64` — `@Environment(\.dynamicTypeSize)`,
  `if dynamicTypeSize.isAccessibilitySize { VStack } else { HStack }`, dropping a purely decorative trailing glyph
  in the stacked form. Reuse the branch; drop the `.lineLimit` caps in the stacked form so title/meta wrap in full.

**Shape — sign-in segments (AUTH-01):**
- `Auth/LoginFormSections.swift:40-50` `modePicker` — native `Picker(...).pickerStyle(.segmented)`; UIKit's
  segmented control does not reflow labels at large content sizes. It is "the only route to Create account".
- `ADHD LifeOSUITests/RenderHarnessUITests.swift:139` — `app.segmentedControls["authModePicker"].buttons["Create account"]`,
  commented *"addressed through the control rather than by an identifier of their own."* **REVERSE this test if the
  native `Picker` is replaced** (`.segmentedControls[...]` only resolves a real `UISegmentedControl`).

**Step 0 — ask E:** the record says the segments "grow", not how, and no custom segmented control exists to
borrow (round 7b's composer segments are a different four-choice shape, arc D's).
1. **(Recommended) A custom two-segment control** — same look, `.lineLimit(nil)` labels that wrap/grow the track.
   Reusable if arc D later needs a two-way switch.
2. Keep the native Picker, add only `.minimumScaleFactor` — cheap, doesn't actually fix AX3 readability.
3. Two full-width stacked 48pt buttons ONLY at accessibility sizes, native Picker below — two UIs to keep in sync.

**Shape — no mid-word breaks:**
- `Home/HomeLifeAreasSections.swift:44-70` `arrangeButton` — `Label(isArranging ? "Done":"Arrange", ...)`, no
  `.lineLimit`/`.minimumScaleFactor`, wraps "Arran/ge" at AX3. Add `.lineLimit(1).minimumScaleFactor(0.7)` or
  `.labelStyle(.iconOnly)` at accessibility sizes. Button's own fix only — Home's surrounding layout is arc E's.

**Shape — metric labels wrap (A11Y-09):**
- `Home/DailySummaryView.swift:288-320` `DailyMetricCard`, label `Text` at `:309-313` is `.lineLimit(1)` +
  `.minimumScaleFactor(0.8)`. Change to `.lineLimit(2)`, drop the scale factor.

**Shape — Areas grid stays 2 columns, names wrap:**
- `Areas/AreasComponents.swift:132-136` — area-name `Text` is `.lineLimit(1)` + `.minimumScaleFactor(0.8)` (why it
  truncates to "Relatio…"). Remove the cap; the card's `minHeight:160`/`maxHeight:.infinity` (`:163-168`) and the
  paired-row equal-height comment (`:159-162`) already let it grow. `Areas/AreasView.swift:187-206` `grid` is
  untouched — 2 columns stays at every size.

**Tests that must be REVERSED, not deleted.** `RenderHarnessUITests.swift:139` (above, only if Step 0 picks option
1 or 3). Grepped `AreasGridTests.swift`, `HomeLifeAreasSectionTests.swift`, `TaskRowPresentationTests.swift`,
`TaskRowSwipeTests.swift`: pure-logic tests (bucket sorting, swipe thresholds) — **none assert `.lineLimit` or row
layout shape.** **But `CelebrationPopCallSiteTests.swift` string-anchors both row files, and this is real risk,
not a "none found":** `:34-41` (`testTheTaskRowsCloseCirclePopsFromTheCircleItself`) requires the anchor
`"private func close(poppingFrom origin: CGPoint? = nil) { Haptics.play(.taskClose)"` to appear EXACTLY ONCE in
`TaskRow.swift`; `:51-57` (`testTheLifeAreaRowsTickPops`) requires `"Button { Haptics.play(.taskClose)"` exactly
once in `AreaTaskRow.swift`; `:150-175` (`testTheCirclePopsFromItselfAndTheSwipePopsFromTheFinger`) requires
`row.contains("Button { close() }")` and three other exact substrings anywhere in `TaskRow.swift`'s flattened
source. **Do not duplicate the close/tick button declaration across the compact and stacked-AX3 branches** —
extract it into ONE shared subview/computed property both branches reference, so these three tests need no
reversal. If the build genuinely must write the button twice, reverse all three with the new anchor text.

**Acceptance criteria**
- [ ] RED first: an AX3 render/snapshot test per fixed view asserting the stacked/wrapped shape; a call-site test
      string-matching the `isAccessibilitySize` branch in `TaskRow`/`AreaTaskRow`.
- [ ] Red-check restoring old bodies; count failures; restore with `git checkout --`.
- [ ] SwiftLint 0, suite green, build green, all pasted.
- [ ] `screenshots/ax3-layouts/` + README: Tasks row and Areas card default vs AX3, sign-in segments before/after
      at AX3, Arrange button at AX3, a metric card at AX3 — board `65`'s `full/s-*-A-*` frames as "before".
- [ ] `apple-design` review owed (§7.6) — all visible fixes.
- [ ] No `#available` site touched (a custom segmented control, if built, is plain SwiftUI); no RM-on pass owed —
      the mode-swap animation itself is B4's.
- [ ] Step 0's answer recorded in the report before building AUTH-01.

**Dependencies:** land after B1 (shared file family). Independent of B3/B4/B5.

---

### FEATURE: F-B3-VoiceOverAndCharts — labels, combined elements, `.isSelected`, hidden chevrons, Smart Invert, chart descriptor  [ ] NOT STARTED

**What E chose (Round 9, "the §M list → 'Approve all, plus automated audits' (Recommended)"):**
- *"labels for the Tasks '+' ('New task'), each tag's remove ('Remove tag Work') and voice Play/Pause; the inbox
  top card and Home's Due-now rows become one element with a button trait; the promote sheet's chips carry
  `.isSelected`; the 13 decorative chevrons are hidden; the countdown gets `.updatesFrequently`."*
- *"Smart Invert: `accessibilityIgnoresInvertColors` on photos."* / *"Charts: `accessibilityChartDescriptor` on
  Week review's chart."*

**Shape — missing labels (§M A11Y-03):**
- `Tasks/TaskListView.swift:114-122` — add `.accessibilityLabel("New task")` (shared edit, see B1).
- `Capture/CaptureRowTagEditor.swift:83-93` — the per-tag "x" (`xmark.circle.fill`) has only an identifier. Reuse
  the shipped pattern at `Tasks/TaskDetailChipsRow.swift:158` (`"Remove tag \(name)"`).
- `Capture/CaptureRowComponents.swift:129-152` `VoicePlaybackButton` — only an identifier. Add
  `.accessibilityLabel(player.isPlaying ? "Pause" : "Play")`.

**Shape — combined elements + button trait (§M A11Y-02):**
- `Capture/CaptureInboxSections.swift:47-59` — `.onTapGesture` + identifier only, no trait/combine. Add
  `.accessibilityElement(children: .combine)` + `.accessibilityAddTraits(.isButton)`. **Test impact:** `:50`'s
  child identifier `captureInboxTopCardPlace` becomes unreachable once combined — grepped both test targets, no
  hit references it today. `IOS27CompatSweepUITests.swift:97` queries the OUTER id
  (`app.descendants(matching:.any)["captureInboxTopCard"]`), which survives unchanged. Say in the report that the
  child id is now unreachable by design.
- `Home/HomeMomentumSections.swift:215-224` — already has `.accessibilityAddTraits(.isButton)` (`:223`) but no
  combine. Add it. Grepped for `homeDueNowRow` in UI tests: no hit.

**Shape — `.isSelected` (§M A11Y-01):**
- `Capture/CapturePromoteSheet.swift:132-142` `chip(_:isSelected:action:)` — styled with `ChoiceChipButtonStyle`
  but no `.accessibilityAddTraits(isSelected ? .isSelected : [])`. Add it (five other call sites already do).

**Shape — 13 decorative chevrons + the closure card's checkmark:**
- `grep -c "chevron.right"` returns exactly 13 across `HomeMomentumSections.swift`, `HomeAccessoryStrips.swift`,
  `AreaMomentumList.swift`, `CaptureRowView.swift`, `Tools/ToolsRoutinesSection.swift`,
  `Areas/AreasComponents.swift:128-130`, `Tools/ToolsView.swift`, `Home/HomeWeekReviewRow.swift`,
  `Places/PlaceAppPickerView.swift`, `Places/PlaceActionAppDetailSection.swift`. Only `AreasComponents.swift:128-130`
  (a `NavigationLink`, confirmed above) was read directly — before hiding each of the other 12, confirm its
  enclosing row is itself a `Button`/`NavigationLink` or already carries `.isButton`; if a chevron is the ONLY
  navigability cue on its row, add the trait to the row first, then hide the glyph.
- `Home/MomentumScoreboardViews.swift:326-330` `ClosureCelebrationCard` — `checkmark.circle.fill` above
  `Text("... — closed")`, decorative. Add `.accessibilityHidden(true)` HERE ONLY. **Do not touch** `:276`'s
  `checkmark.circle.fill` — that one is inside `Label("Close it", ...)`, a real button, not decorative.

**Shape — `.updatesFrequently` — NAMED, OWNED BY ARC F, not built here:**
`Focus/FocusSprintDetailView.swift:160-165` and `Focus/FocusTimerBarContent.swift:197-199` both need
`.accessibilityAddTraits(.updatesFrequently)`; both sites sit inside arc F's round 4b/4c rebuild.

**Shape — Smart Invert:**
- `Capture/CaptureRowComponents.swift:238` (lightbox `AsyncImage` `.success` branch) and
  `Capture/QuickCaptureComponents.swift:301-306` (composer photo preview) — add
  `.accessibilityIgnoresInvertColors(true)` to both. Grep `Image(uiImage:`/`AsyncImage(url:` during the build for
  any other photo surface (§M's "zero app-wide" makes these two a floor, not the whole list).

**Shape — `accessibilityChartDescriptor`:**
- `Home/WeekReviewView.swift:89-108` `barsCard` — hand-drawn `Capsule()` bars, each already labelled
  (`.accessibilityElement(children:.ignore)` + `"\(day.0), \(day.1) closed"` at `:104-106`). Add an
  `AXChartDescriptor` (one series, day → closed count, from `review.dayLabels`/`.dayCounts`) via the generic
  `.accessibilityChartDescriptor` modifier (not Swift-Charts-only) for the audio-graph rotor action, additive to
  the per-bar labels. **Not touched:** `Focus/ProductivityTrendChart.swift`/`WeeklyFocusSummaryWidget.swift` are
  pre-arc-E charts due to be dropped by round 3's "one bar chart in Week review" — don't add there.

**Tests that must be REVERSED, not deleted.** Covered inline above — only `captureInboxTopCardPlace`'s
reachability changes, and nothing references it today.

**Acceptance criteria**
- [ ] RED first: unit/call-site tests for each label string, each `.isButton`/`.combine` pair, the `.isSelected`
      trait, the 14 `.accessibilityHidden(true)` sites, the two `accessibilityIgnoresInvertColors` sites; a unit
      test for the `AXChartDescriptor`'s series against `WeekReviewView`'s data.
- [ ] Red-check restoring old code; count failures; restore with `git checkout --`.
- [ ] SwiftLint 0, suite green, build green, all pasted.
- [ ] No `screenshots/` owed — every change is VoiceOver/Smart-Invert/audio-graph, proved by unit tests, not by
      looking.
- [ ] `apple-design` review owed (§7.6), Lens 1 — VoiceOver's spoken output is what a VoiceOver user "feels".
- [ ] No `#available` site touched; no RM-on pass owed (nothing here reads Reduce Motion).

**Dependencies:** shares the Tasks "+" label edit with B1 (whichever lands second checks the other's edit
survived). Otherwise independent.

---

### FEATURE: F-B4-ReduceMotionSwaps — Daily Summary and sign-in state swaps get a Reduce Motion fade  [ ] NOT STARTED

**What E chose (Round 9, same approved §M list):**
- *"Reduce Motion: the sprint ring stops re-springing every second (§7.2's continuous case, `nil`, as
  `FocusTimerBarContent` already does); the undo bar fades in instead of sliding (§7.2's 'appears' case); the
  Daily Summary and sign-in swaps are covered too; each ... owes E's RM-on phone pass when built (§7.3)."*
- RM-01 (sprint ring) is **arc F's** (`FocusSprintDetailView.swift:151` → `MomentumScoreboardViews.swift:39`'s
  ungated spring). RM-02 (undo bar) is **arc C's** (`Capture/CaptureInboxUndoSections.swift:69,102-106`). **B4
  builds neither** — RM-03 only.

**§7.2/§7.4 constraint that shapes both fixes below:** *"`accessibilityReduceMotion` cannot be injected through
`.environment(\.)`. A leaf that must be tested in both modes takes the resolved value as a PARAMETER from a
parent that reads it."* So neither fix may be "the view reads the environment inline and a test injects the
environment" — each becomes a pure `resolve(reduceMotion:) -> Animation`-style function (§7.4), unit-tested for
both booleans, with a call-site test pinning that the view reads the environment once and passes it in. Also
§7.2's opening-pose rule: both swaps change CONTENT HEIGHT (Create account adds a field; the summary's states
differ in size), so a single animated `Animation` value is not enough — if the swap changes height, split like
`CaptureFanOverlay`: geometry pinned to final value (`nil`/no animation on frame-affecting state), content
`.transition(.opacity)` animated at `.default` under RM.

**Shape — Daily Summary state swap (RM-03):**
- `Home/DailySummaryView.swift:56-73` — `.animation(.spring(response:0.35, dampingFraction:0.8, blendDuration:0),
  value: service.state)` at `:63-65` over `bannerCard`/`toneToolbar`/`metricStrip`/`summaryContent` together; zero
  `accessibilityReduceMotion` reads in the file (grepped).
- Add a pure `static func summarySwapAnimation(reduceMotion: Bool) -> Animation` (e.g. in
  `Home/DailySummaryView.swift` itself or a small `Theme/` helper), returning `.default` when true and the spring
  otherwise; the view reads `@Environment(\.accessibilityReduceMotion)` ONCE and passes it to the function at
  `:63-65`. If the state swap changes the card's height, pin geometry and animate only a `.transition(.opacity)`
  under RM, per the constraint above.
- **Cross-arc note:** round 3 says the Daily Summary "now lives in Week review," and arc E's Today rebuild is
  expected to move/replace this view. Land B4 before arc E if possible; if arc E lands first, its block carries
  this fix instead — say so in whichever report runs second.

**Shape — sign-in mode swap (RM-03):**
- `Auth/LoginView.swift:87-101` — `.animation(.spring(...), value: mode)` (`:96-99`) and
  `.animation(.spring(...), value: isSubmittingApple)` (`:100-103`) on the top-level `VStack`; zero
  `accessibilityReduceMotion` reads (grepped). Same shape: one pure resolver function, one environment read, both
  modifiers gated through it; Create-account adds the name field (a height change), so split geometry/opacity per
  the constraint above rather than animating the whole swap under one `Animation` value.

**Tests that must be REVERSED, not deleted.** Grepped `ADHD LifeOSTests/` for `DailySummaryView`/`service.state`
and `LoginView`/`mode` animation assertions: **none found** — nothing pins the spring today.

**Acceptance criteria**
- [ ] RED first: a unit test per resolver function asserting `.default` when `reduceMotion == true` and the spring
      otherwise; a call-site test (the `FocusCompletionCard → FocusCompletionCelebration` shape, §7.2) pinning
      that each view reads the environment once and passes it as a parameter — not `.environment(\.)` injection
      anywhere in a test.
- [ ] Red-check restoring the ungated `.animation` calls; count failures; restore with `git checkout --`.
- [ ] SwiftLint 0, suite green, build green, all pasted.
- [ ] `screenshots/reduce-motion-daily-summary-signin/` + README: both sites, RM off vs RM on (RM-on frames from a
      render probe that PASSES `reduceMotion: true` into the resolver/leaf as a parameter, never environment
      injection), light/dark.
- [ ] `apple-design` review owed (§7.6), Lens 1.
- [ ] **RM-on device pass owed (§7.3):** both are new reduced sites. Ask E for both passes in one message (RM off,
      then RM on); the report line may only read "Reduced: run on sim (injected) + E's phone (RM on)" after E
      actually toggles and confirms.
- [ ] No `#available` site touched beyond the RM-on line above.

**Dependencies:** independent of B1/B2/B3/B5. Do not build RM-01 or RM-02 here — they ride into arc F's and arc
C's own blocks. See the Daily Summary cross-arc note above re: arc E ordering.

---

### FEATURE: F-B5-AutomatedAuditPlan — `performAccessibilityAudit` per screen, its own test plan  [ ] NOT STARTED

**What E chose:** *"Automated: `performAccessibilityAudit` per screen in the UI journeys, in its own test plan. UI
tests stay out of the standard run, and the audit needs a 17+ test runtime (27.0 is fine)."* §M A11Y-07: *"zero
`performAccessibilityAudit` calls and no `.xctestplan`. Natural homes are the existing journeys ... Each audit
must sit in its own deliberate test plan."*

**Shape:** Confirmed zero `.xctestplan` files repo-wide; one shared scheme
(`ADHD LifeOS.xcodeproj/xcshareddata/xcschemes/ADHD LifeOS.xcscheme`); the project uses
`PBXFileSystemSynchronizedRootGroup` folders, so a new `.swift` file dropped into `ADHD LifeOSUITests/` is an
automatic target member — no `project.pbxproj` edit needed for new test files.
- Existing journeys to piggy-back navigation on (one audit call per screen/state, per the module's "audits only
  see the current screen"): `FirstRunJourneyUITests.swift`, `SignedInJourneyUITests.swift`,
  `JournalJourneyUITests.swift`, `ToolsRoutinesJourneyUITests.swift`/`RoutineJourneyUITests.swift`,
  `SprintBarFurnitureUITests.swift`, `SignedOutLaunchUITests.swift`/`LandscapeLoginUITests.swift`.
- **New files, not edits to those**, e.g. `ADHD LifeOSUITests/Accessibility/FirstRunAccessibilityAuditUITests.swift`
  — reuse each journey's navigation helpers (`UITestSession`, `UITestTabs`) to reach each screen, then audit, so
  the audit suite runs standalone from the journeys' own behavioural assertions. `continueAfterFailure = true`
  before every audit call.
- **Filtering** (module's rule: "filter specific accepted findings — never disable whole audit types"): round 9's
  contrast Criticals are DEFERRED to the colour arc (§F's table: LabelSecondary 4.25, tertiary 1.88/2.33,
  placeholder 1.69/2.43, white-on-accent 3.93/3.65) — filter each by element label/type, comment citing *"Round 9:
  'Leave it to the colour arc.'"* Any `.hitRegion` finding on an arc C/D/F target gets the same per-element filter
  naming the owning arc — or simpler, sequence B5 LAST so B1-B4 have already landed. Un-owned findings not already
  named in §M/§G go to the register as candidates, not fixed here.

**Tests that must be REVERSED, not deleted.** None — greenfield (grepped for any existing
`performAccessibilityAudit` call or `TestPlans` reference in the scheme: zero hits).

**Risk confirmed in the scheme itself:** `ADHD LifeOS.xcscheme:58-61` sets `LIFEOS_FIREBASE_EMULATOR_HOST` on the
Test action with `shouldUseLaunchSchemeArgsEnv = "NO"` (Test-only; `:113` shows the Run action is `"YES"`,
i.e. unaffected). **Adding ANY `.xctestplan` to a scheme migrates Xcode's Test action into test-plan mode**,
which can silently drop this env var and override `-enableCodeCoverage` with the plan's own coverage setting —
both the emulator harness (§ "Firebase emulator" in CLAUDE.md) and the 24.72% baseline depend on these surviving.

**Acceptance criteria**
- [ ] RED-first doesn't apply in the usual sense (no prior passing state) — instead, each new audit test's FIRST
      run must fail on ≥1 real finding (proving it's wired to a real screen), then each accepted finding is
      filtered with its comment, going green only once every unfiltered issue is fixed or filtered with a named
      owner.
- [ ] A new `.xctestplan` (e.g. `AccessibilityAudit.xctestplan`) listing ONLY the new audit classes, added to the
      scheme as an ADDITIONAL plan (not default) — `xcodebuild test -scheme "ADHD LifeOS" -testPlan AccessibilityAudit`
      runs it alone; CLAUDE.md's standard `xcodebuild test` command is untouched.
- [ ] **Prove the migrated default plan still carries `LIFEOS_FIREBASE_EMULATOR_HOST` (Test-only) and coverage
      ON:** diff the `.xcscheme` before/after and paste it; with the emulator UP, run the documented
      `xcodebuild test` command and confirm the `+Seed`/`+Tags`/`+Storage`/`+AccountDeletion` tests RAN (not
      skipped) and `xccov` still reports coverage. If the migration drops either, fix the plan/scheme before
      calling this block done — a silent loss here reopens the emulator-skip and coverage-baseline facts this
      file depends on.
- [ ] **Non-negotiable: `xcrun simctl erase <udid>` immediately after this UI-target run, before any unit run** —
      it poisons the simulator like any other UI-target suite.
- [ ] SwiftLint 0 on new files; the standard unit suite stays green and unaffected; build green; all pasted,
      including a separate run of the new plan (17+/27.0 sim, run deliberately).
- [ ] No `screenshots/` owed — the audit's evidence is pass/fail plus filtered-issue comments, not a picture.
- [ ] `apple-design` review: none owed — pure test harness. Say so.
- [ ] No `#available` site touched; no RM-on pass owed.
- [ ] Report lists every first-run finding split into: fixed inline (file:line), filtered as colour-arc-deferred
      (§F), filtered as owned-elsewhere (name the arc), forwarded to the register as new.

**Dependencies:** sequence LAST among B1-B5 (ideally after arcs A/C/D too) so the first live run has the fewest
already-known findings to filter. Needs the 17+/27.0 runtime already on this machine.

---

## Arc G — Places, sheets, refresh and Fresh Start

Source: `handoff/SESSION-OPENER-adhd-ux-audit-design.md` rounds **10a**, **10b**, **8b**. Findings:
`handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md` §A (MODAL-2/3, REACH-1, GEST-2/3), §D (sheet-primary
placement), §H (SET-01/02, TOOLS-01), §I (TASKS-07, INBOX-04). Evidence: board `67`
(`screenshots/adhd-ux-audit/README.md`) — the Places chain sim-verified this session.

**Order:** G1 before G2 (both touch the two Places toolbars — fold G2's Places moves into G1's
commit if built together). G3's life-areas half needs arc E. G4 is independent. G5 needs arc D and
arc E. Arc B ("Key targets", round 7) owns the 48pt token this arc's new buttons want — nothing
named exists yet (`Theme.swift:198 pillHeight = 48` is the only 48pt token today); use a literal 48
and re-point at arc B's token once it lands.

---

### FEATURE: F-G1-PlacesOneSheet — Places' editor becomes one sheet with pushes inside it  [ ] NOT STARTED

**What E chose:** Round 10a, **"Sheet depth → 'One sheet, pushes inside it' (Recommended)."**
*"Edit place stays the one sheet. An action's editor, and the app's own app picker, push INSIDE
it, with Back to return. Only Apple's system screens (the contact picker, the camera) open over
it."* Sim-verified this session (board `67`): Places → Edit place (1) → Edit action (2) → Apple's
contact picker (3) — three deep (MODAL-2, Critical).

**The shape (verify, do not trust) — today's chain, each a separate `.sheet`:**
- `Places/PlacesListView.swift:41-46` → `PlaceEditorView` (sheet 1, **stays a sheet**).
- `PlaceEditorView.swift:50-74` wraps `Form` in its OWN `NavigationStack`; `PlaceActionsSection`
  (`:57`) is a child of that Form.
- `Places/PlaceActionsSection.swift:88-101` `.sheet(item: $editorContext)` → `PlaceActionEditorSheet`
  (sheet 2). `:104-106` a second `.sheet(item: $guideContext)` → `PlaceAutomationGuideView` (the
  app's OWN screen. E's quote names only the action editor and the app picker — extending "pushes
  too" to this third screen is this session's plain reading of "only Apple's system screens open
  over it", not a quoted decision; say so in the report).
- `PlaceActionsEditorView.swift:39-104` wraps its OWN `NavigationStack`. `:66-71`
  `.sheet(isPresented: $isPickingContact)` → `ContactPicker` (Apple's system UI — **stays a
  sheet**). `:72-102` `.sheet(isPresented: $isPickingApp)` → `PlaceAppPickerView` (sheet 3).
- `PlaceAppPickerView.swift:50-110` wraps a THIRD `NavigationStack` with its own
  `.navigationDestination(for: PlaceAppCategory.self)` (`:85-87`) and
  `(for: PlaceAppDirectoryEntry.self)` (`:88-102`).

**The change:** one `NavigationStack`, owned by `PlaceEditorView`. `PlaceActionEditorSheet` and
`PlaceAppPickerView` lose their own `NavigationStack`s and become `.navigationDestination` pushes
on the shared stack (`PlaceAppPickerView`'s two `.navigationDestination`s move up onto it too);
each loses its Cancel button (Back replaces it). `PlaceAutomationGuideView` becomes a push as well.
`ContactPicker` and the camera covers (MODAL-3: `QuickCaptureView.swift:150`,
`CaptureDetailView.swift:101`, `CaptureRowView.swift:37` — outside this arc, named as already
compliant) stay presented OVER the one sheet.

`PlaceAction` (`PlaceActionModels.swift:60`) is `Codable, Identifiable, Equatable, Sendable` — **not
`Hashable`**, which `.navigationDestination(for:)` needs. Don't add it to the model; carry the push
value on `PlaceActionEditorContext` (`PlaceActionsSection.swift:15-19`, already `Identifiable`
with a minted `id`) instead, adding `Hashable` there. Verify `PlaceAppCategory`/
`PlaceAppDirectoryEntry` are already `Hashable` — don't assume.

**Tests that must be REVERSED, not deleted:**
- `PlaceActionsEditorCallSiteTests.swift:24-31` (exactly-one-`.onMove`) — unaffected; **verify,
  don't reverse.**
- `ADHD LifeOSUITests/ToolsRoutinesJourneyUITests.swift:174-178` waits for
  `app.buttons["placeEditorSaveButton"]` by id only — **verify it survives the button's move
  (this block, and G2's bottom move), don't reverse.**
- None found by grep for a test pinning today's sheet-depth by source or presentation count.

**Acceptance criteria:**
- [ ] RED first: a call-site test that `PlaceEditorView.swift`'s source has NO
      `.sheet(item:$editorContext)`/`.sheet(isPresented:$isPickingApp)` and DOES have
      `.navigationDestination` for both; a second assertion `ContactPicker`'s `.sheet` still exists
      (the compliant exception).
- [ ] Red-check: restore pre-block files; count failures; restore with `git checkout --`.
- [ ] `screenshots/places-one-sheet/` + README: the chain driven end to end, light/dark.
- [ ] `apple-design` review owed (§7.6) — sheet chrome changes.
- [ ] No Reduce Motion site touched (push transitions are UIKit's own) — **no RM-on pass owed.**
- [ ] **Verified paths:** "no new gate; the 18 floor untouched — Places is ungated and universal
      since `F-Floor18`."
- [ ] SwiftLint 0, full suite green, build green, pasted.

**Dependencies:** none. G2 depends on this landing first.

---

### FEATURE: F-G2-BottomAndFixList — Save/Add to the bottom of eight sheets; the fix-list's four items  [ ] NOT STARTED

**What E chose:** Round 10a, **"The fix list → 'Approve all four' (Recommended)."**

#### 2a — REACH-1: Save/Add to the bottom, eight sheets

*"Save and Add move to the BOTTOM of eight sheets... The sprint sheet is round 4b's"* (arc F's, not
this arc's). Template: `Capture/QuickCaptureView.swift:125` (`.safeAreaInset(edge: .bottom) {
footerBar }`) + `QuickCaptureComponents.swift:357-386` (`footerBar`: primary `Button`,
`MomentumSolidButtonStyle` at 54pt — `MomentumScoreboardViews.swift:45-59`, already clears the
48pt floor — `.disabled(...)`, `.composerFooterSurface()`).

| Sheet | file:line | id | today's placement |
|---|---|---|---|
| Edit place | `Places/PlaceEditorView.swift:66-70` | `placeEditorSaveButton` | `.confirmationAction` |
| Edit action | `Places/PlaceActionsEditorView.swift:53-63` | `actionEditorSaveButton` | `.confirmationAction` |
| Add Tag | `TagEditor/TagEditorListView.swift:171-183` | `addTagSaveButton` | `.confirmationAction` |
| Tag detail | `TagEditor/TagEditorDetailView.swift:74-89` | `tagSaveButton` | `.topBarTrailing` |
| Add Life Area | `LifeAreaEditor/LifeAreaEditorListView.swift:197-209` | `addLifeAreaSaveButton` | `.confirmationAction` |
| Life Area detail | `LifeAreaEditor/LifeAreaEditorDetailView.swift:135-147` | `lifeAreaSaveButton` | `.topBarTrailing` |
| New nudge | `Nudges/NudgesView.swift:275-296` | `nudgeAddSubmitButton` | `.confirmationAction` |
| Capture detail | `Capture/CaptureDetailView.swift:71-134` (`actionsRow`) | none pinned | in-scroll |

**Capture detail departs from the other seven — report it as such.** `CaptureDetailView` is
**pushed** (`CaptureInboxView.swift:122-129`, `JournalTimelineSections.swift:348`), not a sheet —
its own header comment says so. Its primary is `actionsRow(capture)` (`:83,126-134`, Sort / Make a
task), placed in-scroll at the END of the `ScrollView` (`:72-84`), not pinned. Build it as E asked
(bottom-pinned, same template) and say in the report that it's a pushed screen, not a sheet. `:213`
is `overflowMenu` (Log to journal / discard) — a secondary exit, leave it where it is.

**Nudges carries a comment arguing FOR top placement — annotate, don't delete**
(`NudgesView.swift:279-280`: *"The confirming action belongs in the nav bar... not buried at the
bottom of the form"*). Same `F-JournalDoorUnpinned` precedent (`TODO-CLAUDE-CODE.md:4731-4735`):
mark it superseded by round 10a, keep the history.

**The change**, each site: replace the toolbar Save/Add with a `.safeAreaInset(edge: .bottom)`
primary (same accessibility id). Cancel/Back stays where it is — only the primary moves (Q8).

#### 2b — SET-01/SET-02: the Notifications card

*"The Settings Notifications card loses its ~310pt gap (SET-01). 'Not requested yet' gets an
in-place 'Allow notifications' button (SET-02); the app already asks in `NudgesService.swift:182`."*

**SET-01's cause is INFERRED, not confirmed.** Reading `SettingsView.swift:119-157`
(`notificationsSection`, `LabeledContent` at `:126-129`, `permissionStatusView` at `:147-156`)
found no explicit `.frame(height:)` explaining a 310pt gap. **Acceptance requires reproducing the
gap on sim first** (measure it), THEN finding the real cause — do not fix an unconfirmed cause.

**SET-02 deliberately breaks a documented invariant.** `NotificationAuthorizationReading.swift:9-14`
and `NotificationCenterAuthorizationReader.swift:12-14` both say this seam is read-only "so no
Settings code path can prompt." Grep for `requestAuthorization`/`NotificationAuthorizationReading`
in tests finds only `FakeNotificationAuthorizationReading.swift` (a double, no such assertion) —
**both doc comments must be ANNOTATED, not silently left claiming a now-false invariant.**
Reusable mechanism: `NotificationCenterNudgeAdapter.swift:25-36`'s
`requestAuthorizationIfNeeded()` shows the call (`center.requestAuthorization(options: [.alert,
.sound])`), but it's nudge-scoped and namespaced — don't reuse it directly. **Shape:** a new,
narrow `NotificationAuthorizationRequesting` protocol (one method) + `NotificationCenterAuthorizationRequester`,
mirroring `NotificationAuthorizationReading`'s own shape. `SettingsView` shows the button only when
`permissionState == .notDetermined`; on tap, request then re-read via the existing
`authorizationReader`.

#### 2c — TASKS-07: a loading state instead of "0 open"

`TaskListView.swift:47` renders `Text(MomentumTaskBuckets.headerLine(tasks: tasksService.tasks))`
unconditionally, ABOVE the `switch tasksService.state` (`:63-86`). `TasksService.swift:50`'s
`tasks` array is `[]` until the first load resolves, and `:61` means `.loading` is true ONLY on
the first cold load (a refetch stays `.loaded`) — so gating the header on `state != .loading` costs
no flicker on later refreshes, only hides the first-appearance "0 open" flash. **Change:** gate
`TaskListView.swift:47` on `tasksService.state`.

**Coordinate with arc A's round-8 header change** at the SAME call site/`MomentumTaskBuckets.swift:56-67`
(round 8 retires "12 OPEN · 2 OVERDUE" → plain "12 open"). Whichever arc lands second re-applies
the other's edit — say in the report which order actually happened.

#### 2d — INBOX-04: the promote sheet's Create Task

`CapturePromoteSheet.swift:48-80`: `CreateTaskButton` (`:69-72`) sits in-scroll inside the `VStack`,
after the warning/error labels — can scroll away at large Dynamic Type. **Change:** move it to a
`.safeAreaInset(edge: .bottom)` on the `ScrollView` (same REACH-2 template), keeping
`.disabled(hasPromoted)`. Verify the pinned bar reads correctly at `.presentationDetents([.medium,
.large])`'s `.medium` too (`:92`), not only `.large`.

**Tests that must be REVERSED, not deleted:**
- None found by grep for `confirmationAction`/`topBarTrailing` pinning any of the eight Save
  buttons' placement (`JournalHeaderControlsTests.swift:60` matches the string but is unrelated —
  the Journal header, not a sheet Save).
- `ToolsRoutinesJourneyUITests.swift:175` — verify, don't reverse (see G1).
- None found for `MomentumTaskBuckets.headerLine`/"0 OPEN" by source-grep, or for
  `CapturePromoteSheet`'s button position.

**Acceptance criteria:**
- [ ] RED first: eight placement assertions (bottom inset, not `ToolbarItem`) for 2a; a
      loading-state test for 2c; a placement assertion for 2d.
- [ ] SET-01 reproduced on sim FIRST (screenshot + measured gap) before any fix.
- [ ] SET-02: RED first for the new requesting seam (a fake proving request-then-reread), then the
      in-place button gated to `.notDetermined`.
- [ ] Red-check each sub-item; count failures; restore with `git checkout --`.
- [ ] `screenshots/sheets-bottom-and-fixlist/` + README: all eight sheets before/after, the
      Notifications card before/after (gap measured), the "Allow notifications" button, Tasks'
      loading state, the promote sheet's pinned button — light/dark.
- [ ] `apple-design` review owed (§7.6) — every sub-item is visible.
- [ ] No Reduce Motion site added (say so, or name it if the build adds a transition to SET-02).
- [ ] No new `#available` gate — **Verified paths: "no new gate; the 18 floor untouched."**
- [ ] SwiftLint 0, full suite green, build green, pasted.

**Dependencies:** G1 (Places' toolbars must already be pushes before their Save moves). Coordinate
with arc A on `TaskListView.swift:47`.

**Step 0:** none — SET-01/02 and INBOX-04 are code facts, not design choices. The read-only
invariant break (2b) is Q8 in effect, not a new decision.

---

### FEATURE: F-G3-TapTwins — up/down buttons and a place-editor Delete button  [ ] NOT STARTED

**What E chose:** Round 10a, **"Tap twins → '↑ ↓ buttons + a Delete button' (Recommended)."**
*"Arrange mode's life areas and a place's action list show ↑ and ↓ on every row (48pt); drag still
works. Edit place gains a bottom Delete button with its confirm (GEST-2; Q10 allows the friction).
GEST-3 is closed by the same buttons."*

**Dependency:** round 3 moves life areas off Today to the Areas tab — **arc E's job.** The shape
below is written against today's `HomeView`/`HomeAccessoryStrips` as a starting point only —
**find where `isArranging`/`arrangeAreas`/`reorderList` actually live once arc E lands, and build
there instead.**

**The shape (verify, do not trust):**
- Life areas: `HomeAccessoryStrips.swift:12-28` (`reorderList`) — a `List` with one `.onMove`
  (`:23`) forced into `.environment(\.editMode, .constant(.active))` (`:27`); edit mode alone gives
  only the drag handle, no ↑/↓. `HomeView.swift:98-102,318-324` hosts arrange mode.
- Place actions: `PlaceActionsSection.swift:50-66` — `ForEach(actions)` with `.onDelete` (`:55-58`)
  AND `.onMove` (`:63-66`) on the same `ForEach`; footer at `:110-114` ("Drag to reorder.").
  `PlaceActionsEditorCallSiteTests.swift:24-38` pins the exactly-one-`.onMove` count and that exact
  footer string by source-grep — this block touches neither; **verify both stay green.**
- **GEST-3's other half:** the action row's `.onDelete` (`:55-58`) is ALSO swipe-only, distinct
  from the reorder gap, and round 10a's fix list only names the delete twin for Edit place
  (GEST-2). **Recommendation:** fold the action row's own delete into the SAME shape as GEST-2 — a
  Delete button inside `PlaceActionEditorSheet` (opened by the existing row tap,
  `PlaceActionsSection.swift:132-148`) — rather than a third control on an already-crowded row.
  Build-time judgment call, not an E decision (Q7's rule is met either way); state which shape was
  built.

**The change:**
- Both reorderable lists gain an explicit ↑/↓ per row, 48pt. House pattern for "row button +
  sibling control" (not nested buttons, which break `List` hit-testing):
  `PlacesListView.swift:137-159` (row `Button` + sibling `.borderless` button in one `HStack`).
  First-row ↑ / last-row ↓ disabled, not hidden. Each needs a label ("Move Home up") — also closes
  A11Y-03 for these two controls. `.onMove` stays wired — "drag still works", not replaced. Verify
  the buttons stay tappable under `.environment(\.editMode, .constant(.active))` on the actual sim.
- `PlaceEditorView` gains a bottom Delete (own `.safeAreaInset`, or folded beside G2's bottom Save
  as a secondary destructive action). `nil`/disabled when `existing == nil`. Confirm styled like
  `TaskDetailView.swift:117-129`'s `"Delete this task?"` pattern; existing wording available at
  `PlacesListView.swift:47-66` ("Anything already tagged with this place keeps its coordinates.").
  On confirm: `PlacesService.delete`, then `dismiss()`. The existing swipe (`PlacesListView.swift:151-158`)
  stays as E's named bonus.

**Tests that must be REVERSED, not deleted:**
- `PlaceActionsEditorCallSiteTests.swift:24-38` — verify, don't reverse.
- None found by grep for a test asserting `HomeAccessoryStrips`/`PlaceEditorView` has NO up/down or
  Delete control — net-new surface.

**Acceptance criteria:**
- [ ] RED first: geometry/call-site tests that each row has labelled 48×48pt up/down controls,
      disabled at the ends; a `PlaceEditorView` test that Delete exists only when `existing != nil`.
- [ ] Red-check by restoring pre-block files; count failures; restore with `git checkout --`.
- [ ] `screenshots/tap-twins/` + README: both reorder lists with visible ↑/↓ and disabled ends,
      Edit place's Delete + confirm — light/dark.
- [ ] `apple-design` review owed (§7.6).
- [ ] No Reduce Motion site added — say so, or name it if a disabled-state transition is added.
- [ ] **Verified paths per surface** once arc E settles where life areas live; Places is ungated
      and universal since `F-Floor18`.
- [ ] SwiftLint 0, full suite green, build green, pasted.

**Dependencies:** arc E (life-areas half only). Do not start that half before arc E lands.

**Step 0 (only if the build session disagrees with the recommendation above):** how the action
row's own delete gets a tap twin — (a) fold into the action editor as Delete (recommended), or (b)
a third inline row control. Either satisfies Q7; no E input needed if (a) is built.

---

### FEATURE: F-G4-Refresh — reload on appear, on foreground, and prove writes reach their screens  [ ] NOT STARTED

**E's addition is a CONTINUITY requirement, not a defect report (E, 2026-09-19, asked directly in the audit's
closing text):** *"I don't think I have seen it fail to refresh but I stated it to ensure continuity."* Nobody has
observed Journal or the Capture inbox failing to update after an in-app write, and the code says they should:
both listen for `DataChangeSignal`, which every generic `save`/`delete`/`update` posts. **So this block's job is to
PIN that behaviour with tests so it cannot regress, and to check the write paths that bypass the generic methods
(the photo upload through `+Storage`, `Shortcuts/ShortcutIntentRunner.swift`). Do not open a bug hunt.** If a test
does turn up a path that misses the signal, that is a real find: report it and fix it here.

**What E chose:** Round 10b, **E verbatim:** *"I choose option one With the addition of an
auto-refresh When a user makes an edit/Change Such as logging a new Journal entry - Then the
Journal should update automatically. Creating a new quick capture - Should update the Capture
inbox page automatically."* Option one: *"every screen reloads when it appears and whenever the
app returns to the front. The pull stays as a bonus, with no new button."*

**The shape (verify, do not trust) — two real gaps, one thing already true:**

1. **Foreground return does almost nothing today.** Only `RootView.swift:389-395`
   (`focusService.syncNow()` + `LocationTriggerService.refreshRegistrations()`) and
   `HomeView.swift:306-309` (`refreshLiveRoutine()`) react to `scenePhase == .active`. Grep for
   `scenePhase` finds it nowhere else (bar `PlaceRoutineScreen.swift`,
   `FocusNotificationResponse.swift`) — Tasks, Areas, Journal, Nudges, Places, Tools,
   LifeAreaDetail have no foreground-return reload.
2. **A warm tab switch doesn't reload either.** `AppTabContent.swift:89-115` keeps every visited
   tab alive (`visitLog.isBuilt`), only toggling opacity/offset/hit-testing on selection change. A
   screen's `.task` (the load-on-first-appear hook every screen uses) does not re-run on a warm
   return — `HomeRoutineCard.swift:122-127`'s own comment says so for the routine card, and it's
   true everywhere else too.
3. **Already true, needs proving not building:** `DataChangeSignal` posts after every generic
   Firestore write (`FirebaseManager.swift:326-341`) and from four batch extensions
   (`+LifeAreas.swift:39`, `+Tags.swift:32,38,105`, `+Seed.swift:65`, plus the routines arc's own
   posts). NINE screens already subscribe (`JournalView.swift:157`, `CaptureInboxView.swift:137-140`,
   `HomeView.swift:376-378`, `TaskListView.swift:138`, `AreasView.swift:120`,
   `LifeAreaDetailView.swift:84`, `NudgesView.swift:63`, `PlacesListView.swift:69-71`,
   `ToolsRoutinesSection.swift:73`). A new journal entry
   (`FirebaseJournalClientAdapter.swift:92-116` `createLog` → `store.appendLog(log)` →
   `FirebaseManager+Logs.swift:20-22` → generic `save`) and a new quick capture
   (`FirebaseCaptureClientAdapter.swift:21-46` `createCapture` → `store.saveCapture` →
   `FirebaseManager+Captures.swift:56-58` → generic `save`) BOTH verified this session to route
   through the funnel, end to end — not assumed. Both screens also get a direct reload
   from their composer's completion closure (`JournalView.swift:148-153`,
   `CaptureInboxView.swift:117-121`). **This block's job for (3) is tests, not new production
   code**, unless a real stale-screen reproduction turns up.
   - `FirebaseManager+Storage.swift`'s `uploadMedia` (`:29-31`) doesn't post the signal, but only
     writes the raw blob — the capture DOCUMENT write goes through `saveCapture` after, which does.
     No gap.
   - `ShortcutIntentRunner.swift:50,62` posts the signal explicitly AFTER calling writers that
     already post it via the generic funnel — a harmless double-post, a fact to record, not a fix.

**The change:** reuse `DataChangeSignal` for both new triggers rather than inventing a parallel
mechanism — every screen already has the one `.onReceive` it needs.
- `RootView.swift:389-395`: on `phase == .active`, also call `DataChangeSignal.post()`.
- `AppTabContent.swift:114`: also call it on every selection change (not only first-visit build).
  This covers a warm tab switch AND every screen pushed under a tab (Places under Tools, Nudges
  under Home, `LifeAreaDetailView`) — the signal is a broadcast, so it needs no owning-tab identity
  threaded down.
- **This refetches every mounted screen on every switch, not only the destination** — the same
  cost the app already accepts for a write anywhere. State this trade-off rather than silently
  narrowing scope; a per-tab-keyed alternative is real but materially more code for a saving that's
  speculative until measured.
- Re-scope `DataChangeSignal.swift:9-17`'s doc comment (it now fires on foreground/tab-switch too,
  not only writes) — annotate, keep the history.
- **Cold-launch double-fetch is expected and fine** — the existing 600ms debounce
  (`DataChangeSignal.swift:24,44-48`) coalesces it, and "never flashes loading"
  (`TasksService.swift:61`) already protects the visible result. **No test may assert "loads
  exactly once"** — the established pattern (`TasksServiceTests.swift:167`,
  `HomeServiceTests.swift:236`, `JournalServiceTests.swift:254`) is "never flashes loading", never
  "loads once".

**Tests that must be REVERSED, not deleted:** none found by grep asserting the signal fires only
after a write, or that `AppTabContent`'s `.onChange(of: selection)` does nothing but
`visitLog.select`. The new tests below extend `DataChangeSignalTests.swift`'s existing pattern.

**Acceptance criteria:**
- [ ] RED first: call-site tests that `RootView.swift`'s active-branch and `AppTabContent.swift`'s
      selection-change both contain `DataChangeSignal.post()`; new `DataChangeSignalTests` proving
      a post from either site reaches a subscriber (inject via `debouncedPublisher`, don't touch
      real `RootView`/`AppTabContent` instances).
- [ ] A regression test pinning that the journal/capture composer's completion closure calls
      `load()`/`refresh()` (extend `JournalServiceTests`/`CaptureInboxServiceTests`, or a call-site
      test on `JournalView.swift:148-153`/`CaptureInboxView.swift:117-121`).
- [ ] Red-check: restore `RootView.swift`/`AppTabContent.swift`; count failures; restore with
      `git checkout --`.
- [ ] No `screenshots/` owed — plumbing/timing only, nothing new to see; say so.
- [ ] No `apple-design` review owed — say so.
- [ ] No Reduce Motion site added — say so.
- [ ] No new `#available` gate — **Verified paths: "no new gate; the 18 floor untouched."**
- [ ] SwiftLint 0, full suite green, build green, pasted.

**Dependencies:** none.

---

### FEATURE: F-G5-FreshStart — "Welcome back. Start fresh?" and the Set-aside row  [ ] NOT STARTED

**What E chose:** Round 8b, **"Fresh Start → 'Set them aside in one folded row' (Recommended)."**
*"After 7+ days away, one tap on Today's 'Welcome back. Start fresh?' card moves the PAST-DUE open
tasks into one collapsed 'Set aside · N' row at the bottom of Tasks. It sits beside round 6's
'Anytime · N', in the same shape. Nothing is deleted, dates are kept, and one tap brings any task
back. Undated tasks already live in Anytime, and future-dated tasks are untouched."* (Research
§5.8, §5.4.)

**Dependencies:** arc D's "Anytime · N" row shape (round 6, not yet built) and arc E's round 5b
active-day definition. **Do not build before both land.**

**The shape (verify, do not trust):**
- `TaskModels.swift:15-58` (`TaskItem`) has `completedAt: Date?` (`:26-30`) as precedent for a
  nullable stamp written once, cleared on re-open. No "set aside" field exists.
- `MomentumTaskBuckets.swift:79-97` puts a past-due open task (`dueDay <= today`) in `.dueToday`
  (`:95`) — exactly the bucket Fresh Start must exclude a set-aside task from.
- No existing "last active"/"last opened" tracker (grep for `lastOpenedAt`/`lastActiveDate`/
  `daysAway`/`daysSinceLast` — the only near-hit, `lastClosedAt`, is per-area derived task data,
  `MomentumScoreboard.swift:109,129,267-288`, not a global signal).

**Step 0 — ask E (two open points, neither settled by the record):**

1. **How "set aside" is stored** (the brief's own named gap). **(a) A task field** — a new
   `setAsideAt: Date?` property on `TaskItem`, added to its explicit `CodingKeys`
   (`Tasks/TaskModels.swift:72-81`) as `case setAsideAt = "set_aside_at"`, verified this session to
   be the exact pattern `completedAt` already uses (`:78`, `"completed_at"`) — `Firestore.Encoder`
   has no automatic camelCase→snake_case conversion here (`FirestoreDocumentCoder.swift:23-25`
   calls it with no `keyEncodingStrategy`), so the snake_case key comes ONLY from this enum, by
   hand, same as every other field on this model. Syncs across devices, survives a reinstall;
   verify whether `firestore.rules` validates field names on the tasks write (it sits in the
   generic per-user allow per this file's architecture notes — a republish may not even be owed)
   before assuming one is. **(b) Derived client state** — a local exclusion set. No schema
   change, but can't reliably honour "brings it back" across devices/reinstall, and needs a second
   local `freshStartAt` timestamp to know what was swept. **Recommendation: (a)** — it matches the
   app's own pattern for exactly this fact and is the only shape that delivers what E asked on any
   device.
2. **How "7+ days away" is measured — not settled.** **(a)** the app wasn't OPENED for 7+ days (a
   local `lastOpenedAt`). **(b)** no ACTIVE day (round 5b's definition) for 7+ days — which would
   greet a daily-opener who's done nothing as if they'd left. The record doesn't choose; don't
   decide it — ask E, with a render only if the answer isn't a plain preference.

**The change (once Step 0 is answered and D/E have landed):**
- A Fresh Start card ("Welcome back. Start fresh?") shown when Step 0.2's condition is true, one
  tap.
- The tap stamps every past-due, open task with `set_aside_at` (Step 0.1) in one batch write
  (house pattern: `FirebaseManager+Tags.swift`'s batch commits; one `DataChangeSignal.post()`
  after, per `FirebaseManager+LifeAreas.swift:39`).
- `MomentumTaskBuckets` excludes set-aside tasks from every bucket; Tasks gains a collapsed
  **"Set aside · N"** row beside arc D's "Anytime · N", reusing its component.
- Tapping into the row and clearing `set_aside_at` restores a task; its due date is untouched.
- **The card's appear/disappear is a Reduce-Motion site** (§7.2's "appears" case,
  `CaptureFanOverlay`'s fade) — this block **owes the RM-on device pass** (§7.3).

**Tests that must be REVERSED, not deleted:** none found by grep for `set_aside`/`freshStart` —
entirely new surface. Check `MomentumTaskBucketsTests.swift` at build time for an assertion that
every past-due open task lands in `.dueToday` unconditionally — extend it, don't reverse it.

**Acceptance criteria:**
- [ ] Step 0 answered by E before any code is written.
- [ ] RED first: a codec round-trip test for `set_aside_at` (if (a)); a bucket-exclusion test; a
      Tasks-board test for the row's count and restore-on-tap.
- [ ] Red-check by restoring pre-block files; count failures; restore with `git checkout --`.
- [ ] `screenshots/fresh-start/` + README: the card, the batch action, the row, a restore — light/
      dark, plus the RM-on/RM-off pair for the card's appearance.
- [ ] `apple-design` review owed (§7.6) — new visible surface.
- [ ] **RM-on device pass owed** (§7.3) — new reduced site.
- [ ] No new `#available` gate expected — **Verified paths: "no new gate; the 18 floor untouched"**
      unless the build introduces one.
- [ ] "firestore.rules changes; E republishes" **only if** Step 0.1 → (a) AND the rules actually
      validate field shape on tasks (verify, don't assume).
- [ ] SwiftLint 0, full suite green, build green, pasted.

**Dependencies:** arc D and arc E. Do not start until both have landed and Step 0 is answered.
