# Stage B — Cognito, `LifeOS` Table, `life-os-api` Lambda

*Written by Cowork (design phase). Date: 2026-07-22. Follows Stage A ("FEATURE: AWS Reminders
View"), shipped and reviewed same day, commit `dcec666`.*

*This is AWS infrastructure + backend work, not a Swift/Xcode task — it is not written as a
`TODO-CLAUDE-CODE.md` FEATURE block for the Claude Code terminal to build. It's executed by E
directly via the AWS CLI (installed and authenticated on E's Mac as of this session), with a
short pointer left in `TODO-CLAUDE-CODE.md` so it isn't lost. Stage C (swapping each Swift
`*ClientAdapting` implementation to talk to this backend) is the next design phase after this
ships and is verified — that work *does* go through the normal FEATURE block / Claude Code
pipeline, since it's real Swift.*

**Decisions confirmed with E before drafting (2026-07-22):**
- Auth: email/password only for v1. No Cognito passwordless/magic-link build in this block —
  deferred, matches the blueprint's own recommendation.
- Provisioning: AWS CLI commands (below), run by E in their own terminal. Not console click-through,
  not IaC/SAM/CDK.
- Lambda runtime: Python 3.13, matching `poke-ios-bridge`'s existing pattern on this account.

**One correction to `MIGRATION-SUPABASE-TO-AWS.md` §4's Stage B text, flagged here rather than
followed blindly:** that doc says to "attach JWT authorizer to the HTTP API (**and retrofit
`/task`**)" — i.e., add the authorizer to the *existing* `qxbwx2qjq7` API Gateway that
`poke-ios-bridge` already uses. Doing that would require Poke's own calls to `/task` to start
carrying a Cognito JWT, which Poke has no way to do — it would break live Poke traffic. That
directly violates the standing rule to never modify or break `poke-ios-bridge`/`PokeTasks`. This
plan instead provisions a **brand-new, separate HTTP API** (`life-os-api-gw`) for all Stage B/C
traffic, with the JWT authorizer attached only there. `qxbwx2qjq7` and `poke-ios-bridge` are not
touched by anything in this document. `MIGRATION-SUPABASE-TO-AWS.md` should be updated to reflect
this once this block is reviewed.

---

## 1. What this builds

1. A **Cognito User Pool** (`adhd-lifeos-users`) — email/password auth, single admin-created user
   (E) — replaces Supabase Auth for the AWS side.
2. The **`LifeOS`** single-table DynamoDB table + two GSIs, per
   `MIGRATION-SUPABASE-TO-AWS.md` §3.2.
3. The **`life-os-api`** Lambda (Python 3.13) — full REST contract for tasks, life areas,
   captures, logs, nudges, tags, and the task↔tag junction. Source:
   `ADHD LifeOS/aws-backend/life-os-api/lambda_function.py` (already written, reviewed here,
   not yet deployed).
4. A **new HTTP API Gateway** (`life-os-api-gw`) with a Cognito JWT authorizer, routing to the
   Lambda above. Entirely separate from `qxbwx2qjq7`.

Nothing here touches Supabase, the existing Swift app, or Poke infrastructure. The app keeps
running exactly as it does today until Stage C explicitly swaps an adapter.

---

## 2. Data model — `LifeOS` table

```
PK  = USER#<userId>              (Cognito `sub`)
SK  = <ENTITY>#<id>               TASK#<uuid>, AREA#<uuid>, CAPTURE#<uuid>, LOG#<uuid>,
                                   NUDGE#<uuid>, TAG#<uuid>, TASKTAG#<taskId>#<tagId>

GSI1PK = USER#<userId>#AREA#<lifeAreaId>     (life-area scoping — tasks/logs only, when set)
GSI1SK = <ENTITY>#<createdAt>

GSI2PK = USER#<userId>#STATUS#<status>       (task status filter)
GSI2SK = TASK#<dueDate-or-createdAt>
```

Item attributes per entity mirror `ARCHITECTURE.md` §4's Swift structs and
`MIGRATION-SUPABASE-TO-AWS.md` §1.3 exactly — see the Lambda source for the authoritative field
list per entity (`create_task`, `create_capture`, etc.).

**Behavioural parity preserved, matching Supabase's current rules:**
- Tasks: no delete route (mirrors `public.tasks` having no delete RLS policy).
- Logs: create + list only, no update/delete route (append-only, mirrors `public.logs`).
- Life areas: no create/update route from the app — the fixed 9-row set is seeded once via CLI
  (§5 below), same one-off-manual-seed precedent Supabase itself used
  (`0004_seed_life_areas.sql`).
