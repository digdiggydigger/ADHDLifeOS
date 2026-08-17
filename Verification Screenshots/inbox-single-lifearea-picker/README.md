# Verification — FIX: Inbox promote flow, collapse to one Life Area picker (+ HIG conformance)

Captured on-device (iPhone 17 Pro simulator, iOS 26.5) after E signed in, following the FIX block
in `TODO-CLAUDE-CODE.md`. Builds on `44837b7`.

| File | What it shows |
|------|---------------|
| `01-expanded-single-lifearea-picker.png` | An expanded Inbox row now has **exactly one** control labelled "Life Area", with the footnote **"Applies to this capture and any task made from it."** directly beneath it — then the tag field, a divider, Priority / Due Date / Create Task. The old second `capturePromoteLifeAreaPicker` is gone. |
| `02-promoted-task-inherited-health.png` | The actual bug, fixed end-to-end. The "SO REALLY IT WORKS…" note was set to **Health** in triage and promoted; here it is the top task on the **Health** life-area detail — i.e. the created task inherited the picked Life Area (non-null, matching what was chosen). Previously this produced a task with `lifeAreaId == nil`. |
| `03-none-promote-succeeds.png` | Promoting a capture whose Life Area is **None** still succeeds: the "Because of whatever" voice capture was promoted with None and dropped out of the Inbox with no crash and no validation error (revealing "Testing real quickly" beneath it). |
| `04-default-collapsed-uniform.png` | Default text size — rows stay uniform (no regression to `44837b7`) and the `Promote to Task` button renders fully on every row, including the long-title GitHub rows. |
| `05-axxxl-button-one-line-reflow.png` | AX-XXXL. The `Promote to Task` button renders on **one line** and the primary text is still legible ("Photo N…", not a single character) — fixing the current failing baseline (`inbox-uniform-row-fix/03-enlarged-dynamic-type.png`, where the button wrapped to four lines and squeezed text to "P…"). See the design note below on how this was achieved. |

## Design note — Part 2, item 6 (button at accessibility sizes)

The block prescribed `.lineLimit(1)` + `.fixedSize(horizontal: true)` on the button and
`.layoutPriority(1)` on the primary text. **Applied literally, those two directives conflict and
fail acceptance criterion 7**, which was verified on-device:

- `.fixedSize(horizontal: true)` forces the button to its full intrinsic width. At AX-XXXL
  "Promote to Task" is wider than the screen, so the button shoves the leading slot and primary
  text off the left edge — the text is *not legible*, violating the criterion.
- Dropping `fixedSize` and leaning on `layoutPriority(1)` instead makes the text greedy at **every**
  size, truncating the button to "P" even at the default size — a regression against criterion 8.

No single static modifier set can satisfy both criteria, because they want opposite winners at
opposite ends of the type scale (button wins width at default; text wins at AX-XXXL). The resolution
— confined to `CaptureInboxView.swift`, touching no behaviour, data, navigation, the `List`, or any
identifier — is an **adaptive reflow**: at normal sizes the button sits trailing on the same line
(matching `44837b7`); at accessibility sizes (`dynamicTypeSize.isAccessibilitySize`) it reflows
beneath the content so both the button and the primary text get the full row width and each stays
legible on one line. This is flagged for review as a deliberate deviation from the literal modifier
list, made to satisfy the block's own acceptance criteria.

The button label still tail-truncates to "Promote to T…" at the very largest sizes because the full
label exceeds even the full row width at AX-XXXL; it remains one line and clearly readable. Shortening
the label or using an icon-only affordance was out of scope for this block.
