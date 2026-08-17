#!/usr/bin/env bash
# Stage C.6-INFRA-a, Step 6 — end-to-end smoke test of the extended capture API.
# Requires GW and TOKEN exported in the environment. Read-only-ish: it creates a couple of
# throwaway capture/tag rows in DynamoDB (there is no delete route for captures by design).
#
#   export GW="https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod"
#   export TOKEN=$(aws cognito-idp initiate-auth ... --query AuthenticationResult.IdToken --output text)
#   bash smoke_test_capture.sh
set -u
: "${GW:?export GW first}"
: "${TOKEN:?export TOKEN first}"

AUTH="Authorization: Bearer $TOKEN"
JSON="Content-Type: application/json"
pass=0; fail=0

ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }
eq()   { if [ "$1" = "$2" ]; then ok "$3 ($1)"; else bad "$3 (got '$1', want '$2')"; fi; }
nonempty() { if [ -n "$1" ]; then ok "$2"; else bad "$2 (empty)"; fi; }
jf()   { printf '%s' "$1" | python3 -c "import sys,json;print(json.load(sys.stdin).get('$2',''))" 2>/dev/null; }

# req METHOD PATH [DATA] -> sets CODE, BODY
req() {
  local m="$1" p="$2" d="${3:-}" out
  if [ -n "$d" ]; then
    out=$(curl -s -w $'\n%{http_code}' -X "$m" "$GW$p" -H "$AUTH" -H "$JSON" -d "$d")
  else
    out=$(curl -s -w $'\n%{http_code}' -X "$m" "$GW$p" -H "$AUTH")
  fi
  CODE="${out##*$'\n'}"
  BODY="${out%$'\n'*}"
}

echo "== 1. POST /captures/upload-url (photo)"
req POST "/captures/upload-url" '{"kind":"photo","contentType":"image/jpeg"}'
eq "$CODE" 200 "upload-url returns 200"
UPLOAD_URL=$(jf "$BODY" uploadUrl)
MEDIA_KEY=$(jf "$BODY" mediaKey)
THUMB_KEY=$(jf "$BODY" thumbnailKey)
nonempty "$UPLOAD_URL" "uploadUrl present"
nonempty "$MEDIA_KEY" "mediaKey present"
nonempty "$THUMB_KEY" "thumbnailKey present (photo)"

echo "== 2. PUT test bytes to the presigned S3 URL"
echo "lifeos-smoke-test-bytes" > /tmp/lifeos_smoke.jpg
S3CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT --data-binary @/tmp/lifeos_smoke.jpg -H "Content-Type: image/jpeg" "$UPLOAD_URL")
eq "$S3CODE" 200 "S3 presigned PUT returns 200"

echo "== 3. POST /captures (photo, referencing mediaKey)"
req POST "/captures" "{\"kind\":\"photo\",\"title\":\"Smoke test photo\",\"mediaKey\":\"$MEDIA_KEY\",\"mediaContentType\":\"image/jpeg\",\"thumbnailKey\":\"$THUMB_KEY\"}"
eq "$CODE" 201 "create photo capture returns 201"
CID=$(jf "$BODY" id)
nonempty "$CID" "capture id returned"
eq "$(jf "$BODY" status)" inbox "new capture status = inbox"
eq "$(jf "$BODY" processed)" False "new capture processed = false"

echo "== 4. GET /captures/{id} (presigned mediaUrl)"
req GET "/captures/$CID"
eq "$CODE" 200 "get capture returns 200"
MEDIA_URL=$(jf "$BODY" mediaUrl)
nonempty "$MEDIA_URL" "mediaUrl (presigned GET) present"

echo "== 5. tags: create tag, attach, list"
req POST "/tags" '{"name":"smoke-test-tag"}'
case "$CODE" in 200|201) ok "create/dedup tag ($CODE)";; *) bad "create tag (got $CODE)";; esac
TID=$(jf "$BODY" id)
nonempty "$TID" "tag id returned"
req POST "/captures/$CID/tags" "{\"tagId\":\"$TID\"}"
eq "$CODE" 201 "attach tag to capture returns 201"
req GET "/captures/$CID/tags"
eq "$CODE" 200 "list capture tags returns 200"
HASTAG=$(printf '%s' "$BODY" | python3 -c "import sys,json;print(any(t.get('id')=='$TID' for t in json.load(sys.stdin).get('tags',[])))" 2>/dev/null)
eq "$HASTAG" True "attached tag appears in capture tag list"

echo "== 6. PATCH status transitions (processed stays coupled)"
req PATCH "/captures/$CID" '{"status":"needs-review"}'
eq "$CODE" 200 "patch -> needs-review returns 200"
eq "$(jf "$BODY" status)" needs-review "status now needs-review"
eq "$(jf "$BODY" processed)" False "processed still false at needs-review"
req PATCH "/captures/$CID" '{"status":"processed"}'
eq "$CODE" 200 "patch -> processed returns 200"
eq "$(jf "$BODY" status)" processed "status now processed"
eq "$(jf "$BODY" processed)" True "processed now true"

echo "== 7. filters: ?status= and ?processed="
req GET "/captures?status=inbox"
INBOX_HAS=$(printf '%s' "$BODY" | python3 -c "import sys,json;print(any(c.get('id')=='$CID' for c in json.load(sys.stdin).get('captures',[])))" 2>/dev/null)
eq "$INBOX_HAS" False "processed capture NOT in ?status=inbox"
req GET "/captures?processed=false"
PF_HAS=$(printf '%s' "$BODY" | python3 -c "import sys,json;print(any(c.get('id')=='$CID' for c in json.load(sys.stdin).get('captures',[])))" 2>/dev/null)
eq "$PF_HAS" False "processed capture NOT in ?processed=false"
req GET "/captures?status=processed"
PS_HAS=$(printf '%s' "$BODY" | python3 -c "import sys,json;print(any(c.get('id')=='$CID' for c in json.load(sys.stdin).get('captures',[])))" 2>/dev/null)
eq "$PS_HAS" True "processed capture IS in ?status=processed"

echo
echo "================ RESULT: $pass passed, $fail failed ================"
[ "$fail" -eq 0 ] || exit 1
