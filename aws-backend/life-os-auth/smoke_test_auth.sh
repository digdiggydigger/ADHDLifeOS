#!/usr/bin/env bash
# Live smoke test for the life-os-auth token proxy (POST /auth) and that its
# token is accepted by the existing JWT-authorized POST /captures.
#
# The password is NEVER hardcoded and NEVER echoed. Provide it via the AUTH_PW
# env var, or the script prompts for it silently:
#
#   export AUTH_PW='...'        # optional; else you'll be prompted
#   bash smoke_test_auth.sh
#
# Requires the Mac's authenticated aws CLI only for the GET /captures no-token
# check to be meaningful (no token is used there on purpose).
set -u

GW="https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod"
USER_EMAIL="ethanant@icloud.com"
JSON="Content-Type: application/json"
pass=0; fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
eq()  { if [ "$1" = "$2" ]; then ok "$3 ($1)"; else bad "$3 (got '$1', want '$2')"; fi; }

# Read a JSON string field without printing secrets.
jf() { printf '%s' "$1" | python3 -c "import sys,json;print(json.load(sys.stdin).get('$2',''))" 2>/dev/null; }

if [ -z "${AUTH_PW:-}" ]; then
  read -r -s -p "Cognito password for $USER_EMAIL (input hidden): " AUTH_PW; echo
fi

echo "== 1. POST /auth, NO Authorization header, WRONG password"
out=$(curl -s -w $'\n%{http_code}' -X POST "$GW/auth" -H "$JSON" \
  -d "{\"username\":\"$USER_EMAIL\",\"password\":\"definitely-not-the-password-xyz\"}")
CODE="${out##*$'\n'}"; BODY="${out%$'\n'*}"
eq "$CODE" 401 "wrong password -> 401"
eq "$(jf "$BODY" error)" "invalid credentials" "body error == invalid credentials"
# A gateway auth rejection would be {"message":"Unauthorized"}; getting our
# Lambda's {"error":...} proves the route is public (reached the Lambda).
echo "  (reaching the Lambda with no auth header proves POST /auth is public)"

echo "== 2. POST /auth, missing password field -> 400"
out=$(curl -s -w $'\n%{http_code}' -X POST "$GW/auth" -H "$JSON" \
  -d "{\"username\":\"$USER_EMAIL\"}")
CODE="${out##*$'\n'}"
eq "$CODE" 400 "missing password -> 400"

echo "== 3. GET /captures with NO token -> 401 (default JWT authorizer intact elsewhere)"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$GW/captures")
eq "$CODE" 401 "GET /captures unauthenticated -> 401"

echo "== 4. POST /auth, GOOD password -> 200 + tokens (Content-Type application/json)"
HDRS=$(mktemp)
out=$(curl -s -D "$HDRS" -w $'\n%{http_code}' -X POST "$GW/auth" -H "$JSON" \
  -d "{\"username\":\"$USER_EMAIL\",\"password\":$(python3 -c 'import json,os;print(json.dumps(os.environ["AUTH_PW"]))')}")
CODE="${out##*$'\n'}"; BODY="${out%$'\n'*}"
eq "$CODE" 200 "good password -> 200"
CT=$(grep -i '^content-type:' "$HDRS" | tr -d '\r' | awk '{print $2}')
eq "$CT" "application/json" "response Content-Type"
ID_TOKEN=$(jf "$BODY" idToken)
ACCESS_TOKEN=$(jf "$BODY" accessToken)
EXPIRES=$(jf "$BODY" expiresIn)
TTYPE=$(jf "$BODY" tokenType)
# Print only lengths, never the token itself.
if [ -n "$ID_TOKEN" ]; then ok "idToken present (len=${#ID_TOKEN})"; else bad "idToken empty"; fi
if [ -n "$ACCESS_TOKEN" ]; then ok "accessToken present (len=${#ACCESS_TOKEN})"; else bad "accessToken empty"; fi
eq "$EXPIRES" "3600" "expiresIn"
eq "$TTYPE" "Bearer" "tokenType"
rm -f "$HDRS"

echo "== 5. Use returned idToken as Bearer against POST /captures -> 201"
if [ -n "$ID_TOKEN" ]; then
  out=$(curl -s -w $'\n%{http_code}' -X POST "$GW/captures" \
    -H "Authorization: Bearer $ID_TOKEN" -H "$JSON" \
    -d '{"kind":"note","title":"life-os-auth smoke test","content":"proxy token accepted"}')
  CODE="${out##*$'\n'}"; BODY="${out%$'\n'*}"
  eq "$CODE" 201 "create capture with proxy token -> 201"
  CID=$(jf "$BODY" id)
  if [ -n "$CID" ]; then ok "capture id returned (${CID})"; else bad "no capture id"; fi
else
  bad "skipped /captures check — no idToken"
fi

echo
echo "================ RESULT: $pass passed, $fail failed ================"
[ "$fail" -eq 0 ] || exit 1
