# On-device checklist — Block A, deferred logging (`9cff2b7`, installed 2026-09-05 00:52)

Installed and launch-verified on `wishwashwacky15`.

**UPDATE 2026-09-05 ~05:40 — the arc has since MERGED to main as `0cea871`, and this walk still
counts.** The app source at `9cff2b7` (what is on your phone) differs from main by a **doc comment
only** — everything else committed after it touched UI-test files. Verified with
`git diff 9cff2b7 main -- "ADHD LifeOS" FocusTimerWidget`: one file, and every changed line begins
`///`. So walking the installed build IS walking main. Reinstalling from a main build is hygiene,
not a prerequisite.

**The one sentence this build is about:** a crossing that offers a routine now writes **nothing**.
The run, Today's card and the journal line come into existence only when you **tap** the
notification. Swipe the banner away and there is no trace anywhere — that is your spec, working,
not a bug.

**Read this before you start, or you will report a bug that isn't one:** the notification body
deliberately changed. It now says **`Will journal "Leg day"`**, not `Journaled "Leg day"`. Past
tense was reporting a write that no longer happens at that moment. The old wording in the previous
handoff is stale by design.

**New button.** The test-fire dialog now has a third option, **"Open the routine notification"**.
It does not simulate a tap — it reads the banner iOS actually delivered and hands it to the same
router a real tap would. Use it whenever the banner has already gone from the screen. Firing alone
can no longer produce a routine, so you will need it.

Checks 1–5 were the essential ones; 6 and 7 the patience items; 8 the parked question. All are
now settled — see the ticked sections below.

**PROGRESS: ALL EIGHT CHECKS ARE WALKED AND PASSED (2026-09-05). Checks 1–2 by E on device;
checks 3–6 and 8 by Claude Code driving E's phone through iPhone Mirroring (E delegated, E's
hands only for connecting and the light-mode toggle); check 7 on the spare iPhone 17 simulator
against the emulator with a REAL simulated fence crossing plus a control. Evidence per check
below, and the full walk record in the session of 2026-09-05. Production Firestore was used
READ-ONLY as the ledger: every write during the walk is accounted for — two "Leg day" logs (one
per tapped run), four location_events (one per crossing), zero from dismissals, re-opens, skips,
or the one-step place.**

---

## ✅ 1. The crossing leaves NO trace — WALKED AND PASSED (2026-09-05, E)

Place: **"routines test"** (arrival: Journal "Leg day", Open Apple Maps, Open YouTube, message
"Time to train").

- [x] Tools → Places → ▶ on "routines test" → **Simulate arrival**.
- [x] A banner appears. **Swipe it away. Do not tap it.**
- [x] Today: **no routine card.** — E confirmed: "today is clean".
- [x] Journal: **no "Leg day" line** from the dismissed crossing.
- [x] Captures inbox: nothing new.

**The evidence, from E's own Journal screenshot at 7:11am — worth keeping, because it is the
shape of proof this rule needs.** Five `Arrived at routines test` timeline rows against only
three `Leg day` logs: the two crossings whose banners were DISMISSED left an arrival row and no
journal line; the three that were TAPPED left both. The topmost row, 7:11, is the dismissal, and
nothing follows it.

**One thing that looked like a failure and is not.** `Arrived at routines test` IS still written
at the crossing. That is the `location_events` timeline row
(`JournalTimeline.locationEventLine`), shipped `92a13e6` on 2026-08-27 under E's own "journal
rows only" call — a different species from a routine log, and it fires for every crossing whether
a routine is involved or not. **E reviewed it on device with the facts corrected and ruled:
KEEP IT.** The row says you were here, not that you did something. (When first asking, I
described it as invisible to Today and Journal. That was wrong; the decision was re-taken on the
real behaviour.)

## ✅ 2. The banner's words — WALKED AND PASSED (2026-09-05, E)

