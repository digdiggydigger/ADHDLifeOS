#!/usr/bin/env bash
# Tag Editor backend block — end-to-end smoke test of the live tag routes:
#   GET /tags (usage counts), PATCH /tags/{id} (rename + 409 conflict + merge), DELETE /tags/{id}
# Modelled on smoke_test_capture.sh / smoke_test_auth.sh.
#
# The password is NEVER hardcoded and NEVER echoed. Provide it via AUTH_PW, or you will be
# prompted (hidden input). A pre-obtained Cognito ID token in TOKEN skips the password entirely.
#
#   export AUTH_PW='...'            # optional; else prompted
#   bash smoke_test_tags.sh
#
# Creates its own throwaway rows (all named "zz-smoke-*"). It cleans up every tag it creates via
# the new DELETE route. The one/two throwaway task+capture rows it needs cannot be deleted (there
# is no delete route for tasks/captures by design, same as smoke_test_capture.sh) — they are left
# marked done/processed so they do not clutter active views.
set -u

GW="${GW:-https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod}"
USER_EMAIL="${USER_EMAIL:-ethanant@icloud.com}"
CLIENT_ID="${CLIENT_ID:-57v25l4t62spds2qkvkhtbq0ae}"
REGION="${REGION:-us-east-1}"
export AWS_PAGER=""

pass=0; fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }
eq()   { if [ "$1" = "$2" ]; then ok "$3 ($1)"; else bad "$3 (got '$1', want '$2')"; fi; }
nonempty() { if [ -n "$1" ]; then ok "$2"; else bad "$2 (empty)"; fi; }
jf()   { printf '%s' "$1" | python3 -c "import sys,json;print(json.load(sys.stdin).get('$2',''))" 2>/dev/null; }
# usage field for a given tag id from a GET /tags body: jusage "$BODY" "$TID" usageCount
jusage() { printf '%s' "$1" | python3 -c "import sys,json
tid,field=sys.argv[1],sys.argv[2]
tags=json.load(sys.stdin).get('tags',[])
m={t['id']:t for t in tags}
print(m.get(tid,{}).get(field,'MISSING'))" "$2" "$3" 2>/dev/null; }
# does a GET /tags body still contain tag id? -> True/False
jhas_tag() { printf '%s' "$1" | python3 -c "import sys,json;print(any(t.get('id')==sys.argv[1] for t in json.load(sys.stdin).get('tags',[])))" "$2" 2>/dev/null; }
# count of rows for a tag id in a {'tags':[...]} item-tag body (list_task_tags / list_capture_tags)
jcount_tag() { printf '%s' "$1" | python3 -c "import sys,json;print(sum(1 for t in json.load(sys.stdin).get('tags',[]) if t.get('id')==sys.argv[1]))" "$2" 2>/dev/null; }
# nested conflict field: jconf "$BODY" id|name|usageCount
jconf() { printf '%s' "$1" | python3 -c "import sys,json;print(json.load(sys.stdin).get('conflict',{}).get('$2',''))" 2>/dev/null; }
# nested merge stat: jmerge "$BODY" tasksRepointed ...
jmerge() { printf '%s' "$1" | python3 -c "import sys,json;print(json.load(sys.stdin).get('merge',{}).get('$2',''))" 2>/dev/null; }
jtagid() { printf '%s' "$1" | python3 -c "import sys,json;print(json.load(sys.stdin).get('tag',{}).get('id',''))" 2>/dev/null; }

# req METHOD PATH [DATA] -> sets CODE, BODY (authenticated)
req() {
  local m="$1" p="$2" d="${3:-}" out
  if [ -n "$d" ]; then
    out=$(curl -s -w $'\n%{http_code}' -X "$m" "$GW$p" -H "$AUTH" -H "$JSON" -d "$d")
  else
    out=$(curl -s -w $'\n%{http_code}' -X "$m" "$GW$p" -H "$AUTH")
  fi
  CODE="${out##*$'\n'}"; BODY="${out%$'\n'*}"
}

# ---- unauthenticated authorizer check (no token needed) --------------------
FAKE="00000000-0000-0000-0000-000000000000"
echo "== 0. unauthenticated new routes must 401 (JWT authorizer attached)"
eq "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$GW/tags/$FAKE" -H 'Content-Type: application/json' -d '{"name":"x"}')" 401 "PATCH /tags/{id} unauth -> 401"
eq "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$GW/tags/$FAKE")" 401 "DELETE /tags/{id} unauth -> 401"

