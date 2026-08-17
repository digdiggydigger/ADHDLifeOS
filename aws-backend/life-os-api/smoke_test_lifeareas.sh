#!/usr/bin/env bash
# Life Areas backend block — end-to-end smoke test of the live life-area routes:
#   GET /life-areas (archived flag), POST /life-areas (create + 409),
#   PATCH /life-areas/{id} (rename/colour/archived + 409 + 404 + 400 edges),
#   PATCH /life-areas/reorder (bulk reorder + set-equality 400s + the reorder-vs-{id} routing proof)
# Modelled on smoke_test_tags.sh.
#
# The password is NEVER hardcoded and NEVER echoed. Provide it via AUTH_PW, or you will be
# prompted (hidden input). A pre-obtained Cognito ID token in TOKEN skips the password entirely.
#
#   export AUTH_PW='...'            # optional; else prompted
#   bash smoke_test_lifeareas.sh
#
# PROTECTING E'S REAL DATA — read this before running:
#   * All throwaway rows are named "zz-la-*". Every destructive create/patch/archive acts only on
#     those. E's nine real areas are NEVER renamed/archived on their own.
#   * The reorder route needs the WHOLE current id set in one payload, so proving it unavoidably
#     rewrites every area's sortOrder (E's nine included) — the block explicitly permits this as a
#     "restored-in-the-same-run reorder proof". The reorder route is 0-indexed; E's real rows use a
#     legacy 1..9 sortOrder that a 0-indexed reorder cannot reproduce, so cleanup restores the nine
#     real rows to their EXACT pre-run bytes via a direct DynamoDB put-item of a snapshot taken
#     before any write (not via the route). Throwaways are hard-deleted the same way (there is no
#     DELETE route for life areas by design — archive-not-delete, §8).
#   * Because of that, the runner needs AWS creds with dynamodb:Scan/PutItem/DeleteItem on the
#     LifeOS table IN ADDITION to a Cognito login — the same identity that runs `aws cognito-idp`
#     below. The script aborts early if either is missing.
set -u

GW="${GW:-https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod}"
USER_EMAIL="${USER_EMAIL:-ethanant@icloud.com}"
CLIENT_ID="${CLIENT_ID:-57v25l4t62spds2qkvkhtbq0ae}"
REGION="${REGION:-us-east-1}"
TABLE="${TABLE:-LifeOS}"
export AWS_PAGER=""
# python3 with boto3 is not needed here; plain python3 is only used as a JSON tool.
PY="${PY:-python3}"

pass=0; fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }
eq()   { if [ "$1" = "$2" ]; then ok "$3 ($1)"; else bad "$3 (got '$1', want '$2')"; fi; }
nonempty() { if [ -n "$1" ] && [ "$1" != "None" ]; then ok "$2"; else bad "$2 (empty)"; fi; }

jf()   { printf '%s' "$1" | "$PY" -c "import sys,json;print(json.load(sys.stdin).get('$2',''))" 2>/dev/null; }
# field of the area with a given id inside a {'lifeAreas':[...]} body
jarea() { printf '%s' "$1" | "$PY" -c "import sys,json
aid,field=sys.argv[1],sys.argv[2]
m={a['id']:a for a in json.load(sys.stdin).get('lifeAreas',[])}
print(m.get(aid,{}).get(field,'MISSING'))" "$2" "$3" 2>/dev/null; }
jhas_area() { printf '%s' "$1" | "$PY" -c "import sys,json;print(any(a.get('id')==sys.argv[1] for a in json.load(sys.stdin).get('lifeAreas',[])))" "$2" 2>/dev/null; }
# comma-joined id order from a {'lifeAreas':[...]} body (already sorted by sortOrder server-side)
jorder() { printf '%s' "$1" | "$PY" -c "import sys,json;print(','.join(a['id'] for a in json.load(sys.stdin).get('lifeAreas',[])))" 2>/dev/null; }
# nested conflict field: jconf "$BODY" id|name
jconf() { printf '%s' "$1" | "$PY" -c "import sys,json;print(json.load(sys.stdin).get('conflict',{}).get('$2',''))" 2>/dev/null; }
# max sortOrder across NON-throwaway areas in a GET body
jmax_sort() { printf '%s' "$1" | "$PY" -c "import sys,json
areas=json.load(sys.stdin).get('lifeAreas',[])
print(max((int(a['sortOrder']) for a in areas), default=0))" 2>/dev/null; }

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
echo "== 0. unauthenticated new routes must 401 (JWT authorizer attached & route registered)"
eq "$(curl -s -o /dev/null -w '%{http_code}' -X POST  "$GW/life-areas"          -H 'Content-Type: application/json' -d '{"name":"x","colour":"x"}')" 401 "POST /life-areas unauth -> 401"
eq "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$GW/life-areas/$FAKE"     -H 'Content-Type: application/json' -d '{"name":"x"}')"             401 "PATCH /life-areas/{id} unauth -> 401"
eq "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$GW/life-areas/reorder"   -H 'Content-Type: application/json' -d '{"order":[]}')"            401 "PATCH /life-areas/reorder unauth -> 401"
# contrast: an unregistered path is 404, so the 401s above genuinely mean "registered", not "gateway rejects everything"
eq "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$GW/life-areas/$FAKE")" 404 "DELETE /life-areas/{id} -> 404 (no delete route by design)"

