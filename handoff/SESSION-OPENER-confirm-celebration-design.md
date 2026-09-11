# Design record — the Confirm celebration (confetti, fireworks, glow, dim)

*This is the design record and the why. It is PERMANENT — never archive it (CLAUDE.md, "Session
handoff": `SESSION-OPENER-*` files are records despite the name). Written 2026-09-11 from E's
answers in chat and the throwaway prototype renders E chose from
(`screenshots/confirm-celebration-prototypes/`). The arc is `F-ConfirmCelebration-1` and
`F-ConfirmCelebration-2`. **Reviewed by E the same day: R1, R2 and R9 approved (see
"Claude Code's recommendations"). **Block 1 (`F-ConfirmCelebration-1`) was built and landed the same
day, PR #69, and is awaiting E's device verdict; block 2 is not started.** Build status lives in
`OPEN-ITEMS-REGISTER.md`; this record stays the design.***

**Everything in "The settled specification" was answered directly by E. Do not re-litigate any of
it without E.** Where a line says E chose, E was shown the alternatives — as text options or as
rendered video — and picked. **"Claude Code's recommendations" are NOT E's decisions yet**; they
are in this record so E can accept or change them in review, and they are marked as such.

---

## What prompted it

E, in the session that landed `F-ModernIOS-2-Celebration` (2026-09-11), verbatim:

> *"And, also, on the notification card that displays above the nav tab menu bar, when the user
> taps "Confirm" on a completed sprint/notification card. There needs to be an animation that can
> use up to the full-screen if so, Possibly confetti?"*

The "notification card" is the focus-sprint completion card (`FocusCompletionCard`, in the
`FocusCompletionCardStack` above the tab bar). Today its Confirm dismisses the card and finalises
the record, and nothing celebrates: the in-ring celebration and the success haptic both belong to
the moment the sprint FINISHES, not to the Confirm.

## The settled specification

### E's answers, in the order they were given

The options are quoted from the chat as E saw them; "(rec.)" marks the one Claude Code recommended.
**Four of E's eight answers overruled a recommendation** (#1, #3, #4, and #5 by combining), which is
why the recommendations are recorded at all: they are not the design.

| # | the question E was asked | E's answer, verbatim | what E was looking at |
|---|---|---|---|
| 1 | "Your phone runs Reduce Motion ON, so falling confetti would never play for you … What should Confirm show with Reduce Motion ON?" A — Still confetti that fades (rec.) / B — A full-screen glow / C — Real falling confetti even with Reduce Motion ON ("I'd record that as a deliberate waiver, like `peekStep`") | **"B AND C"** | text options |
| 2 | "When should the confetti fire?" A — On every Confirm (rec.) / B — Only when the last card is confirmed / C — Every Confirm, with a bigger burst when the stack empties | **"C"** | text options |
| 3 | "Should Confirm also buzz?" A — A light tap on every Confirm, and a success buzz on the stack-emptying one (rec.) / B — The success buzz on every Confirm / C — No haptic on Confirm | **"B"** | text options |
| 4 | "Should there be a way to turn it off?" A — A "Celebrations" switch in Settings, on by default (rec.) / B — No switch. Confetti for everyone, always / C — No switch for now, recorded as a pre-launch item | **"C"** | text options |
| 5 | "Which one?" A · Burst from Confirm / B · Rain from the top / C · Corner cannons — "or a mix" | **"B but also C"** | `00-` / `01-`: the three styles side by side over the real card, 4 s each at real speed |
| 6 | *(unprompted — arrived at 08:04 BST while the #5 combination was being rendered)* | **"for the stack-clearing burst can you incorporate a firework animation?"** | — |
| 7 | "Is this the direction?" A — Yes / B — Yes, with changes / C — Not quite | **"B - more fireworks on the ‘Stack Cleared’ and incorporate MORE and OTHER COLOURED fireworks.<br>and possibly, for light-mode display views, a background dim for the duration of the fireworks could look good"** | `10-` / `11-`: every Confirm (rain + cannons), and the stack-clearing Confirm with 5 fireworks, light and dark |
| 8 | "Which light-mode treatment for the stack-clearing Confirm?" A — Dim 85% (rec.) / B — Dim 55% / C — No dim | **"A"** | `20-` / `21-`: 14 fireworks — light no dim / light 55% / light 85% / dark |

### What that adds up to

**Every Confirm:**
- **the success haptic** (#3);
- **confetti across the full screen from TWO sources at once** — raining from the top edge AND
  fired from both bottom corners (#5);
- **a done-green glow** swelling from the bottom of the screen and fading (#1);
- the card's own dismissal, exactly as today.

**The Confirm that empties the stack** (no card left behind it) gets all of that, **plus fireworks
(#6) — many, in many colours (#7) — and in LIGHT appearance the whole screen dims to 85% while they
play (#7, #8).** Dark appearance does not dim. **The fireworks ARE #2's "bigger burst"**: the
confetti itself is identical on both kinds of Confirm.

**Reduce Motion does not change any of it (#1).** This is a deliberate, named **waiver of
CLAUDE.md §7.2** for this one moment, E's call, in the same way `peekStep = 14` is a waiver of §2.
Reduce Motion OFF is identical, because there is nothing left to reduce.

**There is no off switch (#4)** — recorded as a pre-launch item in `OPEN-ITEMS-REGISTER.md` §D,
because people who turned Reduce Motion on for motion sensitivity will get full-screen falling
confetti with no escape.

### Two readings, and where E answered them

"B but also C" (#5) could have meant rain normally with cannons added for the stack-clearing
Confirm. And "bigger when the stack empties" (#2) could have meant more confetti. **Both readings
were put to E in words, in the message #7 answered**, verbatim:

> *"The combination: I took your "B but also C" as rain from the top and both corner cannons firing
> together on every Confirm. With fireworks now the thing that makes the stack-clearing Confirm
> bigger, the confetti itself is the same on both."*

E answered **"B" — "Yes, with changes"** — and the changes named were the fireworks and the dim
only. So both are answered, not inferred.

---

## Claude Code's recommendations — and E's review of them

**E reviewed this record on 2026-09-11 (PR #67) and answered, verbatim: "R1, R2, R9 (a+b) =
Approved."** "(a+b)" is both of R9's blocks.
- **R1, R2 and R9 are E's decisions now.** Treat them like the settled specification.
- **R3–R8 were not mentioned.** They stand as the build's DEFAULTS, not as E's decisions. The build
  takes them as written, and E can change any of them at a device verdict without that counting as
  re-litigating.

Each item below was the default the build would take.

- **R1 · APPROVED by E · Rapid Confirms overlap, capped.** "Every Confirm fires it" means two Confirms 1s apart
  would each start a celebration. Recommendation: they **overlap** (each is its own instance, keyed
  by start time), **capped at 3** live instances with the oldest dropped. Restarting instead would
  cut the first celebration off mid-air, which reads as a glitch.
- **R2 · APPROVED by E · The trigger is a NEW service stamp, by analogy with `latestConfirmableCompletion`.**
  `confirmCompletion` writes `latestConfirmation = FocusConfirmation(ordinal:clearedStack:)`:
  - **it is a second stamp, never the existing one.** `latestConfirmableCompletion` keys the
    completion haptic and the in-ring burst, and its comment in `+Completions.swift` records that
    Confirm must leave it alone ("a revealed card must not re-celebrate"). Reusing it would break
    both;
  - it is written only when the record was actually in the stack, so a stray second call cannot
    celebrate twice;
  - `clearedStack` is `unconfirmedCompletions.isEmpty` straight after the removal;
  - it is written synchronously, beside the removal and before the `await log`, so the celebration
    never waits on Firestore (the same reason the dismissal happens first);
  - **only Confirm writes it.** Push, restore and a relaunch never do, so a relaunch never replays
    one;
  - it is never persisted.
- **R3 · A full-screen layer in `RootView`:** one more `.overlay` on the tab content, applied after
  `RootBottomOverlay`'s (`RootView.swift:249`) and before the `.fullScreenCover`s. So it draws above
  the tab content, the tab bar, the capture disc and the card, and every sheet and cover still
  presents above it. It is `.allowsHitTesting(false)`, `.ignoresSafeArea()` and
  `.accessibilityHidden(true)`, so it can never block a tap or be read out.
- **R4 · The Confirm haptic lives on `RootBottomOverlay`,** beside the completion haptic, keyed on
  the stamp's ordinal: `.haptic(.success, trigger: …)`. It never goes on the card or the stack
  (`testTheHapticListenerOutlivesTheStack` already bans that, for the reason recorded there).
- **R5 · Each celebration is seeded from the confirmation ordinal,** so no two look identical. The
  prototype used fixed seeds.
- **R6 · The glow shows in both appearances; only the dim is light-only.**
- **R7 · The card's dismissal is unchanged.** The celebration starts on the same Confirm, and the
  card leaves on the overlay's existing animation.
- **R8 · No VoiceOver announcement.** The layer is hidden; the card's removal and the haptic are
  the feedback, as they are today.
- **R9 · APPROVED by E, both blocks · Two blocks,** each closing on E's device verdict (below).

---

## The numbers — the prototype, reproducible

These are the values the renders E chose from were made with, read back out of the prototype's
source rather than from memory. Colours are **asset-catalog token names only** (§4, and the
`raw_hue_color` lint rule). The hex values beside them are each token's LIGHT-appearance value, for
reading, never for code; every token has its own dark variant.

### Confetti — one closed-form model, a pure function of time

Each particle's position at time `t` after its own delay is drag-damped ballistic motion:

```
x(t) = x₀ + vₓ/k · (1 − e^(−k·t)) + flutter(t)
y(t) = y₀ + (v_y − g/k)/k · (1 − e^(−k·t)) + (g/k)·t        (y grows downward)
```

| constant | value |
|---|---|
| gravity `g` | 520 pt/s² |
| linear drag `k` | 2.2 /s |
| fade-out | opacity 1 → 0 over the last 0.7 s of each particle's life |
| shape mix | 75% rectangles 7–10 × 4–6 pt; 25% circles 6 pt |
| rotation | start 0–2π; spin −9…+9 rad/s |
| tumble | x-scale `|cos(ω·t + φ)|`, floored at 0.15, ω 4–11 rad/s |
| flutter | ±6–18 pt sideways at 3–6 rad/s, easing in over the first 0.6 s |
| colours | round-robin over 7 tokens: `AreaWorkVivid` (#0A84FF), `AreaHealthVivid` (#00B6DD), `AreaGrowthVivid` (#C04DF7), `AreaHobbyVivid` (#FF2D55), `AreaOrangeVivid` (#E8720C), `StateGoVivid` (#1ED15F), `StateWarnVivid` (#FFA000) |

**Every Confirm's recipe — 220 pieces:**

| source | count | origin | launch velocity | delay | life |
|---|---|---|---|---|---|
| rain | 120 | x −10 … W+10, y −80 … −10 | vₓ −60…+60, v_y +420…+720 pt/s | 0–0.6 s | 3.0–3.6 s |
| cannons | 100, alternating corners | (−4 or W+4, 0.86 H) | 1100–1900 pt/s at 52°–78° above horizontal, aimed inward | 0–0.12 s | 2.8–3.5 s |

### Fireworks — the stack-clearing Confirm only

**14 shells over 2.6 s, in 9 token colours.** They use the seven confetti tokens plus
`AreaAdminVivid` (#FFC400) and `AreaRedVivid` (#C94057). `AreaSlateVivid` is excluded (grey), and
so is `StateRisk` (it means risk).

| # | launch (s) | apex x (×W) | apex y (×H) | burst | colours | size |
|---|---|---|---|---|---|---|
| 1 | 0.05 | 0.28 | 0.30 | single | StateWarnVivid | big |
| 2 | 0.30 | 0.72 | 0.22 | two-tone | AreaGrowthVivid / AreaHealthVivid | big |
| 3 | 0.55 | 0.50 | 0.40 | ring-in-ring | AreaHobbyVivid / AreaAdminVivid | big |
| 4 | 0.80 | 0.18 | 0.18 | single | AreaWorkVivid | medium |
| 5 | 0.95 | 0.84 | 0.36 | two-tone | StateGoVivid / AreaAdminVivid | medium |
| 6 | 1.20 | 0.40 | 0.16 | ring-in-ring | AreaOrangeVivid / AreaHealthVivid | big |
| 7 | 1.40 | 0.64 | 0.46 | single | AreaGrowthVivid | small |
| 8 | 1.55 | 0.26 | 0.50 | two-tone | AreaRedVivid / StateWarnVivid | small |
| 9 | 1.75 | 0.78 | 0.14 | single | AreaHealthVivid | big |
| 10 | 1.95 | 0.50 | 0.28 | two-tone | AreaHobbyVivid / AreaWorkVivid | big |
| 11 | 2.20 | 0.15 | 0.34 | ring-in-ring | StateGoVivid / AreaGrowthVivid | medium |
| 12 | 2.35 | 0.86 | 0.26 | single | AreaAdminVivid | medium |
| 13 | 2.55 | 0.36 | 0.22 | two-tone | AreaOrangeVivid / AreaGrowthVivid | big (finale) |
| 14 | 2.60 | 0.66 | 0.24 | ring-in-ring | StateWarnVivid / AreaHobbyVivid | big (finale) |

| element | value |
|---|---|
| shell launch point | (apex x + 0.02) × W, 0.96 × H |
| shell rise | 0.55 + 0.25 × (1 − apex y) s, eased `1 − (1 − u)²` |
| shell drawing | 5 pt head in its first colour + 2.5 pt round-capped trail over its last 0.08 s at 55% opacity |
| size classes | big 72 sparks / 400 pt/s / 1.45 s · medium 56 / 310 / 1.3 · small 40 / 220 / 1.1 |
| spark speed | class speed × (0.8 + 0.2 × a per-spark hash); ring-in-ring: half the sparks at 0.55× speed, inner ring offset by half a step, in the second colour |
| two-tone | sparks alternate the two colours |
| spark physics | the confetti model with drag 2.4 /s and gravity 150 pt/s² |
| spark drawing | 2.4 pt round-capped stroke from the spark's position 0.07 s earlier; opacity `(1 − τ/life)^1.4` |
| burst flash | radial gradient in the first colour, radius 40 → 240 pt and alpha 0.35 → 0 over 0.35 s |
| last spark | 4.79 s after Confirm |

### Glow — every Confirm, both appearances

A fixed `RadialGradient` of `StateGo`, opacity 0.32 at the centre to 0 at the rim, centred on the
bottom edge, with a 760 pt radius. Only its overall opacity moves: in over 0–0.3 s, held to 0.9 s,
out by 2.4 s.

### Dim — the stack-clearing Confirm, light appearance only

`Color("Scrim").opacity(0.85)`, and `Scrim` in light is #08080E at α 0.8, so ≈ 68% black. Envelope:
in over 0.35 s, held until 0.4 s before the last spark (≈ 4.39 s), out over 0.6 s (gone ≈ 4.99 s).

### Order and length

Drawn back to front: **app → dim → glow → fireworks → confetti.** An every-Confirm celebration
lasts ≈ **4.2 s** (the last rain piece); a stack-clearing one ≈ **5.0 s** (the dim's fade).

---

## Engineering constraints — so the build cannot trip on them

- **Two files the build must touch are already at their length ceiling (400 lines). Make the room
  FIRST in block 1, as its own commit, rather than discovering it at lint.**
  - **`FocusSessionService.swift` is at 394.** The stamp is a stored `@Published` property, and a
    stored property cannot live in an extension, so it has to go in this file. The room comes from
    moving METHODS out into an extension file. That is the arrangement `+Completions` and
    `+Persistence` already exist for: "in its own file so `FocusSessionService` stays inside its
    length budget".
  - **`RootView.swift` is at 399.** The overlay is a few lines, so the same move applies: code out
    into a `RootView+…` extension file, the `RootView+Doors` / `RootView+Reselect` precedent. (The
    service's own comment records that `RootView` "is at 399 of 400 lines" as a constraint that
    has shaped earlier decisions.)
- **A single-implementation site under §7.1.** `Canvas` and `TimelineView(.animation)` are iOS 15+,
  so there is no `#available` at all. The block report's §7.1 line is "no tier adds value":
  - `MeshGradient` (18) would draw a glow the radial gradient already draws;
  - `.visualEffect` (17) and `.glassEffect` (26) have nothing to act on in a particle field.
- **The §7.2 waiver goes INTO CLAUDE.md §7.2 when block 1 ships,** with a pinning call-site test
  (the celebration layer's files never read `accessibilityReduceMotion`), exactly as `peekStep`'s
  waiver sits in §2 with `testThePeekStepIsTheValueEChoseByLooking`. A later Reduce Motion sweep
  must not quietly restore a fade.
- **The engine is a pure function of time.** Particle and firework state at `t` is computed, never
  accumulated frame to frame. Production drives it with `TimelineView(.animation)` from a start
  date; tests and render probes inject `t` directly. This is what makes the physics unit-testable
  and every frame renderable on demand. `CAEmitterLayer` could offer neither.
- **Performance is unmeasured.** The prototype rendered offline, not in real time. The bound for
  one stack-clearing celebration is 220 confetti fills and 880 spark strokes (8 big shells × 72,
  4 medium × 56, 2 small × 40), plus 14 shells and 14 flashes. That is at most ~1,130 draw
  operations per frame. Staggered launches and 1.1–1.45 s spark lives keep the real figure well
  under it, but it is the figure to plan for, and R1's cap of 3 bounds the overlap case at three
  times it. **E's device is the measurement**; the lever is one particle-count scale on the
  recipes.
- **File sizes.** Split by concern (the model, the recipes, the layer), each well under 400 lines
  and 250-line type bodies.

## The blocks — strictly sequential, E reviews each on device

### F-ConfirmCelebration-1 — the engine, the trigger, and every Confirm's confetti + glow + haptic

- **Pure model tests, first:**
  - a particle is at its origin at `t = 0`;
  - gravity pulls it down over time;
  - drag bounds its horizontal travel below `vₓ / k`;
  - no position before its delay or after its life;
  - the same seed gives the same particles, and different ordinals give different ones.
- **Recipe tests:** 120 + 100 pieces; every colour name resolves in the asset catalog (the test
  host is the app).
- **Service stamp tests:**
  - confirming the last card stamps `clearedStack = true`;
  - a card with one behind it stamps `false`;
  - the ordinal advances;
  - confirming a record that is not in the stack writes no stamp;
  - push and restore never write the stamp, and Confirm still never writes
    `latestConfirmableCompletion`;
  - it is never persisted.
- **Call-site tests:** the layer is hosted in `RootView` with `.allowsHitTesting(false)`; the
  Confirm haptic sits on the overlay keyed on the stamp; **the waiver pin**.
- **CLAUDE.md §7.2** gains the waiver.
- **Evidence:** in-situ renders, and the device verdict (with Reduce Motion ON, which is E's
  setting, and which the waiver makes identical to OFF).

### F-ConfirmCelebration-2 — the stack-clearing fireworks and the light-mode dim

- **Pure model tests:** shell rise and apex timing; spark count per size class; ring-in-ring inner
  speed; the two-tone alternation.
- **Schedule tests:** 14 shells, 9 distinct tokens, every one resolving.
- **Dim tests:** the envelope in pure form; light-only; its end tied to the last spark.
- **Call-site test:** fireworks and dim play only when `clearedStack` is true.
- **Evidence:** in-situ renders, light and dark, and the device verdict.

Whether a fresh session builds these is E's call; the default is to continue in the session E is
talking to.

## Verification bar, per block

The standard bar:
- `swiftlint lint`: 0;
- the full unit suite with the emulator up and 0 `127.0.0.1:9099` hits, the count matching a
  written prediction;
- the sim build;
- red-checks on a committed tree;
- the PR and the four-line close-out;
- the phone installed from `main`.

The **Verified paths** line (§7.3) reads, for a single-implementation site: *runs the same code on
every OS ≥ 16.0; run on the 26.5 simulator and on E's phone; its behaviour on a 16–25 OS is
COMPILE-ONLY — no older runtime installed.* Evidence goes in `screenshots/`, with the mandatory
README.