- Tag creation dedups server-side by exact-name match before inserting, mirroring the app's
  client-side dedup rule and standing in for the unique constraint Postgres enforced
  (`unique(user_id, name)`) — DynamoDB has no native equivalent outside the key, so this is a
  scan-then-check, not airtight under concurrent identical creates. Acceptable for a single-user
  v1 app; flagged in the Lambda source as a known limitation, not a bug.

---

## 3. REST contract (`life-os-api-gw`, JWT-protected, all routes)

| Method | Path | Purpose |
|---|---|---|
| GET | `/tasks` | List all tasks for the caller. Optional `?status=open\|done`. |
| POST | `/tasks` | Create a task. `title` required, `status` always starts `open`. |
| GET | `/tasks/{id}` | Fetch one task. |
| PATCH | `/tasks/{id}` | Partial update (title/notes/lifeAreaId/priority/dueDate/status). |
| GET | `/tasks/{id}/tags` | Tags currently attached to a task. |
| POST | `/tasks/{id}/tags` | Attach a tag (`{"tagId": "..."}`). |
| DELETE | `/tasks/{id}/tags/{tagId}` | Detach a tag. |
| GET | `/life-areas` | List the 9 seeded life areas, sorted by `sortOrder`. |
| POST | `/captures` | Create a capture. |
| GET | `/captures` | List captures. Optional `?processed=false`. |
| GET | `/captures/{id}` | Fetch one capture (used before promote-to-task, matching the existing conflict check). |
| PATCH | `/captures/{id}` | Mark processed (`{"processed": true}`). |
| POST | `/logs` | Create a log/journal entry. |
| GET | `/logs` | List all logs (client filters by life area, matching Journal's existing pattern). |
| GET | `/nudges` | List nudges. |
| POST | `/nudges` | Create a nudge. |
| PATCH | `/nudges/{id}` | Update (schedule/label/active) or mark fired (`lastFiredAt`). |
| GET | `/tags` | List tags, each with `taskCount`, `captureCount`, `usageCount` (their sum; `0` when unused). |
| POST | `/tags` | Create (or return existing, deduped) a tag. |
| PATCH | `/tags/{id}` | Rename (`{"name":"..."}`). On a name clash with a different tag: `409` carrying the conflicting tag's `id`/`name`/`usageCount`, or, with `{"onConflict":"merge"}`, re-points every junction row to the survivor (dedup where an item carries both), deletes the loser, returns `200`. `400` empty name / bad `onConflict`; `404` unknown id; `200` no-op on unchanged name. |
| DELETE | `/tags/{id}` | Cascade delete: removes the tag and every `TASKTAG#*#<id>` / `CAPTURETAG#*#<id>` junction row. `204`; `404` unknown id. |

Every route requires `Authorization: Bearer <Cognito ID token>`. There is no unauthenticated
route in this API — unlike `poke-ios-bridge`, this is not meant to be public.

---

## 4. Cognito setup (run by E, `us-east-1`)

```bash
# 1. User pool — single admin-created user, no public self-signup, email/password only.
aws cognito-idp create-user-pool \
  --pool-name adhd-lifeos-users \
  --auto-verified-attributes email \
  --username-attributes email \
  --policies '{"PasswordPolicy":{"MinimumLength":10,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
  --mfa-configuration OFF \
  --admin-create-user-config '{"AllowAdminCreateUserOnly":true}' \
  --region us-east-1
# → note the returned "Id" as $USER_POOL_ID

# 2. App client — public/native client, no secret (mobile apps can't hold one safely),
#    USER_PASSWORD_AUTH enabled explicitly (Cognito app clients default to SRP-only).
aws cognito-idp create-user-pool-client \
  --user-pool-id $USER_POOL_ID \
  --client-name adhd-lifeos-ios \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --access-token-validity 60 --id-token-validity 60 --refresh-token-validity 30 \
  --token-validity-units '{"AccessToken":"minutes","IdToken":"minutes","RefreshToken":"days"}' \
  --region us-east-1
# → note the returned "ClientId" as $APP_CLIENT_ID

# 3. Create the one v1 user (E) directly — no signup screen needed for a single-user app.
#    --message-action SUPPRESS skips Cognito's default invite email.
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username ethanant@icloud.com \
  --user-attributes Name=email,Value=ethanant@icloud.com Name=email_verified,Value=true \
  --message-action SUPPRESS \
  --region us-east-1

# 4. Set a permanent password yourself — replace the placeholder below before running.
#    Do not paste the real password back into this chat.
aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username ethanant@icloud.com \
  --password 'REPLACE_ME_WITH_A_REAL_PASSWORD' \
  --permanent \
  --region us-east-1
```

**Verify sign-in works before continuing:**

```bash
aws cognito-idp initiate-auth \
  --client-id $APP_CLIENT_ID \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=ethanant@icloud.com,PASSWORD='<the password you set>' \
  --region us-east-1
```

This should return `AuthenticationResult.IdToken` (a JWT) — save one for testing §7. If this
step fails, stop and paste the error rather than continuing to provision the rest.

---

## 5. `LifeOS` DynamoDB table

```bash
aws dynamodb create-table \
  --table-name LifeOS \
  --attribute-definitions \
      AttributeName=PK,AttributeType=S \
      AttributeName=SK,AttributeType=S \
      AttributeName=GSI1PK,AttributeType=S \
      AttributeName=GSI1SK,AttributeType=S \
      AttributeName=GSI2PK,AttributeType=S \
      AttributeName=GSI2SK,AttributeType=S \
  --key-schema AttributeName=PK,KeyType=HASH AttributeName=SK,KeyType=RANGE \
  --global-secondary-indexes '[
    {"IndexName":"GSI1","KeySchema":[{"AttributeName":"GSI1PK","KeyType":"HASH"},{"AttributeName":"GSI1SK","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}},
    {"IndexName":"GSI2","KeySchema":[{"AttributeName":"GSI2PK","KeyType":"HASH"},{"AttributeName":"GSI2SK","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}
  ]' \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

**Seed the 9 life areas once** (replace `$USER_SUB` with the Cognito `sub` claim from your
IdToken above — decode it at jwt.io or `aws cognito-idp admin-get-user` to find it). **Values
below are the real, live Supabase rows** (pulled via the Supabase MCP connector this session,
`select name, colour, sort_order from public.life_areas order by sort_order` against
`iuhmgpedtyikakppokwk`) — `colour` is an emoji character in the live schema, not a hex code:

```bash
NOW=$(date -u +%Y-%m-%dT%H:%M:%S)
declare -a AREAS=(
  "Work:💼:1" "Personal:🌱:2" "Family:👨‍👩‍👧:3" "Health:🫀:4" "Projects:🛠️:5"
  "Hobbies:🎨:6" "Admin:🗂️:7" "Journals:📓:8" "Home:🏠:9"
)
for area in "${AREAS[@]}"; do
  IFS=':' read -r NAME COLOUR SORT <<< "$area"
  ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
  aws dynamodb put-item --table-name LifeOS --region us-east-1 --item "{
    \"PK\": {\"S\": \"USER#$USER_SUB\"}, \"SK\": {\"S\": \"AREA#$ID\"},
    \"entity\": {\"S\": \"AREA\"}, \"id\": {\"S\": \"$ID\"}, \"userId\": {\"S\": \"$USER_SUB\"},
    \"name\": {\"S\": \"$NAME\"}, \"colour\": {\"S\": \"$COLOUR\"}, \"sortOrder\": {\"N\": \"$SORT\"},
    \"createdAt\": {\"S\": \"$NOW\"}, \"updatedAt\": {\"S\": \"$NOW\"}
  }"
