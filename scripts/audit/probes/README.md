# Audit render probes and compositors (ADHD UX audit, session 2)

Throwaway tools, kept so a later audit session can re-render without rebuilding them. **Nothing here is built.** The
Swift probes are stored as `.swift.txt` precisely so no target ever compiles them from this folder.

- **Using a probe:**
  1. Copy it to `ADHD LifeOSTests/<Name>.swift`. The test target is a file-system-synchronised group, so it joins
     automatically.
  2. Run it with `-only-testing:"ADHD LifeOSTests/<Name>"` on `iPhone 17 Pro, OS=27.0`, never the signed-in 18 Pro.
  3. Delete it from the test folder once E has chosen.
- **The render trap:** each probe writes PNGs to a hard-coded scratchpad path (`outDir`); change it for a new session.
  The first `ImageRenderer` render in a fresh host returns nil. `AuditComposerLayoutProbe` shows the two-pass fix.
- **The compositors** (`compose_r*.py`) read those PNGs plus real simulator frames, and write the numbered boards.
  They carry the scratchpad path `S` and the frame names at the top.
  - `annot.py NAME ["label|label"]` boxes controls under 44 / 48pt from the accessibility tree.
  - `stitch.py <dir> <name>` stitches a clean full-length screen from slow scrolls.

| probe | round | board |
|---|---|---|
| `AuditUndoBarRenderProbe` | 2b undo bar | `54` |
| `AuditSprintControlsRenderProbe` | 4c six sprint controls + focus screen | `58` |
| `AuditHeroRenderProbe` | 5 Today's one card | `59` |
| `AuditComposerRenderProbe` | 6 composer shapes + E's combo | `60`, `61` |
| `AuditComposerLayoutProbe` | 7b composer layouts | `64` |
