# Inbox promote — "Create Task" as a real primary action — device verification

Block: "FEATURE: Inbox promote — Create Task as a real primary action". Captured on iPhone 17 Pro
(iOS 26.5) against the live AWS backend with a real Cognito session. The Create Task button in the
Inbox row's expanded promote form becomes a full-width filled primary action, in-flight-aware and
double-tap-safe; the warning/error messages gain an SF Symbol.

| # | Screenshot | What it proves |
|---|-----------|----------------|
| 01 | `01-promote-form-primary-button.png` | **Dark mode.** The Create Task button is a full-width, filled **primary action** at the bottom of the expanded promote form (Priority + Due Date above it unchanged); the filled accent fill and white on-accent label hold contrast. |
| 02 | `02-promote-form-light.png` | **Light mode.** The same filled button holds contrast against the light background — the on-accent white label is legible. (Life-os-auth smoke-test note capture.) |
| 03 | `03-one-task-after-double-tap.png` | After deliberately **double-tapping** Create Task on a capture assigned to **Personal**, the Tasks tab's Personal group shows **exactly ONE** new task (the promoted photo-note) plus the pre-existing "Archivetest task", then Family begins — **no duplicate**. The in-flight guard (unit-proven) holds on device; the button also disables on first tap so the second is a UI no-op. Home separately showed Personal go 1 → 2. |
| 04 | `04-axxxl-button-reflow.png` | At **AX-XXXL** the button reflows full-width with the "Create Task" label uncut, and the promote form still scrolls to reach it (Priority / Due Date above reflow cleanly). |
