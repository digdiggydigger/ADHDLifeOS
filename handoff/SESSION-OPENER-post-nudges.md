# Session opener — post nudges rebuild, next block is F-DiscPill

Read `claudecode.md`, `CLAUDE.md` and the memory index first. The previous opener
(`SESSION-OPENER-post-disc-clearance.md`) is **CLOSED** — everything it recommended shipped, and
its "recommended next block" (isolate the two login UI tests) turned out to be the thread that
unravelled two much larger problems.

The open-items list lives beside this file in `OPEN-ITEMS-REGISTER.md`. **Read it** — this opener
carries only state, the next block, and the lessons.

## State

- **`main bf8e607`**, clean, `origin/main` matches. Nine commits on 2026-08-30 (88407e1 … bf8e607).
- **Unit suite 1,867 / 0.** SwiftLint **0 violations in 558 files** — hold that line.
- **Full UI target 17 / 0.** It had NEVER been run whole before this session; run whole it was
  17/10. Do not go back to `-only-testing` scoping as the only way you run it.
- **Device `wishwashwacky15` carries `bf8e607`** — current as of session end.
- **Disk 36 GB free**, swap 0. The reboot and the 12.2 GB cache clear held.
- **The Firebase emulator must be restarted** (`./scripts/emulators.sh`, second terminal) or every
  journey SKIPS silently. Confirm 9099 / 8080 / 9199 before running UI tests.

## Next block: F-DiscPill

**E's report, twice, and it is in nearly every render this session:** the capture disc sits over
real content throughout the app — over a nudge row's time, over a capture's subtitle, over the
"Week review" card. E's own words: *"the FAB sits over multiple places throughout the app at
different stages."*

**E's design call, already made — do not re-ask:** *shrink the disc to a small pill while
scrolling.* (The alternatives offered and NOT chosen: hide-on-scroll, move it into the tab bar,
keep it fixed and extend clearance.)

**What F-DiscClearance (`b62aea4`) already did, so you do not redo it:** it added
`.captureDiscClearance()` — an 84pt `safeAreaInset` — to every screen under the disc, so the LAST
row of each scroll can clear it. That fixed the end of the scroll. It did nothing about the disc
parking over content **mid-scroll**, which is what E is reporting now.

Evidence to work from, all in-repo:
```
screenshots/nudges-door-device/dark-5-due.jpeg        disc over "Eastenders" time
screenshots/nudges-door-device/light-4-due.jpeg       disc over "nan — Tomorrow 7:10pm"
screenshots/nudges-door-device/light-nothing-due.jpeg disc over "Rough idea for 'Chef' app"
screenshots/first-nudge-reachable/*.png              disc over the "Week review" card
```

`CaptureDiscMetrics` (`Theme/Theme.swift`) owns the geometry; `clearance` is `60 + 16 + 8`. If the
pill changes the disc's size, that constant and the modifier that consumes it move together — there
is **exactly one spelling** of this clearance in the tree today and it must stay that way.

## Then, in order

1. **F-LandscapeFix.** E wants BOTH orientations supported — do not restrict the app to portrait.
   E's scope call: *fix login first, then sweep for other screens that break.* The proven defect is
   that `loginPasswordField` never becomes hittable in landscape.
2. **The pre-release UI pass** — now a list in the register, not a re-look.

## Still unanswered, and worth more than any of the above

E ran a fresh-account signup on device but we never got the answers to the two questions that
motivated it:

- **Did first-run seeding actually land?** (six life areas, starter tasks, a journal entry)
- **Does any OTHER tab dead-end the way Nudges did?** Tasks, Areas, Journal, Captures.

The Nudges dead end was a section that hid itself when empty while holding the only route to its
feature. **Nothing tests the first-run state**, because every journey seeds what it is about before
launching. If the same shape exists elsewhere it will only show on a brand-new account.

## Five lessons from 2026-08-30, each paid for

1. **A green assertion is not the same as the screen showing the thing.** Three near-misses in one
   session: a still shot mid-animation; a render named "keyboard-up" containing no keyboard
   (`app.keyboards` was satisfied by the simulator's attached HARDWARE keyboard); and a proposed
   `XCTAssertFalse(app.buttons["Done"].exists)` that would have passed with or without the fix.
   Before trusting a still, ask what would be in it if the fix were absent. **"Unverified, and here
   is why" is a legitimate result.** See [[geometry-journey-vacuity]].

2. **Tests prove correctness, never REACHABILITY.** The nudges empty-state copy was written,
   documented and unit-tested behind a gate no user could pass. Ask "what state must the user be in
   to see this, and can they GET to that state?" See [[dead-shared-component-pattern]] — six
   instances now, and the old advice ("grep call sites") would have MISSED this one, because the
   call site was fine and the section around it was gated off.

3. **A failed grep is evidence about your search, not about the codebase.** While correcting
   CLAUDE.md I nearly "fixed" two claims that were right: `FirebaseDailySummaryDataAdapter` exists
   inside another file, and `Color.cardSurface` is an asset-catalog-generated symbol. Confirm a
   negative a second way before writing a correction.

4. **A deliberate, documented decision can still be the bug — surface it, do not reverse it
   silently.** The nudges gate carried its own reasoning ("an empty schedule is not news"). That
   was right about a status card and wrong about a feature's sole entrance. E chose a third option
   that preserved the original intent. Same for the keyboard Done bar, which was E's own BUG-b5.

5. **Check the DENOMINATOR before comparing two coverage figures.** 23.62% is not a fall from
   25.35% — the denominators were 36,721 and 20,794, measuring different extents. Covered lines
   rose 64%.

## Two corrections to the record worth knowing

- **`AccentColor` is iOS system blue (`#0A7CFF`), not coral.** CLAUDE.md claimed coral for months;
  there is no coral colorset. Every blue thing in the app is the accent behaving correctly.
- **The "9/9 journeys" figure only ever added up as 3 + 9**, which is what proved earlier runs were
  scoped and excluded `testLaunch` — the test that was poisoning every journey after it by leaving
  the simulator in landscape.
