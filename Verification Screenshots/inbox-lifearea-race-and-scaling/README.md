# Inbox — Life-Area PATCH race fix + accessibility text scaling

Verification for the FIX block *"Serialise the Life Area PATCH (revert race) + finish the
accessibility-size text sizing"* — follow-on to `345233b`. Captured on iPhone 17 Pro (iOS 26.5)
against the live AWS backend, signed in as E.

| File | What it shows |
|------|---------------|
| `01-default-collapsed-list.png` | **Default text size, collapsed list.** Unchanged from `345233b`'s uniform two-line rhythm (44×44 leading slot, primary line, `Kind · time ago` caption). The button now reads **"Promote"** (was "Promote to Task"). |
| `02-expanded-row.png` | **Expanded row.** Button toggles to **"Cancel"**, triage section + Life Area picker ("None") appear. Layout unchanged from `345123b` apart from the label. |
| `03-promoted-task-health-inheritance.png` | **Promote-to-task inheritance re-verify** (part 1 touches this path). The Voice Note capture was triaged to **Health**, then promoted. Under Health → Tasks the exact task appears — "🗣️📣 Voice Note: 28 July 2026 at 23:50", transcription "Just a quick test note at 11:50 PM on a Tuesday", notes "not today. only a test", P4. The Home Health count also went 2 → 3. |
| `04-axxxl-collapsed-list.png` | **AX-XXXL, after this fix.** Compare against the baseline `../inbox-single-lifearea-picker/05-axxxl-button-one-line-reflow.png`. The `isAccessibilitySize` reflow (button below content) is retained; `.minimumScaleFactor(0.8)` is now applied to the primary text, the caption, and the button label. |

## AX-XXXL improvement vs baseline `05`

| Element | Baseline `05` | This fix `04` |
|---------|---------------|---------------|
| Button label | `Promote to T…` (ellipsis) | **`Promote`** — fully readable, no ellipsis |
| Caption | `Photo · 2 days…` (ellipsis) | **`Photo · 2 days ago`** — fully readable, no ellipsis |
| Primary (photo) | `Photo N…` | `Photo Note…` — visibly less truncated |
| Primary (link) | `GitHub - p…` | `GitHub - palle…` — visibly less truncated |

The two short strings (caption, button) now fit without ellipsis at AX-XXXL. The long primary
titles still ellipsize — `minimumScaleFactor(0.8)` only permits a 20% shrink, which is the
intended behaviour (shrink slightly rather than wrap), and they show ~20% more characters before
the ellipsis than the baseline. This meets the acceptance criterion: each element readable without
ellipsis on the shortest captures, and visibly less truncated than the baseline on the longer ones.

## Item 8 — is the reflow still needed?

**Yes — kept in place, not removed** (per the block's instruction). Even with the shorter "Promote"
label and `minimumScaleFactor(0.8)`, at AX-XXXL the content text is large enough that forcing the
button and content side-by-side in an `HStack` would still shove the primary text off-screen or
crush the button to a stub. `minimumScaleFactor` prevents truncation *within* each element's own
line but does not free up enough horizontal room to abandon the reflow. Simplifying that branch
remains a separate decision for E.
