# Arc D review — the composer, and the Anytime row

*Written 2026-09-24 at the arc-D close, under E's per-arc bypass (CLAUDE.md › "Per-arc bypass"):
the arc's three blocks were built back to back, each fully gated, and this is the ONE phone pass
that reviews them together. **The build on E's phone is `main` @ `<SHA — filled at install>`**,
installed and launched BEFORE this page was sent (memory `ask-for-device-checks-on-a-build-e-has`).
Force-quit the app once before starting (memory `relaunch-before-judging-device`).*

**Reduce Motion: leave it OFF for the whole pass.** No block in arc D adds or changes a reduced
site — D1 and D2 have none (the composer's selection recolours in place), and D3's fold has no
motion at all (a static chevron; `grep` finds no animation, transition or `#available` in any file
it touched). So **no RM-on pass is owed**, and you do not need to flip the setting.

---

## 1 · `F-D1-ComposerBothDoors` — one composer, every door

1. **Tasks tab → "+"** opens the composer: a title, the four "when" segments, Area and Time.
2. **Today → a life area → "Add to <area>"** opens the SAME composer, with that area already chosen.
3. **The capture disc → Task** opens the same composer again.
4. Tags, place and notes are NOT in the composer — they live on the task once it exists.

**Verdict D1:** ______

## 2 · `F-D2-ComposerKeyboardLayout` — L3 rides the keyboard ("Let it settle", "Keep the panel")

Use either door from §1.

5. **Type a title** → the bar (the four segments over Area | Time | Add) rides directly on the
   keyboard, in one Liquid Glass panel.
6. **Tap Area** → the keyboard goes down and the bar settles at the bottom of the screen. *This is
   your "Let it settle" — nothing brings the keyboard back by itself.* Choose an area.
7. **Tap Time, then Date** → the bar stays where it settled (no jump).
8. **Tap the title again** → the keyboard comes up and the bar rides it again.
9. **Date** reads "Date" (no glyph) → tap it → a whole calendar (the full month, Next Month on
   screen) → pick a day → the segment now reads that day (e.g. "Sat 10") and is lit as the choice.
10. **Settings › Accessibility › Display & Text Size › Larger Text → the AX3 size** (third notch of
    the accessibility sizes) → open the composer → the STACKED form: the title in a box, the
    segments one above the next, Area and Time full width, Add pinned alone. **Set the size back
    afterwards.**

**Verdict D2:** ______

## 3 · `F-D3-TasksAnytimeRow` — "Anytime · N" at the bottom of Momentum

11. **Tasks tab, Momentum filter** (the default) → scroll to the bottom → a quiet
    **"ANYTIME · N"** row with a small ▲ chevron, and NO task rows under it. N is how many of your
    open tasks have no date. (Before this block those tasks were only under "Open".)
12. **Add a task with no date** ("Not yet") → back on Momentum the count reads **N + 1**, and the
    row stays folded — round 6: *"the tail stays folded, but a new task is visible where it was
    added."*
13. **Tap the Anytime row** → it opens (chevron ▼) and lists your undated tasks, the new one among
    them. **No ▶ sprint button on these rows** — the ▶ stays on Due today only.
14. **With the row open, scroll so the rows pass under the Anytime header** (easier at a larger text size) → the header stays pinned and the rows do
    not show through it.
15. **Force-quit and reopen** → the row is as you left it (open stays open; folded stays folded).
16. **A task due next week** is still NOT on Momentum (round 8b: *"future-dated tasks are
    untouched"*) — only under Open.

**Verdict D3:** ______

---

*Frames for §3: `screenshots/tasks-anytime-row/`. For §2: `screenshots/composer-l3-layout/`.
For §1: `screenshots/composer-both-doors/`.*
