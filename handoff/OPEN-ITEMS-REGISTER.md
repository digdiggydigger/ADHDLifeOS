# Open items register — 2026-09-25 (eighty-fourth edition; **`F-E2-NextStepField` is BUILT — arc E's second block; the session STOPS here at a clean line and E3 starts fresh.** A task carries one optional "Next step" line (`next_step`, snake_cased; cleared = delete), editable on Task Detail beside Notes, staged behind Save and autosaved on the way out; no rules change. The `apple-design` review caught a High in the block's own frame — a saved line read as an unnamed note once its placeholder vanished — and it was fixed in-block with a "Next Step" caption. Suite **3,375 / 0** after a clean build, SwiftLint **0 / 902**; coverage waits for the arc close. `screenshots/next-step-field/` filed. **Two machine traps cost reruns, neither an app bug:** an ORPHANED Firestore JVM with Auth/Storage dead, and a stale incremental build that crashed Task Detail.) Opener: `handoff/START-HERE-adhd-audit-arc-E3-onecard.md` — a `WIP:` opener for `F-E3-OneCardToday`, then E4, E5 and the arc close. **Nothing is owed to E mid-arc; E1's and E2's phone looks are batched to `handoff/ARC-REVIEW-E.md`.** *(Edition 83's header, superseded: Open items register — 2026-09-25 (eighty-third edition; **`F-E1-WeeklyChain` is BUILT — arc E's first block, under the per-arc bypass.** One streak survives: a WEEKLY chain (a week counts at 3 active days by default — a closed task, a finished sprint, a sorted capture or a journal line — with one missed week per rolling four weeks bridged). Both daily goals are OFF until set (pre-E1 5/30 decode as none; the migration keys on the chain field so a chosen 5 survives), Close reads "Close it — makes today count" until today counts, and the closing streak, every best-ever tally, the nudge "· best N" and the widget's focus streak are gone. Suite **3,366 / 0**, SwiftLint **0 / 900**, build SUCCEEDED; coverage waits for the arc close. `screenshots/weekly-chain-goals-off/` filed.) Opener: `handoff/START-HERE-adhd-audit-arc-E.md`, still live (the opener is written once per arc). **Nothing is owed to E mid-arc; the phone look is batched to `handoff/ARC-REVIEW-E.md`.** *(Edition 82's header, superseded: Open items register — 2026-09-24 (eighty-second edition; **ARC D IS CLOSED: `F-D3-TasksAnytimeRow` is BUILT and MERGED (PR #202, `ca06c04`), and the arc's build is ON E'S PHONE.** Undated open tasks fold into "Anytime · N", last on Momentum and collapsed by default (round 6); beyond-tomorrow stays off the board (8b). A third test the spec missed was reversed in place; the red-check caught a VACUOUS sprint guard (a `contains` check passed a build that widened ▶ to Anytime) and it now pins the whole line. Suite **3,344 / 0**, SwiftLint **0 / 895**, clean build-for-testing SUCCEEDED, **arc-D coverage 30.08% (15,101/50,195)**; `screenshots/tasks-anytime-row/` filed (9 frames, L / D / AX). **`ca06c04` built, installed and launched on `wishwashwacky15`.**) Opener: `handoff/START-HERE-adhd-audit-arc-E.md`, which builds arc E from `F-E1-WeeklyChain`. **E's verdicts, the same day: *"D1–D3 pass"* (all three blocks PASSED on the phone, RM off) and *"Keep the chevron as is"* (§A-CHEVRON DECIDED). Nothing is owed to E.** *(Edition 81's header, superseded: Open items register — 2026-09-24 (eighty-first edition; **`F-D2-ComposerKeyboardLayout` is BUILT — arc D's second block, under the per-arc bypass.** Round 7b's L3: the title owns the page and the four "when" segments ride over Area | Time | Add in one panel above the keyboard (402–538pt keyboard-up); accessibility sizes stack (L1's form); the Date segment reads "Date" then the picked day; the popover offers a day only. **A design-changing finding stopped the block mid-arc and E decided it the same hour:** on iOS 27 EVERY presentation (SwiftUI `Menu`, a UIKit menu tried in its place, the popover) drops the keyboard and it does not return, so the carried condition could not hold — **E chose "Let it settle"** (the bar settles once and stays; nothing re-focuses the title) **and "Keep the panel"** (the Liquid Glass container). Suite **3,337 / 0**, SwiftLint **0 / 892**, build SUCCEEDED; coverage waits for the arc close. `screenshots/composer-l3-layout/` filed.) Opener: `handoff/START-HERE-adhd-audit-arc-D3-anytime.md` — a `WIP:` opener (the session stopped at 65% context on E's warning, with D2 LANDED); it builds `F-D3` then closes arc D. **Nothing is owed to E mid-arc; the phone check is batched to `handoff/ARC-REVIEW-D.md`.** *(Edition 80's header, superseded: Open items register — 2026-09-24 (eightieth edition; **`F-Floor18` is BUILT and MERGED: the minimum iOS is 18 on every target.** All six `IPHONEOS_DEPLOYMENT_TARGET`s read 18.0 and both built `Info.plist`s read `MinimumOSVersion 18.0`; the 89 availability checks below 18 that the RED run counted are gone — only the three iOS 26 gates remain, their `else` now meaning 18–25; Places and the routine screen are universal and the three absence flags (`placesSupported`, `available(placesSupported:)`, `routineScreenAvailable`) are deleted; the 35 `onChange(of:perform:)` deprecations are fixed and a CLEAN build of all four targets shows 0; eleven tests were REVERSED in place with E's words quoted and none deleted; `DeploymentFloorTests` (RED 7 → GREEN) is the tree-wide guard the compiler does not provide. Governing docs rewritten (CLAUDE.md §7 and the Architecture bullet, the open TODO blocks D2/F2/F5/A3/A4/G1–G5, this register's live rows, six memory notes); records untouched (`git diff --stat` over the archive, the screenshots, `TODO-ARCHIVE.md` and every `SESSION-OPENER-*` is EMPTY). Suite **3,320 / 0**, SwiftLint **0 / 886**, clean build SUCCEEDED, coverage **30.18% (15,074/49,955)**. **E asked for the iOS 18 simulator runtime to be installed for E; it cannot be from the CLI** (§A has the route). Device smoke PASSED on E's phone — E: *"Passes"*.) Opener: `handoff/START-HERE-adhd-audit-arc-D2-keyboard.md`. **Nothing is owed to E.** *(Edition 79's header, superseded: Open items register — 2026-09-23 (seventy-ninth edition; **E decided the FLOOR: the minimum iOS goes from 16 to 18, BEFORE `F-D2`.** *"iOS 18, before F-D2 — write the spec block"*, and find every place the iOS 16 floor lives. `F-Floor18` is SPECCED (not built) directly above `F-D2` in `TODO-CLAUDE-CODE.md`, from a measured inventory: six build settings, ~95 availability annotations in 43 files, 35 deprecated `onChange` spellings, the tests that pin the floor, and the governing docs — while the RECORDS stay untouched. A throwaway worktree built the app at BOTH floors: 18 is GREEN, adds only the 35 deprecations and removes 5 linker warnings, and the ~1,790 concurrency warnings are pre-existing. **Also this session: `F-D1` was INSTALLED on E's phone** (`main @ d85b18a`, launch verified). No Swift changed after edition 78; its figures stand.) Opener: `handoff/START-HERE-floor18-then-D2.md`. **Nothing is owed to E.** *(Edition 78's header, superseded: Open items register — 2026-09-23 (seventy-eighth edition; **`F-D1-ComposerBothDoors` is COMPLETE — arc D's first block.** The Tasks "+", a life area's "Add to <area>" and the capture disc's Task tile (and the widget door, which routes the same way) now open ONE composer: a title, the four when-chips, and Area and Time pop-up menus. Tags, place and notes live on the task, and the tag methods were PRUNED from the create seam rather than left dead. **A frame beat every green gate for the second block running**: the first after-render measured the Area menu's tap target at **338 × 20.3pt** inside a card drawn 48pt tall. A `Menu`'s hit area is its label; fixed, and the harness now asserts ≥ 48pt. Suite **3,317 / 0**, SwiftLint **0 / 885**, build SUCCEEDED, coverage **30.11% (15,081/50,094)**, `screenshots/composer-both-doors/` filed with 12 frames and a README.) Opener: `handoff/START-HERE-adhd-audit-arc-D2-keyboard.md`. **Nothing is owed to E** — but `F-D2` opens on TWO Step 0 questions that are E's. *(Edition 77's header, superseded: Open items register — 2026-09-22 (seventy-seventh edition; **`F-C4-TagsRecentlyDeleted` is COMPLETE.** Tags are the third kind in Recently Deleted, and a tag delete now does LESS than it used to: it stamps the document and touches no `tag_ids` array, so the old atomic cascade became the 30-day purge and E's *"back on every item"* is a property of never having unlinked. **E took one decision** — the Tag Editor's delete confirmation is gone, replaced by an Undo capsule, the third time that reasoning has run. **And a FINDING: that capsule is mounted but INVISIBLE in the Tag Editor**, because Settings is a `.sheet` and the capsule lives in `RootBottomOverlay` beneath it — every gate was green while this was true, and only a frame caught it. **E answered it the same day: Option C, DEFERRED with a condition — circle back and add a user in-app notification** (§A-CAPSULE, which stays open as WORK). Suite **3,306 / 0**, SwiftLint **0**, build SUCCEEDED, coverage **30.03% (15,103/50,300)**, `screenshots/recently-deleted-tags/` filed with 16 frames and a README.) Opener: `handoff/START-HERE-adhd-audit-arc-D1-composer.md` — **arc C is CLOSED, all four blocks merged**, and the build moves to arc D. **Nothing is owed to E. The capsule-behind-the-sheet question was ANSWERED the same day — Option C, DEFERRED with a condition: circle back and add a user in-app notification. §A-CAPSULE stays open as WORK, not as a question.** *(Edition 76's header, superseded: Open items register — 2026-09-22 (seventy-sixth edition; **docs-only chore: the LAUNCH GATES the monetisation audit surfaced are now in §D.** A read-only audit of this repo, `PersonalChef---Template` (Chef.ly) and `v2MaidServe` ran the same day OUTSIDE the repo — four strategy files in `../MONETISATION AUDIT/` beside this clone, a web page, a session record. It found that LifeOS cannot reach the App Store without eight things nobody had listed here: a privacy manifest (a hard upload reject), policy/terms URLs, a per-user cap on `dailySummary` (uncapped Opus 5 costs more per engaged user than a £3.99 UK subscription nets), the iPad device-family decision, a multi-tenant `capture` function, StoreKit, onboarding and analytics. **No Swift changed; suite, lint and coverage are as edition 75 recorded them and were NOT re-run for a register-only change.**) Opener: `handoff/START-HERE-adhd-audit-arc-C4-tags.md`, unchanged. **Nothing is owed to E.** *(Edition 75's header, superseded: Open items register — 2026-09-22 (seventy-fifth edition; **`F-C3-RecentlyDeleted` is COMPLETE and MERGED.** Deleting a task or a capture now stamps rather than destroys: the document survives 30 days, the capsule offers Undo at the moment of the delete, one row in Tools opens the list, Restore is a visible 48pt button, and a launch purge clears anything past the window. **The hard delete left every UI-facing seam** — a tree-walking test keeps it out. **E took two decisions the `apple-design` review surfaced**: both delete CONFIRMATIONS are gone (`alerts.md`: do not confirm common, undoable actions), and "Discard" became **"Delete"** on captures so one action stops having three names. Suite **3,253 / 0**, SwiftLint **0 / 877**, build SUCCEEDED, coverage **29.87% (14,953/50,068)**, `screenshots/recently-deleted/` filed with 20 frames and a README.) Opener: `handoff/START-HERE-adhd-audit-arc-C4-tags.md`. **Nothing is owed to E.** *(Edition 74's header, superseded: Open items register — 2026-09-22 (seventy-fourth edition; **`F-C3-RecentlyDeleted`'s READ SIDE is landed and INERT.** Three RED→GREEN→commit cycles: `SoftDelete`, the stamp on four models, and `live(_:)`/`requireLive(_:)` over all NINE read paths with a call-site test that pins their COUNTS so a tenth cannot be added unfiltered. **Nothing writes `deleted_at` yet, so behaviour is unchanged** — the only boundary in this block where that is true. Suite **3,192 / 0**, SwiftLint **0 / 859**, build green, coverage **29.89% (14,713/49,217)**. Earlier the same session: BOTH device looks PASSED and `F-C2`'s screenshots debt was discharged.) Opener: `handoff/START-HERE-adhd-audit-arc-C3-continued.md`. **Nothing is owed to E.** *(Edition 73's header, superseded: Open items register — 2026-09-22 (seventy-third edition; **BOTH device looks PASS and NOTHING is owed to E.** `F-C1`'s shape on E's own phone — fully rounded, no chip, one line, the subject reading in full — and `F-C2`'s capsule reading *"Kept in your inbox · ↗ Reopen"* with Reopen landing on that capture; on the swipe-back, E: *"Also passes"*. **`F-C2`'s last unmet acceptance criterion is DISCHARGED**: `screenshots/drafts-to-inbox/` landed at PR #183 (`51910cd`) with 33 frames and a harness, SwiftLint **0 / 854**. Eleven device frames filed in `screenshots/undo-capsule-device/` and `screenshots/drafts-to-inbox-device/`. **One finding of mine was RETRACTED by E's own frames** — see §D. `F-C3-RecentlyDeleted` started.) Opener: `handoff/START-HERE-adhd-audit-arc-C3-deleted.md`. **Nothing is owed to E.** *(Edition 72's header, superseded: Open items register — 2026-09-20 (seventy-second edition; **`F-C2-DraftsToInbox` is BUILT and MERGED** — unsent text in any of the three composers is filed into the Capture Inbox as a note, the capsule says *"Kept in your inbox · Reopen"*, Cancel became **Close** on all three, and task detail's blocking *"Discard changes?"* is gone with **swipe-back restored**. Suite **3,174 / 0**, SwiftLint **0 / 853**, build green, and the two UI journeys this touches were run deliberately: **6/6 PASSED**.) Opener: `handoff/START-HERE-adhd-audit-arc-C3-deleted.md`. **TWO things owed to E, both device looks (RM-off): `F-C1`'s shape round AND this block. One thing owed to the code: `screenshots/drafts-to-inbox/`.** *(Edition 71's header, superseded: Open items register — 2026-09-20 (seventy-first edition; **`F-C1-UndoCapsule`'s SHAPE ROUND is BUILT** — fully rounded, no chip, the Undo control's 16pt padding deleted, ONE line, 44pt. **The render caught a Critical the round could not have:** every frame E ever chose from was at the DEFAULT text size, and a `Capsule`'s radius is derived from its height — at Accessibility XL's 194.3pt card the caps grew to 97.2pt and **6,329 pixels of the completion glyph and 2,604 of the ↶ Undo control were drawn OUTSIDE the card**. E was shown both shapes and **chose to cap the radius at `minHeight / 2`**, which is pixel-identical to a capsule at the 44pt E approved. Suite **3,137 / 0**, SwiftLint **0 / 843**, build green, coverage **29.83% (14,612/48,985)**.) Opener: `handoff/START-HERE-adhd-audit-arc-C2-drafts.md`, which builds `F-C2-DraftsToInbox`. **ONE thing is owed to E: the RM-off device look on the new shape.** *(Edition 70's header, superseded: Open items register — 2026-09-20 (seventieth edition; **`F-C1-UndoCapsule` went to E's phone for the FIRST time and the shape came back**. The **Reduce-Motion-ON pass PASSED** — *"Passes your request requested checks"* — so §7.3's pass is DISCHARGED, not owed. RM-off sent the capsule back: no chip, fully rounded, and E then chose **44pt with ONE wider line** over a 59pt two-line card. **No Swift shipped** — the round's code was removed before merging. Suite 3,132 / 0, SwiftLint 0 / 842.) Opener: `handoff/START-HERE-adhd-audit-arc-C1-shape.md`, which BUILDS the chosen shape then `F-C2-DraftsToInbox`. **Nothing is owed to E.** *(Edition 69's header, superseded: Open items register — 2026-09-20 (sixty-ninth edition; **`F-C1-UndoCapsule` built, landed, then RESIZED on E's call**: the capsule went 74pt → **44pt** — *"it looks ugly with the UndoCapsule at the same height as the FAB Icon"* — with E choosing the shape and the Undo control's draw-32/tap-44 trade from real renders. Suite 3,132 / 0, SwiftLint 0 / 842.) Opener: `handoff/START-HERE-adhd-audit-arc-C2.md`. **E's phone must be RECONNECTED — the device look is owed and has never happened.** *(Edition 68's header, superseded: Open items register — 2026-09-20 (sixty-eighth edition; **the ADHD audit's first block is BUILT**: `F-C1-UndoCapsule` — one undo capsule in the disc row for every close — merged, suite 3,130 / 0, SwiftLint 0 / 842. **The first app Swift the audit has produced.**) Opener: `handoff/START-HERE-adhd-audit-arc-C2.md`, which builds `F-C2-DraftsToInbox`. *(Edition 67's header, superseded: Open items register — 2026-09-19 (sixty-seventh edition; **the ADHD / neurodivergent UX audit is CLOSED**: session 3 ran rounds 7b–10, collected Decision A, and specced **all 31 FEATURE blocks** across seven arcs in `TODO-CLAUDE-CODE.md`. **No Swift changed in the whole audit — three sessions of records, evidence and specs.**) Opener: `handoff/START-HERE-adhd-audit-arc-C.md`, which builds arc C. *(Edition 66's header, superseded: # Open items register — 2026-09-19 (sixty-sixth edition; **the ADHD / neurodivergent UX audit, session 2: options rounds 2–7 DONE** (drafts, undo, Recently Deleted, Today = one card, the sprint, the hero, composers, targets) plus E's nine Today ideas; every answer verbatim in `handoff/SESSION-OPENER-adhd-ux-audit-design.md`. **No Swift changed.** Handed off at round 7b by E's call at 60% context.) Opener: `handoff/START-HERE-adhd-ux-audit-rounds-7b-to-10.md`. *(Edition 65's header, superseded: Open items register — 2026-09-19 (sixty-fifth edition; **E opened the ADHD / neurodivergent UX audit** — research, E's ten answers, a full iPhone 18 Pro / iOS 27.0 simulator audit (~80 findings, 51 frames) and options round 1. **No Swift changed.** Handed off at round 1 by E's call.) Opener: `handoff/START-HERE-adhd-ux-audit-rounds.md`.)*)*)*)*)*)*)*)*)*)*)*)*)*)*)*)*)*)*)*