# ---- obtain token ----------------------------------------------------------
if [ -z "${TOKEN:-}" ]; then
  if [ -z "${AUTH_PW:-}" ]; then
    read -r -s -p "Cognito password for $USER_EMAIL (hidden): " AUTH_PW; echo
  fi
  TOKEN=$(aws cognito-idp initiate-auth --region "$REGION" \
    --auth-flow USER_PASSWORD_AUTH --client-id "$CLIENT_ID" \
    --auth-parameters USERNAME="$USER_EMAIL",PASSWORD="$AUTH_PW" \
    --query 'AuthenticationResult.IdToken' --output text 2>/dev/null)
fi
if [ -z "$TOKEN" ] || [ "$TOKEN" = "None" ]; then
  echo "FATAL: could not obtain a Cognito ID token (bad password or client id)."; exit 2
fi
AUTH="Authorization: Bearer $TOKEN"
JSON="Content-Type: application/json"

SUF="$(date +%s)-$$"
LOSER="zz-smoke-loser-$SUF"
SURV="zz-smoke-surv-$SUF"
UNUSED="zz-smoke-unused-$SUF"
FREE="zz-smoke-free-$SUF"
FREE2="zz-smoke-free2-$SUF"

# ---- setup: two tasks, two captures, four tags -----------------------------
echo "== 1. setup rows"
req POST "/tasks" "{\"title\":\"zz-smoke-task1-$SUF\"}"; T1=$(jf "$BODY" id); nonempty "$T1" "task T1 created"
req POST "/tasks" "{\"title\":\"zz-smoke-task2-$SUF\"}"; T2=$(jf "$BODY" id); nonempty "$T2" "task T2 created"
req POST "/captures" "{\"kind\":\"note\",\"content\":\"zz-smoke-cap1-$SUF\"}"; C1=$(jf "$BODY" id); nonempty "$C1" "capture C1 created"
req POST "/captures" "{\"kind\":\"note\",\"content\":\"zz-smoke-cap2-$SUF\"}"; C2=$(jf "$BODY" id); nonempty "$C2" "capture C2 created"
req POST "/tags" "{\"name\":\"$LOSER\"}";  L_ID=$(jf "$BODY" id); nonempty "$L_ID" "loser tag created"
req POST "/tags" "{\"name\":\"$SURV\"}";   S_ID=$(jf "$BODY" id); nonempty "$S_ID" "survivor tag created"
req POST "/tags" "{\"name\":\"$UNUSED\"}"; U_ID=$(jf "$BODY" id); nonempty "$U_ID" "unused tag created"
req POST "/tags" "{\"name\":\"$FREE\"}";   F_ID=$(jf "$BODY" id); nonempty "$F_ID" "free tag created"

# Attach: T1=loser+surv (dedup), T2=loser+free, C1=loser, C2=loser+surv (dedup)
echo "== 2. attach tags"
req POST "/tasks/$T1/tags"    "{\"tagId\":\"$L_ID\"}"; eq "$CODE" 201 "T1 <- loser"
req POST "/tasks/$T1/tags"    "{\"tagId\":\"$S_ID\"}"; eq "$CODE" 201 "T1 <- surv"
req POST "/tasks/$T2/tags"    "{\"tagId\":\"$L_ID\"}"; eq "$CODE" 201 "T2 <- loser"
req POST "/tasks/$T2/tags"    "{\"tagId\":\"$F_ID\"}"; eq "$CODE" 201 "T2 <- free"
req POST "/captures/$C1/tags" "{\"tagId\":\"$L_ID\"}"; eq "$CODE" 201 "C1 <- loser"
req POST "/captures/$C2/tags" "{\"tagId\":\"$L_ID\"}"; eq "$CODE" 201 "C2 <- loser"
req POST "/captures/$C2/tags" "{\"tagId\":\"$S_ID\"}"; eq "$CODE" 201 "C2 <- surv"