done
```

Note: the live query returned each of the 9 rows **twice** — this is expected, not a data bug.
Two Supabase users exist (E's original account and the `reckedgelato@gmail.com` test account
from FEATURE-M1), each auto-seeded their own 9-row set by the `auth.users` trigger
(`0009_seed_life_areas_on_signup.sql`), distinguished by `user_id`, which this query didn't
select. Only seed once per Cognito user (just E, for v1) — the loop above already does that.

---

## 6. IAM role + Lambda deploy

```bash
# IAM role for the Lambda
aws iam create-role \
  --role-name life-os-api-lambda-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws iam attach-role-policy \
  --role-name life-os-api-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam put-role-policy \
  --role-name life-os-api-lambda-role \
  --policy-name LifeOSTableAccess \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["dynamodb:GetItem","dynamodb:PutItem","dynamodb:UpdateItem","dynamodb:DeleteItem","dynamodb:Query"],"Resource":["arn:aws:dynamodb:us-east-1:891943683816:table/LifeOS","arn:aws:dynamodb:us-east-1:891943683816:table/LifeOS/index/*"]}]}'

# Package and deploy the Lambda (source already written, see §1)
cd "ADHD LifeOS/aws-backend/life-os-api"
zip lambda.zip lambda_function.py

aws lambda create-function \
  --function-name life-os-api \
  --runtime python3.13 \
  --role arn:aws:iam::891943683816:role/life-os-api-lambda-role \
  --handler lambda_function.handler \
  --zip-file fileb://lambda.zip \
  --timeout 10 \
  --memory-size 128 \
  --environment 'Variables={TABLE_NAME=LifeOS}' \
  --region us-east-1
