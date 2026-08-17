# Cowork ↔ Claude Code Workflow

**One-way handoff → TDD execution → Status return**

Repo: https://github.com/digdiggydigger/es-life-os-mobile (private, branch `main`) — see `CLAUDE.md` → Version Control for commit/push discipline.

---

## The Cycle

### Phase 1: Cowork (Desktop App) — DESIGN

**Output:** Updated docs + TODO items

1. Open Claude Cowork (Desktop)
2. Brainstorm the feature: problem, acceptance criteria, fit in architecture
3. Update `/docs/` files:
   - `FEATURES.md` → feature name + dependencies
   - `ARCHITECTURE.md` → where it fits
   - `WIREFRAMES.md` → screen layout, navigation, component structure (described in words/diagrams — no Swift)
   - `DATABASE_SCHEMA.md` → data model changes (if any — check the shared Supabase schema first)
   - `API_SPEC.md` → Supabase queries/RPC calls this feature needs (if any)
4. Add a **FEATURE:** block to `TODO-CLAUDE-CODE.md` (template below)
5. **Do NOT write Swift in Cowork**

---

### Phase 2: Claude Code (Terminal) — BUILD & TEST

**Input:** `TODO-CLAUDE-CODE.md` + `/docs/`
**Output:** Production Swift + passing tests

1. Open Terminal in the project folder → run Claude Code
2. Claude Code reads `claudecode.md`, `docs/ARCHITECTURE.md`, `TODO-CLAUDE-CODE.md`
3. TDD: write XCTest cases first, then implement
4. Run:
   ```bash
   swiftlint lint
   xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
     -destination 'platform=iOS Simulator,name=iPhone 15' \
     -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
   xcrun xccov view --report TestResults.xcresult
   ```
5. Commit: `<FEATURE-ID>: <short description>` — then **push to `origin/main` immediately** (never batch multiple features into one push; see `CLAUDE.md` → Version Control)
6. Update `TODO-CLAUDE-CODE.md`: mark `[x] COMPLETED`
7. If blocked, add `[BLOCKED]` to `TODO-CLAUDE-CODE.md`, stop, wait for Cowork

---

### Phase 3: Feedback Loop (Optional)

1. Claude Code adds `[BLOCKED] - <what's unclear>` to `TODO-CLAUDE-CODE.md`
2. Cowork sees it, clarifies in the TODO
3. Claude Code resumes

---

## File Structure & Ownership

| File | Owner | Read-only to |
|------|-------|--------------|
| `/docs/**` | Cowork | Claude Code reads, never writes |
| `TODO-CLAUDE-CODE.md` | Cowork writes, Claude Code updates checkboxes | Both |
| `ADHD LifeOS/` (Swift source) | Claude Code | Cowork never writes code here |
| `ADHD LifeOSTests/`, `ADHD LifeOSUITests/` | Claude Code | Cowork never writes code here |
| `claudecode.md` | Reference (never changes) | Claude Code reads on startup |
| `.swiftlint.yml` | Claude Code (config only, per an agreed rule change) | Both |

---

## FEATURE Block Template

```markdown
## FEATURE: <name>

**Context:** What problem this solves, how it fits the architecture.

**Acceptance Criteria:**
- [ ] ...

**Test Plan:**
- Unit tests: ...
- (UI tests only if the feature needs one — most domain/service logic doesn't)

**Implementation Checklist:**
- [ ] Create `ADHD LifeOS/<File>.swift`
- [ ] Create `ADHD LifeOSTests/<File>Tests.swift`
- [ ] Run: `swiftlint lint`
- [ ] Run: `xcodebuild test ...` — verify ≥70% coverage on new code
- [ ] Run: `xcodebuild build ...`

**Dependencies:**
- Needs: ...
- Blocks: ...

**Notes:**
- Any flagged assumptions or scope decisions.
```

---

## Anti-Patterns to Avoid

❌ **Cowork writes Swift** — Not allowed. Design only.
❌ **Claude Code modifies docs** — Not allowed. Reads only.
❌ **Missing acceptance criteria** — Claude Code needs clarity.
❌ **Skipping tests** — TDD is mandatory.
❌ **Uncommitted or unpushed changes** — Commit AND push to `origin/main` after every feature; never end a session with local-only work.
❌ **"Tests passed" with no pasted output** — Cowork can't run Xcode; paste the real terminal result.
✅ **"User can X" → Test: User does Y → Assert: Z** — Clear.

---

## Quick Checklist

**Before Claude Code starts:**
- [ ] TODO item has acceptance criteria, test plan, implementation checklist
- [ ] Docs reflect the architecture decision
- [ ] Dependencies are clear

**Before Cowork designs next feature:**
- [ ] Previous feature completed, committed, and pushed to `origin/main`
- [ ] `swiftlint lint` clean, tests passing, coverage ≥70% on new code
- [ ] Commit message is descriptive