# ---- criterion: usage counts ----------------------------------------------
echo "== 3. GET /tags usage counts"
req GET "/tags"; eq "$CODE" 200 "GET /tags 200"
eq "$(jusage "$BODY" "$L_ID" taskCount)"    2 "loser taskCount"
eq "$(jusage "$BODY" "$L_ID" captureCount)" 2 "loser captureCount"
eq "$(jusage "$BODY" "$L_ID" usageCount)"   4 "loser usageCount"
eq "$(jusage "$BODY" "$S_ID" usageCount)"   2 "surv usageCount"
eq "$(jusage "$BODY" "$U_ID" taskCount)"    0 "unused taskCount = 0"
eq "$(jusage "$BODY" "$U_ID" captureCount)" 0 "unused captureCount = 0"
eq "$(jusage "$BODY" "$U_ID" usageCount)"   0 "unused usageCount = 0"

# ---- criterion: PATCH edge cases ------------------------------------------
echo "== 4. PATCH edge cases"
req PATCH "/tags/$L_ID" "{\"name\":\"$LOSER\"}";                       eq "$CODE" 200 "no-op unchanged name -> 200"
req PATCH "/tags/$L_ID" "{\"name\":\"   \"}";                          eq "$CODE" 400 "empty name -> 400"
req PATCH "/tags/$L_ID" "{\"name\":\"$SURV\",\"onConflict\":\"nope\"}"; eq "$CODE" 400 "bad onConflict -> 400"
req PATCH "/tags/$FAKE" "{\"name\":\"whatever\"}";                     eq "$CODE" 404 "PATCH unknown id -> 404"
req DELETE "/tags/$FAKE";                                              eq "$CODE" 404 "DELETE unknown id -> 404"

# ---- criterion: free rename leaves junction rows intact --------------------
echo "== 5. free rename (used tag) keeps its junction rows"
req PATCH "/tags/$F_ID" "{\"name\":\"$FREE2\"}"; eq "$CODE" 200 "free rename -> 200"
eq "$(jf "$BODY" name)" "$FREE2" "renamed tag name updated"
req GET "/tasks/$T2/tags"; eq "$(jcount_tag "$BODY" "$F_ID")" 1 "T2 still carries the renamed tag (same id)"

# ---- criterion: collision 409 writes nothing ------------------------------
echo "== 6. collision without onConflict -> 409, writes nothing"
req PATCH "/tags/$L_ID" "{\"name\":\"$SURV\"}"; eq "$CODE" 409 "collision -> 409"
eq "$(jconf "$BODY" id)"         "$S_ID" "409 conflict.id = survivor"
eq "$(jconf "$BODY" name)"       "$SURV" "409 conflict.name = survivor name"
eq "$(jconf "$BODY" usageCount)" 2       "409 conflict.usageCount = 2"
req GET "/tags"
eq "$(jhas_tag "$BODY" "$L_ID")" True "loser still exists after 409 (no write)"
eq "$(jusage "$BODY" "$L_ID" usageCount)" 4 "loser usageCount unchanged after 409"
eq "$(jusage "$BODY" "$S_ID" usageCount)" 2 "surv usageCount unchanged after 409"

