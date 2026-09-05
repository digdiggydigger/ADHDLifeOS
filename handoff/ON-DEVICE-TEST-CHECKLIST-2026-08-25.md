# On-device test checklist — 2026-08-25 build (`1373a76`)

Everything below is what the unit suite CANNOT prove — view behaviour, widgets, deep links,
haptics, sound. Work top to bottom; anything that feels off becomes a review note.

## 1. Home Screen widgets (needs one app-open first)
- [ ] Open the app once, then add both widgets: long-press Home Screen → + → Momentum.
- [ ] **Life Areas widget**: shows your areas (emoji, name, open counts) in their hues, max 6.
- [ ] Change an area's COLOUR in Settings → Life Areas → area → Colour → Save. Widget follows
      after the app republishes (open Today, pull to refresh, background the app).
- [ ] Tap the Life Areas widget → app opens ON THE AREAS TAB.
- [ ] **Quick Capture widget**: five discs. Tap each one — the composer must open with THAT
      type preselected (Task, Note, Voice, Photo, Link). Cold-launch too (kill app first).
## 2. Today
- [ ] Inbox card: 📥 header, count chip, three newest captures, "and N more" when >3.
- [ ] Tap a peek ROW → that capture's detail opens. Promote it → back → card no longer lists it
      and "N handled today" (green) ticks up.
- [ ] "Clear the deck" → triage screen. Empty inbox → card stays with quiet copy, no CTA.
## 3. Capture inbox
- [ ] Tag chips under the decision card and the "Then" rows (tags you attached at capture).
## 4. Journal
- [ ] One scroll direction: newest at top INSIDE each day too; no time zigzag at day breaks.
- [ ] No wrapped times in the gutter ("12:19 a/m" bug is dead).
- [ ] Sprints show "N min sprint" / "N of M min sprint"; sub-minute false starts are GONE.
- [ ] Day header says "Today · N min focused" on sprint days; eyebrow counts sprints.
- [ ] Tap rows: closed task → task detail; sprint → its task; capture → capture detail.
- [ ] Filters: Sprints / Captured chips isolate their kinds.
- [ ] Composer (top-right pencil): Log/Journal chips with explainers, TAGS section (pick +
      create); saved entry shows its tag chips on the timeline row. (Tags are create-only.)
- [ ] Capture disc no longer covers the "One line about today…" bar.
## 5. Composers (Tasks tab "+")
- [ ] S1 style: big title box, due CHIPS (Not yet/Today/Tomorrow/Pick a date — picker only on
      Pick a date), nudge controls appear only once a due date exists, chips hug their words
      (no sparse two-column grid), hairline edge above "Add the task".
- [ ] Fast path still works: title only → Add the task.
## 6. Areas
- [ ] Grid tiles all equal size, pairs level.
- [ ] Assign a colour to one area → its grid card, chips, journal/task rows ALL repaint.
      Automatic reverts to emoji-derived.
## 7. Settings
- [ ] About shows real "Version X (Y)".
- [ ] Daily focus goal: change it → weekly focus summary + widget ring rescale.
- [ ] Default sprint length: set e.g. 45 → one-tap Start Session on a task WITHOUT its own
      plan runs 45:00; a task WITH a saved plan keeps its own.
- [ ] Haptics OFF → start sprint / promote / save task: no buzz (no relaunch needed).
- [ ] Notification sounds OFF → schedule a near nudge → it arrives SILENT (banner only);
      ON → sound. iOS Settings untouched.
## 8. Sweeps
- [ ] Dark mode pass over everything above (palette, chips, hairlines, widgets).
- [ ] Larger Dynamic Type: composers and Journal rows still read; nothing clips.