# ---- preflight: AWS creds for snapshot/restore -----------------------------
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "FATAL: no AWS credentials — cleanup/restore of E's real areas needs dynamodb access."; exit 2
fi

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

USER_ID=$(printf '%s' "$TOKEN" | "$PY" -c "import sys,json,base64
p=sys.stdin.read().split('.')[1]; p+='='*(-len(p)%4)
print(json.loads(base64.urlsafe_b64decode(p))['sub'])" 2>/dev/null)
nonempty "$USER_ID" "decoded Cognito sub from token"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SUF="$(date +%s)-$$"
A_NAME="zz-la-alpha-$SUF"
B_NAME="zz-la-beta-$SUF"

# ---- BEFORE snapshots ------------------------------------------------------
# (a) raw DynamoDB snapshot of every real area — used to restore EXACT bytes at the end.
echo "== 1. snapshot E's real areas (raw DynamoDB, for byte-identical restore)"
aws dynamodb scan --table-name "$TABLE" --region "$REGION" \
  --filter-expression "entity = :e" --expression-attribute-values '{":e":{"S":"AREA"}}' \
  --output json > "$TMP/scan_before.json" 2>/dev/null
"$PY" -c "import json
items=json.load(open('$TMP/scan_before.json'))['Items']
real=[i for i in items if not i['name']['S'].startswith('zz-la-')]
json.dump(real, open('$TMP/real_before.json','w'), sort_keys=True)
print('  real area count:', len(real))
print('  names:', sorted(i['name']['S'] for i in real))"
# (b) human-readable GET before — pasted in the report as the 'before' side of the diff.
req GET "/life-areas"; eq "$CODE" 200 "GET /life-areas 200"
echo "  --- GET /life-areas BEFORE (name, sortOrder, archived) ---"
printf '%s' "$BODY" | "$PY" -c "import sys,json
for a in json.load(sys.stdin)['lifeAreas']:
    print('    %-14s sort=%-2s archived=%s' % (a['name'], a['sortOrder'], a['archived']))"
BEFORE_ORDER="$(jorder "$BODY")"

echo "== 2. GET: every area carries archived:false, still sorted by sortOrder"
req GET "/life-areas"
REAL_N=$(printf '%s' "$BODY" | "$PY" -c "import sys,json;print(sum(1 for a in json.load(sys.stdin)['lifeAreas'] if not a['name'].startswith('zz-la-')))")
eq "$REAL_N" 9 "9 real areas returned"
ALL_FALSE=$(printf '%s' "$BODY" | "$PY" -c "import sys,json;print(all(a.get('archived') is False for a in json.load(sys.stdin)['lifeAreas']))")
eq "$ALL_FALSE" True "every returned area has archived:false"
SORTED_OK=$(printf '%s' "$BODY" | "$PY" -c "import sys,json
s=[int(a['sortOrder']) for a in json.load(sys.stdin)['lifeAreas']];print(s==sorted(s))")
eq "$SORTED_OK" True "areas returned in sortOrder order"
MAXSORT="$(jmax_sort "$BODY")"

# ---- create --------------------------------------------------------------
echo "== 3. POST create two throwaway areas"
req POST "/life-areas" "{\"name\":\"$A_NAME\",\"colour\":\"🅰️\"}"; eq "$CODE" 201 "POST zz-la-alpha -> 201"
A_ID=$(jf "$BODY" id); nonempty "$A_ID" "alpha got a fresh id"
eq "$(jf "$BODY" archived)" "False" "alpha archived:false on create"
eq "$(jf "$BODY" sortOrder)" "$((MAXSORT+1))" "alpha sortOrder = prev max + 1"
req POST "/life-areas" "{\"name\":\"$B_NAME\",\"colour\":\"🅱️\"}"; eq "$CODE" 201 "POST zz-la-beta -> 201"
B_ID=$(jf "$BODY" id); nonempty "$B_ID" "beta got a fresh id"
eq "$(jf "$BODY" sortOrder)" "$((MAXSORT+2))" "beta sortOrder = prev max + 2"

echo "== 4. POST duplicate name (an existing REAL area name) -> 409, creates nothing"
req GET "/life-areas"; EXISTING_NAME=$(printf '%s' "$BODY" | "$PY" -c "import sys,json
print(next(a['name'] for a in json.load(sys.stdin)['lifeAreas'] if not a['name'].startswith('zz-la-')))")
EXISTING_ID=$(printf '%s' "$BODY" | "$PY" -c "import sys,json
print(next(a['id'] for a in json.load(sys.stdin)['lifeAreas'] if a['name']==sys.argv[1]))" "$EXISTING_NAME")
req POST "/life-areas" "{\"name\":\"$EXISTING_NAME\",\"colour\":\"❌\"}"
eq "$CODE" 409 "POST duplicate name -> 409"
eq "$(jconf "$BODY" id)"   "$EXISTING_ID"   "409 conflict.id = existing area"
eq "$(jconf "$BODY" name)" "$EXISTING_NAME" "409 conflict.name = existing name"
req GET "/life-areas"
CREATED_COUNT=$(printf '%s' "$BODY" | "$PY" -c "import sys,json
print(sum(1 for a in json.load(sys.stdin)['lifeAreas'] if a['name']=='$EXISTING_NAME'))")
eq "$CREATED_COUNT" 1 "still exactly one '$EXISTING_NAME' after 409 (nothing created)"

echo "== 4b. archived-name reservation: 409 conflict carries archived:true, nothing created"
ARCH_NAME="zz-la-arch-$SUF"
req POST "/life-areas" "{\"name\":\"$ARCH_NAME\",\"colour\":\"📦\"}"; eq "$CODE" 201 "create zz-la-arch -> 201"
ARCH_ID=$(jf "$BODY" id); nonempty "$ARCH_ID" "arch area id"
req PATCH "/life-areas/$ARCH_ID" '{"archived":true}'; eq "$CODE" 200 "archive it -> 200"
req POST "/life-areas" "{\"name\":\"$ARCH_NAME\",\"colour\":\"🆕\"}"
eq "$CODE" 409 "POST onto archived name -> 409"
eq "$(jconf "$BODY" id)"       "$ARCH_ID" "409 conflict.id = the archived area"
eq "$(jconf "$BODY" archived)" "True"     "409 conflict.archived == true"
req GET "/life-areas"
ARCH_COUNT=$(printf '%s' "$BODY" | "$PY" -c "import sys,json;print(sum(1 for a in json.load(sys.stdin)['lifeAreas'] if a['name']=='$ARCH_NAME'))")
eq "$ARCH_COUNT" 1 "still exactly one '$ARCH_NAME' (nothing created)"
# and the PATCH-rename path reports it too
req PATCH "/life-areas/$A_ID" "{\"name\":\"$ARCH_NAME\"}"
eq "$CODE" 409 "PATCH-rename onto archived name -> 409"
eq "$(jconf "$BODY" archived)" "True" "PATCH 409 conflict.archived == true"

# ---- patch: rename / colour / archived -----------------------------------
echo "== 5. PATCH rename + colour"
req PATCH "/life-areas/$A_ID" "{\"name\":\"$A_NAME-renamed\"}"; eq "$CODE" 200 "rename -> 200"
req GET "/life-areas"; eq "$(jarea "$BODY" "$A_ID" name)" "$A_NAME-renamed" "GET reflects new name"
req PATCH "/life-areas/$A_ID" '{"colour":"🔵"}'; eq "$CODE" 200 "colour (emoji) -> 200"
req GET "/life-areas"; eq "$(jarea "$BODY" "$A_ID" colour)" "🔵" "GET reflects new emoji"

echo "== 6. PATCH archived round-trip (still returned by GET when archived)"
req PATCH "/life-areas/$A_ID" '{"archived":true}'; eq "$CODE" 200 "archived:true -> 200"
req GET "/life-areas"
eq "$(jhas_area "$BODY" "$A_ID")" True "archived area STILL returned by GET"
eq "$(jarea "$BODY" "$A_ID" archived)" "True" "GET shows archived:true"
req PATCH "/life-areas/$A_ID" '{"archived":false}'; eq "$CODE" 200 "archived:false -> 200"
req GET "/life-areas"; eq "$(jarea "$BODY" "$A_ID" archived)" "False" "archived restored to false (round-trip)"

echo "== 7. PATCH rename onto ANOTHER area's name -> 409, writes nothing"
req PATCH "/life-areas/$A_ID" "{\"name\":\"$B_NAME\"}"; eq "$CODE" 409 "collision rename -> 409"
eq "$(jconf "$BODY" id)"   "$B_ID"   "409 conflict.id = beta"
eq "$(jconf "$BODY" name)" "$B_NAME" "409 conflict.name = beta name"
req GET "/life-areas"; eq "$(jarea "$BODY" "$A_ID" name)" "$A_NAME-renamed" "alpha name unchanged after 409 (no write)"

echo "== 8. PATCH validation edges"
req PATCH "/life-areas/$FAKE" '{"name":"x"}';       eq "$CODE" 404 "unknown id -> 404"
req PATCH "/life-areas/$A_ID" '{"sortOrder":3}';    eq "$CODE" 400 "unknown key -> 400"
req PATCH "/life-areas/$A_ID" '{"archived":"true"}';eq "$CODE" 400 "archived string \"true\" -> 400"
req PATCH "/life-areas/$A_ID" '{"name":"   "}';     eq "$CODE" 400 "empty name -> 400"

# ---- reorder -------------------------------------------------------------
echo "== 9. reorder-vs-{id} ROUTING PROOF"
# A valid reorder that RETURNS 200 and actually reorders proves API Gateway resolved
# '/life-areas/reorder' to the literal reorder route. Had it matched 'PATCH /life-areas/{id}'
# with id='reorder', update_life_area would have looked up AREA#reorder and returned 404
# "Life area not found" — never a 200 with a lifeAreas array.
req GET "/life-areas"; CUR_ORDER="$(jorder "$BODY")"
req PATCH "/life-areas/reorder" "{\"order\":[$(printf '%s' "$CUR_ORDER" | "$PY" -c "import sys;print(','.join('\"%s\"'%x for x in sys.stdin.read().split(',')))")]}"
eq "$CODE" 200 "PATCH /life-areas/reorder reached reorder handler (200, not 404 from {id})"
HAS_ARRAY=$(printf '%s' "$BODY" | "$PY" -c "import sys,json;print('lifeAreas' in json.load(sys.stdin))")
eq "$HAS_ARRAY" True "reorder response carries a lifeAreas array (not a {id}-handler 404 body)"

echo "== 10. reorder set-equality 400s each leave the order UNCHANGED"
req GET "/life-areas"; BEFORE_BAD="$(jorder "$BODY")"
# build bad orders from the current id list
mkbad() { printf '%s' "$CUR_ORDER" | "$PY" -c "import sys,json
ids=sys.stdin.read().split(',')
mode=sys.argv[1]
if mode=='missing': ids=ids[:-1]
elif mode=='unknown': ids=ids+['zzz-not-an-id']
elif mode=='dup': ids=ids[:-1]+[ids[0]]
print(json.dumps({'order':ids}))" "$1"; }
req GET "/life-areas"; CUR_ORDER="$(jorder "$BODY")"
req PATCH "/life-areas/reorder" "$(mkbad missing)"; eq "$CODE" 400 "reorder missing id -> 400"
req PATCH "/life-areas/reorder" "$(mkbad unknown)"; eq "$CODE" 400 "reorder unknown id -> 400"
req PATCH "/life-areas/reorder" "$(mkbad dup)";     eq "$CODE" 400 "reorder duplicate id -> 400"
req PATCH "/life-areas/reorder" '{"order":"a,b,c"}';eq "$CODE" 400 "reorder order-not-a-list -> 400"
req GET "/life-areas"; eq "$(jorder "$BODY")" "$BEFORE_BAD" "order completely unchanged after 4 bad reorders"

echo "== 11. reorder VALID full permutation rewrites every sortOrder"
REVERSED="$(printf '%s' "$CUR_ORDER" | "$PY" -c "import sys,json;print(json.dumps({'order':list(reversed(sys.stdin.read().split(',')))}))")"
req PATCH "/life-areas/reorder" "$REVERSED"; eq "$CODE" 200 "valid reorder -> 200"
req GET "/life-areas"
WANT="$(printf '%s' "$CUR_ORDER" | "$PY" -c "import sys;print(','.join(reversed(sys.stdin.read().split(','))))")"
eq "$(jorder "$BODY")" "$WANT" "GET returns areas in exactly the requested order"

# ---- cleanup (each check inside its OWN pass/fail branch) -----------------
echo "== 12. cleanup: restore E's real areas byte-for-byte, hard-delete every zz-la-* throwaway"
# Re-scan so cleanup removes ANY zz-la-* row this run created, not a hardcoded id list.
aws dynamodb scan --table-name "$TABLE" --region "$REGION" \
  --filter-expression "entity = :e" --expression-attribute-values '{":e":{"S":"AREA"}}' \
  --output json > "$TMP/scan_cleanup.json" 2>/dev/null
"$PY" - "$TMP/real_before.json" "$TMP/scan_cleanup.json" "$TABLE" "$REGION" "$USER_ID" <<'PYEOF'
import json, subprocess, sys
snap, scan, table, region, user_id = sys.argv[1:6]
real = json.load(open(snap))
for item in real:
    subprocess.run(["aws","dynamodb","put-item","--table-name",table,"--region",region,
                    "--item", json.dumps(item)], check=True)
throwaways = [i["id"]["S"] for i in json.load(open(scan))["Items"]
             if i["name"]["S"].startswith("zz-la-")]
for tid in throwaways:
    subprocess.run(["aws","dynamodb","delete-item","--table-name",table,"--region",region,
                    "--key", json.dumps({"PK":{"S":f"USER#{user_id}"},"SK":{"S":f"AREA#{tid}"}})],
                   check=True)
print("  restored %d real areas; hard-deleted %d throwaway(s)" % (len(real), len(throwaways)))
PYEOF

# verify no throwaway left behind — inside its own branch, NOT printed unconditionally
req GET "/life-areas"
LEFTOVER=$(printf '%s' "$BODY" | "$PY" -c "import sys,json
print(sum(1 for a in json.load(sys.stdin)['lifeAreas'] if a['name'].startswith('zz-la-')))")
if [ "$LEFTOVER" -eq 0 ]; then ok "no zz-la-* throwaway left behind"; else bad "$LEFTOVER zz-la-* areas left behind"; fi

# verify E's nine real areas are byte-identical to the pre-run snapshot
aws dynamodb scan --table-name "$TABLE" --region "$REGION" \
  --filter-expression "entity = :e" --expression-attribute-values '{":e":{"S":"AREA"}}' \
  --output json > "$TMP/scan_after.json" 2>/dev/null
IDENTICAL=$("$PY" -c "import json
after=[i for i in json.load(open('$TMP/scan_after.json'))['Items'] if not i['name']['S'].startswith('zz-la-')]
before=json.load(open('$TMP/real_before.json'))
key=lambda x:x['id']['S']
print(json.dumps(sorted(after,key=key),sort_keys=True)==json.dumps(sorted(before,key=key),sort_keys=True))")
if [ "$IDENTICAL" = "True" ]; then ok "E's 9 real areas byte-identical to pre-run snapshot"; else bad "real areas differ from snapshot"; fi

# GET after — pasted in the report as the 'after' side of the diff
echo "  --- GET /life-areas AFTER (name, sortOrder, archived) ---"
req GET "/life-areas"
printf '%s' "$BODY" | "$PY" -c "import sys,json
for a in json.load(sys.stdin)['lifeAreas']:
    print('    %-14s sort=%-2s archived=%s' % (a['name'], a['sortOrder'], a['archived']))"
eq "$(jorder "$BODY")" "$BEFORE_ORDER" "GET order after == GET order before (real areas untouched net)"

echo
echo "================ RESULT: $pass passed, $fail failed ================"
[ "$fail" -eq 0 ] || exit 1