# ---- criterion: merge (repoint + dedup) -----------------------------------
echo "== 7. merge: onConflict=merge"
req PATCH "/tags/$L_ID" "{\"name\":\"$SURV\",\"onConflict\":\"merge\"}"; eq "$CODE" 200 "merge -> 200"
eq "$(jtagid "$BODY")" "$S_ID" "merge returns survivor tag"
echo "  merge stats: repointed tasks=$(jmerge "$BODY" tasksRepointed) captures=$(jmerge "$BODY" capturesRepointed); deduped tasks=$(jmerge "$BODY" tasksDeduped) captures=$(jmerge "$BODY" capturesDeduped)"
eq "$(jmerge "$BODY" tasksRepointed)"    1 "merge tasksRepointed (T2)"
eq "$(jmerge "$BODY" tasksDeduped)"      1 "merge tasksDeduped (T1)"
eq "$(jmerge "$BODY" capturesRepointed)" 1 "merge capturesRepointed (C1)"
eq "$(jmerge "$BODY" capturesDeduped)"   1 "merge capturesDeduped (C2)"
req GET "/tags"
eq "$(jhas_tag "$BODY" "$L_ID")" False "loser tag deleted after merge"
eq "$(jusage "$BODY" "$S_ID" taskCount)"    2 "surv taskCount after merge = 2 (deduped, not 3)"
eq "$(jusage "$BODY" "$S_ID" captureCount)" 2 "surv captureCount after merge = 2 (deduped, not 3)"
eq "$(jusage "$BODY" "$S_ID" usageCount)"   4 "surv usageCount after merge = 4 (deduped, not 6)"
echo "  -- dedup proof: T1 carried BOTH tags, must end with exactly ONE survivor row"
req GET "/tasks/$T1/tags"; eq "$(jcount_tag "$BODY" "$S_ID")" 1 "T1 has exactly one survivor row"
eq "$(jcount_tag "$BODY" "$L_ID")" 0 "T1 no longer carries loser"
req GET "/tasks/$T2/tags";    eq "$(jcount_tag "$BODY" "$S_ID")" 1 "T2 repointed to survivor"
req GET "/captures/$C1/tags"; eq "$(jcount_tag "$BODY" "$S_ID")" 1 "C1 repointed to survivor"
req GET "/captures/$C2/tags"; eq "$(jcount_tag "$BODY" "$S_ID")" 1 "C2 has exactly one survivor row (deduped)"

# ---- criterion: cascade delete --------------------------------------------
echo "== 8. cascade delete survivor"
req DELETE "/tags/$S_ID"; eq "$CODE" 204 "DELETE survivor -> 204"
req GET "/tags"; eq "$(jhas_tag "$BODY" "$S_ID")" False "survivor gone from GET /tags"
req GET "/tasks/$T1/tags";    eq "$(jcount_tag "$BODY" "$S_ID")" 0 "T1 no longer lists survivor"
req GET "/tasks/$T2/tags";    eq "$(jcount_tag "$BODY" "$S_ID")" 0 "T2 no longer lists survivor"
req GET "/captures/$C1/tags"; eq "$(jcount_tag "$BODY" "$S_ID")" 0 "C1 no longer lists survivor"
req GET "/captures/$C2/tags"; eq "$(jcount_tag "$BODY" "$S_ID")" 0 "C2 no longer lists survivor"

# ---- cleanup ---------------------------------------------------------------
echo "== 9. cleanup (delete every smoke tag; mark tasks/captures done/processed)"
for TID in "$U_ID" "$F_ID"; do req DELETE "/tags/$TID"; done   # loser+surv already gone
req GET "/tags"
leftover=0
for TID in "$L_ID" "$S_ID" "$U_ID" "$F_ID"; do
  if [ "$(jhas_tag "$BODY" "$TID")" = "True" ]; then bad "smoke tag $TID left behind"; leftover=$((leftover+1)); fi
done
[ "$leftover" -eq 0 ] && ok "all smoke tags removed"
req PATCH "/tasks/$T1" '{"status":"done"}' >/dev/null 2>&1
req PATCH "/tasks/$T2" '{"status":"done"}' >/dev/null 2>&1
req PATCH "/captures/$C1" '{"status":"processed"}' >/dev/null 2>&1
req PATCH "/captures/$C2" '{"status":"processed"}' >/dev/null 2>&1
echo "  (throwaway task/capture rows T1/T2/C1/C2 marked done/processed — no delete route by design)"

echo
echo "================ RESULT: $pass passed, $fail failed ================"
[ "$fail" -eq 0 ] || exit 1
