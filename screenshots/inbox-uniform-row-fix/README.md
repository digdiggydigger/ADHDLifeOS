# Verification — FIX: uniform collapsed Inbox row layout

Captured on-device (iPhone 17 Pro simulator, iOS 26.5 — no iPhone 15 Pro runtime is
installed on this machine) after E signed in. Commit `44837b7` on `main`.

| File | What it shows |
|------|---------------|
| `00-clean-launch-login.png` | App launches cleanly to the Sign in screen with no session — proves no crash from the change. |
| `01-collapsed-mixed-list.png` | The core fix. Every collapsed row is a uniform height: one 44×44 leading slot (photo thumbnail / voice control / link thumbnail / SF-Symbol glyph tile), one 1-line primary text, one `"Kind · time ago"` caption. Note, photo, link (with and without a preview thumbnail), and voice are all present; the multi-paragraph shortcut note (`SO REALLY IT W…`) that previously sprawled is now a single truncated line. |
| `02-expanded-row.png` | The note row expanded. Primary text is now fully readable (unbounded when expanded — the load-bearing `.lineLimit(isExpanded ? nil : 1)`), the button flips to `Cancel`, and `triageSection` → `Divider` → `promoteForm` appear unchanged. Neighbouring collapsed rows stay uniform. |
| `03-enlarged-dynamic-type.png` | Collapsed list at AX-XXXL Dynamic Type. The 44×44 slots stay fixed (correctly not scaled), primary + caption stay 1 line each, and nothing clips. The extra row height comes only from the pre-existing `Promote to Task` button wrapping, which is out of this block's scope. |

Note: no `.task`-kind capture existed in the live inbox, so that kind's layout was
verified via its identical code path to `.note` (both resolve to the glyph slot) plus
the unit tests in `CaptureRowPresentationTests.swift`.
