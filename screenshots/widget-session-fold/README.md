# widget-session-fold — the fold seen working on E's device

**Environment:** E's iPhone 15 Pro (`wishwashwacky15`), live Firebase, E's own account;
build `e4fe956` (main, F-WidgetStoreFold + F-DiscClearanceBarBand) installed via `devicectl`
at 22:05 the same evening; shots taken by E 22:46–22:49, 2026-09-06. Signed-out pair first
(22:46), then E signed back in (22:48).

**Why this folder exists — what no test can assert.** `F-WidgetStoreFold` (PR #4) claims that
on session end both App Group widget snapshots are emptied AND both timelines reloaded. The
unit suite pins the stores, the sweep's content, and the hook's call — but the thing that
matters is another PROCESS: WidgetKit re-rendering the Home Screen after a real sign-out on a
real device. Either half failing leaves E's data on screen (unemptied store → old data decodes;
unreloaded timeline → old render persists for hours). These four shots are the claim settled by
looking: every widget type in its honest empty state signed out, and repopulated signed in.

**What looking caught that the tests could not:** the Life Areas widget's signed-out copy reads
**"Open Momentum once and your areas will appear here."** — "Momentum" is the Home-redesign
codename, not the app's name (the widget gallery and every other surface say LifeOS). Stale
copy, logged in the register for E's call; not fixed in this pass.

**Throwaway data:** none — E's own account, one sign-out and sign-in; nothing to clean up.

| file | what it proves |
|---|---|
| `00-signed-out-home-three-widgets.jpeg` | Signed out (10:46): medium Focus shows "Open the app to sync your focus data.", **0m**, 0/7 days, 0s avg, 0 streak, blank bars; small Focus shows "Open the app to sync", **0m**, 0/7 · 0 streak; Capture launcher unchanged (static by design — it carries no user data). Nothing of E's renders anywhere. |
| `01-signed-out-life-areas-medium.jpeg` | Signed out: the Life Areas medium widget shows its empty state — **no area names** — where six of E's areas rendered before the fold. (Also the "Open Momentum once…" copy find, above.) |
| `02-signed-in-home-three-widgets.jpeg` | Signed in again (10:48): Life Areas back to E's six (Projects, Family, Growth, Health, Work, Home); small Focus back to **58m**, 6/7 days · 4 streak — Home's republish path intact after the fold. |
| `03-signed-in-focus-medium.jpeg` | Signed in, medium Focus close-up: ACTIVE GOAL "Nothing open — enjoy the gap." with THIS WEEK **58m**, real spark bars, 6/7 days, 8m 22s avg, 4 streak — the full payload round-trips after a fold-and-republish cycle. |
