# Arrival card vanishing on drag-reload (F-ArrivalCardRefresh)

**Environment:** E's iPhone 15 Pro (`wishwashwacky15`), light mode, live Firebase, signed in as E,
**2026-09-08 06:14 BST**, `main` @ `e8d1605` (the code is `76a4f47`; every merge since is
docs-only). Taken by E, not by the session — E's own screenshots from
`../Ethan's Screenshot Folder/`, filed here because they are the evidence for the bug the block
fixes and for the case E settled by looking: the task was STILL OPEN when the card went.

**What driving the real screen caught that the tests could not:** the tests could pin the
arrival card's rule (no card unless something is open here) but never that a pull-to-refresh
threw a correct card away. The mechanism turned out to be three saved places at E's home — all
with the 100 m floor radius, centred 1.2 m and 34.5 m apart — and a resolver that picked ONE of
them by nearest centre: a coin flip per fix, and a pull re-tossed it. A standalone probe over
the real geometry files put Home's share at **50% at 10 m jitter, 31% at 40 m** (against 100% /
96% with Home alone). No throwaway data was created by the session; `test quick` is E's own task.

| # | file | what it proves |
|---|---|---|
| 00 | `00-before-pull-card-test-quick.jpeg` | Today at 06:14: the card — *"YOU'RE AT HOME 🏠 · 1 thing lives here · test quick P4"* — above the ring (1 of 6 closed), `test quick` also the Best Next Move. The state before the pull. |
| 01 | `01-after-pull-card-gone-task-still-open.jpeg` | Same minute, after one drag-reload: **no card**, and `test quick` still open in Best Next Move. This is the bug — hypothesis (a)/(c), not (b): nothing was closed. |
| 02 | `02-task-detail-at-place-home-open.jpeg` | `test quick`'s detail: **At Place = 🏠 Home**, P4, due 8 Sep 6:00 pm, open — the task the card was built from, with its place set. **Also shows the next item:** the Tasks tab's bottom "Search tasks" row is still on screen with a task detail pushed (E, 06:20: *"remove the 'search tasks' search bar from a full view task screen"*). |
| 03 | `03-tasks-list-test-quick-open.jpeg` | Tasks list: **1 open · 0 overdue**, `test quick` due today and open, `september` closed 4:53 am — the account state at the moment of 00/01, so the vanish cannot be the closed-task case. |

**After the fix (owed as `04-`…):** E pulls repeatedly on the reinstalled build and the card
stays — a claim only the device can settle, since the coin flip lives in CoreLocation's fixes.