- [x] Title: `You're at routines test 🏃` ✅
- [x] Body, verbatim from the device: `Time to train · Will journal "Leg day" · 2 steps ready —
      Open YouTube · Open Apple Maps. Tap to run.` ✅
      (Step order follows the place's saved action order, so it reads YouTube-then-Maps here.)
- [x] The word **`Journaled`** appears nowhere. ✅

## ✅ 3. The tap creates everything — WALKED AND PASSED (2026-09-05, Claude Code via mirroring)

- [x] Fired Simulate arrival 07:27:10Z; opened via **"Open the routine notification"** (banners
      land on the locked phone, not in the mirror — the button is exactly the right tool).
- [x] The routine screen opened on "routines test" ("Time to train" · 1 of 3 done).
- [x] Journal step **pre-ticked** (blue check), subtitle verbatim **"Ran by itself when you
      started"**.
- [x] Closed → **Today showed the routine card** (AT ROUTINES TEST · ROUTINE LIVE, 2 steps left).
- [x] **Exactly one** new "Leg day" log: `323A0ECE` created 07:27:45Z — at the TAP, 35s after the
      crossing — carrying `place_id` 44D247EE… and the place's own lat/long. **The interval
      between crossing and tap had the location_event row (`07014E01`, E's deliberate keep) and
      NO log** — Block A's rule held at both timestamps.

## ✅ 4. Tapping twice does not write twice — WALKED AND PASSED (2026-09-05)

- [x] **Continue** on Today's card reopened the SAME run ("arrived 1 min 17 secs ago", still
      1 of 3 done, journal step still ticked).
- [x] Firestore still had **exactly one** new "Leg day" (`323A0ECE`); nothing newer appeared.

## ✅ 5. Departure still clears the card, with no tap — WALKED AND PASSED (2026-09-05)

- [x] Arrival routine live, fired **Simulate departure** (07:28:56Z), tabbed straight to Today.
- [x] **The arrival card was gone by the first poll (~4s)** — no backgrounding, no relaunch;
      the whole sequence stayed in-app. (`DataChangeSignal.changes` earning its keep.)
- [x] No departure card appeared un-tapped; Today rendered its normal furniture.
- [x] "Open the routine notification" → departure screen ("Leaving routines test", 0 of 2) →
      closed → **LEAVING ROUTINES TEST · ROUTINE LIVE card on Today.**
- [x] Ledger: the crossing wrote its departure location_event (`C3146344`) and NOTHING else —
      the arrival run's ending was a deletion, no log, no capture.

## ✅ 6. One tap-step is still not a routine — WALKED AND PASSED (2026-09-05), one caveat

- [x] Fired **Simulate departure** on "Action Test 01/09/2026" (07:32:27Z).
- [x] **"Open the routine notification" produced NO routine screen** — the router refused the
      per-action banner, exactly the discriminator wanted.
- [x] **No routine card on Today** for Action Test; the routines-test departure card survived
      untouched beside it.
- [x] The delivered banner routed like a real per-action tap and bounced the phone into
      **Shortcuts** (observed indirectly: LifeOS left the foreground and Shortcuts topped Siri
      Suggestions immediately after).
- Ledger: one departure location_event (`D1B18087`), zero logs.
- **Caveat, honestly held:** the banner's literal on-screen text ("Open Shortcuts") could not be
  read remotely — the phone's notification shade does not open through mirroring and macOS
  Notification Center is not capturable. Round 2 (2026-09-04) verified that byte-for-byte on
  device; nothing in this walk contradicts it.

## ✅ 7. The kill switch — WALKED AND PASSED (2026-09-05) on a REAL crossing, sim + emulator

Run on the spare iPhone 17 simulator against the local emulator (throwaway account
`etest+reckedgelato@gmail.com`, E signed in manually per the auth rule). Place **"Fence Test"**
@ Apple Park (37.3348863, −122.0089878, r=200m), TWO arrival tap-steps (Open Apple Maps + Open
Apple Music) — routine-qualifying, nudge toggles off, fence earned by actions. Crossings were
REAL CoreLocation region transitions driven by `simctl location` stepped movement (2.5km out →
stepped approach → center), not the test-fire button.

- [x] **Master OFF + crossing: nothing at all.** No banner, no card, and emulator Firestore
      showed **zero location_events and zero logs** (only the account's seed journal entry).
- [x] **Control: master ON, immediate re-cross of the same fence 3 minutes later → the arrival
      FIRED** (location_event 08:07:04Z). That single observable proves the sim geofence
      mechanism works (the OFF result is not vacuous) AND that the OFF crossing **spent no
      cooldown** — a spent 30-minute cooldown would have suppressed it.
- [x] Deferred logging held on the ON crossing too: location_event only, no card, no log
      (notification never tapped).

## ✅ 8. The light-mode keyline — ANSWERED WITH PHOTOS (2026-09-05)

**Dark: keyline PRESENT. Light: keyline ABSENT. Same Activity, no relaunch, 30 seconds apart.**
Retina captures through the mirror (E toggled appearance; both photos sent to E in-session:
`keyline-dark.png` / `keyline-light.png`, scratchpad copies kept). In dark, the pill carries the
orange `#FF6B00` ring — and the iPhone-Mirroring minimal bubble beside it gets its own green
keyline. In light, both outlines vanish; the pill sits plain black on the light chrome.

Since both colorset variants are byte-identical and there is no light branch in code, **this is
iOS suppressing `keylineTint` in light appearance — not a token bug, not a stale build, and no
colour change can fix it.** The keyline's job (edge definition on a dark background) is also
moot in light, where the black pill has maximal contrast. Recommendation: accept as iOS
behaviour; the ruling on whether to pursue further is E's.

- Observation for free: the island shows the app's Live Activity only while LifeOS is NOT
  foreground, and under mirroring the handover from the mirroring indicator to the Activity's
  compact presentation can lag a minute or two. Not a defect; worth knowing before alarm.

---

## What the suite DID verify before the merge (updated 2026-09-05 ~06:20)

**Both routine journeys passed, together, in the final pre-merge run** —
`RoutineJourneyUITests` (151s) and `RoutineRefreshJourneyUITests` (152s). The earlier caveat in
this file said they had not yet passed in one clean run; that is now out of date and the merge
went ahead on it.

Full UI target at the merge: **19 passed / 6 failed**, every failure accounted for — four
re-run at `2c46ee7` and reproducing there (so they predate this arc and sit on main either
way), one a vacuity guard added this session that turns a false green into an honest red, and
one that passes in isolation.

**Still unexplained, and NOT something your walk can settle:** a row that is on screen, settled,
and still refuses a tap. It is a test-harness mystery, not a reported product symptom — but if
you ever find a row on Today or Tools that will not respond to a tap, that is the same thing and
worth telling me about.
