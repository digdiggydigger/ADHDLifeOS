# START HERE — `F-C4-TagsRecentlyDeleted`. `F-C3` is COMPLETE; tags are the third kind.

*Written 2026-09-22 by the session that finished `F-C3-RecentlyDeleted`. A disposable pointer:
archive it when you write your successor. Its predecessor, `archive/START-HERE-adhd-audit-arc-C3-continued.md`,
is spent — but its §4 (traps) is still true and is not repeated here.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."* **Every design question in the `F-C4` spec is already answered by E.
Nothing is owed to E.**

## 0. Before anything else

1. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-c4-tags`.
2. **Read:** `CLAUDE.md` (§1–§7, especially §7.6), `claudecode.md`, the
   `### FEATURE: F-C4-TagsRecentlyDeleted` block in `TODO-CLAUDE-CODE.md` (it is unusually
   complete — five numbered steps, every call site already read and line-referenced),
   `handoff/ADHD-AUDIT-BUILD-LOG.md` **session 6**, and `OPEN-ITEMS-REGISTER.md` edition 75.
   Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`.
3. **Start the emulator** — `./scripts/emulators.sh --import scripts/audit/emulator-state` — and
   leave it running. It was UP at close-out.

### 0.1 NOTHING IS OWED TO E. Do not ask for a device look.

`F-C3` owed none: it added no `#available` site and no reduced site, and the new screen has no
animation of its own. `F-C1` and `F-C2` both PASSED on E's phone on 2026-09-22. **Do not raise the
capsule radius cap** — the AX3 render covers it and E's own frames settled the rest.

## 1. What `F-C3` shipped, because `F-C4` builds directly on it

**Read these five files before writing anything; `F-C4` is the same shape applied to a third
collection.**

- **`RecentlyDeleted/SoftDelete.swift`** — `isLive(deletedAt:)` (**`nil` means LIVE**),
  `isPurgeable(deletedAt:asOf:)` (`>`, so exactly 30 days is KEPT; a FUTURE stamp is not purgeable),
  `retention`, `SoftDeleteError.itemIsDeleted`.
- **`Firebase/FirebaseManager+SoftDelete.swift`** — the `SoftDeletable` protocol, `live(_:)` for
  lists, `deleted(_:)` for the inverse, `requireLive(_:)` for single-document reads.
- **`FirestoreFieldPayloads`** — `taskSoftDelete(now:)` / `taskRestore()` / `captureSoftDelete(now:)` /
  `captureRestore()`. **Restore ERASES with `FieldValue.delete()`, never writes null.** Tags are
  snake_cased like tasks, so `deleted_at`.
- **`RecentlyDeleted/RecentlyDeletedPresentation.swift`** — the row, the countdown, the empty
  state, the Tools row's line, the Delete forever copy. **`RecentlyDeletedItem.Kind` is where a
  `.tag` case goes**, and `glyph(for:)` / `word(for:)` are its two switches.
- **`RecentlyDeleted/FirebaseRecentlyDeletedClientAdapter.swift`** — `fetchDeleted()` merges both
  collections concurrently; a third `async let` joins it here.

**Six tests will fail the moment you add a `.tag` case, and every one of them is doing its job:**
`RecentlyDeletedPresentationTests` (the glyph and word switches), `SoftDeleteCallSiteTests`' fetch
COUNTS if you add a fetch to `FirebaseManager+Tags.swift`, and
`testTheHardDeleteExistsNowhereOutsideFirebaseAndRecentlyDeleted` if you leave `deleteTag` on a UI
seam. Update them deliberately.

## 2. The one thing about `F-C4` that is genuinely different

**Tags are not hidden by removing them — they are hidden by NOT removing them.** The spec's step 1
is *"Do not touch any `tag_ids` array"*, and steps 3 and 4 depend on that: "back on every item" is
a property of never having unlinked, not of re-attaching at restore. Today's
`removeTagEverywhere(_:replacingWith:)` does the unlink and the delete in ONE atomic batch
(`FirebaseManager+Tags.swift:86-106`); `F-C4` splits that batch in two and defers the second half
by 30 days.

**So the purge grows a third branch, and it is the only one that does real work.** A task's purge
is a document delete; a tag's purge is today's whole batch.

