# Verification — Life Areas backend (rename, emoji, create, archive, reorder)

Proof record for the FEATURE block "Life Areas backend" in `TODO-CLAUDE-CODE.md`.

## Step 0 — live stored shape (before any code)

Raw `AREA#` item from the live `LifeOS` table:

```json
{ "PK": "USER#b428d4c8-…", "SK": "AREA#0ca215b5-149b-4915-b19a-9e0ab1173304",
  "entity": "AREA", "id": "0ca215b5-…", "userId": "b428d4c8-…",
  "name": "Personal", "colour": "🌱", "sortOrder": 2,
  "createdAt": "2026-07-22T07:39:44", "updatedAt": "2026-07-22T07:39:44" }
```

Matches the block's assumed set plus `userId/createdAt/updatedAt`. **No `archived` attribute**
(missing-means-false confirmed). The nine real areas carry `sortOrder` **1..9**, not 0..8 — cosmetic
per §8 (nothing reads the integer; `list_life_areas` and Swift only sort by it, `next_sort_order` is
max+1), so 0-indexing on write is safe. `dynamodb:BatchWriteItem` confirmed present on
`life-os-api-lambda-role` → `LifeOSTableAccess`.

## Two proof layers

- **[live-invoke]** — a real `aws lambda invoke` against the **deployed** `life-os-api` code, its
  **real IAM role**, and the **real `LifeOS` table**. This exercises the exact failure mode the block
  warns about (the Tag Editor's `AccessDeniedException` on `BatchWriteItem` would surface here — same
  role, same call). It does **not** exercise API Gateway URL→routeKey resolution or the JWT authorizer.
- **[live-gw]** — through API Gateway with a Cognito JWT. Requires E's password, so the full
  `smoke_test_lifeareas.sh` run is E's (hidden-prompt, same as the Tag Editor smoke). Unauthenticated
  route-registration + authorizer checks were run without a token (below).

## Unit tests (pure functions, zero boto3)

```
$ /usr/local/bin/python3.14 -m unittest test_lambda_function
Ran 50 tests in 0.002s
OK
```

17 pre-existing (Decimal/`_response`, tag planners) + 33 new: `plan_life_area_patch` (allow-list
reject, name/colour trim+reject+noop, `archived` real-bool incl. string/int rejection and
missing-means-false), `next_sort_order` (max+1, Decimal-safe, empty, missing), `validate_reorder`
(exact set, missing/unknown/duplicate/non-list/empty), and `find_name_conflict` (live→`False`,
archived→`True`, **no-`archived`-attribute→`False`**, `exclude_id` self-skip on rename, rename-onto-
archived→`True`).

## Live route proofs (direct Lambda invoke, deployed code + real table)

| Route behaviour | Result |
|---|---|
| `GET /life-areas` | 9 areas, every one `archived:false`, `sortOrder` still `1..9`, no migration |
| `POST` create | `201`, fresh uuid, `archived:false`, `sortOrder` = prev max+1 (got 10 then 11) |
| `POST` duplicate real name ("Work") | `409`, `conflict{id,name}`, nothing created |
| `POST` onto an **archived** throwaway name | `409`, **`conflict.archived: true`**, nothing created |
| `PATCH` rename / colour(emoji) | `200`, follow-up GET reflects both |
| `PATCH` `archived` true→false | `200`; archived area **still returned by GET**; round-trips |
| `PATCH` rename onto another name | `409`, `conflict{id,name,archived}`, no write |
| `PATCH` rename onto an **archived** name | `409`, **`conflict.archived: true`** |
| `PATCH` unknown id / unknown key / `archived:"true"` | `404` / `400` / `400` |
| `PATCH /life-areas/reorder` valid (reverse 11) | `200`, persisted, **BatchWriteItem succeeded** |
| `reorder` missing / unknown / duplicate / non-list | four `400`s, order unchanged |

## Gateway route registration (no token needed)

```
POST  /life-areas          (unauth) -> 401     PATCH /life-areas/foo/bar -> 404 (unregistered)
PATCH /life-areas/{id}     (unauth) -> 401     DELETE /life-areas/{id}   -> 404 (no delete route)
PATCH /life-areas/reorder  (unauth) -> 401
```

401 (not 404) on the three new routes proves they are registered with the JWT authorizer attached;
the 404 on an unregistered path proves the 401s mean "registered", not "gateway rejects everything".

## reorder-vs-`{id}` resolution

Proven at every layer bar an authenticated gateway round-trip: literal route registered + `401`;
AWS HTTP-API resolves a literal segment over an `{id}` template; direct invoke confirms routeKey
`PATCH /life-areas/reorder` dispatches to `reorder_life_areas`. The authenticated `200`-not-`404`
confirmation is §9 of the smoke script (E's run).

## E's real data

A pre-run raw-DynamoDB snapshot of the nine real areas was taken; the destructive direct-invoke
sequence (incl. a full reorder that necessarily rewrote their `sortOrder`) was run; the nine were then
restored **byte-for-byte** via direct `put-item` of the snapshot and every `zz-la-*` throwaway
hard-deleted (no DELETE route by design). Post-run scan: **byte-identical to snapshot, zero
leftovers**, table back to a clean 9 × `1..9`. `smoke_test_lifeareas.sh` reproduces this protection
(§1 snapshot, §12 restore + generic `zz-la-*` sweep, byte-identical assertion in its own branch).

## Pending E

`bash smoke_test_lifeareas.sh` (hidden Cognito prompt; also needs the runner's AWS creds for the
snapshot/restore). Flips the two `[~]` criteria to `[x]`.
