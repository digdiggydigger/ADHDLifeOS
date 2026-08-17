# Verification — Tag Editor backend (usage counts, rename+merge, cascade delete)

Proof record for the FEATURE block "Tag Editor backend" in `TODO-CLAUDE-CODE.md`.

## Live smoke test

- **Script:** `aws-backend/life-os-api/smoke_test_tags.sh`
- **Target:** live API `https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod` (`life-os-api`
  Lambda, `LifeOS` DynamoDB table), authed with a real Cognito ID token.
- **Run by:** E, in a real terminal (hidden password prompt), 2026-07-30.
- **Result:** `================ RESULT: 62 passed, 0 failed ================`

The 62 assertions reconcile exactly to the script's assertion count (2 + 8 + 7 + 8 + 5 + 3 + 7 +
15 + 6 + 1 = 62), i.e. every assertion in every section passed. Coverage by section:

| § | Section | Proves |
|---|---------|--------|
| 0 | unauthenticated new routes | `PATCH`/`DELETE /tags/{id}` return **401** with no token → JWT authorizer is attached |
| 1 | setup | two tasks, two captures, four tags created (201s) |
| 2 | attach | 7 junction rows created across tasks + captures (dedup + repoint fixtures) |
| 3 | GET /tags counts | `taskCount`/`captureCount`/`usageCount` correct for a used tag (2/2/4); **unused tag returns 0/0/0**, not a missing key |
| 4 | PATCH edges | 200 no-op on unchanged name · 400 empty name · 400 bad `onConflict` · 404 unknown id (PATCH) · 404 unknown id (DELETE) |
| 5 | free rename | rename to a free name → 200, name updated, **junction row on the used tag survives** (same id still on its task) |
| 6 | collision 409 | clash without `onConflict` → **409** carrying conflicting tag's `id`/`name`/`usageCount`; **writes nothing** (loser still present, both usage counts unchanged) |
| 7 | merge | `onConflict:merge` → 200, survivor returned; stats repointed=1 task/1 capture, deduped=1 task/1 capture; loser tag gone; survivor now 2/2/**4** (deduped, **not 6**); the item that carried BOTH ends with **exactly one** survivor row |
| 8 | cascade delete | `DELETE /tags/{id}` → **204**; tag gone from `GET /tags`; no task/capture still lists it (junction rows cascaded) |
| 9 | cleanup | every `zz-smoke-*` tag deleted via the new route (leftover counter = 0); throwaway task/capture rows marked done/processed (no delete route by design) |

## Unit tests (pure functions)

```
$ python3 -m unittest test_lambda_function
Ran 17 tests in 0.001s
OK
```

4 pre-existing Decimal/`_response` regressions + 13 new: `tally_tag_usage`, `plan_tag_merge`
(loser-only repoint, survivor-only, both→dedup, spanning tasks+captures, unrelated-tags-untouched),
`plan_tag_cascade`. All planners tested with plain dicts, zero boto3 / no AWS mocking.

## Criteria proven by code inspection, NOT by the smoke run

Two acceptance items are not observable from a green smoke run and must not be treated as proven by
it:

1. **`GET /tags` issues exactly two junction queries regardless of tag count (no N+1).** Proven by
   inspection: `list_tags` calls `_tag_usage_counts(user_id)` once, which makes exactly two
   `_query_all` sweeps (`TASKTAG`, `CAPTURETAG`) and tallies in memory — there is no per-tag query.
   A smoke run returns correct counts whether or not the implementation is N+1, so it cannot prove
   this; only reading the code can.
2. **Pagination fix (`_query_all` follows `LastEvaluatedKey`; `_query_entity` repointed at it).**
   Proven by inspection + the loop's construction: truncation only manifests when a single
   entity's rows exceed DynamoDB's 1MB page, which the smoke fixtures (a handful of rows) never
   reach. The `while`/`ExclusiveStartKey` loop is verified by reading it, not by the smoke run.

## Infrastructure (AWS-side, not in git)

- Routes `PATCH /tags/{id}` and `DELETE /tags/{id}` created on API `2pzqn8yih5` with JWT authorizer
  `ajwddr` (aud `57v25l4t62spds2qkvkhtbq0ae`).
- `dynamodb:BatchWriteItem` added to the `LifeOSTableAccess` inline policy on
  `life-os-api-lambda-role` (required by `batch_writer`; first use of that action in this codebase).
- `life-os-api` Lambda code deployed (`LastUpdateStatus: Successful`).