```

IAM role creation can take a few seconds to propagate — if `create-function` fails with a
role-not-found-style error immediately after `create-role`, wait ~10 seconds and retry.

---

## 7. API Gateway — new HTTP API, JWT authorizer, routes

```bash
# New, separate HTTP API — qxbwx2qjq7/poke-ios-bridge is never touched by any of this.
aws apigatewayv2 create-api --name life-os-api-gw --protocol-type HTTP --region us-east-1
# → note "ApiId" as $API_ID

aws apigatewayv2 create-authorizer \
  --api-id $API_ID \
  --authorizer-type JWT \
  --identity-source '$request.header.Authorization' \
  --name cognito-jwt \
  --jwt-configuration Audience=$APP_CLIENT_ID,Issuer=https://cognito-idp.us-east-1.amazonaws.com/$USER_POOL_ID \
  --region us-east-1
# → note "AuthorizerId" as $AUTHORIZER_ID

aws apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type AWS_PROXY \
  --integration-uri arn:aws:lambda:us-east-1:891943683816:function:life-os-api \
  --payload-format-version 2.0 \
  --region us-east-1
# → note "IntegrationId" as $INTEGRATION_ID

# One route per method+path from §3's table — every one JWT-protected.
for ROUTE in \
  "GET /tasks" "POST /tasks" "GET /tasks/{id}" "PATCH /tasks/{id}" \
  "GET /tasks/{id}/tags" "POST /tasks/{id}/tags" "DELETE /tasks/{id}/tags/{tagId}" \
  "GET /life-areas" \
  "POST /captures" "GET /captures" "GET /captures/{id}" "PATCH /captures/{id}" \
  "POST /logs" "GET /logs" \
  "GET /nudges" "POST /nudges" "PATCH /nudges/{id}" \
  "GET /tags" "POST /tags" "PATCH /tags/{id}" "DELETE /tags/{id}"
do
  aws apigatewayv2 create-route \
    --api-id $API_ID \
    --route-key "$ROUTE" \
    --target "integrations/$INTEGRATION_ID" \
    --authorization-type JWT \
    --authorizer-id $AUTHORIZER_ID \
    --region us-east-1
done

aws apigatewayv2 create-stage --api-id $API_ID --stage-name prod --auto-deploy --region us-east-1

aws lambda add-permission \
  --function-name life-os-api \
  --statement-id apigw-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:891943683816:$API_ID/*/*" \
  --region us-east-1
```

Your invoke URL will be `https://$API_ID.execute-api.us-east-1.amazonaws.com/prod`.

---

## 8. Verification (before calling this done)

```bash
TOKEN='<the IdToken from §4>'
BASE='https://<your API_ID>.execute-api.us-east-1.amazonaws.com/prod'

# No token → expect 401
curl -i "$BASE/tasks"

# With token → expect 200, empty list first run
curl -i "$BASE/tasks" -H "Authorization: Bearer $TOKEN"

# Life areas → expect the 9 seeded rows, sorted
curl -i "$BASE/life-areas" -H "Authorization: Bearer $TOKEN"

# Create a task → expect 201 with the full item back
curl -i -X POST "$BASE/tasks" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"title":"Stage B smoke test"}'
```

Paste the results back and Cowork will review them the same way every prior feature's live
verification was reviewed — actual response bodies, not "it worked."

---

## 9. What's explicitly NOT in this block

- **No Stage C adapter cutovers.** The Swift app is completely untouched by this document — it
  still talks to Supabase for everything. Stage C is the next design phase, one `AWS*ClientAdapter`
  FEATURE block at a time, per `MIGRATION-SUPABASE-TO-AWS.md` §4's order (Auth → Home → Tasks →
  Capture → Journal → LifeAreaDetail → Nudges).
- **No Cognito passwordless/magic-link.** Email/password only, per the confirmed decision above.
- **No data migration from Supabase.** Stage D, still deferred.
- **`poke-ios-bridge`, `PokeTasks`, `qxbwx2qjq7`, `life-os-writer-mcp` are not modified,
  redeployed, or written to anywhere in this document.**

---

## 10. Open items — none blocking

The life-area values in §5 are the real, verified Supabase rows (pulled this session) — nothing
outstanding before this can be run. Only remaining judgment call is timing: run whenever you're
ready, section by section, and paste back output/errors as you go rather than running all of
§4–§7 unattended, since each section depends on IDs captured from the previous one.