> ## Edition 84 in six lines (2026-09-25, arc E — `F-E2` built; the session hands E3 to a fresh one)
>
> - **Model:** `nextStep` on `TaskItem`/`TaskSummary`/`TaskDetail` (`next_step`); `TaskUpdatePayload.nextStep: String??`;
>   `TaskEditedFields.nextStep: String?` (unstaged = unchanged). No `firestore.rules` change (whole-document CRUD).
> - **Surface:** Task Detail's row beside Notes — a footnote caption "Next Step" over a field whose placeholder is "What
>   to do first" (the `apple-design` High fixed in-block, `text-fields.md › Best practices`). Card-side editing is E3's.
> - **Red-check:** 19-error compile RED; six compiling mutations, all caught (restored 56 / 0).
> - **Traps (memory updated):** an orphaned Firestore JVM on 8080 made emulator tests FAIL rather than skip; a `some
>   View` shape change in a split file crashed Task Detail on a stale incremental build (clean build fixes it).
> - **Register candidate (C2, below the bar):** Notes has the same placeholder-only shape the Next Step row just lost.
> - **Next:** `F-E3-OneCardToday` in a FRESH session (E3 is the arc's biggest block; this one stopped at ~55%).

> ## Edition 83 in six lines (2026-09-25, arc E — `F-E1` built)
>
> - **Model:** `Home/WeeklyActiveChain.swift` (four signals, calendar weeks, N 1…7 default 3, rolling four-week
>   repair that bridges without counting); `MomentumPreferences` goals `Int?` + `weeklyActiveDayGoal`, migration keyed
>   on the chain field; `DailyGoalRules.goal: Int?` so no goal is never crossed.
> - **Surfaces:** Close's gain line on all THREE detail doors (spec named two; Journal is the third); Settings reveal
>   rows; `MomentumRingCard` without a goal shows a plain count and no streak column (the spec missed that decode→nil
>   changes Today); widget + in-app focus goal bars gated on a set goal; the focus and nudge best tallies retired.
> - **Red-check:** compile-failure RED, then 11 compiling mutations all caught (restored 90 / 0).
> - **`apple-design`: Good**; one in-scope Medium fixed (the chain's Stepper now hides with the chain).
> - **Handed to E3/E4:** Today's hero still reads plain "Close it" (E3 takes `closeButtonTitle`); E4's `streakLine`
>   deletion is already done.

> ## Edition 82 in six lines (2026-09-24, arc D closes — `F-D3` built, the build on the phone)
>
> - **Anytime is built** (`Tasks/MomentumTaskBuckets.swift` `case anytime` LAST; `Tasks/TasksAnytimeHeader.swift`;
>   `TaskListView`'s `@AppStorage("tasks.anytimeCollapsed") = true`). The header is the shared `CollapsibleSectionHeader`,
>   painted the page because it pins; ▶ stays on Due today. Frames: folded "ANYTIME · 2", the count moving to 3 with the
>   fold closed, the new task there once opened; header 370 × 44.0pt at default and AX XL.
> - **Tests:** RED 9 tests / 14 failures; three reversed in place (`MomentumTaskBucketsTests` ×1 + two fixtures,
>   `TasksServiceTests` ×1 — the one the spec missed); new `TasksAnytimeRowCallSiteTests`, `TasksAnytimeRowRenderUITests`.
> - **Red-check:** both-file restore = compile failure (2); seven compiling mutations, each caught by its own test —
>   after **the sprint guard was found VACUOUS** (a superset line passed `contains`) and fixed.
> - **`apple-design`: Good.** Medium: the house chevron vs `disclosure-controls.md` (§A-CHEVRON, E's). Medium, HELD for
>   the colour arc: the `.tertiary` chevron is 1.71:1 light / 2.47:1 dark (title 3.30 / 6.11, passes bold 3:1). Low:
>   the 44pt fold sits ~8pt looser than its 8pt-padded neighbours (§3 wins).
> - **Arc D's close ran:** coverage once (30.08%), `ca06c04` INSTALLED on E's phone first, then `handoff/ARC-REVIEW-D.md`
>   (16 items, three verdict lines; no RM-on pass owed anywhere in arc D). D1 had never been on the phone on its own.
> - **Next:** arc E, back to back under the bypass, from `handoff/START-HERE-adhd-audit-arc-E.md`. E1 has no Step 0.
> - **VERDICTS, same day:** E — *"D1–D3 pass"* and *"Keep the chevron as is"*. Arc D is closed with nothing owed.

> ## Edition 81 in six lines (2026-09-24, arc D — `F-D2` built, and the keyboard finding)
>
> - **L3 is built from the probe's geometry** (`Tasks/TaskComposerKeyboardBar.swift`,
>   `Tasks/TaskComposerControls.swift`, `Theme/ComposerMenuTile.swift`): 48pt segments, 56pt tiles,
>   a 48pt Add, concentric 24pt panel. Keyboard-up bar 402–538pt (approved 406–518pt); no keyboard
>   "Done" row exists on this screen, before or after.
> - **The finding:** findings §L's "a menu keeps the keyboard up" was unverified and is FALSE on iOS 27 —
>   SwiftUI `Menu`, UIKit `UIButton` menu and popover all drop it, and focus never returns. **E: "Let
>   it settle"** (over hold-and-refocus and over inline choices) and **"Keep the panel"**. Memory
>   `menus-dismiss-the-keyboard`.
> - **Fixed in-block, all mine:** a ~60pt popover sliver (now 320pt, asserted on screen); "No…"/"15…"
>   at xxxLarge (layout priority + 0.8); Close's 48×48 cannot be reached inside a bar item (72×36 on
>   27, 56×56 on 18) → reverted and handed to `F-B1`.
> - **Red-check:** the pre-block restore is a COMPILE failure (1 error, the pruned `popUpRowHeight`);
>   nine compiling mutations → 16 failures / 9 tests, all caught; restored 28 / 0.
> - **Verified paths:** 26 (Liquid Glass panel) run on sim 27.0; 18–25 (bar-material panel) run on
>   sim 18.0, light and dark; 19–25 never run. E's phone at the arc close. No RM site → no RM-on pass.
> - **Next, a FRESH session** (this one stopped at 65% on E's warning): `F-D3-TasksAnytimeRow` from
>   `handoff/START-HERE-adhd-audit-arc-D3-anytime.md`, then the arc-D close.

> ## Edition 80 in six lines (2026-09-24, `F-Floor18` — the floor is 18)
>
> - **The floor moved, everywhere, in one PR of six commits**: settings + `DeploymentFloorTests`
>   (RED 7: six settings and 89 gates); the ActivityKit/App Intents/trivial gates; the iOS 17
>   degraded sites incl. `.haptic`'s UIKit branch; Places + routines universal with the three flags
>   deleted and the tests reversed; the 35 `onChange` spellings; the governing docs.
> - **Numbers that must be right:** six `18.0` settings and no other value; `MinimumOSVersion 18.0`
>   on the app AND the widget (`plutil`); 0 gates below 18 (test + grep); 0 `onChange` deprecations
>   on a CLEAN build; 3 iOS 26 gates intact.
> - **Red-checks both ways:** a planted `#available(iOS 17.0, *)` → 1 failure; a planted `16.0`
>   target → 1 failure (each restored with `git checkout --` and proven by a green re-run).
> - **The inventory reconciled:** the spec's "~95 in 43" was 93 in 41 by grep (four were comment
>   lines) and 89 in code; the spec's 35 `onChange` sites were exactly the compiler's 35 (+2 test
>   pins the spec did not list: `AppSearchCallSiteTests` twice).
> - **Nothing looks different on E's phone (27.0)**, so no `apple-design` review and no RM-on pass
>   were owed; the device SMOKE launch (widget, Live Activities, App Intents all changed targets)
>   is recorded in State.
> - **E pulled the other two speed levers the same evening:** **per-arc BYPASS for arcs D–G** (build
>   an arc's blocks back to back, each fully gated; stop at the arc close with the phone build
>   installed and `handoff/ARC-REVIEW-<arc>.md` for E's one-pass review; F-F1's Plan-Mode round,
>   F-F5's render pass, design-changing findings and red gates still stop) and the **three build-loop
>   economies** (targeted runs in the loop, `test-without-building` for source-reading tests, one
>   scripted close-out chain; coverage once per arc). Both are now standing rules in `CLAUDE.md`.
> - **E's ask this session — install the iOS 18 sim runtime — DONE by the end of the day:** E downloaded
>   the DMG, the install needed the inner image extracted and cloned (five attempts; §A, memory
>   `simulator-runtime-install`), and **the suite passes on iOS 18.0: 3,320 / 0.** The floor path is no
>   longer compile-only.
> - **LATER THE SAME DAY: E answered EVERY open Step 0 question in one message** — *"Take all the
>   recommendations as written"* — 17 questions across 10 blocks (D2, E3, E4, E5, F1, F5, A1, A2, A4,
>   B2, G5), each written into its block in `TODO-CLAUDE-CODE.md` as **"E DECIDED 2026-09-24"**. Plus
>   one directive: **F-F1 MUST open with a thorough questioning of E on the checkpoints → heads-up
>   redesign before any code.** The biggest speed lever on the remaining build is now pulled.

> ## Edition 79 in six lines (2026-09-23, the floor decision — docs only)
>
> - **E's call:** the minimum iOS rises from 16 to **18**, in its own block, **before `F-D2`**. 18
>   was recommended over 17 because it excludes the same hardware (iPhone 8, 8 Plus and X stop at
>   16 and are lost at ANY floor ≥ 17) and unlocks more. The app is not public, so no user strands.
> - **`F-Floor18` is SPECCED, not built.** A global sweep, never beside another block.
> - **The compiler was asked, not guessed:** a worktree at 18 builds GREEN and adds exactly 35
>   `onChange` deprecations; the ~1,790 concurrency warnings are identical at 16 and NOT this block's.
> - **The trap the spec names:** Swift does not warn about a `#available` check made redundant by the
>   deployment target, so the grep is the only inventory and a new tree-walking test the only guard.
> - **Governing docs get rewritten; records do not.** CLAUDE.md §7, open TODO specs, live register
>   rows, memory and the opener change IN the build; `TODO-ARCHIVE.md`, `handoff/archive/`,
>   `SESSION-OPENER-*` and every screenshots README stay as the history they are.
> - **`F-D1` is on E's phone** (`d85b18a`), installed and launched in one wireless pass.

> ## Edition 78 in six lines (2026-09-23, arc D — `F-D1` built, and a frame found a bug again)
>
> - **The block is done and every acceptance criterion is met.** RED was 15 of 23 tests (66
>   assertion failures + 1 thrown) against a compile-only scaffold; GREEN 49/0 targeted, then 3,317/0 in full. The
>   red-checks: restoring the three pre-block files is a COMPILE failure (3 errors, the pruned
>   seam); three compiling mutation batches failed **6 tests / 9 assertions** and **2 / 5**.
> - **E's decisions are built as E made them.** "One composer, both doors" (round 6); the content
>   is title + four when-chips + Area and Time MENUS; Area's empty choice reads "None" (round 10b);
>   new tasks are undated unless a chip says otherwise, so CAPT-02's forced date is gone.
> - **Time defaults to 15 min and is always written**, because every board E approved read
>   "15 min". The named cost is that tasks from the Tasks "+" door go from `nil` to 900 seconds,
>   which moves them in `MomentumScoreboard.bestNextMove`'s effort ranking.
> - **THE FINDING: the Area menu's tap target was 338 × 20.3pt inside a 48pt card.** The card was
>   padded from outside the `Menu`, whose hit area is its label. The picture looked right and the
>   suite, lint and build were green; the render harness's tap failed on it. Fixed by sizing the row
>   inside the label, and the harness now asserts both menus are ≥ 48pt.
> - **One test was VACUOUS and is fixed.** `ComposerDraftCallSiteTests` looked for the disc
>   composer's `captureClient:` in `RootView.swift`, where the tabs make it pass whatever the cover
>   does. It now reads `RootView+Doors.swift`, and the red-check proves it catches the revert.
> - **`apple-design`: Good.** One High is recorded rather than fixed, because contrast is held for
>   the colour arc (R9): the menu value text in light is **3.22:1** (§A0). One Medium goes to §C2:
>   the composer's warning is never on screen long enough to read (pre-existing shape).

> ## Edition 77 in six lines (2026-09-22, arc C — `F-C4` finished, and a frame found a bug)
>
> - **The block is done and every acceptance criterion is met.** Six RED→GREEN→commit cycles: the
>   stamp on `Tag` (its FIRST `CodingKeys`, because `deletedAt` is the first multi-word field the
>   collection has ever had), the manager layer, the Tag Editor's seam renamed rather than
>   re-pointed, the third kind in Recently Deleted, and merge-on-restore in one atomic batch.
> - **ONE `live(` wrap covers EIGHT screens**, and that is structural rather than lucky:
>   `fetchTags(for:parentId:)` and `fetchTag(named:)` both resolve through the base `fetchTags()`.
>   A call-site test pins that they keep doing so, because re-pointing either at a raw
>   `fetchAll(Tag.self, …)` would restore the deleted tag to that surface and break nothing else.
> - **E's decision: the tag delete's confirmation is GONE, replaced by an Undo capsule.**
>   `alerts.md` only asks for an alert on an uncommon destructive action *"that they can't undo"*;
>   `feedback.md`, read afterwards, says it from the other side. The named cost: the USAGE COUNT
>   was only visible before the tap and the capsule cannot show it.
> - **THE FINDING, and it is §A's newest row: that capsule is MOUNTED BUT INVISIBLE.** Settings is
>   a `.sheet` from Today and `RootBottomOverlay` — where the capsule and the tab bar both live —
>   is beneath it. The harness's `untilExists: capsule` PASSES, because XCUITest finds occluded
>   elements; `.environment(\.recordAction, …)` is applied outside every sheet so the RECORDING
>   works. **Inheriting the environment is not being drawn**, and nothing in the suite can tell
>   them apart. This is the per-surface-mount failure CLAUDE.md already documents for Celebrations.
> - **Two things found by reading, not by a failing test.** `renameTag`'s clash check is live-only
>   too, so renaming onto a hidden tag's name succeeds — a SECOND route into the merge case. And
>   the survivor choice is not cosmetic: the collision folds case while the app renders the stored
>   case, so the survivor decides which spelling the user is left reading.
> - **`TagEditorService.restore(tagId:)` measured 0.00% (0/11)** on the coverage run — written this
>   session, reachable in production, exercised by nothing. F-AdapterDrift's exact shape, findable
>   only by reading the report. Three tests now cover it.

> ## Edition 76 in six lines (2026-09-22, register-only chore — the audit's launch gates)
>
> - **Nothing in the app changed.** This edition exists so the work queue KNOWS what a
>   read-only session found; the Swift, the suite and the C4 opener are exactly as edition 75
>   left them. The figures below are carried, not re-measured.
> - **The finding that matters most is a hard reject, not a polish item:** there is no
>   `PrivacyInfo.xcprivacy`, and 35 files use `UserDefaults`, a required-reason API. App Store
>   Connect refuses the upload. It was in nobody's list because no upload has ever been attempted.
> - **The second is a cost hole shaped like a feature.** `dailySummary` calls `claude-opus-5` per
>   request with no per-user quota. At $5/$25 per MTok one summary a day is ~$2–3 per engaged user
>   per month; a £3.99 UK subscription nets ~£2.83 after VAT and Apple's 15%. Model and frequency
>   are E's pricing decision (Sonnet 5 ≈ $1.2, Haiku 4.5 ≈ $0.6); the CAP is a blocker either way.
> - **Six more gates, in dependency order, are now §D rows** — policy/terms URLs, iPad (declared
>   `"1,2"`, never designed: design it or set `"1"`), the single-tenant `capture` function (fixed
>   UID + one shared secret), StoreKit behind a `SubscriptionStatus` seam in the house adapter
>   pattern, an onboarding flow (only a first-run card exists), and analytics of the TelemetryDeck
>   kind (none exists, so no activation or retention data can be collected today).
> - **None of these is a block yet.** They are register rows so that the next launch-readiness
>   conversation starts from a list rather than from memory. The audit's ordering, the reasoning and
>   the numbers are in `../MONETISATION AUDIT/` (files 01 and 02), which is outside git on purpose.
> - **One item the audit found is not the app's and is not here:** a public repo of E's exposes a
>   live Firebase config with open rules. It is E's action, recorded in the audit's file 04 §0.


> ## Edition 75 in six lines (2026-09-22, arc C — `F-C3` finished)
>
> - **The block is done and it is no longer inert.** Five more cycles on top of the three that
>   landed last session: the write payloads, the manager methods, the hard delete leaving every UI
>   seam, two capsule kinds, and the screen + adapter + Tools row + purge. `deleteTask`/
>   `deleteCapture` survive only in `Firebase/` and `RecentlyDeleted/`, and
>   `testTheHardDeleteExistsNowhereOutsideFirebaseAndRecentlyDeleted` walks the WHOLE tree rather
>   than a list of files, because the failure it guards is a file nobody thought to list.
> - **The read-path counts moved deliberately** — tasks 4 → 5, captures 5 → 6 — which is last
>   session's test working, exactly as it predicted. The two new fetches are the one pair that must
>   NOT be wrapped in `live(`; they go through a new `deleted(_:)` inverse, and a test says so.
> - **E took two decisions the design review surfaced, and both removed something.** The delete
>   confirmations are gone (`alerts.md › Best practices`: *"Avoid displaying alerts for common,
>   undoable actions"* — both existed BECAUSE delete was irreversible, and this block ended that);
>   and "Discard" became "Delete", because "Recently Deleted" is the anchor Photos, Notes and Files
>   all use. **"Delete forever" keeps its confirm** — the same rule read the other way.
> - **Two strings written in this very block went dead when the confirms did.**
>   `softDeleteReassurance` and `captureDiscardMessage` replaced the false *"This can't be undone."*
>   and then had no call site. Caught by grep, not by a test — the dead-shared-component pattern's
>   **eighth** instance. Removed, with a note in their place recording what is lost: the 30-day rule
>   is still taught by the Tools caption and the empty state, but no longer at the moment of the
>   delete. E's accepted cost.
> - **One measured Critical, fixed without touching the HELD palette.** Delete Forever's label was
>   `StateRisk` `#F5102B` on `CardSurface` `#FFFFFF` — **4.21:1**, under the 4.5:1 `accessibility.md`
>   requires below 18pt (dark is 4.79:1 and passes). The row's button is now `.secondary`;
>   `action-sheets.md` puts destructive prominence on the SHEET, which the confirm provides.
> - **A test drove out a real design fault and the DESIGN changed.** The service published a
>   `state` beside a computed `content`, and on a FAILED load the items array is empty — so
>   `content` answered `.empty`. Nothing was drawing it, but "nothing draws the wrong answer today"
>   is not "the wrong answer cannot be drawn", and "Nothing deleted" over a failed fetch is a
>   confident lie to someone who has just deleted something. One `Screen` enum now; §6 earning its
>   keep.


> ## Edition 74 in six lines (2026-09-22, arc C — `F-C3`'s read side)
>
> - **The read side of Recently Deleted is landed and it changes nothing.** `SoftDelete.isLive`
>   treats **`nil` as LIVE** (every document written before this block has no such key), the four
>   fetched models carry the stamp, and nine read paths go through one shared filter. Since nothing
>   writes the stamp yet, the filter drops nothing and the guard never throws.
> - **`fetchUnprocessedCaptures` is the seam argument in one line.** It is not only the inbox's
>   list but the TAB BAR BADGE (`RootView+Furniture.swift:51`), so filtering in the services rather
>   than the manager would have left deleted captures counted at the user on every screen.
> - **The call-site test is built on COUNTS, not on checking today's methods.** It pins
>   `count(of: "func fetch") == 4` and `== 5` beside the number of `live(` wrappings, so the
>   TENTH read path fails it. Pinning "every fetch that exists today is filtered" would catch
>   nothing tomorrow — and adding `fetchDeletedTasks`/`fetchDeletedCaptures` next session WILL
>   trip it, deliberately.
> - **Three departures from the spec, each with its reason recorded in the TODO block:**
>   `isLive` takes no `asOf` (the clock cannot change that answer); the hard delete KEEPS its name
>   so a caller who wants the irreversible thing has to type it; and the optional rules hardening
>   is **DECLINED** because `request.resource.data.deleted_at <= request.time` checks the CLIENT's
>   clock — a phone a minute fast could not delete anything, and what it prevents is a user
>   pre-dating their own purge window. **`firestore.rules` verified unchanged against `:55-59`.**
> - **A test of mine failed in the full run, and it was the good kind.** It asserted the throw's
>   name appeared in the FETCH files — i.e. it asserted the centralisation had NOT happened, while
>   the design centralises it. The failure forced the question "where should this rule live?", and
>   the answer (one helper pinned by its own test, call sites pinned by going THROUGH it) is better
>   than either half. A test that only ever passes has told you nothing about your design.
> - **Two facts established by reading, for whoever finishes the block:** `deleteCapture` does NOT
>   clean up Storage media (`FirebaseManager+Captures.swift:60` is a plain document delete), so
>   photo and voice captures ALREADY orphan their media today — pre-existing, out of scope, named
>   so it is not mistaken for something this block introduced; and `ToolsCatalogTests` is untouched
>   by the section route, because it pins the CARD count only.


> ## Edition 73 in six lines (2026-09-22, arc C — E's device round, and `F-C2`'s debt paid)
>
> - **Both device looks PASS, and nothing is owed to E.** `F-C1`'s shape round had been owed since
>   session 3 and `F-C2`'s since it merged. E ran both on an iPhone 15 Pro / iOS 27.0 against the
>   live project with Reduce Motion OFF, and sent eleven frames. `F-C2`'s swipe-back half is E's
>   word (*"Also passes"*) with **no frame**, recorded as such rather than as evidence.
> - **`screenshots/drafts-to-inbox/` is DISCHARGED** (PR #183, `51910cd`): 33 frames — light, dark
>   and AX3 — plus `ADHD LifeOSUITests/DraftsToInboxRenderUITests`, committed deliberately because
>   arc C's later blocks reuse the drive. **No app Swift changed**, so the frames are of the
>   shipped build.
> - **The AX3 render answered the question `F-C1`'s Critical implied.** A `Capsule`'s radius is
>   derived from its height, so `F-C2` putting a WIDER control ("↗ Reopen" against "↶ Undo") into
>   that card was an open question. The capped card holds it: glyph, verb, subject and control all
>   inside the fill.
> - **What is unverified ON DEVICE, and no block owes it: the radius CAP.** E's larger-text look
>   was the top of the **standard** range with "Larger Accessibility Sizes" OFF — E supplied the
>   settings page as its own frame so nobody could over-claim it — and the cap only differs from a
>   plain capsule once the layout STACKS, which needs an accessibility size. One toggle would give
>   it device evidence.
> - **Four things rendering caught that a green suite could not:** the Journal has no compose
>   control while a capsule is pending (it stands in for the pencil, and `F-C2` made that common);
>   Reopen lands on a PUSHED screen, not a sheet; the AX3 set needs TWO runs because the second
>   test's sign-out falls past eight swipes at accessibility sizes; and `focusAndType`'s focusing
>   tap lands BETWEEN words at those sizes, which made an equality assertion report a **working**
>   autosave as broken.
> - **§D — a finding of mine, RETRACTED by E's frames, kept as the record.** I reported the
>   selected Captures tab truncating to "Captu…" *because the badge takes width from the pill*.
>   The badge is an `.overlay` and consumes no layout width at all; the clamp is
>   `AppTabBarMetrics.maximumRestingPillWidth = 120`, whose own comment predicts that spot and
>   expects `minimumScaleFactor` to absorb it. **E's phone renders "Captures" in full** beside a
>   two-digit badge, and the icon-only pill in the other frames is `showsLabel`'s
>   `isSelected && !isFloating` working as designed. It stands as a **simulator-only** observation
>   and a register candidate worth one measurement. The lesson: a plausible mechanism is not a
>   measured one.


> ## Edition 72 in six lines (2026-09-20, arc C block 2)
>
> - **Nothing typed is lost any more.** All three composers file unsent text on the way out via
>   `.onDisappear` — which also covers the thing the spec got wrong: `QuickCaptureView` is
>   presented TWICE, a `.fullScreenCover` from the disc and a **`.sheet` from the Capture Inbox**,
>   so "swipe-down is already impossible" was true of one route only.
> - **Task detail autosaves and swipe-back is back.** The blocking "Discard changes?", its two
>   buttons, `attemptBack()` and `.navigationBarBackButtonHidden(true)` all went together — that
>   last line was what had disabled the gesture. **Autosave fires on LEAVING, not on field
>   change**: saving sets `state = .loaded`, which resets the Form's scroll to the top, so a
>   per-blur save would yank the user's position mid-edit.
> - **The capsule's control is no longer always "Undo".** E asked for "Reopen", which reverses
>   nothing, so the word and glyph became properties of the kind. The five existing kinds still
>   answer "Undo" verbatim — `SignedInJourneyUITests` addresses the control by that exact word.
> - **TWO device looks are owed, both RM-off**: `F-C1`'s shape round (owed since session 3, never
>   shown) and this block. Ask in one message. **No RM-on pass** — no reduced site was added or
>   changed.
> - **`screenshots/drafts-to-inbox/` was NOT produced** and is the one acceptance criterion unmet.
>   The block was settled by assertion rather than by looking, but the spec asks for it.
> - **One `apple-design` finding recorded and NOT actioned:** `sheets.md` lists **"Close" as a
>   SYNONYM for "Cancel"** — *"The Cancel (or Close) button dismisses a sheet without saving any
>   changes."* E's stated reason for the relabel slightly overstates the page, so the rename alone
>   does not resolve the mismatch; the behaviour is now "dismiss and keep your text elsewhere",
>   which neither word states. **The capsule is what resolves it** ("Kept in your inbox" —
>   `feedback.md`'s rule that feedback belongs in the interface), so the pairing is sound. E's
>   decision, shipped as asked; recorded here so it is not rediscovered as a bug later.
> - **Accepted costs, recorded so nobody invents a richer draft type:** only the primary text field
>   is caught; a filed draft is an ordinary `.note`; voice and photo captures are untouched; and
>   **filing a draft SPENDS whatever undo was pending**, the same one-slot cost E already accepted.


> ## Edition 71 in six lines (2026-09-20, the capsule's shape round)
>
> - **E's shape round shipped exactly as specified, including the part most likely to be
>   mis-built.** Fully rounded, no chip, `undoHorizontalPadding` DELETED (not zeroed — 0 is off §2's
>   grid and would have failed `testEveryCapsuleSpacingIsOnTheGrid` rather than lapsed), and **NO
>   SECOND LINE** — E's own reversal of their own opening words. The reclaimed 32pt widens the one
>   line: the frames read *"Take a 10-minute walk"* where the shipped shape truncated.
> - **ONE departure, and E made it: the card's radius is CAPPED at `minHeight / 2`.** Rendering the
>   stacked accessibility layout at the new shape — which nobody in the whole arc had done, because
>   every frame was at the default text size — showed a true `Capsule`'s 97.2pt caps drawing **6,329
>   glyph pixels and 2,604 Undo-control pixels outside the card's own fill**. After the cap: **0 and
>   0**. It is not a compromise on what E approved: at 44pt the two shapes rendered
>   **byte-identical over the capsule band (max channel delta 0)**.
> - **THE RM-OFF DEVICE LOOK ON THE NEW SHAPE IS OWED, and it is the only thing owed.** E has seen
>   renders, not the phone. **No RM-on pass** — geometry and fill only, `UndoCapsuleMotion` is
>   untouched, and F-C1's RM-on pass PASSED earlier the same day. No "Verified paths" line, no rules
>   change.
> - **The colour-arc input moved the right way again:** with the chip gone the Undo label sits on
>   `cardSurface` — **3.38 → 3.93:1** light, **3.48 → 4.47:1** dark. Still short of 4.5:1, still the
>   HELD arc's. Recorded, not fixed. (Computed from the colorsets; the method reproduces the
>   register's existing figures exactly, which is what validates it.)
> - **The lesson to carry into every later arc — this block's THIRD instance of the same one:**
>   *a combination has to be RENDERED, not reasoned about.* Specifically: **when a shape's geometry
>   is DERIVED from its content's size, the accessibility layout is a different shape. Render it
>   before calling a shape round closed.**
> - **Coverage is flagged, not claimed.** **29.83% (14,612/48,985)** against edition 68's 29.07%
>   (14,225/48,930): the denominator barely moved (+55) but the numerator moved +387, which four
>   assertion-only tests cannot account for. The six emulator suites ran and their four documented
>   extensions match exactly, so a skipped emulator is ruled out — the cause was NOT established and
>   the delta is not this round's.


> ## Edition 70 in six lines (2026-09-20, the capsule's first device round)
>
> - **The RM-on device pass is DONE and no longer outstanding.** E ran both passes on `main` @
>   `3f7932c` and Reduce Motion ON **PASSED**. The phone-checks list below is corrected accordingly.
> - **E's phone was NEVER disconnected.** Edition 69's header said it must be reconnected; it was
>   `available (paired)` over a live local-network tunnel, and build → install → launch went clean
>   **wirelessly, with no cable and nothing for E to do**. Probe with
>   `devicectl device info details` before ever asking E for a cable again.
> - **RM-off sent the shape back**, verbatim: *"Bringing back a second line is smart. I also
>   recommend that we remove the blue chip background colour behind the "Undo" Button and increase
>   the corner radius of the entire UndoCapsule card."*
> - **THE FINAL SHAPE HAS NO SECOND LINE, and that is E's own reversal.** Eight shapes were rendered
>   on the real screen (`screenshots/undo-capsule-redesign/`). E chose fully rounded, no chip, and
>   the Undo control's 16pt padding deleted — then, shown that a second line costs 15pt on every
>   realistic task title, chose **44pt with one wider line**. Spec: the "THE FINAL SHAPE — build
>   exactly this" block in `TODO-CLAUDE-CODE.md`. **NOT BUILT — it is the next session's first job.**
> - **The colour-arc input MOVED the right way:** dropping the chip takes the Undo label from
>   **3.38 → 3.93:1** light and **3.48 → 4.47:1** dark. Still short of 4.5:1, still the HELD arc's.
>   Recorded, not fixed.
> - **Three render lessons worth more than the shape:** a combination of decisions must be RENDERED,
>   not reasoned about (two of E's picks interacted and one stopped serving its own reason); a
>   measurement must be validated against a known value before it is believed (five identical card
>   heights were a tolerance bug, not a design that had not changed); and a variant must stamp its
>   own name onto an accessibility identifier and ASSERT it — one render failed with "the variant
>   did not reach the app" instead of photographing the shipped shape and mislabelling it.

> ## Edition 69 in five lines (2026-09-20, the capsule's height round)
>
> - **The capsule is 44pt now, not 74.** E marked a 45.3pt band on the evidence folder's own frame
>   against a 60pt capture disc. Four shapes were rendered on the real Tasks screen from one build
>   (`screenshots/undo-capsule-height/`) and E chose **two lines, a size smaller** — board `54`'s
>   arrangement kept, verb `.caption2`, subject `.footnote` on one line.
> - **Round 7's "48pt for anything that … undoes" is overridden for the Undo control, by E's
>   explicit choice** (*"Yes — draw 32, tap 44"*). The pill is drawn at 32 and its hit area grown
>   back to §3's 44 with `AppTabBarMetrics.slotHitOverflow`'s negative-padding trick. **This covers
>   that one control and nothing else.** Two tests that pinned 48 were reversed, not deleted.
> - **THE DEVICE LOOK IS STILL OWED, and it is now the next session's first job.** E chose the new
>   size from renders; nothing has been on the phone, and E's phone is currently DISCONNECTED.
>   The RM-on pass (§7.3) is owed with it — ask for both in one message.
> - **Two render rounds were lost to a switch the app never received**: a launch argument starting
>   with `-` is parsed as a UserDefaults key expecting a value, and `xcodebuild`'s environment does
>   not reach the test runner (the same thing defeated this block's AX3 pass). Both look identical —
>   every variant renders the default. One test method per variant is the fix.
> - **Suite 3,132 / 0, SwiftLint 0 / 842**, build green. Evidence re-rendered at the new height in
>   light, dark and AX3; the two landscape frames are suffixed `-PRE-HEIGHT-ROUND` and still show
>   the 74pt capsule, because what they prove is the ARRANGEMENT, which the height does not change.


> ## Edition 68 in six lines (2026-09-20, arc C block 1 — the audit starts shipping)
>
> - **`main` @ the merge of `F-C1-UndoCapsule`.** Suite **3,130 / 0**, SwiftLint **0 / 842**, build
>   green — **re-measured, not carried**; the 3,085 / 831 figures below were the audit's, from before
>   any Swift changed. App-target coverage **29.07% (14,225/48,930)**, up from 24.72% at `93beff2`
>   two weeks and much other work ago, so the delta is not this block's alone. What IS: all four
>   non-view files in `ADHD LifeOS/Undo/` at 100%.
> - **Shipped:** one undo capsule for every close — five task surfaces (including the Life Area tick
>   E added in Step 0), the nudge "Done for now" with its new `unmarkFired` write, and the three
>   capture triage verbs, all through ONE app-level `RecentActionCenter`. Home's in-place
>   `ClosureCelebrationCard` and the Capture Inbox's own bottom undo bar are both retired onto it.
> - **OWED TO E, and it is the top of the next session:** the device look **and** the
>   Reduce-Motion-on pass (§7.3). Nothing has been on the phone. Ask for both in ONE message so E
>   flips the setting once — and install the build first.
> - **Two things the renders caught that no test could**, both fixed in the block: the Undo button
>   truncated to "Un…" beside a two-line subject, and the capsule arrived silently for VoiceOver.
>   Evidence and the numbers: `screenshots/undo-capsule/` (26 frames + README).
> - **Two new colour-arc inputs, routed not fixed** (§A below): the Undo label measures **3.38:1
>   light / 3.48:1 dark** — it is the tab bar's own selected-pill wash — and the verb line **4.25:1
>   light**. Round 9's *"Leave it to the colour arc"* holds; these are the first measured numbers
>   for that relationship written anywhere.
> - **A new standing hazard, learned the hard way:** a visible change can break a UI JOURNEY while
>   every gate stays green, because **UI tests are skipped in the standard run**. `F-C1` shipped
>   with the capture journey broken and it was caught only on a deliberate re-read (PR #174).
>   Grep `ADHD LifeOSUITests` for any identifier or label a block changes, and run what it touches.
> - **Next: `F-C2-DraftsToInbox`**, arc C block 2, from `handoff/START-HERE-adhd-audit-arc-C2.md`.
>   The build thread is `handoff/ADHD-AUDIT-BUILD-LOG.md` and it now has a session entry.


> ## Edition 67 in six lines (2026-09-19, the ADHD UX audit, session 3 — the audit closes)
>
> - **`main` @ the merge of this hand-off.** No app Swift changed since edition 65, so the suite,
>   lint and coverage figures below still stand: suite **3,085 / 0**, SwiftLint **0 / 831** at
>   `061dbaa`; coverage 24.72% at `93beff2`.
> - **Shipped: records and specs only.** Rounds 7b–10 (composer layout, pressure copy, accessibility
>   and colour, modals/Settings/polish), boards `65`–`68`, findings §L and §M, and **31 FEATURE
>   blocks** in `TODO-CLAUDE-CODE.md` (section "The ADHD UX audit's seven arcs").
> - **Next: BUILD arc C, "Nothing lost"** (E's call: *"C · Nothing lost first"*), one block at a
>   time, in a fresh session, per `handoff/START-HERE-adhd-audit-arc-C.md`. Proposed order after C:
>   D composer → E Today → F sprint → A copy/colour → B accessibility → G places/refresh.
> - **E's new standing principle (round 8): gamification is essential throughout the app**, framed as
>   progress, never debt. It is E's call over research §5.3, like sounds in round 1 — do not re-raise.
>   It also adds a WANTED arc: **points / levels / badges, after the audit**.
> - **Contrast is NOT in any block.** Round 9: *"Leave it to the colour arc"*, which stays HELD. The
>   measured numbers (board `66`) are that arc's input, and **Sufficient Contrast cannot be claimed
>   as an App Store accessibility label until it lands**.
> - **Schema, corrected and verified this session:** `firestore.rules` has NO field-level validation,
>   so neither `next_step` (arc E) nor soft delete (arc C) needs a rules change. Only the optional
>   hardening rule arc C names would, and then E republishes.

## §Z. The audit's own outstanding lists (2026-09-19)

**Gaps E wants that nothing in the 31 blocks builds** (Scope C; all WANTED unless marked):
- the leave-by countdown on Today (needs calendar read, which arc F adds);
- wake-event routines, for a morning surface;
- the one card on the Lock Screen, a new accessory-widget family;
- an app-wide daily notification cap (never requested; the audit's own suggestion);
- journal edit and delete (JRNL-03; until it ships, the Journal keeps "Entries can't be changed
  after saving");
- **points / levels / badges, as its own arc after the audit** (E, round 8).

**Phone checks owed once the blocks land** (E's device, iOS 27):
- the Dynamic Island in compact, minimal and expanded;
- the haptics that differ by meaning, and sounds with the silent switch both ways;
- the Live Activity's +5 min hit area, and the 5-minute heads-up notification;
- Password AutoFill, and Always-On dimming;
- **the composer's bar staying put while Area, Time or the date picker is open** (arc D);
- **a Reduce-Motion-on pass** for the sprint ring (arc F). **The undo capsule's is DONE** — E ran
  it on 2026-09-20 and it PASSED (*"Passes your request requested checks"*); the shape round that
  followed changes geometry and fill only, so it does not re-open the pass;
- Differentiate Without Color, and Smart Invert on photos (arc B);
- whether the voice-capture transcript counts as Captions — E's judgment;
- the Settings Notifications gap after a relaunch (arc G).

**Advisory, from the first `apple-skills` accessibility audit (findings §M):** none of the nine App
Store accessibility labels can be claimed today. Arc B moves VoiceOver, Larger Text, Reduced Motion
and Dark Interface toward claimable; Sufficient Contrast waits for the colour arc.


*Close-out of the session that opened the iOS 27 arc on the day iOS 27 shipped, researched it to
primary sources, and captured the pre-upgrade baseline.
Supersedes the forty-five earlier editions. **Everything the forty-fifth recorded still stands** —
nothing in any merged block is owed to E, and the three older device looks are still owed.*

> ## ⏸ EVERYTHING BELOW IS ON HOLD — E's instruction, 2026-09-13
>
> E paused the whole queue to start **a curated colour scheme for the app**: *"can we hold on
> starting any of those above tasks. I would like to create a properly curated & developed colour
> scheme that we will implement throughout the LifeOS application. lets start that planning in a
> fresh claude code terminal session."*
>
> **Nothing in §A, §B or §C should be started, or offered, until E lifts the hold.** Nothing about
> those items changed except priority — they are still accurate and still outstanding. The three
> device looks in §A and the photosensitivity blocker in §D are unaffected as FACTS; they are
> simply not to be chased.
>
> **THE HOLD STANDS, AND E RE-CONFIRMED THE ORDER ON 2026-09-14: iOS 27 FIRST, colour arc still
> held.** Asked directly where iOS 27 sat against it, E chose *"iOS 27 first, colour arc stays
> held"*. There is a real dependency, and the research since has confirmed it: Apple's HIG
> *Branding* page was revised **2026-09-09** to say brand colour belongs *"in the content layer,
> where it scrolls beneath Liquid Glass controls and gets picked up dynamically"*. The curated
> palette should be designed against iOS 27's guidance, not iOS 26's.
>
> The colour arc's opener has moved to **`handoff/archive/START-HERE-colour-scheme.md`** so this
> folder keeps exactly ONE live opener (CLAUDE.md: *"If `handoff/` ever holds two live
> `START-HERE-*` files, one of them is a trap"*). **Nothing about the arc changed — only the
> pointer.** Its measured inventory of the 63 colorsets and the five questions for E are intact in
> the archive, and it gets a fresh opener when E lifts the hold. It is still PLANNING first.

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**Eighty-second edition — 2026-09-24, `main` @ `ca06c04` (PR #202) at the close of `F-D3` and of ARC D.**
- **Figures, measured this session:** suite **3,344 / 0** (3,337 + 7 new: `TasksAnytimeRowCallSiteTests` 6,
  `MomentumTaskBucketsTests` +1), SwiftLint **0 / 895**, CLEAN `build-for-testing` (all four targets)
  SUCCEEDED. **Arc-D coverage, measured once for the arc with the documented command, emulator UP:**

```
ADHD LifeOS.app                 30.08% (15101/50195)
ADHD LifeOSTests.xctest         93.85% (54547/58121)
ADHD LifeOSUITests.xctest        0.00% (0/5454)      ← skipped in the standard run by design
FocusTimerWidgetExtension.appex 10.34% (228/2204)
```

  Comparable to `F-Floor18`'s 30.18% (15,074/49,955) under CLAUDE.md's rule: the denominator moved
  +240 because the TREE grew (D2's composer bar and tiles, D3's header), not because the extent
  changed; the numerator rose +27. `MomentumTaskBuckets.swift` is 100% (111/111).
- **UI runs (deliberate):** `TasksAnytimeRowRenderUITests` on 27.0 — light, dark and Accessibility XL
  **3 / 3 PASSED**; simulator `0ACE7E5C…` ERASED after.
- **Device:** `ca06c04` built (`-allowProvisioningUpdates`), installed and launched on `wishwashwacky15`.
- **Rules:** no `firestore.rules` / `storage.rules` change. No `#available` site; no Reduce Motion site.

**Eighty-first edition — 2026-09-24, `feature/adhd-d2-keyboard` at the close of `F-D2`.**
- **Figures, measured this session:** suite **3,337 / 0** (3,320 + 17 new: `TaskDueChoiceTests` +6,
  `TaskComposerLayoutTests` 4, `ComposerKeyboardBarCallSiteTests` 7), SwiftLint **0 / 892**,
  `build-for-testing` SUCCEEDED. **Coverage NOT re-measured** — once per arc (CLAUDE.md economy 1),
  at the arc-D close.
- **UI runs (deliberate, not the standard run):** on 27.0 the pin, the render, `F-D1`'s both-doors
  harness and the create journey **4 / 4 green** in light; the render green in dark, at AX3 (the
  stacked form engaged — no bar in the hierarchy) and at xxxLarge (still rides). On 18.0 the render
  green light and dark; **the settle pin PASSED on 18.0 too** (rode at 394pt, settled at 696pt) once
  the sim showed a software keyboard (its first boots did not; the pin now SKIPS, not fails, then).
- **Red-checks:** see the six lines. **Rules:** no `firestore.rules` / `storage.rules` change.
- **Where the build departed from the spec, and why:** the keep-focus pin became a settle pin (E's
  decision); Close stays the system bar item (the spec asked for 48×48 in place — not reachable,
  measured, `F-B1`'s); the two helper lines and the section eyebrows went (board 64 has none);
  `LifeAreaPicker.popUpRowHeight` was replaced by `tileGlyph`/`tileIsCompact` rather than left dead.
- **`apple-design`:** Good (in the block report). **RM-on pass:** none owed.

**Eightieth edition — 2026-09-24, `chore/floor-ios18` at the close of `F-Floor18`.**
- **Figures, all re-measured this session at the floor's last code commit (`442db4e`):** suite
  **3,320 / 0** (3,317 + `DeploymentFloorTests`' 2 + the reversed `ToolsCatalogTests` gaining one),
  SwiftLint **0 / 886**, CLEAN `build-for-testing` of all four targets **SUCCEEDED**, coverage
  **30.18% (15,074/49,955)**, emulator UP (200) and 0 `127.0.0.1:9099` hits.
- **Coverage IS comparable to edition 78's 30.11% (15,081/50,094)**, and it went up. The
  denominator moved because code was DELETED (−139 executable lines: the floor branches, the
  `placesSupported` plumbing, the inert-presenter guard); the numerator fell by only 7. Nothing
  new needs covering — the block added guards over the tree, not logic.
- **The clean build's warning count is the pre-existing concurrency set:** 1,787 distinct
  `warning:` lines, all Swift-concurrency, against ~1,790 measured at both floors when the spec
  was written; **0** `'onChange(of:perform:)' was deprecated` lines; **0** `iOS-simulator-16`
  linker warnings (the five the spec predicted would go, went).
- **`MinimumOSVersion`, pasted from the built bundles:** app `18.0`, widget `18.0`
  (`DTSDKName iphonesimulator27.0` on both).
- **Red-checks:** a planted `#available(iOS 17.0, *)` in `Haptics.swift` → `testNoAvailabilityCheck
  BelowTheFloor` failed, 1 offender named; a planted `16.0` on one setting →
  `testEveryTargetIsAtTheIOS18Floor` failed. Both restored with `git checkout --` and proven by a
  2 / 0 re-run. (The first attempt's `sed '0,/…/'` is GNU-only and planted nothing on BSD sed; the
  target half was re-run with a Python edit — say so rather than paper over it.)
- **Rules:** no `firestore.rules` or `storage.rules` change. Nothing to republish.
- **Device smoke launch — PASSED. E, 2026-09-24: *"Passes — all three checks work as before"*** (open + every tab unchanged; a sprint started, paused, resumed and stopped from the Lock Screen Live Activity; the Focus widget added and rendering). Detail of what was run: Built for the phone
  at `442db4e` with `-allowProvisioningUpdates` (both profiles re-issued: app and widget
  `iOS Team Provisioning Profile`s), `** BUILD SUCCEEDED **`; the device bundle is stamped
  `DTSDKName iphoneos27.0`, `MinimumOSVersion 18.0` for the app AND the widget appex
  (`plutil -p`); installed WIRELESSLY (`available (paired)`) and launched via `devicectl`
  (`Launched application with com.ethananthony.ADHD-LifeOS bundle identifier`). **What E still
  does on the phone, in one pass:** open the app, start and end a sprint (the Live Activity and
  its Pause/Stop buttons), and add the Focus widget. Nothing should look different from `d85b18a`;
  if anything does, that is the finding. **"Verified paths":** 26 path — run on sim 27.0 + E's
  phone; **18–25 path — RUN on sim 18.0 later the same day (suite 3,320 / 0, app boots; §A,
  `screenshots/floor-ios18-first-run/`); 19–25 never run.**
- **Simulator:** no UI-target run this session, so no erase was needed. **Emulator:** started at
  session start with the audit's imported state; UP for the coverage run.
- **Where the build departed from the spec, and why:** `ToolsCatalog.available(placesSupported:)`
  became `static let entries` rather than a parameterless `available()` (a constant, not a
  question); the ActivityKit files' iOS 17 sites went in commit 2 with their files rather than in
  commit 3, so each file changed once; `InertRoutineActivityPresenter` was KEPT for previews (E's
  call this session, no test uses it); the widget bundle's floor comment was caught by the final
  grep after the coverage run and fixed as a comment-only change in the docs commit.
- **`apple-design`:** owed nothing — nothing a person sees or feels changed; every branch E has
  ever seen on the 27.0 phone is the branch that stays (§7.6). **RM-on pass:** owed nothing — no
  reduced site added or changed; the 26 gates' reduced paths are untouched (§7.3).

**Seventy-eighth edition — 2026-09-23, `feature/adhd-d1-composer` at the close of `F-D1`.**
- **Figures, all re-measured this session:** suite **3,317 / 0**, SwiftLint **0 / 885**, build
  **SUCCEEDED**, coverage **30.11% (15,081/50,094)**. The render harness
  `ComposerBothDoorsRenderUITests` was run on the pre-block tree (light, dark) and on the finished
  block (light, dark): **1 test, 0 failures** each on the final code.
- **The suite figure is corrected, not just updated.** Edition 77 recorded 3,306, but `d38cf10`
  (three `restore(tagId:)` tests) landed after that run, so `9da589f` held **3,309**. This block
  adds **+8** by source: +2 effort, +7 call-site, +6 service, −4 adapter tag tests, −3 at-place
  service tests. The run's count equals the source's `func test` count exactly.
- **Coverage IS comparable to edition 77's 30.03% (15,103/50,300)**, and it went UP. The
  denominator moved because code was DELETED (−206 executable lines: the tag, place and notes
  surfaces and Quick Capture's task path), not because the measurement extent changed. The
  numerator fell by only 22. `TaskCreateService`, `TaskEffortChoice` and
  `FirebaseTaskCreateClientAdapter` are all at **100%**. The service's last partial region, the
  `?? error.localizedDescription` fallback, was closed by one test, and that test was proven by
  mutation.
- **The submitted create was run for real, and its journey had a RACE.**
  `SignedInJourneyUITests.testCreateTask_fromTasksTab_appearsInList` failed once on this branch:
  it waited on an "Open" chip that exists UNDER the sheet the whole time, then tapped before the
  composer left. The emulator's timestamps settle it: in a slow run the create landed at +9.2s
  and the Time write at +9.8s, while the chip was tapped at +7.5s, so the old single-write
  composer would have lost that run too. Clean, the whole path takes **2.08s** (create, then the
  Time write 54ms later, `focus_duration_seconds: 900`). The journey now waits for the composer to
  LEAVE first, and re-run: **1 test, 0 failures**. (One run in between SKIPPED on a 3s emulator
  probe timeout while the machine was loaded; that is not counted as a pass.)
- **Rules:** no `firestore.rules` change (`focus_duration_seconds` already existed on the task).
  Nothing to republish.
- **Simulator:** `9181EBF9-…` was ERASED after every UI run. **Emulator:** restarted at session
  start (it had been up 14h, E's rule) and is UP with the audit's imported state.

**Owed to E: NOTHING.** No `#available` site and no reduced site, so no RM-on pass and no Verified
paths line. **E's phone carries `F-C3` + `F-C4`, not `F-D1`**, and the profile expires 2026-09-24,
so a look at D1 would need an install first. `F-D2`'s opener asks its two Step 0 questions before
any code.

**Owed to the code: nothing for this block.**

**Seventy-seventh edition — 2026-09-22, `feature/adhd-c4-tags` at the merge of `F-C4`.**
- **Figures, all re-measured this session:** suite **3,306 / 0**, SwiftLint **0**, build
  **SUCCEEDED**, coverage **30.03% (15,103/50,300)**. The three UI render journeys were run
  deliberately, twice (light and dark): **3 tests, 0 failures** each.
- **Coverage IS comparable to edition 75's 29.87% (14,953/50,068)** and it went UP. The
  denominator moved because the TREE GREW (+232 executable lines), not because the measurement
  extent changed — both runs measured 100% of the app target. The numerator grew +150, so coverage
  grew faster than the code. Everything this block added is at or near 100%:
  `RecentlyDeletedPresentation` **100% (91/91)**, `FirebaseRecentlyDeletedClientAdapter` **96.72%
  (118/122)**, `RecentlyDeletedItem` **100%**, `FirebaseManager+Tags` **92.92% (105/113)**,
  `FirebaseTagEditorClientAdapter` **94.67% (71/75)**, `RecentlyDeletedService` **93.98% (78/83)**.
- **One coverage hole was found and closed inside the block.** `TagEditorService.restore(tagId:)`
  measured **0.00% (0/11)** — the capsule's Undo, reachable in production, exercised by nothing.
  F-AdapterDrift's shape exactly, and only findable by reading the report.
- **Rules:** `firestore.rules` verified UNCHANGED by this block (git) and byte-identical to the
  LIVE ruleset via the Firebase MCP. `tags` sits in the generic owner-CRUD allow, so a `deleted_at`
  field needs no new rule. **Nothing to republish.**
- **Simulator:** `9181EBF9-…` must be **ERASED** after the render runs, per CLAUDE.md — a UI run
  signs it in and the next unit suite then drags a Firebase client retrying at 60-80s per test.
  **Emulator:** UP with the audit's imported state, plus six throwaway accounts from the render
  runs (three per appearance).
- **CLAUDE.md's adapter counts were stale and are corrected**: **fifteen** `Firebase*ClientAdapter`
  files (was "fourteen", flagged by edition 75 and not acted on), **seventeen**
  `FirebaseManager+<Domain>` files (was "sixteen" — `+SoftDelete` joined with `F-C3`).

**Owed to E: NOTHING.** §A-CAPSULE was answered the same day (Option C, DEFERRED with a condition — it is now WORK, not a question). No device look and no RM-on pass were owed: the block adds no `#available` site and no reduced site.

**DEVICE PASS, 2026-09-22 — E: *"All those checks work nicely"*.** The phone was brought from `4917955` (`F-C1` + `F-C2` only) to `main @ 82d669b`, so this is the **first time either `F-C3` or `F-C4` has been on the device at all**. Recently Deleted, the confirmation-free task/capture deletes with the capsule, the tag delete and the survivor alert all confirmed working. Install clean in one wireless pass; profile expires **2026-09-24**, so the next install after Wednesday evening re-issues it.

**Owed to the code: nothing for this block.** All acceptance criteria are met, including
`screenshots/recently-deleted-tags/` (16 frames + README) and the `apple-design` review.

**Seventy-fifth edition — 2026-09-22, `main` @ the merge of `F-C3-RecentlyDeleted`.**
- **Figures, all re-measured this session on an ERASED simulator:** suite **3,253 / 0**, SwiftLint
  **0 / 877**, build **SUCCEEDED**, coverage **29.87% (14,953/50,068)**.
- **Coverage IS comparable to edition 74's 29.89% (14,713/49,217)**, and the 0.02 dip is real and
  explained. The denominator moved because the TREE GREW (+851 executable lines), not because the
  measurement extent changed — both runs measured 100% of the app target. The numerator grew +240.
  The dip is the **523 lines of new view body** (`RecentlyDeletedView` 349, `ToolsRecentlyDeletedSection`
  174), which are 0% by design and always will be. Everything else this block added is at or near
  100%: `RecentlyDeletedPresentation` **100% (62/62)**, `FirebaseRecentlyDeletedClientAdapter`
  **100% (61/61)**, `RecentlyDeletedItem` **100%**, `RecentlyDeletedService` **90.48% (57/63)**.
- **`FirebaseManager+SoftDelete.swift` reads 33.33% (4/12) and that is the honest floor, not a
  gap.** Its three functions are members of `FirebaseManager`, which has a `private init` and
  cannot be instantiated in a test target that deliberately does not link the Firebase SDK — the
  same exclusion the whole manager carries. The RULE they apply (`SoftDelete.isLive`) is at 100%
  and the call sites are pinned by `SoftDeleteCallSiteTests`.
- **Rules:** `firestore.rules` verified unchanged against `:55-59` — the owner already has full
  write on `tasks` and `captures`, so a `deleted_at` field needs no new allow rule, and the spec's
  optional hardening stays DECLINED (it would check the CLIENT's clock, so a phone a minute fast
  could not delete anything). **E republishes to confirm nothing changed**, per house policy.
- **Simulator:** `9181EBF9-…` was **ERASED** after the render runs and is Shutdown. **Emulator:**
  UP with the audit's imported state; three throwaway accounts per appearance were left in it.
- **A15 adapter count:** there are now **fifteen** `Firebase*ClientAdapter` files, not fourteen —
  CLAUDE.md's Architecture notes say fourteen and should be corrected at the next edit.

**Owed to E: nothing.** No device look and no RM-on pass — the block added no `#available` site
and no reduced site, and the new screen has no animation of its own (§7.3). E's two decisions this
session are implemented and merged.

**Owed to the code: nothing outstanding for this block.** All acceptance criteria are met,
including `screenshots/recently-deleted/` (20 frames + README) and the `apple-design` review.


**Sixty-fifth edition — 2026-09-19, `main` @ the merge of this hand-off. Docs, evidence and audit tools only; no Swift.**
- **Figures carried:** suite **3,085 / 0**, SwiftLint **0 / 831**, both on `061dbaa` (nothing re-run: no Swift changed).
- **Rules:** untouched. **Emulator:** running at hand-off with the audit account; its state is exported to the git-ignored
  `scripts/audit/emulator-state/`.

**What happened.** E directed a new piece of work: an ADHD / neurodivergent UX audit on the iPhone 18 Pro / iOS 27.0
simulator, with the rule that every fix gets 2–3 options framed on executive-function struggles and nothing is edited
before E selects. It ran research (a sub-agent's evidence-graded brief), E's answers to ten questions, a code sweep by four
sub-agents, a seeded simulator pass in light / dark / AX3, three `apple-design` HIG reviews, a contrast measurement from the
colorset hex, and E's own hand-entered places, photo, voice and task. **Round 1 of ~10 options rounds is decided:**
- every close gets an undo until the next action (retiring the "one-way" addendum);
- sprint start is 1 tap wherever a task stands alone (amending b11);
- sounds stand as a grounding cue;
- **the app targets ADHD specifically, not autistic people.**

**Where it lives:**
- `handoff/SESSION-OPENER-adhd-ux-audit-design.md`: E's answers verbatim and the round log.
- `handoff/SESSION-OPENER-adhd-ux-audit-research.md`: the evidence brief.
- `handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md`: every finding, marked sim-verified or code-only.
- `screenshots/adhd-ux-audit/`: the evidence frames.
- `scripts/audit/`: the drive tools.

**Outstanding (owed, in order):**
- [ ] **Options rounds 2–10**, per `handoff/START-HERE-adhd-ux-audit-rounds.md`, on a new branch.
- [ ] Then the **Scope C gaps list** and the **phone-checks list** (Dynamic Island, haptics, sound, AutoFill, Always-On).
- [ ] Then **Decision A:** build here or fresh? The honest answer is fresh session(s), as FEATURE blocks.
- [ ] Audit close-out: clear the sim location, erase the 18 Pro, stop the emulator.

**Verified defects already on record (not yet fixed; the fixes wait for E's selections):**
- The quick Task composer's Cancel silently discards typed text.
- Tasks-tab closes (tap and full swipe) and nudge dismissals have no undo.
- The Lock Screen Live Activity's Stop ends a sprint with no confirmation (code).
- A task added from the Tasks toolbar "+" with no date vanishes from the board it was added from.
- Targets under 44pt: the Settings gear (40×40), the Tasks "+" (27×36), the tag "Add" (24×14), the inbox Undo (34×16).
- `LabelSecondary` fails 4.5:1 in light mode; no colorset has an Increase Contrast variant.

**The colour arc's hold is unchanged.** The audit fixes colour MISUSE only (E's Q6).

---

**Sixty-fourth edition's State follows, unchanged.**

**Sixty-fourth edition — 2026-09-19, `main` @ the merge of this hand-off. Docs only.**
- **Figures carried:** suite **3,085 / 0**, SwiftLint **0 / 831**, both on `061dbaa`. **No Swift
  changed.** Rules untouched; emulator not started; the phone still carries `654012f`.

**Landed: CLAUDE.md §7.6 — `apple-design` is owed wherever a person will see the change.** E
installed the skill 2026-09-18 and asked that it be *"PROPERLY utilised"*. §7.6 says when it is owed
(any visible change, before design options go to E, any review ask, the colour arc), how to run it
(Skill tool, freshness check, always-load set, `file.md › Heading` citations, real numbers, its report
format as a SECTION of the block report), and seven settled disagreements with this repo. The "feature
isn't done until" bar now points at it. §7.5 records that `swiftui-pro` and `swiftui-design-principles`
are no longer installed.

**E's decision this session:** the in-app appearance override (`AppearancePreference`, `cf027ae`)
breaks `dark-mode.md › Best practices` ("Avoid offering an app-specific appearance setting") —
**E: "that was intentional."** Recorded in §7.6 as settled; never report it, never remove it.

**Found: the skill's HIG pages were stale on arrival.** Pulled 2026-09-09; upstream had nothing
newer. A scratch re-pull against Apple's live site found `layout.md` (always-load) REWRITTEN,
`branding.md` REVISED — **the installed copy carries the old accent-colour paragraph, not the "content
layer" sentence this register cites as the colour arc's dependency** — plus a NEW
`designing-for-iphone-duo.md`, the IAP page renamed, and four small edits. §7.6 carries the re-pull
check.

**E's decision, the same session: refresh IN PLACE, with standing permission (PR #165).** Asked for
a recommendation, then *"yes, do both"*. The installed pages were refreshed 2026-09-19 (backed up
first). The diff against the backup was exactly the pages listed above, `SKILL.md` and the curated
`liquid-glass.md` were untouched, no `doc://` leftovers, and every page `SKILL.md` names exists.
§7.6's freshness step is now: re-run the pull in place when `hig-lookup.md` is more than 7 days
old, and always before a colour, branding or layout decision. Nothing about it is outstanding.

---

**Sixty-third edition's State follows, unchanged.**

**Sixty-third edition — 2026-09-18 (evening, the look session), `main` @ the merge of this hand-off.**
- **Figures carried:** suite **3,085 / 0**, SwiftLint **0 / 831**, both on `061dbaa`. **No Swift
  changed this session.**
- **Rules:** `firestore.rules` untouched; nothing for E to republish.
- **Emulator:** not started (nothing was run).

**Device:** unchanged. The phone carries **`654012f`**. Profiles run to **2026-09-24T19:49Z**.

**E's verdicts on the one install, asked in ONE message (§7.3), option labels verbatim:**
- **Reduce Motion OFF — "All passed":** the pencil disc beside the +, the nav bar with the eye alone,
  the Journal re-tap bringing the large title back, and the **24pt gap** in portrait and landscape.
- **Reduce Motion ON — "All faded, passed":** the capture fan's cards fade, the pencil disc fades in
  and out on a tab switch, and the re-tap. **E toggled the setting for this**, so the pencil block's
  Verified-paths line now honestly reads *"Reduced: run on sim (injected) + E's phone (RM on)"*.
- **Landscape, fan → Note — "Composer opened".** Per the opener's rule, the sweep's failure at that
  step is therefore the TEST's fault (below).

**Evidence: E's six frames (`IMG_8543–8548`), filed as `screenshots/journal-pencil-disc/19–24`**, with
a README section and measurements. **The device matches the sim gate to the point:** + disc centre
**(339.0, 696.0)**, pencil 42 × 42 at **(272.0, 696.0)**, gap 16. Disc to bar ≈ **24** in portrait
(725.7 → 751.0) AND landscape (280.7 → 305.0). Frames 20 and 22 are the first renders of the eye
**ON** since Step 0. The frames show no motion; the verdicts cover it.

**What this closes:**
- **The Journal-door arc (blocks 1 + 2): nothing owed.** Memory `journal-door-arc`.
- **`F-FurnitureGap24`'s 24pt look and the RM-on fan-fade pass: PASSED.** They were carried from
  2026-09-17 onto this install. Memory `fab-overlap-and-tab-inset`.

**Outstanding from this look — PARKED by E the same evening.** Asked *fix it now / hand off / park*,
E chose **"Park it"**. It is listed in §C and is not to be started unprompted:
- [ ] **`RenderHarnessUITests.testRenderLandscapeSweep` — fix the TEST.** It fails at "The note
  composer never opened from the fan tile tapped in landscape" on 27.0, and fails identically on
  `aec558a`. E's phone opens the composer from that tile. **The leading hypothesis is unverified — do
  not fix on it:** `quickCaptureContentField` is a `TextField(axis: .vertical)`, and the test queries
  `app.textFields[…]`. If iOS 27 exposes a vertical-axis field as a `textView`, the query can never
  match. Confirm first by dumping the element's `elementType` in the failing run. Red-check the fix by
  restoring the old query. It needs the emulator, a ~460s UI run, and `xcrun simctl erase` in the same
  command. Test-only, so it involves no design decision.

**Carried, unchanged:** the colour arc stays **HELD**. `F-Search-3-Journal`'s objection is LIVE. The
cards' VoiceOver gap under the fan (`F-FanCardsFade`, the pencil's fix) is small and below the bar.
§A's three older device checks (`SwipeOrigin`, `NoCooldown`, `PopScale`) and §D's photosensitivity
blocker are untouched. Frame 08's pushed-up disc and Phase D's dark schedule-summary dimness are
still unlooked-at.

---

**Sixty-second edition's State follows, unchanged.**

**Sixty-second edition — 2026-09-18 (the build session), `main` @ the merge of this hand-off.**
- **Figures, all on the final tree `061dbaa` (merged as `654012f`):** suite **3,085 / 0** (was
  3,057; +28), SwiftLint **0 / 831**, `** BUILD SUCCEEDED **`, app coverage **29.72%
  (14,442 / 48,593)**. Last recorded 27.67% (13,399 / 48,433): the denominator moved by this
  block's own ~160 lines (same measurement extent, so the ratios compare); the numerator jumped
  because the committed hosted-window test renders the real `JournalView` body.
- **Rules:** `firestore.rules` untouched; nothing for E to republish.
- **Emulator:** started this session; stopped at close-out.

**Device: the phone carries `654012f` — blocks 1 + 2 TOGETHER, block 1 on it for the first time.** Built from merged `main` (`-allowProvisioningUpdates`, scratch DerivedData), `** BUILD SUCCEEDED **`, 0 signing tells, `codesign --verify --deep --strict` OK, profiles valid to **2026-09-24T19:49Z**. Installed, launched clean first time (no `Security` denial), then relaunched (terminate + launch) so E judges a fresh process, not one launched over an install.

**Landed — `F-JournalPencilDisc`, PR #160, merge `654012f`.** Evidence `screenshots/journal-pencil-disc/`.
- **The header:** the Journal keeps the system nav bar, with the large title and the "All activity" eye
  ALONE in its toolbar (OFF label colour, ON accent — E's B). `JournalHeaderMetrics` deleted.
- **The pencil:** a 42pt disc in `RootBottomOverlay.discRow`, 16pt left of the + on its line: the +
  disc's colours with the gradient REVERSED, the same glow, 0.68 with the pill on the same curves,
  fading + untouchable + VoiceOver-hidden while the fan is open, arriving and leaving on a fade (plain
  ease under RM). 44pt target via the `slotHitOverflow` shape. `CaptureDiscFace` holds the twins'
  shared values. Its tap reaches the Journal as a count, `TabNavigationCoordinator.requestJournalEntry()`.
- **The re-tap:** iOS 26+ brings a collapsed large title back (54pt → 106pt at −168), by an overscroll
  written with no finger down that FINDS the expanded top. Pages with a hidden bar are never probed.
  Below 26 the shipped `proxy.scrollTo` (§7.1 degraded).
- **Gate by pixels on 27.0 and 26.5:** + disc centre **696.0** (the constants predict 696.0), the
  pencil 42 × 42 on the same line, gap **16.0**. Nothing lands on a card, a tile or the gear.

**E's decision this session:** asked the one gap in the spec — does the disc show while the Journal is
loading or has failed? — E chose **"Always on the Journal (Recommended)"**.

**What this session established:**
- **Step 0's re-tap finding HOLDS, and a probe showed why it hides:** the shipped spring overshoots the
  plain top by ~6pt, the bar pops to 106 for ~0.25s, then collapses back to 54 as it settles. A test
  that polls for "bar > 100" passes on the bug — so the hosted test asserts the SETTLED page.
- **A red-check that swaps a `some View` member's underlying type can SEGV** in an extension file the
  incremental build did not recompile (`JournalTimelineSections.swift` calling `header`). `touch` the
  dependents. Memory `opaque-type-incremental-segv`.
- **The landscape sweep (`RenderHarnessUITests.testRenderLandscapeSweep`) FAILS on `main` @ `aec558a`
  too** — at the capture fan's Note tile, in landscape on Today ("The note composer never opened"). It
  predates this block; its Journal step was run on its own instead (PASSED). **Unknown yet whether the
  app or the test** — an optional ten-second check on E's phone below settles it.
- **Two HIG-review findings applied**, one deferred: the CARDS under the fan are invisible and
  untouchable but still reachable by VoiceOver (`F-FanCardsFade`) — the same fix the pencil got.
- **Residual for the look:** Tasks shows a nav bar, so its re-tap is still probed (and handed back — its
  title never collapses). No twitch expected; say so if E sees one.

**Owed by E, all on the `654012f` install — ask in ONE message (§7.3):**
1. **RM OFF:** the final disc beside the + (at rest, scrolled/pilled); the nav bar with the eye; on the
   Journal scroll down, then tap the Journal tab → the large title comes back; the **24pt gap** in
   portrait AND landscape, with the collapsed bar alone and under a Confirm card.
2. **RM ON (Settings → Accessibility → Motion):** the capture fan's cards FADE, not cut; the pencil disc
   fades in and out on a tab switch; the re-tap.
3. **Optional, ten seconds:** in landscape, open the capture fan and tap Note — does the composer open?

**Carried, unchanged:** the colour arc stays **HELD**. `F-Search-3-Journal`'s objection is LIVE (the
band left of the disc is the pencil's). Frame 08's pushed-up disc; Phase D's dark schedule-summary dimness.

---

**Sixty-first edition's State follows, unchanged.**

**Sixty-first edition — 2026-09-18 (later still), `main` @ the merge of this hand-off.**
- **Figures carried:** suite **3,057 / 0** and SwiftLint **0 / 826**, both at `d1b3601`.
  **No Swift changed this session.** Every probe edit was temporary, reverted with `git checkout --`,
  and `git status` was empty before anything was committed.
- **Rules:** `firestore.rules` untouched; nothing for E to republish.
- **Emulator:** started this session, stopped cleanly at close-out.

**Device:** unchanged. The phone carries **`c54efd7`**. Blocks 1 + 2 install together after
`F-JournalPencilDisc`. Profiles run to **2026-09-24T19:49Z**.

**What this session did:** it ran `F-JournalPencilReachable`'s Step 0, the throwaway probe the plan
required before any test. It rendered on **27.0 (E's OS) and 26.5**, then put the result in front of
E. Evidence: `screenshots/journal-pencil-step0/` (PR: this hand-off).

**E's decisions, verbatim:**
- Shown that a filled pencil splits (b)'s one toolbar capsule into two circles: *"move the filled
  pencil icon disc down to the left-hand side of the FAB Icon. make the filled pencil disc inline with
  the FAB icon"*.
- **"B (Recommended)"**: the eye is OFF in the label colour and ON in accent; the pencil glyph is
  white.
- **"Keep the nav bar"**: the large title stays, with the eye alone top right.
- **"48pt (Recommended)"**, then mid-session: *"decrease the size of the filled pencil disc from
  48pt to 42pt"*.
- **"1 · Follows the pill (Recommended)"**: 68% translucent with the + while pilled.
- **"Match the + gradient"**, then, shown 42pt without and with the glow: *"Can you reverse the DIRECTION that the gradient on the pencil disc currently points in? And use the same glow as the +. So the pair are twins with halos, But with the pencil disc's Background colour gradient direction different."*
  So: the same colours, direction reversed, plus the + disc's glow.
- **"Hand off to fresh session (Recommended)"**.

**Facts Step 0 established** (the spec's table has the numbers):
- **The re-tap does NOT bring the large title back.**
  - `proxy.scrollTo` leaves the bar at **54pt**, and so does iOS 18 `ScrollPosition.scrollTo(edge:)`.
    A UIKit offset to the expanded top restores **106pt**.
  - An overscroll written with no finger down settles at the expanded top by itself, so the fix can
    FIND that top.
  - Measured on 26.5 AND 27.0.
  - **The fix is specced iOS 26+ only**, with the shipped scroll as the floor (§7.1 degraded):
    nothing below 26.5 can be run here, and a wrong guess there would displace the page.
- **Tasks' large title never collapses.** Its scroll view sits under a filter row, so it is not a
  control for the re-tap and must be left alone.
- **`.borderedProminent` ≡ `.glassProminent` in a toolbar:** pixel-identical on both runtimes.
- **The prominent-item glyph:** iOS draws it BLACK in dark mode, and a `.foregroundStyle` overrides
  it.
- **Toolbar glyphs on 26/27 default to the label colour, not accent.**
- **The pencil disc at E's inset:** centred on the + disc's line (695.8 / 695.8), with the + disc's
  centre unmoved (gate ≈ 696).

**Process note, worth keeping.** The plan's Step 0 was framed as "a confirm, not a re-ask", but a
confirm can come back as a redesign, and this one did. The fresh-session rule then applied mid-session.
E was asked rather than assumed, and E chose the hand-off. Memory `build-in-a-fresh-session`.

**Owed by E, carried, not blocking. Put them all on the blocks 1 + 2 install:**
1. The **24pt gap** look: portrait AND landscape, with the bar alone and under a Confirm card.
2. The **Reduce Motion ON pass**, now covering THREE reduced sites:
   - the fan's cards fading;
   - the pencil disc appearing and leaving on a tab switch;
   - the re-tap.

---

**Sixtieth edition's State follows, unchanged.**

**Sixtieth edition — 2026-09-18 (later), `main` @ the merge of this hand-off.** Suite **3,057 / 0**,
SwiftLint **0 / 826** — both measured at `d1b3601` (block 1's code) with the emulator UP; nothing merged
since touched Swift. Build `** BUILD SUCCEEDED **`. `firestore.rules` untouched — nothing for E to
republish.

**Device:** the phone still carries **`c54efd7`** — **block 1 is NOT installed, on purpose.** Alone it
leaves the Journal with no door once scrolled, so blocks 1 + 2 install together in one build after
block 2. Profiles run to **2026-09-24T19:49Z**.

**Landed this session:**
- **`F-JournalDoorUnpinned`** (PR #156, `d1b3601` + evidence `8a237be`, merge `6656866`). The composer
  bar, its `safeAreaInset` and its private trailing clearance are deleted; the timeline calls
  `.captureDiscClearance()` like every other screen; both header circles 40 → 44 through
  `JournalHeaderMetrics.controlSize`. RED 4 tests / 8 assertions → GREEN; red-check (bar restored +
  pencil id deleted) 4 / 8 red, exit 65, restored 32 / 0. No `#available` or reduced site → no RM-on
  pass owed. Evidence `screenshots/journal-door-unpinned/`.
- **`screenshots/journal-pencil-options/`** (PR #157) — three shapes × at rest/scrolled × light/dark,
  plus three pencil treatments.
- **`F-JournalPencilReachable` specced** in `TODO-CLAUDE-CODE.md` with E's answers and the approved plan.

**E's decisions this session:** **"(b) Restore a nav bar"** (over the recommended (c) disc's band, and
(a)); **"Filled accent"** (over the recommended accent glyph); and, asked mid-plan, that building happens
**in a fresh session** — *"Did you remember that we need to do building in a fresh session?"*

**Numbers worth keeping, measured at E's phone's real 34pt home-indicator inset:**
- Block 1 bought **+96pt visible at rest** (653.7 → 750.0), not the +107 the options README recorded —
  that rig had no home-indicator inset. Reserve 164 → 160: a look-and-feel win, not scroll reach.
- The "~5.5pt disc-below-composer" figure in the docs was DERIVED, not measured; the constants give 7.3.
  Moot now — block 1 deleted the composer.
- Shape (a)'s pinned header would have cost **85pt** permanently (hairline at y 147).

**Render rig, improved:** the hosted window must be pinned to the BOTTOM of the simulator's 874pt screen
(else it inherits 12 of the 34pt inset); all variants from one build via static switches; targeted runs
with `-enableCodeCoverage NO` (a coverage-on run hung ~20 min after its tests finished). Memory
`full-screen-render-harness`.

**Owed by E, carried, not blocking — put them on the blocks 1 + 2 install:**
1. The **24pt gap** look — portrait AND landscape, bar alone and under a Confirm card.
2. The **Reduce Motion ON** fan pass — the cards must FADE, not cut.

---

**Fifty-ninth edition's State follows, unchanged.**

**Fifty-ninth edition — 2026-09-18, `main` @ `79fa171`.** Suite **3,053 / 0**, SwiftLint **0 / 824**
— both measured at `c54efd7`; the two commits since are **evidence and spec only, no Swift changed**,
so the figures carry. `firestore.rules` untouched — nothing for E to republish.

**Device:** the phone carries **`c54efd7`** (Swift-identical to `173ba7d`). **The profiles EXPIRED
mid-session at 2026-09-17T19:25:02Z and were re-issued at 19:49Z — they now run to
2026-09-24T19:49Z.** Getting there needed E's Xcode → Settings → Accounts sign-in: the free-account
profile and the empty account list died together, exactly as on 2026-09-03. `devicectl` launch was
then denied `Security` twice **with a valid, freshly minted profile and an UNCHANGED July
certificate** — a third species beyond the two on record — and E cleared it by trusting the
developer on the device. E confirmed: *"the app works"*.

**Landed this session (no production Swift):**
- **`screenshots/journal-door-options/`** (PR #154) — five options × light/dark of the Journal's
  bottom furniture, rendered from the REAL views at 393×852, plus a README carrying the numbers.
- **`F-JournalDoorUnpinned` + `F-JournalPencilReachable`** specced in `TODO-CLAUDE-CODE.md`.

**E's decisions this session:**
- The ugliness is **"The bar — its bulk and position"**, NOT the shared `composerFooterSurface()`
  treatment — so that treatment and the four other screens wearing it are untouched.
- **"Render them first, then I'll choose"**, then **"Go with option '04'"** — nothing pinned.
- Next: *"making the current new journal entry icon … MORE visable and EASIER to interact with"*, in
  a fresh session.

**What the options work established, worth keeping:**
- **The pinning was never E's design.** The v3 mockup (`handoff/…v3.dc.html:204`) has this bar as the
  last child of the *scrolling* screen. Height 54, radius 14, hairline and caption all shipped
  faithfully; the pinning was added in implementation.
- **The caption wraps on every iPhone** — 355.6pt of text in 285pt — and the composer already states
  the same rule at the moment it applies.
- **Options 02-04 are a look-and-feel win, not a scroll-reach win** (reserved band 164 → 160pt). A
  first draft overstated them by omitting `.captureDiscClearance()`; corrected before E saw them.
- **`ImageRenderer` cannot render a whole screen** and fails as a plausible image both ways. The
  working harness and its three gates are memory `full-screen-render-harness`.

**Owed by E, carried, not blocking:**
1. The **24pt gap** look — portrait AND landscape, bar alone and under a Confirm card. **The Journal
   composer-alignment half is now MOOT**, since block 1 deletes the reference.
2. The **Reduce Motion ON** fan pass — the cards must FADE, not cut.

---

**Fifty-eighth edition's State follows, unchanged.**

**Fifty-eighth edition — 2026-09-17 ~13:30, `main` @ `173ba7d`.** Suite **3,053 / 0**, **0**
`127.0.0.1:9099` hits, SwiftLint **0 / 824**, sim `** BUILD SUCCEEDED **`. `firestore.rules`
untouched — nothing for E to republish. **Phone: see "Device" below.**

**E's device look on the three blocks (~12:55, four portrait frames, light + dark):**
- **`F-FanXAtRest` — PASSED** (*"your fixes to the FAB Icon were successful"*). **RM-ON pass still
  OWED** (the × jumps by design; the cards must still FADE — the container's `nil` wraps the cards'
  `.default` fade and no RM render has proved the inner wins).
- **`F-CollapsedBarLift` — margin REVISED:** *"please reduce it slightly."* E chose **everything
  together** and **24pt** → **`F-FurnitureGap24`** (PR #152): `gapAboveTabBar` 32 → 24,
  `bottomFurnitureLift` 100 → 92, content clearance follows. **Accepted cost, owed a look:** the disc
  was centred on the Journal composer at 32 (2.5pt off); at 24 ~5.5pt off. Landscape not yet looked at.
- **`F-FanHoldsCelebration`** — no ordinary device look exists (a Confirm cannot be tapped under the
  fan; only a background daily goal / streak can fire while it is open). Tested-only unless E sets it up.

**Device:** **The phone is ON MAIN at `173ba7d`** (installed ~13:35; device build + `devicectl` install clean, 0 signing tells, `codesign --verify --deep --strict` exit 0). The LAUNCH was denied `Locked` — the known "install is real, unlock and open" case, so E opens it by hand (and force-quits first). **Profile NOT re-issued: expires 2026-09-17T19:25:02Z (20:25 BST)** — after that, rebuild after expiry.

---

**Fifty-seventh edition's State follows, unchanged.**


**Fifty-seventh edition — measured 2026-09-17 on `main` @ `4653433` (Xcode 27.0, iOS 26.5 runtime,
emulator UP, freshly started this session):** suite **3,053 / 0** (3,029 + `F-FanXAtRest`'s 10 +
`F-CollapsedBarLift`'s 1 + `F-FanHoldsCelebration`'s 13), **0** `127.0.0.1:9099` hits, SwiftLint
**0 / 824**, sim `** BUILD SUCCEEDED **` (incremental — the 37-distinct-warning figure was NOT
re-measured like-for-like). Journeys PASSED on 26.5 (sim erased after every run):
`FanOverAwayCardUITests` (reversed), `SprintBarFurnitureUITests` (new, 3 tests: Tasks, bar alone,
bar under a Confirm card). `firestore.rules` untouched — **nothing for E to republish**.
**The phone is ON MAIN at `4653433`** — device build, `devicectl` install AND launch clean,
`codesign --verify --deep --strict` exit 0, 0 signing tells. **The profile was NOT re-issued: it still
expires 2026-09-17T19:25:02Z (20:25 BST)** — after that the app will not open until a rebuild after
expiry re-issues it via `-allowProvisioningUpdates`.

**Landed this session (all back to back, E's pacing call):**
- **`F-FanXAtRest`** (PR #147) — while the fan is open the stacked disc row drops to the column's
  bottom line; every close path animates (scrim/pick set `isFabOpen` bare, so the container carries
  `.animation(value: isFabOpen)`, `nil` under RM); the disc row draws above the fading cards
  (`zIndex`, proved in a custom `Layout` by render). RED on the unfixed tree: "× sits on PHOTO, 35.3pt";
  wiring cut on Tasks: "× on TASK, 9.49pt" (E's frame 19: 9pt). `screenshots/fan-x-at-rest/`.
- **`F-CollapsedBarLift`** (PR #148) — the 32pt `.offset` removed; the keyline closes in both states
  (`cardShape.strokeBorder`); `FocusBarCardBorder` and the three drop metrics deleted
  (`FocusBarMetrics.bottomLift`). Measured both orientations, alone and under a Confirm card: bar
  bottom +32 → 0 off the disc's line, gap above the tab bar 0 → 32, Confirm button → bar 56 → 24.
  `screenshots/collapsed-bar-lift/`.
- **`F-FanHoldsCelebration`** (PR #149) — **E NARROWED IT in-session.** Frame 20 (`IMG_8521`) was E's
  OWN Confirm already playing when the fan opened (fireworks = stack-clearing Confirm only; the card
  cannot be tapped under the fan; the × was at rest). E: **"Only hold new requests"** and **"Same 60s
  rule"**. `RootView` reports `isFabOpen || composerKind != nil` (closes the composer gap by
  construction); the fan joins `isBlocked` beside the probe at `.root`. Red-check pins the rejected
  "replay" shape.

**What this session established:**
- **A spec's reading of a screenshot is a hypothesis.** The collecting session read frame 20 as "a
  sprint ended while the fan was open"; three facts in the code (fireworks, the only Confirm caller,
  the × at rest) said otherwise, and E confirmed. Asking before building changed the block.
- **UI-harness traps, each paid for once** (memory `sprint-seed-harness-traps`): the timer bar's
  container identifier OVERRIDES its children's (`focusBarPause` matches nothing — find by label);
  sweep AutoFill before the first wait; a `simctl io screenshot` poller HUNG and blocked a chained
  erase for an HOUR — kill it on exit, never `wait` on it; `pkill -f` matched its own shell and skipped
  a restore; macOS `seq` prints epochs in exponent form.

---

**Fifty-sixth edition's State follows, unchanged.**


**Measured 2026-09-17 on `feature/landscape-fab-overlap` @ `11224c9` (Xcode 27.0, iOS 26.5 runtime,
emulator UP, freshly started this session):** suite **3,029 / 0** (3,011 + `F-LandscapeFabOverlap`'s 14 + the pill pin + `F-FanCardsFade`'s 3), **0** `127.0.0.1:9099` hits, **58** emulator cases across the six classes,
SwiftLint **0 / 819**, `** BUILD SUCCEEDED **` (**37 distinct warnings**, the Phase C figure, 0 errors),
coverage **27.67% (13,399/48,433)** — numerator +43 on a denominator +76 (the layout file and the
overlay's new lines), i.e. comparable and the new code is covered. `LandscapeAwayCardUITests`
**PASSED on 26.5 light and 27.0 dark** (both sims erased after). `firestore.rules` untouched —
**nothing for E to republish**. **The phone is ON MAIN at `9eb5198`** — all three of the day's blocks (`F-LandscapeFabOverlap`,
`F-TabBarPillInset`, `F-FanCardsFade`): device build, `devicectl` install clean (0 signing tells,
`codesign --verify --deep --strict` exit 0); the LAUNCH was denied for `Locked` — the known
"install is real, unlock and open" case, so **E opens it by hand**. Profile valid to
**2026-09-17T19:25:02Z — it expires TONIGHT**; after that the app needs a rebuild + reinstall
before it will open. **Three looks were owed on that build — see §B's first three items.** **The looks came in the same morning (fifty-sixth edition).** E ran a sprint on the phone and sent five frames and a GIF (`screenshots/landscape-fab-overlap/16–21`). **PASSED:** the pill at 12 (*"i think it looks perfect"*), and `F-FanCardsFade` with Reduce Motion OFF and ON. **Not passed as it stands:** landscape, where E wants margin under the collapsed bar. **Found:** the × lands on a tile whenever ANY card pushes the disc up in portrait (TASK under the sprint bar and under a Confirm card, 9pt and 7pt). **E's calls became three blocks in `TODO-CLAUDE-CODE.md`'s last section, NOT built** (E: *"I suggest that any building happens in a fresh Claude code terminal session"*). E's pacing: all three back to back, one install. See §B's first three items. **The phone still carries `9eb5198`, and its profile expires 2026-09-17T19:25:02Z.** The emulator is NOT running.

**`main` @ PR #131 — Phase D landed** (`4e4ec1c` was the baseline). Measured for Phase D on
2026-09-15 (Xcode 27.0, iOS 26.5 runtime, emulator UP): suite **3,011 / 0**, **0** `127.0.0.1:9099`
hits, **58** emulator cases across the six classes, SwiftLint **0 / 814** (the sweep harness is the
814th file), `** BUILD SUCCEEDED **`, coverage **27.62% (13,356/48,357)** — bit-identical to Phase C,
as it must be: the block adds a UI-target file and evidence, and no app code. `firestore.rules` untouched — **nothing for E to
republish**. **No app SWIFT code has changed since `598da3b`**; `F-FirebaseKeychainFix` moves a
dependency pin and adds a test, nothing else.

**Measured on the bump (2026-09-15, Xcode 26.6, emulator UP):** suite **3,011 / 0** in 26.3 s
(3,008 baseline + 3 new floor tests), **0** `127.0.0.1:9099` hits, **58** emulator cases across the six
classes, SwiftLint **0 / 813**, `** BUILD SUCCEEDED **` **70 warnings / 0 errors** (identical breakdown
to baseline), coverage **27.56% (13,356/48,454)** — bit-identical, as it must be.

**THE iOS 27 BASELINE — measured 2026-09-14 at `855759c` on Xcode 26.6 / iOS 26.5 SDK, against a
FRESHLY RESTARTED emulator.** This is the discriminator for the whole arc: without it, no
post-upgrade failure is attributable to the SDK rather than to something already broken.
- unit suite **3,008 / 0**, `** TEST SUCCEEDED **`, **49.7 s**, emulator UP, **0** `127.0.0.1:9099` hits;
- **58 emulator-backed cases ran across SIX classes** (not the four CLAUDE.md records — see §F);
- SwiftLint **0 violations, 0 serious, 812 files**;
- sim `** BUILD SUCCEEDED **` — **70 warnings, 0 errors, and ALL SEVENTY ARE CONCURRENCY WARNINGS**
  (13 of them already say *"this is an error in the Swift 6 language mode"*). See §F;
- coverage, app target **27.56% (13,356 / 48,454)** — up from 24.72% (11,114/44,961) on 2026-09-07,
  and **comparable**: the denominator moved because the TREE GREW (380 → 423 Swift files,
  46,978 → 53,093 raw lines), not because the measurement extent changed. Numerator +20.2% against
  a denominator +7.8%, so coverage grew ~2.5× faster than the code;
- **both UI journeys GREEN** (run for `-6`; not re-run for `-Surfaces`, which touches no UI, nor
  for `-Corners`, which changes a shape no UI test asserts);
- **device: ON MAIN at `560d068`, REINSTALLED 2026-09-16 — E's phone is on iOS 27.0 (24A437) and
  the build is running on it.** `** BUILD SUCCEEDED **`, 0 errors, installed and launched via
  `devicectl`; **app (pid 869) AND `FocusTimerWidgetExtension` (pid 843) both running as processes**.
  Bundle `LifeOS 1.3 (1)`, `DTSDKName iphoneos27.0`, `MinimumOSVersion 16.0`.
  **This is the SAME APP CODE as step 1's `b47aad5` build** — `git diff b47aad5..HEAD -- '*.swift'`
  is **0 files**, the only change being this register — so step 2's "same build, re-checked on 27"
  is satisfied exactly. The reinstall was needed only because the erase-and-restore to reach 27
  removed the app; step 1's PASS at 26.4 was observed before that and is unaffected.
  Two mechanics worth keeping: a restored phone has **Developer Mode OFF** and `xcodebuild` fails at
  destination resolution until E enables it; and the **first launch was denied for `Security`
  (untrusted profile) and the immediate RETRY succeeded** — the transient denial already recorded in
  the device-build notes. (Was `b47aad5`, installed 2026-09-15 for step 1; `1920536` from 2026-09-13.) **ALL FOUR blocks have passed on the phone**: `-6`, `-7`,
  `-Surfaces` (*"you can mark a PASS"*) and `-Corners` (*"they look okay"*, with two screenshots
  filed). **Nothing in any merged block is owed to E.**

**The emulator was restarted on E's instruction and it mattered.** The running instance had been up
since **Sun 13 Sep 03:48 — 1 day 19 hours**. E: *"if there's a stale or old emulator running then
I'd suggest closing it and starting a fresh one … purely because it has been running for so long."*
Correct call: a baseline is only worth having if the environment under it is clean. The old one was
on the right project and rules, but the whole point of Phase A is that nothing underneath it is
suspect. Cycled cleanly (SIGTERM to the parent, ports released in 3 s, the Firebase **MCP** left
untouched) and the suite re-run against the fresh one.

### Landed this session

**`F-LandscapeFabOverlap`** (PR #137, `main` @ `7e85ec6`) — see §B's first item: the landscape FAB
overlap, reproduced first, fixed with a `Layout` that keeps the portrait stack byte for byte,
red-checked, passing on 26.5 and 27.0. Owed: E's verdict on the side-by-side look (the build is on the phone).

**`F-TabBarPillInset`** — E chose 12 from the rendered options; shipped, red-checked at 4 and 16; §B's second item.

**`F-FanCardsFade`** — E's third finding of the day, fixed the way E chose; §B's first item.

**`F-CTACelebrations-6`** — C6–C9: the routine Completed flow wired (PRs #106–#109). See the
forty-first edition's detail; nothing about it is outstanding.

**`F-CTACelebrations-7`** — the chime (PR #110). E's F5, and the block that made a switch true:
"Celebration sounds" had been in Settings since `-3` storing a choice nothing read. Five candidates
went to E as `.wav`, peak-normalised to the same −3.0 dBFS so the comparison was of timbre; E picked
the first ElevenLabs generation by ear and **reserved the second for future use**. (NEW)

**`F-CTACelebrations-Surfaces`** — hold a celebration behind any unknown sheet (PR #112). E's
design call, taken before a line of it was written: asked to choose between a house modifier on all
26 `.sheet`/`.fullScreenCover` presenters and asking UIKit, **E chose asking UIKit**, plus holding
behind alerts / dialogs / system pickers and leaving a pop alone. `KeyWindowPresentationProbe`
walks the key window; `isBlocked` is the single predicate behind the hold and the release; a hold
watch replaces the `onDismiss` an untracked sheet never sends, and R-g is enforced by time rather
than by the next dismissal. **It is a PREVENTIVE block** — the five milestone sites were traced and
none of them can be reached from inside an untracked sheet as the tree stands, so what it closes is
the class rather than a live defect. **PASSED ON DEVICE 2026-09-13** (E: *"you can mark a PASS to
'the celebration hold' checklist item"*). Nothing outstanding. (NEW)

**`F-FocusCard-Corners`** — the collapsed card's bottom corners (PR #116). E's *"Round them"* was
a word, not a number, so the four radii went to E as a render and E chose **24 — "match the top"**
("leave it square after all" was offered and not chosen). `FocusBarCardOutline` now cuts BOTH the
fill and the keyline from one silhouette, so they cannot disagree about where the corner is; the
`Bool` became a `CGFloat` on `animatableData`. **PASSED ON DEVICE 2026-09-13** (E: *"they look
okay"*, two screenshots filed). Nothing outstanding. (NEW)

### What this session established

- **"Owed a device check" and "the code is on E's phone" are DIFFERENT FACTS, and conflating them
  wastes E's time.** Both blocks were reported as owing a device verdict while the phone was still
  on `eade58a`, two PRs behind. E looked, saw nothing, and reported it — *"i cant see any change on
  my iphone"* — about a change that was correct and simply not installed. The `device-build-lag`
  note already said *"after a device-affecting block, push a device build too"*. **Install as part
  of the close-out, and write the SHA the phone carries.**

- **A GREEN test suite can leave the one thing users depend on unproven.** Every test in
  `CelebrationSoundTests` injected `loadAsset`, so none of them touched the asset catalog —
  and `assetutil` on the built `Assets.car` proves the bytes SHIP, not that `NSDataAsset(name:)`
  resolves or that `AVAudioPlayer` accepts them. A dataset can be present and unreadable by name.
  **One test using the DEFAULT loader closes it**, and the test target hosts the app so it costs
  nothing. Generalises past audio: whenever a seam is injected everywhere for testability, ask
  what exercises the REAL implementation. (NEW)
- **Reversing a test is now a three-times-proven habit, and once it was the test NAME that lied.**
  `testTheFeedbackFooterExplainsBothSwitchesAndSaysTheSoundIsNotLiveYet` had the reversed claim in
  its own name. Also loosened — not deleted — a mount guard anchored on `CelebrationCenter()`'s
  empty parentheses, in its ARGUMENTS only, so what it is really about (the App owning the centre)
  stayed pinned. (NEW)
- **Footer prose is checked by no compiler, and it had drifted twice.** The Settings footer said
  the sound switch "does nothing until the chime arrives" AND that the milestone celebrations were
  "still to come" — the second stale since `-4`, nothing to do with this block, and nobody had
  noticed. **When a block touches user-facing copy, read the whole paragraph, not the clause.**
  (NEW)
- **E reserved a rejected candidate, which is a case the "no dead assets" rule does not cover.**
  `05-generated-b` is kept in the evidence folder as `.wav` and a ready-to-ship `.caf`, and
  deliberately NOT in the asset catalog: an asset with no call site is weight in every build. Kept
  where it is findable, added when a site exists. (NEW)
- **The provisioning "fastest check" FALSE-ALARMED** — `defaults read … DVTDeveloperAccountManagerAppleIDLists`
  returned an EMPTY `IDE.Identifiers.Prod` and the device build signed perfectly. On Xcode 26 that
  key is not evidence of anything; run the build and read its LOG. (NEW)
- **GitHub can report a merge as unmerged for the better part of an hour.** PR #109's merge landed
  (`4451326`) while `gh pr merge` returned 502; the PR read `merged=false` through ~40 s of polling
  and two more write attempts failed with 504/GraphQL errors. It reconciled itself later. **Verify
  against `origin/main` — `git merge-base --is-ancestor` — and do not re-run `gh pr merge`**, which
  would have put a second empty merge commit on `main`. (NEW)

## ⓪ · THE iOS 27 ARC — LIVE, and the next move is E's

**Opened 2026-09-14, the day iOS 27 shipped.** E: *"i need to look at updating the LifeOS application up to
the most recent iOS version that was released today - iOS 27. This must be done safely to ensure that nothing
breaks."* Plan: `/Users/ethan/.claude/plans/okay-claude-i-need-melodic-origami.md`.
Opener (this edition): **`handoff/START-HERE-three-device-looks.md`** — the single live opener; `START-HERE-ios27.md` is archived.

**E's three decisions, 2026-09-14:**
1. **Phone holds at iOS 26.4**, Automatic Updates off, until Xcode 27 is installed.
2. **Scope = move to the 27 SDK AND prove nothing broke AND adopt worthwhile 27 APIs** behind `#available`
   with complete iOS 16 floors. **The 16.0 deployment target does not move.** *(SUPERSEDED by E on
   2026-09-23 — "iOS 18, before F-D2" — and built as `F-Floor18` on 2026-09-24: the floor is 18 on
   every target. The line above is E's decision as made on 2026-09-14 and is kept as such.)*
3. **iOS 27 first; the colour arc stays held.**

- [x] **Phase A — the baseline. DONE 2026-09-14.** Figures in "State" above. This is the discriminator for
      every later phase. (NEW)
- [ ] **⛔ Phase B — THE GATE, and it is E's. Nothing from Phase C on can start until this is done.**
      - **Automatic Updates OFF on the phone; hold at 26.4.** (E has been asked.)
      - **Free the boot volume — it had 12.2 GB.** `~/Library/Developer/CoreSimulator/Devices` is **11 GB**
        and regenerates safely. `iOS DeviceSupport` is 5.5 GB but is **entirely E's phone at 26.4**.
      - **Xcode 27 onto `/Volumes/Es-SSD`** — E's instruction, and it works for the `.xip` and the app.
        **BUT the iOS 27 simulator runtime (~8 GB) CANNOT go there**: runtimes are MobileAsset cryptex disk
        images under `/System/Library/AssetsV2/`, on the system volume, with no supported relocation. That
        8 GB of boot volume is unavoidable. **This is the one place E's instruction cannot be followed
        literally, and E has been told.**
      - **Keep Xcode 26.6 as `Xcode-26.6.app` — the rollback.** Switch with `DEVELOPER_DIR`, never
        `xcode-select`.
      - **DO NOT delete the iOS 26.5 runtime** (7.9 GB, deletable): Phase D needs both runtimes.
      - **`brew upgrade swiftlint`** — 0.65.0 may not parse Swift 6.4.
      - **Optional, and it will never be cheaper:** the older simulator runtime §A has wanted since
        2026-09-11 is the same Components screen. (NEW)
- [x] **Phase C — build on the 27 SDK. DONE 2026-09-15 (`F-iOS27-C-SDK`).**
      **The app compiles and the whole suite passes under Xcode 27.0 / Swift 6.4 / iOS 27.0 SDK**, run on
      the iOS 26.5 runtime (target was 16.0 then — 18.0 since `F-Floor18` — so the 27 runtime is not needed for this and is deliberately
      not installed — it is a Phase D need). `Package.resolved` verified **unchanged** on every run, so
      the SDK was the only variable.

      **Exactly TWO compile errors, both in TEST DOUBLES, none in app code.** `DailySummaryGenerating`
      is implicitly `@MainActor` because the app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
      and **Swift 6.4 began enforcing that an `actor` cannot conform to a global-actor-isolated
      protocol** — which broke `GatedDailySummaryGenerator` and `GatedFailingDailySummaryGenerator`.

      **A wrong turn worth recording, because it looks right: marking the PROTOCOL `nonisolated` does
      not fix it.** That propagates `nonisolated` to conformers, and an actor cannot be `nonisolated`
      either — the error simply moves. Reverted; app code ended up untouched. The fix is the two doubles
      becoming `final class … @unchecked Sendable`, following `ToggleableDailySummaryGenerator` ten lines
      below them in the same file. **Nothing is lost semantically:** the mid-flight hold is the `Gate`
      actor's doing, not the generator's own isolation, so `generate` still suspends and "generating"
      remains a state a test can stand in.

      **App-target build warnings: 33 → 37, and the +4 is two NEW Swift 6.4 diagnostics**, not decay.
      Every pre-existing category is unchanged to the count (14, 8, 5, 2, 2, 1, 1). The new ones are
      **3 × `[#IsolatedConformances]`** and **1 × `[#ImplicitStrongCapture]`**.
      ⚠ **Count DISTINCT warnings.** The "70" in the forty-sixth edition was a raw `grep -c`; the log
      repeats each warning, and the distinct figure was always 33. Same doubling trap as the emulator
      count — both are now corrected. A `test` run's warning count is NOT comparable to a `build` run's,
      and neither is comparable across incremental builds, since only recompiled files emit.

      Suite **3,011 / 0** in 57.9 s · **58** emulator cases across the six classes · **0**
      `127.0.0.1:9099` hits · SwiftLint **0 / 813** · `** BUILD SUCCEEDED **`, 0 errors · coverage
      **27.62% (13,356/48,357)** — numerator BIT-IDENTICAL; the denominator moved 48,454 → 48,357 with
      no source change, i.e. Swift 6.4 attributes executable lines slightly differently. (NEW, CLOSED)

- [ ] ~~Phase C~~ — superseded above. Still outstanding from its trap list:
      **add an explicit `,OS=` to CLAUDE.md's documented destinations**, which becomes load-bearing the
      moment the iOS 27 runtime is installed and two `iPhone 17 Pro` sims exist. (NEW) Traps enumerated in the opener. The load-bearing ones: decline
      "update to recommended settings"; keep `SWIFT_VERSION = 5.0`; **first build on the committed
      `Package.resolved`, unchanged, then `git diff` it**; add explicit `,OS=` to every destination and
      update CLAUDE.md's Commands section. (NEW)
- [x] **THE APP RUNS ON iOS 27.0 — verified 2026-09-15.** Not merely built against the SDK: the full
      suite executed on the **iOS 27.0 (24A434)** runtime. **3,011 / 0**, 0 errors, 58 emulator cases,
      0 `127.0.0.1:9099` hits, `Package.resolved` unchanged. Both runtimes are now green:
      **26.5 → 3,011/0 (57.9 s)** and **27.0 → 3,011/0 (90.7 s)**. (NEW)

- [x] **The iOS 27 runtime is INSTALLED, and the failure on the way in is worth keeping.** Xcode's
      Components download sat on "Preparing…" all night: **it was DISK**, not a network or Xcode fault.
      "Preparing" is the decompression step, the boot volume had 8.4 GB, and the asset needs ~7.5 GB plus
      room to expand — **Xcode does not error in that state, it spins indefinitely.** After freeing space
      the download completed but then reported ***"Failed — Registering simulator runtime with
      CoreSimulator failed."***, **caused by me `pkill`ing a parallel `xcodebuild -downloadPlatform` when
      E's GUI download started.** Recovery needed no re-download: the asset was intact at
      `/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/<hash>.asset/AssetData/Restore/*.dmg`
      and `xcrun simctl runtime add <dmg>` registered it, **at zero disk cost** — same volume, so simctl
      cloned rather than copied (27 GiB free before and after). **Do not run two runtime downloads at
      once**, and if registration fails, re-add the local image rather than re-downloading. (NEW)

- [x] **Disk: 8.4 GiB → 35 GiB free** (2026-09-15). The internal Data volume was **96% full** — this was
      never an Xcode problem. Dev caches took it to 15 GiB (`iOS DeviceSupport` 5.5 GB, swiftpm 619 MB,
      Homebrew 614 MB — all regenerate); **E then asked for Steam (11 GB) and EVE Online (9.3 GB) to be
      deleted**, which was safe on inspection: Steam's `userdata` was **196 KB** and its 10 GB was six
      re-downloadable games, EVE's 9.3 GB was **entirely `SharedCache`**. (NEW)

- [x] **Phase D — the 26.5-vs-27.0 UI sweep. DONE 2026-09-15.** Evidence in
      `screenshots/ios27-compat/` (52 frames, 26 composites, 2 zooms, README with the per-band
      measurement). Thirteen surfaces × two runtimes × two appearances, the SAME binary, driven by
      `IOS27CompatSweepUITests` (committed deliberately — it is the re-runnable camera for Phase F
      and every 27.x point release). **Answer to E's question: nothing the app draws moved.**
      - **The custom tab bar is pixel-identical** — bottom band **0.00 %** on all ten plain-tab
        frames, both modes. The audit's highest-risk surface is closed.
      - **iOS 27 retunes SHEET CHROME**: bottom corners rounded and inset, a thin dark edge, on every
        sheet (promote, Settings, New nudge at both detents). Content inside unchanged.
      - **Glass capsules retuned, visible in DARK**: sheet-toolbar Cancel/Save are lighter and edged
        on 27.0. System controls, consistent with iOS 27 — **an input to the held colour arc**, not a
        defect.
      - `confirmationDialog` is a **popover on both runtimes** (no Cancel element in either tree);
        27.0 places it above the row rather than beside it.
      - The bottom search row is unchanged; frame 02's delta is iOS 27's first-run QuickPath tip
        pane where 26.5 shows the keyboard. The `.searchable` precedent did not repeat.
      - One text delta in 52 frames (the schedule summary line, dark, ~30 % dimmer on 27.0) carries
        an opacity transition and is recorded as an observation, not a finding.
      - **NOT covered: widgets and Live Activities** — see the bridge item below. Owed to Phase F.
      (NEW, CLOSED)
- [ ] **The Xcode bridge's `RenderPreview` cannot be pointed at a chosen runtime — established, not
      assumed.** The scheme was switched to `iPhone 17 Pro (26.5)` and confirmed active; the preview
      launched on `iPhone 18 Pro` (27.0) regardless — **the preview canvas picks its own device**. Both
      27.0 attempts then failed on launch timeouts (`AppLaunchTimeoutError` 15 s; then
      `CHSErrorDomain 1051 timelineReloadTimeout` for the widget extension) on this 8 GB machine with
      Xcode, the emulator and a simulator all resident. So the widget and Live Activity previews were
      NOT rendered on either runtime. **Phase F covers it on the phone**; if a sim render is wanted
      first, the route is the home-screen widget gallery driven through the simulator, not the bridge.
      (NEW)
- [ ] **Phase E — Firebase.** See the bump item below; the proof is the six emulator classes still passing.
- [ ] **Phase F — device, IN PROGRESS. Step 1 DONE 2026-09-15: the 27-SDK build is ON THE PHONE at
      iOS 26.4.** `main` @ `b47aad5` built for `wishwashwacky15` (iPhone 15 Pro, iOS 26.4 / 23E246)
      with `-allowProvisioningUpdates` (both profiles re-issued), installed and launched via
      `devicectl`; the app AND the widget extension were running as processes afterwards. The bundle
      is stamped `DTSDKName iphoneos27.0`, `MinimumOSVersion 16.0` (widget 16.1 — both pre-`F-Floor18`; 18.0 since). **This is the first
      27-SDK binary on the phone, and the first build on the phone that carries the Firebase keychain
      fix** — compiled from the 12.19.1 checkout (`AuthKeychainServices.swift` has
      `isKeychainAccessible` ×3; `Package.resolved` unchanged). Note the embedded Firebase version
      string reads `12.19.0`: Firebase did not bump its core constant for the .1 patch, so the SOURCE
      is the proof, not the string. **E's look at 26.4 PASSED, 2026-09-16** (E: *"your most recent install to my iphone works
      correctly throughout the app"*) — the 27-SDK binary runs on the old OS, the floor-side half of
      the compatibility claim. **STEP 2's PRECONDITION IS MET, 2026-09-16: the phone is on iOS 27.0 (24A437)**, updated through
      the MacBook as planned. **What changed is the shape of step 2.** Getting there required an
      erase-and-restore, so the 27-SDK build is **no longer on the phone** — step 2 is a REINSTALL of
      the same `main` build followed by the device look, NOT the "re-checked on 27 without a
      reinstall" this item originally planned. **THE REINSTALL IS DONE (2026-09-16) and E's LOOK IS DONE the same evening.** `560d068` ran on
      the phone at iOS 27.0, app and widget extension both. **E's verdict: the app is correct** —
      *"LifeOS looks to be working correctly. The live activity & home screen widgets look to be
      working."* That closes the two biggest Phase D asks (**widgets and Live Activities on 27**,
      never rendered on 27 anywhere before) and the **sheet chrome**, which E photographed in both
      modes: iOS 27's lighter, edged toolbar capsules are confirmed on a physical display, content
      inside unchanged, system behaviour rather than a defect. Evidence:
      `screenshots/ios27-device-findings/` (5 files + README with the measurements).
      **The look also surfaced TWO NEW items, neither of them an iOS 27 regression — see §B.**
      Still unlooked-at from the Phase D list: **the schedule summary line's dimness in dark**. Nothing about the app or the compatibility claim changed. Note also the phone now has
      **~92 GB free** where storage was previously very limited, so the constraint that shaped step 2
      is gone. (NEW)
      Original brief: install the 27-SDK build while the phone is STILL on 26.4
      (proves the new binary runs on the old OS), then E updates to 27 and it is checked again. The
      device look now carries three specific asks from Phase D: **the Focus Live Activity and the
      Home Screen widgets on iOS 27** (never rendered on 27 anywhere yet), **the retuned sheet chrome
      and dark-mode capsules on a physical display**, and the schedule summary line's dimness in dark.
      E's phone does not yet carry the Firebase keychain fix either. (NEW)
- [ ] **Phase G — adoption.** Candidate list first, E picks, **each pick is its own FEATURE block** that
      stops for review. Possibly zero. §7.1's filter governs and `apple:modernize` does not skip the gate. (NEW)

### ⚠ THE ONE ITEM HERE THAT IS A REAL USER-FACING BUG, NOT MIGRATION WORK

- [x] **DONE 2026-09-15 (`F-FirebaseKeychainFix`). Bumped firebase-ios-sdk 12.17.0 → 12.19.1 — it fixes silent random sign-outs.**
      **Verified the FIX ITSELF is in the source we compile, not just the version string:**
      `AuthKeychainServices.swift` in the resolved checkout has `isKeychainAccessible()` at :265, called
      at :60 and :189, with the `errSecInteractionNotAllowed` remap at :65 and :194. Version numbers are a
      proxy; this is the thing.
      **Clean bump — suite 3,011/0 (3,008 + the 3 new floor tests), all 58 emulator cases across the six
      classes still pass, SwiftLint 0/813, BUILD SUCCEEDED with 70 warnings — byte-identical breakdown to
      the baseline — and app coverage bit-identical at 27.56% (13,356/48,454), which is exactly right
      because no app code changed.** Four packages moved: firebase 12.17.0 → 12.19.1 (LINKED) plus three
      transitive pins that are **not linked into any target** (googleappmeasurement, googleutilities,
      google-ads-on-device-conversion). **The prebuilt binaries did not move at all** — abseil, grpc,
      leveldb, nanopb, promises were already the newest that exist, as the research predicted.
      `FirebaseSDKVersionFloorTests` now pins the floor in BOTH places — the resolved version and the
      pbxproj `minimumVersion`, which was raised 12.0.0 → 12.19.1 so a clean resolve or a fresh clone
      cannot legally land below the fix. Red-checked before the bump: both assertions failed on 12.17.0.
      (NEW, CLOSED)

      ~~The original entry, kept because it is the reasoning:~~
      [PR #16505](https://github.com/firebase/firebase-ios-sdk/pull/16505): a known iOS 15+ bug where
      `SecItemCopyMatching` returns `errSecItemNotFound` instead of `errSecInteractionNotAllowed` on a locked
      device; FirebaseAuth trusted it and wiped the user. Reporters measured **~1% of recently active users**
      losing their session. **This app is maximally exposed**: it restores sessions with a single
      `Auth.auth().currentUser` read (`FirebaseAuthClientAdapter.swift:29` → `FirebaseManager.swift:97`) and
      has **no `addStateDidChangeListener` fallback**, so a spurious `nil` drops straight to `.signedOut`.
      **Skip 12.18.0** (app-extension `UIApplication.shared` regression, reversed in 12.19.0).
      **This is independent of iOS 27 and worth doing regardless.** (NEW)

### Facts the arc turned up that are NOT its scope

- [ ] **`UIApplication.canOpenURL` is deprecated in iOS 27** (release note 179874781). Used at
      `Places/PlaceAppInstallVerification.swift:91`; the app-directory "installed" badge and its **45
      `LSApplicationQueriesSchemes`** rest on it. Apple's advice — *"attempt to open the URL and handle any
      failure instead"* — **does not preserve the feature**, because the badge must answer "is it installed"
      *without* launching anything. It sits behind a one-method seam (`:83`) so the code blast radius is one
      function, but **what the badge becomes is a design question for E.** Not urgent: deprecated, not
      removed. (NEW)
- [ ] **No `PrivacyInfo.xcprivacy` anywhere in the project**, while the app links three SDKs on Apple's
      third-party-requirements list (`FirebaseAuth`, `FirebaseCore`, `FirebaseFirestore`) plus five listed
      transitive binaries, and uses `UserDefaults` — a required-reason API — via the App Group. **A
      submission blocker at launch**, not an iOS 27 one. Belongs with §D. (NEW)
- [ ] **The gRPC XCFramework slices are unsigned on disk** (`codesign -dvv` → *"code object is not signed at
      all"*) and gRPC is on Apple's signature-required list. **Current state under Xcode 26 too — not new**,
      but it had never been written down. (NEW)
- [ ] **`Home/FirebaseDailySummaryGenerator.swift:77,127` bypasses the adapter seam**, calling `Auth.auth()`
      and the callback `getIDToken` directly — the exact pattern `AuthBackingStore.swift:10-13` records as
      removed elsewhere because "nothing could stub it". The only Auth consumer outside `Firebase/`. (NEW)

### Corrections to CLAUDE.md this session earned

- **"The four extensions the emulator harness covers" — there are SIX.** `FirebaseManagerRoutineRunsTests`
  and `FirebaseManagerNudgeCompletionTests` joined and were never added. All six ran in the baseline
  (58 cases). (NEW)
- **`PlaceMapPicker.swift:15` says "the 40-odd `#available` gates"; the real count is 28** code sites (plus
  68 `@available` declarations, zero `#unavailable`). (NEW) → **CLOSED by `F-Floor18` (2026-09-24):** the
  comment was rewritten as history and every gate below 18 is gone; only the three iOS 26 sites remain.
- **`ModernAPIPolicyCallSiteTests.swift:13-14` claims every other iOS 17 gate is an `if` with no `else`.**
  `VoiceCaptureRecorder.swift:74` is an iOS 17 gate **with** a full `else`. (NEW) → **CLOSED by
  `F-Floor18`:** both the gate and the test's claim are gone; the test now pins the helper as ungated.
- **CLAUDE.md records the app target's deployment target as 16.0 only**; the widget is **16.1**, and the
  file's §7 does say so elsewhere — but the "Architecture notes" bullet does not. (NEW) → **CLOSED by
  `F-Floor18`:** the bullet now says one number, 18.0, on every target.

## A · Decisions only E can make — minutes each

### A-STEP0 · The open Step 0 questions — **ALL ANSWERED by E, 2026-09-24**

> **E, verbatim:** *"Take all the recommendations as written. When building 'Arc F-F1' Claude Code
> MUST Give Ethan a thorough questioning on the desired approach to redesigning the "Checkpoints"
> System with the "Heads-up" System."*

Every open block's Step 0 now carries an **"E DECIDED 2026-09-24"** banner with the chosen answer
(D2 date-only; E3 Nudges door → Tools, arrival + routine cards count as the one card; E4 the Mon–Sun
focus widget; E5 18:00 + Settings override, pins, reappears; F1 own sound switch default ON, no
heads-up ≤ 5 min, +5m does not re-arm; F5 build the seam + write, render pass for the picker; A1 keep
the age chip; A2 copy `StateGo` + drift guard; A4 "cannot be undone" always visible; B2 custom
two-segment control; G5 `set_aside_at` task field, "not opened for 7+ days"). **The one thing still
owed before a block is F-F1's questioning round — E, 2026-09-24: *"insists that we run in 'Plan Mode'"*,
so that round is run in Plan Mode — and F-F5's picker render pass.** No other block
waits on E. (CLOSED as a question; the two rounds are WORK, carried on their blocks.)

### A-CHEVRON · The fold's chevron against Apple's disclosure conventions — **E DECIDED 2026-09-24: KEEP**

> **E, 2026-09-24: *"Keep the chevron as is."*** ▲ folded / ▼ open stays on all three screens. Settled: a future
> `apple-design` review names the divergence from `disclosure-controls.md` as E's decision, never as a finding to fix.
> The contrast reading below stays colour-arc input (HELD); the stale "two screens" prose rides whichever block next
> touches `CollapsibleSectionHeader.swift` — no block of its own.


`F-D3`'s `apple-design` review read `disclosure-controls.md` (HIG pages dated 2026-09-22). Apple defines two
conventions: a disclosure **triangle** "points inward from the leading edge when its content is hidden and down when
its content is visible" (SwiftUI's `DisclosureGroup`), and a disclosure **button** "points down when its content is
hidden and up when its content is visible". The house fold — `CollapsibleSection.chevron`, **▲ folded / ▼ open**,
E's call on 2026-08-28 after seeing both ("points AT the content") — matches **neither**. The decision predates the
skill (installed 2026-09-18) and was never checked against this page. **Nothing was changed.** It is shared by Home's
life areas, Journal's days and now Tasks' Anytime, so any change is ONE line in `CollapsibleSection.chevron` plus its
pinning test — its own small block, never folded into an arc block unasked. **Colour-arc input beside it:** the
`.tertiary` chevron measures **1.71:1 light / 2.47:1 dark** on `PageBackground` and is the fold's only visual state
cue (VoiceOver hears the state). Contrast is HELD (round 9).
**Stale prose for that block to fix:** `Theme/CollapsibleSectionHeader.swift` (its header comment and the
`CollapsibleSection` doc) and `CollapsibleSectionTests.swift` still say "two screens" — it is THREE since `F-D3`
(Home, Journal, Tasks' Anytime via `TasksAnytimeHeader`). Left out of the docs-only close PR on purpose.

### A-CAPSULE · The Undo capsule is INVISIBLE in the Tag Editor — **E DECIDED 2026-09-22: Option C, DEFERRED with a condition**

> **E, 2026-09-22, verbatim:** *"Option C — BUT YOU MUST LOG THIS DECISION INTO MEMORY SO THAT WE
> CAN CIRCLE BACK TO IT IN FUTURE AND ADD A USER IN-APP NOTIFICATION."*

**This row stays OPEN.** Option C was "accept it", but E attached a condition, so the work is owed
— just not now. **Do not close this row and do not report the tag delete as finished
feedback-wise.** Logged in memory as `tag-delete-needs-in-app-notification`.

**What is still undecided is the SHAPE.** E said "in-app notification", which reads closer to
option 2 below (`tagEditorInfoToast`, which already draws inside the sheet) or to a new shared
in-sheet notice, than to option 1 (mounting the capsule layer on every sheet). **Ask E which before
building it**, and check the same question for every OTHER sheet that hosts an undoable action —
the tag delete is the instance that was found, not necessarily the only one.

**What happened.** E chose *"drop the alert, add an Undo capsule"* for the tag delete over
*"drop the alert, no capsule"*, whose named cost was *"it's the one option that gives no feedback
at the moment of the delete."* **As shipped, the Tag Editor delivers that second option.** Settings
is a `.sheet` presented from Today; the capsule lives in `RootBottomOverlay`, the same app-level
layer as the tab bar, and the sheet covers both. Frame
`screenshots/recently-deleted-tags/01-deleted-and-the-capsule-offers-undo-*.jpg` shows the delete
landing with no capsule and no tab bar.

**Why no test caught it, and why none could.** The harness asserts `tap(deleteButton, untilExists:
capsule)` and it PASSES — XCUITest finds elements in the accessibility hierarchy whether or not
anything is drawn over them. `.environment(\.recordAction, …)` is applied outside every cover and
sheet, so a site inside one RECORDS correctly. **Inheriting the environment is not being drawn.**
CLAUDE.md already documents this failure mode for Celebrations ("drawn by one layer PER PRESENTED
SURFACE… a cover that hosts a site and mounts no layer draws nothing and passes every other test")
— the undo capsule has ONE mount.

**The options, for E:**
1. **Mount the capsule layer on the Settings sheet** (the Celebrations answer, and it generalises
   to every sheet that hosts an undoable action). Touches app-wide furniture, every constant in
   which is E-approved — which is why it is not done unasked.
2. **Give the tag delete its own in-sheet feedback** — a brief inline notice in the Tag Editor,
   like `tagEditorInfoToast`, which already exists and already draws inside the sheet.
3. **Accept it**: the delete is still undoable from Tools → Recently Deleted within 30 days, and
   the Tag Editor's row simply disappears. This is the option E was shown and did not pick.

**Not urgent and not a data risk** — nothing is lost either way. It is a decision about whether the
delete says anything at the moment it happens.


### A0 · The undo capsule's two contrast readings — colour-arc input, NOT a decision yet (2026-09-20)

Measured from the colorsets during `F-C1-UndoCapsule`'s `apple-design` review, not estimated from a
screenshot. **No action is asked for**: round 9 settled that contrast belongs to the HELD colour
arc, and both readings are of relationships E already approved elsewhere. They are recorded because
nobody had written a number down for either.

| what | light | dark | the bar |
|---|---|---|---|
| Undo label — accent on the tab bar's selected-pill wash | **3.38:1** | **3.48:1** | 4.5:1 (16pt semibold) |
| The verb line — `LabelSecondary` on `CardSurface` | **4.25:1** | 5.52:1 | 4.5:1 |
| The subject — `LabelPrimary` on `CardSurface` | 19.26:1 | 14.97:1 | passes comfortably |

The first row is **the tab bar's own selected pill**, which E approved by looking; changing it here
would silently re-tune an approved token in one place and not the other. The second is the app's
`LabelSecondary`, used on every screen. Both are palette questions.

**Added 2026-09-23 by `F-D1-ComposerBothDoors`'s `apple-design` review** — the composer's Area and
Time menu rows, same method (colorsets, not a JPEG; iOS `secondaryLabel` as `#3C3C43`/`#EBEBF5` at
60%):

| what | light | dark | the bar |
|---|---|---|---|
| A menu's VALUE ("None", "15 min") — `.secondary` on `CardSurfaceSecondary` | **3.22:1** | 5.38:1 | 4.5:1 (17pt regular) |
| A menu's TITLE ("Area", "Time") — label on `CardSurfaceSecondary` | 17.76:1 | 14.37:1 | passes comfortably |

Not new to the app: it is the composer's existing card treatment (the old place row and the custom
date card sat on the same surface with the same value styling). Round 9 holds it for the colour arc.

### A1 · Everything below predates edition 68

**Every device check on the CTA-CELEBRATIONS ARC and the FOCUS CARD is clear** — E settled four at
the sitting on 2026-09-12/13, then `-6`'s and `-7`'s verdicts, then `-Surfaces`' and `-Corners`' on
2026-09-13 once the phone was finally carrying them.

**"Nothing in any merged block is waiting on E" was written here and it was TOO STRONG — corrected
2026-09-13.** Three earlier follow-on blocks (`SwipeOrigin`, `NoCooldown`, `PopScale`) still owe
device looks; they are landed, green and installed, and the first of them replaces a defect E
themselves reported, so it is the one with a known "before". The honest statement is: **nothing in
the last four blocks is owed; three older ones still are, and none is urgent.**

- [x] **`F-CTACelebrations-Surfaces`' DEVICE PASS — PASSED 2026-09-13.** E, on `main @ 1920536`:
      ***"you can mark a PASS to 'the celebration hold' checklist item"***. **Nothing in the block
      is outstanding.** The note below is kept because it is the reasoning, not the task:

      ~~**read what it is FOR before running it, because the obvious version of this check cannot
      fire.**~~ All five milestone sites were
      traced: `inboxZero`'s three doors, `streakSeven`'s "Done for now", `dailyGoal`'s ring and
      `routineFinished` are reachable only from `.root` or from the two tracked surfaces, and
      **Quick Capture creates captures rather than clearing them** — so as the tree stands today
      there is no user action that fires a milestone from inside an untracked sheet. **The block is
      preventive, not a fix for a demonstrable bug**: it closes the class (every future sheet, plus
      alerts, dialogs and iOS's own interruptions such as "Save Password?") and the composition
      test is its proof.
      **So the device check is the REGRESSION one, and it is two minutes.** Get the capture inbox
      down to one waiting capture, open it, **Create Task**, promote. Inbox zero should celebrate
      **immediately** as the sheet closes, exactly as it did before. That path is the one
      `releaseHeldIfClear` now gates on the probe, it is shipped and E-verified from
      `F-CTACelebrations-5`, and it is the only place this block could have made something worse.
      **No RM-on pass is owed** (§7.3): no `#available` site and no Reduce Motion site is added or
      changed, so the reduced path cannot look different either way. (NEW)

- [x] **`F-FocusCard-Corners`' DEVICE VERDICT — PASSED 2026-09-13.** E: ***"they look okay"***,
      with two device screenshots filed as
      `screenshots/focus-card-bottom-corners/02-device-collapsed-light.jpeg` and
      `03-device-collapsed-dark.jpeg` — the shipped 24pt corner on real glass, light and dark.
      **Nothing in the block is outstanding.** The note below is kept as the reasoning:

      ~~a look rather than a test.~~ Start a sprint, collapse the card, and look at where its bottom
      corners meet the tab bar; then expand it again. E chose 24pt from a simulator render
      (`screenshots/focus-card-bottom-corners/`), and what a render cannot show is how the notch
      between card and bar reads on glass at arm's length. **No RM-on pass is owed** (§7.3): no
      `#available` site is added, and the only Reduce Motion interaction is the existing collapse
      animation, untouched. (NEW)

- [x] **`F-CTACelebrations-7`'s DEVICE VERDICT — PASSED, 2026-09-13, both checks.** E, verbatim:
      ***"both work correctly"*** — the chime plays UNDER music without pausing it
      (`.mixWithOthers`) and stays silent with the ring switch off (`.ambient`). Neither is
      provable on the simulator. **Nothing in the block is outstanding.** (CLOSED)
      - **E reserved the runner-up sound** for use elsewhere: *"keep a hold of the sound 'el-b'
        ... there is likely other locations that [it] Could be used."* Kept at
        `screenshots/cta-celebrations-block-7/candidates/05-generated-b.{wav,caf}`, deliberately
        out of the asset catalog until a real site exists. **This is a standing item for whoever
        adds the next sound** — do not regenerate one. (NEW)


- [x] **`F-CTACelebrations-6`'s DEVICE VERDICT — PASSED, 2026-09-13, BOTH passes.** Installed at
      `4b0f0ad` (build, install, launch clean in one wireless pass). E, verbatim: ***"both work
      correctly"***, answering an ask that enumerated the two checks separately — Reduce Motion OFF
      (Close leaves the card, it reads "Finish routine", reopening offers Completed, the
      congratulation over a real fetch, a step ROW closes it) and then Reduce Motion ON. **So
      §7.3's RM-on pass is EARNED for this block**, and its Verified-paths line reads *"Reduced: run
      on sim (injected) + E's phone (RM on)"* — the second time in this arc that line is earned
      rather than owed. **Nothing in the block is outstanding.** (CLOSED)
      - **Shipped but NOT approved, and worth knowing:** under `.spring` the checklist scales down
        to 0.9 as the congratulation scales in. The plan specified the entrance only; the symmetric
        exit was the implementer's call, was flagged to E in the same message, and drew no comment
        either way. Overrulable. (NEW)

- [ ] **DEVICE CHECK OWED on the three follow-on blocks, whenever E is next on the phone.** All
      three are landed, green and installed from `main`; none is urgent, and E has already passed
      everything that came before them.
      - **The swipe's pop** (`SwipeOrigin`) — swipe a task closed and confirm the paper now leaves
        from the finger rather than off the right-hand edge. **This is the one that replaces a
        defect E reported**, so it is the only check with a known "before".
      - **The overlap** (`NoCooldown`) — clear the last capture and cross the daily goal close
        together; two full-screen celebrations now OVERLAP rather than the second being downgraded.
        That is the direct consequence of removing the cooldown and it is E's decision; it is worth
        a look only to confirm it does not read badly.
      - **Reduce Motion ON** (`PopScale`) — the still pop's scatter scaled 48 → 76.8 pt with the
        pop, so §7.3 owes it one RM-on look. Until then that block's Verified-paths line reads
        *"Reduced: run on sim; NOT on device."* (NEW)
- [ ] **PHOTOSENSITIVITY — E POSTPONED this on 2026-09-13, and asked in the same breath that it be
      brought back before public launch.** E, verbatim: *"Can we postpone this decision for later
      date? But we must come back to this before shipping to the public."*
      **So this is now a LAUNCH BLOCKER by E's own instruction, not an open polish item** — it is
      listed in §D as well, and neither entry may be closed without E.
      The finding, unchanged: the stack-clearing Confirm's 14 shells flash **5 times inside one
      second** (from ≈ 2.00 s) against **WCAG 2.3.1's threshold of 3**. Each flash is a radial
      gradient growing 40 → 240 pt at up to 0.35 alpha over 0.35 s. **Unmeasured:** whether the
      luminance delta and screen area also cross the guideline — the flash COUNT alone is what
      crosses. There is no app-readable API for iOS's "Dim Flashing Lights", so it cannot be gated
      in code. The finding does NOT extend to the pops or the milestones (both re-confirmed).
      The options remain: measure the luminance properly, thin the two clusters, or accept it with
      eyes open. (DEFERRED BY E, carried to §D)
- [x] **Install the iOS 18 simulator runtime — DONE 2026-09-24.** iOS 18.0 (22A3351) is Ready,
      "iPhone 16 Pro (iOS 18 floor)" exists, the full unit suite passes on it (**3,320 / 0, 6
      iOS-26-only skips**) and the app boots and draws (`screenshots/floor-ios18-first-run/`). E
      downloaded the DMG (Apple serves it only behind the developer sign-in; `-downloadPlatform`
      offers no 18.x) and keeps it at `/Volumes/Es-SSD/Ethan/Developer/Xcode iOS Runtimes/`; the
      install took FIVE attempts because the portal DMG is two layers and each failed add leaked an
      8 GB mount — the whole procedure is memory `simulator-runtime-install`. E also freed 13 GB
      (both `iOS DeviceSupport` folders + the previews cache, regenerable). Internal disk: 19.4 GB
      free after. (CLOSED)
- [ ] **Optional, still not decided: an `.accessibilityHint` on the Celebration sounds row only.**
      (carried)
- [x] **THE DEVICE SITTING — DONE 2026-09-12, and BOTH blocks PASSED with Reduce Motion OFF *and*
      ON.** E, verbatim: *"both of those tests work correctly!"*, confirmed when asked precisely
      about RM. So `F-CTACelebrations-4` and `-5` are verified on device and **both blocks'
      Verified-paths lines read "Reduced: run on sim (injected) + E's phone (RM on)"** — the first
      time in this arc that line is earned rather than owed. (CLOSED)
- [x] **The milestone cooldown — E REMOVED IT ENTIRELY, 2026-09-13.** Verbatim: *"Remove the
      cooldown entirely."* It was E's own 5 s testing value from the start, so this closes the
      question rather than reversing a settled answer. Shipped in `F-CTACelebrations-NoCooldown`;
      the consequence to watch on device is the overlap, above. (CLOSED)
- [x] **The VoiceOver announcement on the streak — E: leave as shipped, 2026-09-13.** E was told
      that the premise behind the original answer was wrong (the nudge card VANISHES on dismissal,
      so day seven leaves nothing on screen that distinguishes it) and chose to keep the shipped
      behaviour anyway: the daily goal announces, the other two do not. **Decided with the correct
      facts in hand, which is what the re-ask was for.** (CLOSED)
- [x] **Whether the Celebrations switch should also gate pops — E: leave as shipped, 2026-09-13.**
      So the switch covers full-screen celebrations only, the Settings footer continues to say so,
      and a user wanting zero decorative motion has Reduce Motion (which stills the pop rather than
      removing it). Raised by the `apple:hig-reviewer` pass; E has now ruled. (CLOSED)
- [x] **An accessibility announcement for the milestones** — E chose "the daily goal only",
      2026-09-12, re-confirmed 2026-09-13 on corrected facts. (CLOSED)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12**, written into CLAUDE.md §7.3. (CLOSED)

## B · Real work, ready to start — recommended order

- [ ] **🐞 CANDIDATE (found 2026-09-24, E said "add to the register") — an inbox area chip is LOST
      when you tap Task it.** Found while filming the LifeOS brag video on the iPhone 18 Pro / iOS 27.0
      simulator against the emulator (`main @ 1cc1564`). In Capture Inbox, tap an area chip under
      *"WHERE DOES THIS LIVE?"* (e.g. 🫀 Health), then **Task it**. The **Make a task** sheet says
      *"The new task inherits this capture's life area, tags and notes."*, but the created task has
      **no `life_area_id`**, and the capture has no `lifeAreaId` either. **Cause, read, not yet
      red-checked:** `CaptureInboxSections.topCardActions` computes the staged area
      (`selectedArea(for:)` over `sortSelection`), but Task it only sets
      `promotingCapture = capture`. The staged choice is written only by **Sorted**, so the sheet
      reads the STORED capture's nil. Evidence: `brag-output/footage/B-sort.mp4` (outside the repo) and
      the task document `B8330A5F…` in the exported emulator state. **Not built. Needs a spec and a
      failing test first** (pass the staged area into the promote sheet, or persist it on chip tap).
      (NEW)

- [x] ~~**🐞 `F-FanXAtRest` — the × drops to its resting corner while the capture fan is open.**~~ **BUILT + MERGED 2026-09-17 (PR #147); ON THE PHONE at `4653433`; OWED: E's look incl. the RM-ON pass.** E's GIF
      and frame 19: in portrait any card pushes the disc (and so the ×) up, while the fan's tiles are
      anchored to the resting corner, so the × lands on a tile (TASK under the sprint bar, 9pt; TASK
      under a Confirm card, 7pt; LINK / PHOTO under the taller cards). E called it a bug and chose
      **shape B** over "move the arc up" and "render first". Reverses `F-FanCardsFade`'s "the × stays
      where the + was", including a UI journey assertion. RM-on device pass owed. **Spec:
      `TODO-CLAUDE-CODE.md`, last section.** (NEW, first)

- [x] ~~**`F-CollapsedBarLift` — the collapsed sprint bar stops dropping onto the tab bar, portrait AND
      landscape.**~~ **BUILT + MERGED 2026-09-17 (PR #148); ON THE PHONE; OWED: E's look (no RM pass owed).** E's answers: the collapsed bar (not the expanded card, which already has 33pt);
      *"Portrait too"* (reverses the 2026-09-09 flush drop); *"Line up with the Disc, But when there
      are multiple cards being displayed, then maintain the alignment."* Removing the visual `.offset`
      does all three by construction; the bottom keyline returns (it was removed only because the
      card sat on the bar). **Spec: `TODO-CLAUDE-CODE.md`, last section.** (NEW, second)

- [x] ~~**`F-FanHoldsCelebration` — a full-screen celebration waits while the capture fan is open.**~~ **BUILT + MERGED 2026-09-17 (PR #149), NARROWED BY E: only NEW requests wait; one already playing keeps playing. ON THE PHONE; OWED: E's look.**
      Frame 20: a sprint ended with the fan open and the celebration played over it. E: *"Wait until
      the fan closes."* The fan is a SwiftUI overlay that `-Surfaces`' UIKit probe cannot see, so
      `RootView` has to tell the centre. **Spec: `TODO-CLAUDE-CODE.md`, last section.** (NEW, third)

**E's pacing for the three above: back to back, no review stop between them, ONE install, ONE set of
looks** (the looks list is at the foot of the TODO section).

- [x] ~~**🐞 THE LANDSCAPE FAB OVERLAP — a REAL user-facing bug, found on device 2026-09-16.**~~
      **FIXED AND MERGED 2026-09-17 — `F-LandscapeFabOverlap`.** The hypothesis the last session
      recorded was right in kind and wrong in one word: the bottom stack does not overflow the
      landscape screen, it FILLS it — 372 (safe height) − 100 (lift) − 186 (away card) − 8 − 60 puts
      the disc's top at **18pt**, inside the header's gear well; the expanded sprint card alone
      (148) leaves 56, eight points clear, which is why neither landscape nor the card alone ever
      showed it. **Reproduced BEFORE a line was written**: `LandscapeAwayCardUITests` raises the
      away card through the app's own UserDefaults key (argument domain, no production seam) and
      failed at its landscape assertion on the unfixed tree with the portrait control passing;
      the simulator printed the same sum to the point (381 − 100 − 196.7 − 8 − 60 = 17.3).
      **The fix keeps E's stack byte for byte in portrait.** In compact height with anything up
      the cards take the column BESIDE the disc row (`RootBottomOverlayLayout.arrangement`); the
      container is a `Layout` whose arrangement is a property — a `switch` between a `VStack` and
      an `HStack` would have re-identified the timer bar and dismissed its detail sheet on
      rotation. RED 25 compile errors → GREEN 14 / 0 → red-check exactly the 3 predicted
      call-site failures plus the journey's landscape failure → restored → PASS on 26.5 light and
      27.0 dark. Evidence: `screenshots/landscape-fab-overlap/` (host-side `simctl` frames;
      `app.screenshot()` lies on a rotated sim). **Owed: E's device verdict on the side-by-side
      arrangement** — the card bottom-left, the disc in its corner — **— the build IS on the phone
      (installed after the close-out report).** No RM-on pass owed (no reduced site touched). **E's verdict
      2026-09-17: the arrangement stands, but the collapsed bar needs margin above the tab bar, which became
      `F-CollapsedBarLift` above.** (CLOSED as a bug; its follow-up is §B's second item)

- [x] ~~**🐞 NEW 2026-09-17 03:44 — THE SPRINT CARDS SIT ABOVE THE CAPTURE FAN, and in portrait the
      away card HIDES two of the five tiles.**~~ **FIXED AND MERGED — `F-FanCardsFade` (E's call:
      *"Fade the cards out while the fan's open"*, option A).** While the fan is open the whole
      cards column — away card, Confirm stack, timer bar — fades by opacity and drops out of
      hit-testing, keeping its layout so the disc (the fan's ×) stays where the + was; the
      reduced path is the same fade on `.default`. `RootBottomOverlayLayout.cardsPresence` is the
      rule; a call-site guard forbids gating the cards on an `if`. `FanOverAwayCardUITests`
      reproduced E's frame 12 (TASK and LINK inside the card's frame, un-hittable) on the unfixed
      tree and passes on the fixed one. **Deliberately NOT done: re-anchoring the fan's arc to the
      disc's real position** — moving the origin up with a pushed-up × risks the top tiles going off
      the top edge; the arc still leans out of the resting corner, which is where it always has.
      A separate question for E if that reads wrong once the cards are gone. **Owed: E's look on
      the phone with Reduce Motion OFF and then ON** (this block adds a reduced site — §7.3), and
      the verdict. **And the remainder the fade exposes, now concrete (frame 14): with the card
      pushing the disc up in portrait, the × sits ON the PHOTO tile** (centres 34pt apart) —
      the same overlap E's frame 8508 showed before the fade, because the arc leans out of the
      RESTING corner while the × is ~200pt higher. Two shapes for E: re-anchor the arc to the
      ×'s real centre (works with one card; with the away card AND a Confirm stack the top tile
      would clip off the top edge, so it needs a cap), or let the × drop to its corner while the
      fan is open (the cards are invisible then anyway; the × moves under the thumb as the fan
      opens, which is the cost). Not built; E's call.
      **WIDENED BY E's FRAME 19 (2026-09-17 05:44, phone): it is not PHOTO-specific.** With a
      running sprint's COLLAPSED bar up in portrait, the push is 68pt and the × covers **TASK**, the
      nearest and most-used tile (centres (339, 620) and (336, 611), 9pt apart). The tiles are 78pt
      apart, so any push lands the × within ~39pt of some tile. On the 15 Pro, by arithmetic: the
      expanded card (push 156) lands on LINK, and the away card (push 194) lands between PHOTO and
      LINK. **"Leave it" therefore means TASK is covered whenever a sprint bar is up in portrait.**
      Frame 20 adds two facts: when the sprint ENDED with the fan open, the × dropped 68pt to its
      corner on its own (shape B's cost, already live today), and **a celebration played over the
      open fan**. That is the code as written: `-Surfaces` holds behind sheets, alerts and pickers,
      and the fan is an overlay nothing reports. An observation for E, not a finding. Table and
      measurements: `screenshots/landscape-fab-overlap/README.md`, the 05:44 section.
      **E's GIF, 05:47 (`…/21-…gif`): E calls it a BUG** (*"the drifting FAB 'x' icon … when there is
      an unresolved notification such as a completed sprint"*). With the finished sprint's Confirm card
      up, the × sits at (339, 604), 84pt up and 7pt from TASK, and does not move while the fan opens.
      Landscape is clear. The cause is any card pushing the disc, not the notification: frame 19 showed
      the same with a running sprint's bar.
      **E's CALLS, 2026-09-17 ~06:00 — four answers, three of them new work:**
      - **The ×: shape B** — the × drops to its resting corner while the fan is open. TO BUILD.
      - **A celebration that fires while the fan is open WAITS until the fan closes.** TO BUILD.
      - **`F-FanCardsFade` PASSED ON DEVICE with Reduce Motion OFF and ON** (E: *"Right, Reduce Motion
        OFF and ON"*). Verified paths: full run on sim + E's phone (RM off); reduced run on sim
        (injected) + E's phone (RM on).
      - **Landscape: NOT passed as it stands.** E: *"it needs to have some margin space added BELOW the
        card bottom-left AND ABOVE the NAV tab menu bar."* Measured on E's frames: the expanded card
        already sits 33pt above the bar, and the COLLAPSED bar sits on it (~1pt, the flush drop). Asked
        which card, where and how much, E chose: **the collapsed bar; portrait TOO** (this REVERSES the
        2026-09-09 flush drop that `F-FocusCard-Corners` kept); **"Line up with the Disc, but when there
        are multiple cards being displayed, then maintain the alignment."** TO BUILD. Frame 08's observation (the pushed-up disc over the hero's *Start another
      session*) is unchanged and still only an observation. **The fade PASSED on device, Reduce Motion OFF
      and ON (2026-09-17). The × question was answered: shape B, which became `F-FanXAtRest` above.**
      (CLOSED; PASSED ON DEVICE)

- [x] ~~**The selected tab pill's left inset — RENDERED 2026-09-17, E's pick is the only thing
      outstanding.**~~ **E PICKED 12 — SHIPPED as `F-TabBarPillInset` (2026-09-17).** E: *"padding 12
      is the right choice for now."* `floatingPaddingHorizontal` 4 → 12, the second named §2 waiver
      beside `peekStep = 14` (off-grid, chosen from the real bar rendered at 4 / 8 / 12 / 16 with 8
      and 16 offered); SE floor 47.8 → 44.6, still clear; pinned by
      `testTheCardsInnerPaddingIsTheValueEChoseByLooking`; red-checked at 4 and at 16 with the
      predicted counts. Options + the shipped render: `screenshots/tabbar-pill-inset-options/`.
      **E's device verdict, 2026-09-17: PASSED** — *"regarding the pill at 12 - i think it looks
      perfect."* Nothing outstanding. (CLOSED; PASSED ON DEVICE)

~~**00. THE CTA CELEBRATIONS ARC — `F-CTACelebrations-6` is BUILT TO C5 ON A BRANCH.**~~
   **THE WHOLE ARC IS FINISHED — corrected 2026-09-13, and this entry was badly stale.** It still
   described `-6` as half-built on a branch and pointed at
   `handoff/START-HERE-cta-celebrations-6-part2.md`, which has been ARCHIVED for days; C6–C9, `-7`
   and `-Surfaces` have all landed and all passed on device since. Anyone following it would have
   gone looking for a branch that no longer exists.
   **Every block is merged:** `F-ConfirmCelebration-2` → `-1` → `-2` → `-3` → `-4` → `-5` → `-6`
   → `-7` (the chime) → `F-CTACelebrations-Surfaces`, plus `PopScale`, `NoCooldown`, `SwipeOrigin`.
   The design record — permanent, never archive — is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`. **Nothing in the arc is work any more**;
   what survives it is the three device looks in §A and the photosensitivity blocker in §D.
   (CLOSED)

~~**0b. Two surfaces question, raised by the HIG pass and NOT closed.**~~ **ANSWERED BY E,
   2026-09-13 — and it is now a BLOCK, not a question.** Offered "add Quick Capture only", "hold
   behind any unknown sheet", "accept it and close the item" or "defer and ask again", E chose
   **hold a full-screen celebration behind ANY unknown sheet**. Written up as
   **`F-CTACelebrations-Surfaces`** in `TODO-CLAUDE-CODE.md`. **BUILT AND MERGED 2026-09-13**
   (`a472f28`, PR #112). The design question it flagged was settled with E FIRST, as the spec
   demanded: two options put to them with catches, misses, cost and what keeps each honest, and E
   chose the UIKit probe. R-g applies unchanged in substance, and is now enforced by time rather
   than by a dismissal that an untracked sheet never sends. **Nothing is outstanding here but E's
   device pass.** (CLOSED as a question; CLOSED as a block bar the verdict)

**0c. The daily-goal announcement is an INTERRUPT, and nothing here has been checked on a real
   VoiceOver device.** `UIAccessibility.post(notification: .announcement,)` speaks over whatever
   VoiceOver is reading, and it can fire on any tab about a second after an unrelated action; a
   second accessibility notification landing in the same beat can coalesce one away. Neither effect
   is provable from source. Worth folding into the next VoiceOver pass rather than a block of its
   own. A 17+ attributed-string announcement API with a priority option may exist in the 26.5 SDK —
   unverified — which would make this a §7.1 register candidate. (NEW)

**0d. Follow-ups to the modern-iOS pilot — only what E asks for.** (carried)
   - **RM arrival fade for the bottom furniture**, only if E likes the cross-fade.
   - **The modern-API inventory, register-only until each is a block.**
     - **Re-sorted against the 18 floor (`F-Floor18`, 2026-09-24). Free at 18 — no gate needed:**
       `.contentTransition(.numericText(countsDown: true))` on the sprint countdown and ~20
       `.monospacedDigit()` counters; `.presentationBackground` on three sheets;
       `ContentUnavailableView` in four empty states; `.contentTransition(.symbolEffect(.replace))`;
       interactive widgets and routine Live Activity check-off; the `@Observable` migration (now 28
       classes); TipKit; `Tab`/`.tabBarMinimizeBehavior` (constrained by the custom `AppTabBar` —
       adoption means replacing it, not by the floor).
     - **Needs 26 (the only tier left that needs a gate):** `.glassEffect`, also constrained by
       `AppTabBar`.
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift`'s declared-but-unread `reduceMotion`.

1. ~~**E's one un-run device check: airplane mode + pull-to-refresh on Home.**~~ **RUN AND PASSED
   2026-09-13** — E: *"Airplane mode ON check has been run and was successful."* Home keeps the
   last-known task set rather than emptying it, which is what `F-HomeTasksLastKnown` (`8b5f740`)
   exists to do. **Nothing is outstanding here.** (CLOSED)

2. ~~**`F-FocusCard-Corners` — after the arc (E: "Round them").**~~ **BUILT AND MERGED 2026-09-13**
   (`598da3b`, PR #116). E chose **24pt, "match the top"** from a four-way render. Note for anyone
   reading the old line: the `animatableData` half is DONE and is currently **inert**, because
   E's radius equals the expanded one — the snap is gone because the difference is gone. That is
   recorded in the code rather than glossed. **Nothing outstanding but the device verdict** (§A).
   (CLOSED)

3. **`AppFeedback.hapticsEnabled()` and `.notificationSound()` have no test that calls them.** Two
   small tests, no production change. (carried)

4. **Two more dead design tokens, and two dead helpers.** `BarSurface` is defined, unit-tested and
   used by nothing; `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call
   sites and disagree about their input. (carried)
5. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops.** (carried)
6. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
7. **`F-Search-3-Journal`** — the recommendation is still to kill the block. **Its objection is BACK
   in a new form (2026-09-18, later).** E moved the pencil into the band left of the disc
   (`F-JournalPencilDisc`), so a Journal search row would have to share that band with it. Still E's
   call; not to be started unasked.
8. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **A nudge-specific screen animation for EVERY "Done for now".** E, 2026-09-11. (carried)
- **14- and 21-day streak milestones** (R-b): the arc fires at exactly 7. (carried)
- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of the focus-card arc explicitly. (carried)
- **`testRenderLandscapeSweep`'s fix** — E, 2026-09-18: **"Park it"**. The test fails at the Note tile on
  27.0, E's phone opens the composer there, so the TEST is at fault. The hypothesis (`app.textFields`
  missing a `TextField(axis: .vertical)` on iOS 27) is UNVERIFIED; the recipe is in the 63rd State.
  Only the render harness is affected, not the app. (NEW)

## C2 · Noticed, below the bar — **E asked explicitly that these be KEPT, 2026-09-13**

*E, verbatim: "Don't forget Your flagged points, So we can come back to them later." So nothing in
this section is dropped for age, and none of it may be quietly closed as stale. Each is something
this session or an earlier one noticed and judged below the bar for its own block — not something
that was tried and dismissed.*

- **Task Detail's Notes field is named only by its placeholder.** Found 2026-09-25 by `F-E2`'s
  `apple-design` review, which fixed the same shape on the new Next Step row beside it
  (`text-fields.md › Best practices`: a placeholder "disappears when people start typing", so "it
  can also be useful to include a separate label"). Once Notes holds text, nothing on screen says it
  is the notes. Below the bar because it is pre-existing and outside E2's scope; the fix is the Next
  Step row's own caption pattern (`TaskDetailFormSections.addMoreInfoSection`). (NEW)

- **A long area name ends in an ellipsis in the composer's compact Area tile.** Found 2026-09-24 by
  `F-D2`'s `apple-design` review. The keyboard bar's thirds are ~132pt (~123pt at xxxLarge), so a
  user-given name like "Relationships" shows as "Relatio…" even at the default size; fixed copy
  ("None", "15 min") was made to fit (layout priority + 0.8 scale). The full name is in the menu and
  is the tile's VoiceOver value. Below the bar because it is user content in a width E approved;
  the fix, if wanted, is a design call (a two-line value, or the stacked form earlier). (NEW)

- **The task composer's WARNING is never on screen long enough to read.** Found 2026-09-23 by
  `F-D1-ComposerBothDoors`'s `apple-design` review (`feedback.md`: feedback belongs in the
  interface). When the create succeeds and the follow-up Time write fails,
  `TaskCreateService` sets *"Task created, but couldn't save its time."* and returns `true`, but
  the composer dismisses on `true` in the same tick. **Not new:** the deleted tag-attach warning
  had exactly this shape since v3. It is below the bar because the task exists and its time can be
  set on detail. The natural home, once E wants it, is the undo capsule (one bottom bar for
  everything, round 2). (NEW)

- **Apple published "Designing for iPhone Duo" on 2026-09-09 — a two-display iPhone whose system
  puts tab bars and toolbars on the SIDE, vertically.** Found 2026-09-19 by the `apple-design`
  freshness check (§7.6). The custom `AppTabBar` is drawn by the app, so it will not move there on
  its own, and the page also stresses layouts that adapt across the hinge and device poses. Nothing
  in this repo mentioned the device before. Not work until E says so: a candidate beside register
  §B's modern-API inventory, and a public-launch question. (NEW)

- **A fully-ticked routine that is never confirmed will be recorded as `dayEnded`, not
  `completed`.** Found while planning `-6`. An arrival run stays live until **end of day**
  (`RoutineRun.swift:96-102`) and `RoutineRunReconciliation` then stamps `.dayEnded` /
  `.windowLapsed` (`:40-42`), so R1's *"Completed can be tapped later"* has a deadline: midnight.
  Tick every step, swipe away, come back tomorrow — the Journal shows a lapsed run. **This is
  exactly what E asked for** (*"nothing is recorded as completed without the tap"*), so it is
  intended rather than a defect, but E has not seen it stated. (NEW)
- **A shared constant reaches more sites than the block that changes it.** The swipe's pop went
  off-screen because `PopScale` moved a throw distance that a DIFFERENT block had built an origin
  decision around. Fixed in `F-CTACelebrations-SwipeOrigin`, but the shape recurs: the next time a
  celebration constant moves, re-read every site that constant reaches rather than trusting the
  suite. (NEW)
- **The daily goal is the one celebration the user did not just cause with their thumb.** Raised by
  the HIG pass. Inbox zero and the streak both fire from a tap, so a wash starting under the thumb
  is no surprise; the daily goal can land about a second after ANY action, anywhere — including
  while typing in a task's notes. Hit-testing passes through, so nothing is blocked, but it is a
  real cost of E's "any tab" design (F7) rather than a defect. Worth naming at the device sitting.
  (NEW)
- **Eight of the ten pop sites are OPTIMISTIC** — they pop before the work is known to have
  succeeded. Each fires in the same closure and at the same instant as the haptic that was already
  there. The one worth a second look is **Sorted from the triage card**, where the
  `await service.sort(...)` genuinely can return false. **The three milestones are NOT optimistic**
  — each is asked for only after its write landed, which is why a failed sort celebrates nothing.
  (updated)
- **The promote sheet's celebration layer is sized to the SHEET, not the screen**, so the Create
  Task pop clips at the sheet's top edge. By design, and visible for 0.45 s (R-e). (carried)
- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it.** A REDUCED-path effect, so E's passing verdicts did not see it.
  **The RM-on pass this sitting owes is the natural moment to look.** (carried)
- **The Feedback section's footer is a thirteen-line paragraph** covering six switches. (carried)
- **The Tasks tab's large title NEVER collapses**, so it permanently costs about 52pt of viewing
  space. Measured in Step 0's rig: the bar stays at 106pt with the list scrolled 420pt. The cause is
  that `TaskListView`'s `ScrollView` sits under the count line and filter row inside a `VStack`, so
  UIKit never links it to the bar. This is the same species of complaint E made about the Journal's
  bar (*"reduces viewing space"*). Noticed; not work until E says so. (NEW 2026-09-18)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **Minimum iOS is 18 (`F-Floor18`, E's call 2026-09-23, built 2026-09-24).** App Store
  consequence: **iPhone 8, 8 Plus and X can no longer install** — they stop at iOS 16. Every device
  that runs 17 also runs 18 (iPhone XS/XR and newer), so 17 would have excluded exactly the same
  hardware. The app is not public, so no current user is stranded; the cost is future reach alone.
  Nothing else to do before launch; the App Store listing will show "Requires iOS 18.0 or later". (NEW)
- **Photosensitivity: the stack-clearing Confirm's fireworks flash 5 times in one second** against
  WCAG 2.3.1's 3. **E POSTPONED the decision on 2026-09-13 and asked in the same breath that it come
  back before launch** — verbatim: *"Can we postpone this decision for later date? But we must come
  back to this before shipping to the public."* So it sits here by E's own instruction rather than
  by anyone's judgement, and **it may not be closed without E**. Full detail, and what is and is not
  claimed, in §A. The finding does not extend to the pops or the milestones. (DEFERRED BY E)

**From the monetisation audit of 2026-09-22 (read-only; source and reasoning in
`../MONETISATION AUDIT/01_FULL_CAPABILITY_AND_TECH_AUDIT.md` §2.3 and
`02_MONETIZATION_OFFERS_PRODUCTS_AND_SERVICES.md` offer 5). In dependency order after the paid
account above. None is a FEATURE block yet; each becomes one only when E opens the launch
conversation.**

- **`PrivacyInfo.xcprivacy` is ABSENT** — 35 app files use `UserDefaults` (a required-reason API)
  and the Firebase SDKs need declared reasons. **A hard App Store Connect upload rejection**, not
  a warning. (NEW, 2026-09-22)
- **Privacy policy and terms URLs are ABSENT** — required App Store Connect fields; `AboutInfo`
  ships version and build only. A free GitHub Pages site is enough. (NEW)
- **`dailySummary` has no per-user quota, rate limit or cost cap** — one `claude-opus-5` call per
  request. ~$2–3 per engaged user per month at one summary a day, against ~£2.83 net from a £3.99
  UK subscription. **The cap is a blocker regardless of model; the model and frequency are E's
  pricing decision** (Sonnet 5 ≈ $1.2/user/month, Haiku 4.5 ≈ $0.6), never a silent downgrade. (NEW)
- **iPad is declared but not designed** — `TARGETED_DEVICE_FAMILY = "1,2"` on every target, yet
  every record and every screenshot folder is iPhone-only. Either design for iPad or set the family
  to `"1"` before the first upload, or review will run it on iPad and want iPad screenshots. (NEW)
- **The `capture` Cloud Function is single-tenant by construction** — a fixed `CAPTURE_UID` and one
  shared secret, documented as "a single-user personal app". Per-user keys or ID tokens before a
  second user can use the Shortcut. (NEW)
- **StoreKit does not exist** — no products, no paywall, no tier boundary; no feature has ever been
  designed as free-vs-paid. A `SubscriptionStatus` seam in the `*BackingStore` pattern is the shape.
  (NEW)
- **No onboarding flow** — the public-launch lens names first-run states and permission ladders as
  non-negotiable; only the Nudges first-run card exists. (NEW)
- **No analytics or crash reporting** — Auth, Firestore and Storage are the only linked Firebase
  products; no activation, retention or funnel data can be collected today, so there is no basis
  for pricing or conversion measurement. TelemetryDeck-class, privacy-preserving. (NEW)
- Also noted, below the bar: `LSApplicationQueriesSchemes` is at 45 of the 50 Apple allows; the
  app directory is five schemes from a hard ceiling. (NEW, noise until it bites)


## E · Known, not work

- **`MILESTONE_PROBE_OUT` passed on the `xcodebuild` command line does NOT reach the test process.**
  It is taken as a build setting, and the probe falls back to `NSTemporaryDirectory()` — the
  simulator's own app-container `tmp`. Not a failure: the probe prints the path it actually wrote
  to, and the files are copied out afterwards. **Read the printed path rather than assuming the
  environment variable landed.** (NEW)
- **The `xcode` MCP bridge was NOT USED this session**, as the opener instructed; the
  run-loop-pumping probe did everything needed. (carried)
- **A stale `TestResults.xcresult` fails the whole suite before a test runs.** Gitignored, so it
  survives everything; delete it as part of the run. It was present at session start again.
  (carried)
- **A green suite cannot see a `View`'s appearance, a TIMING WINDOW, or a COORDINATE.** This block
  added the third: the fallback pop's origin was correct, its request was correct, and it was drawn
  faithfully at a point 10,000 pt off screen. Render, render the CONTROL, and prove the harness
  deterministic before any pixel claim — then ask what the numbers in the picture MEAN. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  both, and treat a MISS as a possible defect in the guards rather than a bad forecast — this
  session's two misses were exactly that. (carried)
- **SwiftLint's ceilings bite in two places now.** The 400-line FILE ceiling
  (`CaptureInboxService.swift` 397 → 355 this block; `PlaceRoutineScreen.swift` 384 is next), and
  the 250-line TYPE BODY ceiling, which `CelebrationCenterTests` crossed — split to
  `CelebrationCenterHeldBurstTests` on the `CaptureInboxTriageServiceTests` precedent. (updated)
- **Moving an extension to a new file ends same-file `private` access.** `replaceCapture` could not
  follow its two callers out of `CaptureInboxService.swift` — it writes `state`, whose
  `private(set)` setter keeps every writer in the type's own file — so it was relaxed to internal
  instead. (updated)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). No UI target was run this session.
  (carried)