**And the hiding happens at a read layer that does not exist yet for tags.** `fetchAllTags()` and
`fetchTagsForTask(taskId:)` need `live(...)`, and so does wherever the filter menu's tag list is
built — enumerate them the way `SoftDeleteCallSiteTests` enumerated the nine, and pin the COUNT.

## 3. What must NOT be re-tuned or re-litigated

- **The capsule's radius cap, `peekStep = 14`, `floatingPaddingHorizontal = 12`, the tab bar, the
  capture disc, the appearance override, the Confirm celebration's RM waiver.**
- **Do NOT "improve" task detail's autosave to on-blur** — saving resets the Form's scroll, which
  is why it fires on leaving.
- **Do NOT re-add a confirmation to a soft delete.** E dropped both on 2026-09-22 after the
  `apple-design` review (`alerts.md`: do not confirm common, undoable actions). A tag delete is
  the same case, so `TagEditorDetailView`'s *"Delete Tag"* alert is a candidate to drop too —
  **but ask E rather than assuming**, because a tag's delete touches many items and E has not been
  asked about that one.
- **"Delete forever" keeps its confirm**, and it is the only place *"This can't be undone."* is
  true. The Tag Editor's own two "can't be undone" strings are still TRUE today and must be
  re-checked when tags become soft: `TagEditorPresentation.swift:36` and `:52`.
- **`firestore.rules`: verified unchanged against `:55-59`** — `tags` is in the same generic allow,
  so a `deleted_at` field needs no new rule. The optional hardening stays DECLINED (it checks the
  CLIENT's clock).

## 4. Traps this session paid for, all in the UI-test harness

**Read these before writing `screenshots/recently-deleted-tags/`'s harness — they cost six runs.**

1. **`UITestSession.tap(_:untilGone:)` returns `true` WITHOUT TAPPING** when the doomed element is
   already absent. Scrolling a `Form` to its last row takes the title field out of the hierarchy,
   so `untilGone: titleField` was satisfied by the scroll. Two assertions passed on a build that
   had deleted nothing.
2. **`tap(_:untilExists:)` fails the same way from the other side** — it returns immediately when
   the expectation already holds, and a capsule left pending from an earlier action satisfies it.
   **Use a signal that belongs to THIS screen and this moment**; the nav bar is the one that works.
3. **`openTab` returns on `isSelected`, before the content has slid.** Wait for the tab's own root
   control to be HITTABLE, and for a pushed screen wait for its nav bar — otherwise XCUITest
   reports frames at x ≈ 10016 and a tap lands on another tab.
4. **A coordinate tap is WORSE than a plain tap on a bogus frame**: it bypasses hittability and
   taps whatever is really there. One run ended on the Areas tab.
5. **An identifier is inherited by a container's children**, so `descendants(matching: .any)[id]`
   is ambiguous and reports "does not exist". Use a typed query plus `.firstMatch`.
6. **A `confirmationDialog`'s button matches twice.** `.firstMatch`.
7. **The emulator is the arbiter.** A `runQuery` with `Authorization: Bearer owner` against
   `http://127.0.0.1:8080/v1/projects/adhdlifeos-acb49/databases/(default)/documents:runQuery`
   reads any document; without that header the rules refuse and you get an empty result that looks
   like an empty database. That query is what proved the frames were lying.

## 5. The state you inherit — VERIFIED at close-out, not assumed

- **`main` @ the merge of PR #185**, `git status` clean, local and `origin/main` identical.
- Suite **3,253 / 0**, SwiftLint **0 / 877**, build **SUCCEEDED**, coverage **29.87%
  (14,953/50,068)** — comparable to session 5's 29.89%, the dip being 523 lines of new view body.
- **The simulator (`9181EBF9-…`) was ERASED and is Shutdown.**
- **The Firebase emulator was UP** with the audit's imported state, plus six throwaway accounts
  from the render runs.
- **E's phone has `main` @ `4917955`** — `F-C1` + `F-C2`. **It has NOT seen `F-C3`.** Nothing owes
  a look, but if E asks to see Recently Deleted on the phone, that install is the prerequisite
  (memory: `ask-for-device-checks-on-a-build-e-has`).
