# Session opener — after captures round 2, with the canvas open

Read `claudecode.md`, `CLAUDE.md` and the memory index first, then this brief. The previous opener
(`SESSION-OPENER-captures-round-2.md`) is **CLOSED** — every item in it shipped, plus a design
thread that ran well past it. Nothing is queued behind this one.

## Where things stand

- **`main` at `891ea8f`**, clean and pushed; `origin/main` matches. Thirteen commits landed on
  2026-08-28, all committed, pushed and SHA-verified.
- **Suite 1,796 / 0** (up from 1,751). **All five signed-in UI journeys pass** — there are five
  now, not four; the new one covers the Captures tab end to end.
- **Lint debt is EXACTLY two and nothing else is acceptable:** `TaskDetailView` file_length (438)
  and UITests `static_over_final_class`. Both were held at exactly two through thirteen commits —
  every new violation was fixed rather than accepted, including two file splits.
- **Emulator is UP** (auth 9099, firestore 8080, storage 9199) via `./scripts/emulators.sh`.
  Verified reachable at the time of writing. A fresh machine boot needs it started again.
- **Device `wishwashwacky15` is installed at `22dba79`** — which is behaviourally current, because
  `891ea8f` only deleted a test file. `devicectl` install works.
- `feature/location-services` still exists locally and on origin. Leave it unless E says delete.
- `TODO-CLAUDE-CODE.md`'s Current Sprint is still empty. Check it anyway in case Cowork has
  written a block.

## FIRST THING: a large amount is un-reviewed on device

E did no device pass across the back half of this session — the work was moving fast and E was
explicit about not being in the mood. **Nothing below is known-broken; it is simply unconfirmed by
a human.** Ask before building on any of it:

1. **The journal composer's gold pad**, day face AND night face — the last four commits are all
   this. E approved the day face from a render but has not confirmed the night face on a real
   screen.
2. **Collapsible journal days and Today's life-area list** (`9abfec8`) — never seen on device.
   Note the arrow direction was flipped to E's mock-up at their request; worth confirming it reads
   right in the hand.
3. **Settings now shows Name and Email** (`9c3418a`) — never seen on device.
4. **Undo for "Journal it"** (`b1ed121`) — never exercised on device. Journal a capture, hit Undo,
   confirm the capture returns AND the journal entry disappears.

## What landed on 2026-08-28 (context, not work)

Three arcs. Full reasoning is in the commit messages, which are long on purpose.

**Captures round 2 — E's "too many places it lives", answered**
```
4f03d7a  F-CaptureAudit      six audit findings fixed; markSeen deleted, `status` field removed
51a0a99  F-CaptureHome       Captures takes the fifth tab back; Nudges becomes a Today section
b1ed121  F-JournalUndo       the fourth triage verb learns to take itself back
39c3dd5  F-CaptureJourney    a journey for the rebuilt tab; it found two more silent failures
```

**Smaller open items, closed**
```
9abfec8  F-CollapsibleSections   journal days and Today's life areas both fold
9c3418a  F-DisplayName           the sign-up name stops vanishing; Settings names the account
```

**The journal composer's surface — five passes, E-directed throughout**
```
8230f7d  F-JournalPaper           first cut: a cream. Rejected on device — read as off-white paper
f797a8f  F-JournalPaper-fix       E's #FFDA03. Real yellow, but a lemon wall
956f549  F-JournalPad             goldenrod #DAA520 + forced-light "legal pad", chosen from renders
8d98606  F-JournalPadDefinition   warm ink labels, and the writing box becomes ruled paper
9848ee8  F-JournalPadNight        the pad gets a real night face instead of a forced light one
22dba79  F-DisabledCTA            the disabled primary button stops borrowing the page's colour
891ea8f  F-RemoveCamera           the temporary screenshot harness comes out
```

## The open list

Nothing is queued. These are the honest leftovers, smallest first.

- **`CaptureInboxService.swift` is still at 398/400.** Unchanged all session, and still the case
  that stored properties cannot move to an extension and `state`/`counts` have `private(set)`
  setters, so their writers must stay in that file. **The next stored property added there needs a
  real split first.**
- **`TaskDetailView` is 438/400.** Accepted debt of long standing. The next feature that touches it
  should split it rather than grow it again.
- **Areas' "Unfiled" card survived the door cull.** It is content rather than a duplicate door now
  — it selects the Captures tab instead of pushing its own inbox — but it is the last place a
  capture is counted outside that tab, if E ever wants it gone.
- **The Journal tab has no UI journey.** Collapsible days shipped with unit tests for the pure
  logic only. If a journey is ever added there, the composer is the obvious thing to walk.

## House rules that bit THIS session — these cost real time

### Container accessibility: FOUR instances of the same bug in one session

**A bare `.accessibilityIdentifier` on a container is INHERITED by every descendant, and
`.accessibilityElement(children: .combine)` SWALLOWS the controls inside it.** Both are invisible
on screen and invisible to the unit suite. Only a UI journey sees them.

- Today's nudges section: both buttons inside answered to `homeNudgesSection`, and
  `nudgeDismissButton-<id>` stopped existing.
- The capture undo bar: `.combine` fused its Undo button into the bar, so the button could not be
  addressed at all.
- `captureInboxSortAreaChips` already carried the correct fix, which is how the pattern was
  recognised.
- `CollapsibleSectionHeader` would have swallowed `homeArrangeButton` — caught in review before it
  shipped, and fixed INSIDE the component so no future call site can reintroduce it.

