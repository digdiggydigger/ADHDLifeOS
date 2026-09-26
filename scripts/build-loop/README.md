# Build-loop scripts (CLAUDE.md › "The build loop — three standing economies")

Small, reusable drivers so no session re-derives them. Set `SP` to a scratch directory first
(`export SP=<your scratchpad>`; default `/tmp/lifeos-build`). Each writes `$SP/<label>.log`
ending in an `XCODEBUILD_EXIT=<n>` sentinel, and never pipes `xcodebuild` into `tail` (that
masks the exit code), and removes its own result bundle INSIDE the run.

| script | what it runs |
|---|---|
| `t.sh <label> <Class> [...]` | targeted unit classes on iPhone 17 Pro 26.5, coverage off |
| `full.sh <label> [YES\|NO]` | the full unit suite (UI target skipped), coverage optional |
| `ui.sh <label> <tag> <light\|dark> <content-size> <Class[/test]> [...]` | UI classes on iPhone 17 Pro **27.0**, with the appearance and text size set first; `<tag>` reaches the harness as `TEST_RUNNER_TODAY_RENDER_TAG` |
| `e3-mutations.py <pure\|source>` | `F-E3-OneCardToday`'s red-check mutations, one batch at a time; restore with `git checkout -- "ADHD LifeOS"` |

**After any `ui.sh` run, erase the 27.0 simulator before it is used for anything else**
(`xcrun simctl erase 0ACE7E5C-513C-4989-B110-F8A713BFD472`) — a UI journey leaves it signed in.
