# Task Detail — staged-vs-immediate-apply clarity (device verification)

Captured on the booted **iPhone 17 Pro** simulator (iOS 26.5) against the live AWS backend, signed
in as E's account. The "Photo Note" task in the **Personal** area was used as the test subject and
was restored to its original state (Priority P4, no due date) after verification.

| # | File | What it shows |
|---|------|---------------|
| 01 | `01-detail-immediate-apply-footers-dark.png` | Task Detail with the three immediate-apply section footers (Part 6): the status action ("Marking this done or reopening it applies immediately — no Save needed."), Tags, and Nudges. Custom back chevron top-left (Part 4). |
| 02 | `02-saved-confirmation-banner-dark.png` | The transient **"Saved"** confirmation banner (Part 3) — green checkmark + text on `.ultraThinMaterial`, anchored under the nav bar. Icon **and** text, never colour alone. |
| 03 | `03-discard-changes-alert-dark.png` | The **discard confirmation** (Part 4) on backing out with unsaved staged edits: destructive **Discard Changes** / **Keep Editing**, native `.alert`. |
| 04 | `04-duedate-dirty-notifications-gated-dark.png` | The **Part 5 gate**: with the due date edited but unsaved, both "Nudge me on this reminder" and "Notify me when this is due" are **disabled**, each with the neutral line "Save the due date first to change this." Save is enabled (the due date is a staged change). |
| 05 | `05-ax-xxxl-status-footer-dark.png` | **AX-XXXL, Dark.** The status footer reflows across five lines with no clipping or truncation. |
| 06 | `06-ax-xxxl-immediate-footer-light.png` | **AX-XXXL, Light.** The immediate-apply footer reflows fully; `LabeledContent` rows stack (label above value) instead of clipping. |

## Behaviours verified on device (not pictured or transient)

- **Save reflects state (Part 2):** disabled with no edits; enabled the instant a staged field
  changes; **disabled again when that edit is reverted by hand**; disabled again after a successful
  save (baseline correctly advances to the saved task — no "Save stays enabled forever" bug).
- **Save confirmation persistence (Part 3):** after the banner, the Priority change survived a cold
  relaunch — the confirmation never fires for a save that did not land.
- **Discard flow (Part 4):** *Keep Editing* returns with the edit intact; *Discard Changes* leaves
  and the edit is gone after re-opening. Verified from **both** entry points — the Tasks tab **and**
  Life Area Detail (Health).
- **Swipe-back (Part 4):** with unsaved changes, the interactive edge-swipe is **inert** — it does
  nothing (no dismiss, no dialog, and critically **no silent discard**). This is the expected
  consequence of `.navigationBarBackButtonHidden(true)` disabling the pop gesture.
- **Part 5 re-enable:** saving the due date re-enables both notification controls with no further
  action; editing a non-due-date field never disables them (`isDueDateDirty` is kept separate from
  `hasUnsavedChanges`).

The success haptic (Part 3) fires on the same success path as the visible banner via the
`#available`-gated `saveSuccessHaptic` (mirrors `CaptureInboxView.promoteSuccessHaptic`); haptics are
not observable in the simulator or in a screenshot.