**The rule: a container that names itself and holds a control wants
`.accessibilityElement(children: .contain)` BEFORE the identifier.** Better still, build it into
the component.

### Existing ≠ hittable, and on a Form, existing ≠ existing

Two different traps, both hit this session:

- On a long **ScrollView** (Today, the Captures tab) an element below the fold is in the hierarchy
  but not tappable. Use a bounded `swipeUp` loop — `scrollUntilHittable` in
  `SignedInJourneySupport.swift`.
- In a **Form** (Settings) SwiftUI materialises rows lazily, so a row below the fold **does not
  exist at all**. `waitForExistence` cannot substitute for scrolling; it will burn the full timeout
  and then report the wrong thing.

Also: **`LabeledContent` merges its title and value into ONE element** reading "Email,
someone@example.test". Nothing carries the bare value, so match the row by identifier and assert on
its `label`.

### A flaky suite is a harness bug until proven otherwise

Adding the fifth journey made two unrelated ones fail. Both passed when re-run **in isolation**,
which is what identified the harness rather than the app. Two real defects came out of it:

- `signOutIfSignedIn` began an eight-swipe hunt for the sign-out row after only a 2s grace, so a
  Settings sheet still presenting swallowed every swipe — which then scrolled **Today** instead —
  and reported "Settings did not present a sign-out control" for a screen that had never opened.
- The same helper tapped `settingsButton` without ever waiting for it. `tabBar.exists` only proves
  the signed-in SHELL is up; Today's header arrives with its content, and a tap on a
  not-yet-existing button is a silent no-op.

**Diagnose by re-running the failures alone before touching app code.**

### On taste, render — do not guess

Three colour attempts were rejected on device before a render loop was built. The pattern that
worked, and is worth rebuilding rather than re-deriving:

- A throwaway `XCTestCase` that signs in via `UITestSession`, navigates, and calls
  `add(XCTAttachment(screenshot: app.screenshot()))`. Recover the exact file with
  `git show 22dba79:"ADHD LifeOSUITests/ComposerLookCaptureUITests.swift"`.
- Drive the appearance explicitly — `xcrun simctl ui <booted-sim-udid> appearance dark|light` —
  rather than trusting whichever the simulator happens to be in. This is what proved the
  "forced light" pad had no night face.
- Extract with `xcrun xcresulttool export attachments --path X.xcresult --output-path DIR`, then
  read `DIR/manifest.json` to map the exported UUID filenames back to attachment names.
- **Let the animation settle before the shutter.** A capture fired mid-spring showed Log's content
  on the gold footer, which reads exactly like an app defect rather than a camera one.

### Smaller things that cost time

- **The `raw_hue_color` lint rule reads COMMENTS.** Naming a built-in SwiftUI hue in a sentence
  explaining why not to use it flags the file. That is the rule behaving correctly — reword the
  sentence.
- **System *fills* are translucent by design.** `Color(.secondarySystemFill)` layers over content
  and takes its colour; on a saturated page a "grey" disabled button became gold. Filled prominent
  controls want an opaque token plus a hairline.
- **Doc comments overstate.** `JournalBackingStore` claimed logs had "no update or delete path,
  matching the `logs` rule in `firestore.rules`". The rule is `allow read, create, delete` — only
  `update` is denied. That overstatement had quietly blocked a feature. **Read the rules; do not
  trust a comment about them.**
- **`-resultBundlePath` fails outright if the path already exists.** `rm -rf` it first.
- **`xcodebuild build-for-testing`** proves every test target compiles in a fraction of a full run
  — the right check after moving or deleting a test file.
- **A five-journey run is ~8.5 minutes and exceeds the 10-minute foreground command cap** once the
  build is included. Run it in the background.

### Standing project rules (unchanged)

- Per change: failing test first → `swiftlint` (exactly the two debts) → full suite with the
  emulator up → sim build → commit + push → SHA-verify against origin → device build + install.
  Run the UI journeys when a block touches what they walk, or when a shared style has wide reach.
- File budgets 400/file, 250/type body, 50/function. House fix is a same-file extension or an
  own-file split with members made internal (`HomeCaptureDoor`, `SignedInJourneySupport`,
  `JournalDayCollapsedLineTests` are this session's precedents).
- Colour is lint-enforced (`raw_hue_color`); the asset catalog is the ONLY home for hex; haptics via
  `Theme/Haptics.swift` only; `inclusive_language` rejects "master" in DECLARATIONS.
- Wire conventions: tasks / places / location_events / focus_sessions snake_case; captures
  camelCase EXCEPT `created_at` and `tag_ids`. Tests assert the WRONG spelling is absent too.
- iOS 16.0 floor app-wide; the Places UI alone is 17+ by E's explicit §7 deviation.
- `firestore.rules` enumerates COLLECTIONS, not fields — a new field needs no rules change.
  Publishing rules stays E's call; verify live via the Firebase MCP rather than asking E to paste.
- **Never destroy uncommitted work** ([[never-destroy-uncommitted-work]]): commit working code
  BEFORE any deliberate-regression red-check, restore with `git checkout -- <file>`, and prove the
  restore by REBUILDING. Never diff against a hand-rolled backup. `xcodebuild | tail` throws away
  the exit code — use a log and `echo $?`.

Start by asking E which of the four unconfirmed things above they want to check, then take
direction. Nothing here is urgent and nothing is blocked.
