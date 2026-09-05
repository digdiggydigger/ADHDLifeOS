# Auth Proxy Endpoint — `POST /auth` for the "E's Capture" Shortcut

**Status:** DRAFT for build (2026-07-28). Green-lit by E. Execution owner: Claude Code (AWS deploy — needs the Mac's `aws` CLI).
**Relates to:** `docs/CAPTURE-SHORTCUT-AWS-DUALWRITE.md` (this unblocks the auth step of that dual-write) and `docs/STAGE-B-COGNITO-DYNAMODB-LAMBDA.md` (the JWT-authorizer API this fronts).

---

## 1. Why this exists (root cause, proven this session)

The "E's Capture" shortcut must obtain a Cognito **IdToken** to call the JWT-authorized `life-os-api`. We built the shortcut to call Cognito `InitiateAuth` directly. Every part of that request is now **proven correct** (captured via a request inspector and replayed against live Cognito → HTTP 200 + valid 1081-char IdToken):

- `Content-Type: application/x-amz-json-1.1` ✅ (sent correctly via File-body workaround)
- `X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth` ✅
- Body clean, password exact ✅

**The blocker is on the response side and is a hard iOS Shortcuts limitation:** Cognito replies with `Content-Type: application/x-amz-json-1.1`. Shortcuts receives that as an **opaque File** it will neither JSON-parse nor convert to text:

- "Get Dictionary Value" → error: *"Shortcuts couldn't convert from File to Dictionary."*
- Text-action wrap of the response → empty.
- "Get Text from Input" → returns the URL host, not the body.

Verified against a content-type-controlled inspector clone: the identical token JSON parses perfectly when served as `application/json`, and fails identically to Cognito when served as `application/x-amz-json-1.1`. So the fault is purely the content-type Shortcuts can't read — **not** the request, the password, or AWS config. Pure-Shortcuts approaches are exhausted.

**Fix:** a thin server-side proxy in E's own AWS account that performs `InitiateAuth` and returns the token as **clean `application/json`**, which Shortcuts reads without issue.

## 2. Live constants (verified this session, account `891943683816`, `us-east-1`)

| Thing | Value |
|---|---|
| Cognito User Pool | `us-east-1_fOmtVlMih` ("adhd-lifeos-users") |
| App client (no secret) | `57v25l4t62spds2qkvkhtbq0ae` ("adhd-lifeos-ios") — `ALLOW_USER_PASSWORD_AUTH` enabled |
| Pool `UsernameAttributes` | `['email']` → USERNAME is the email |
| Sign-in user | `ethanant@icloud.com` (CONFIRMED, enabled, email_verified) |
| HTTP API (API Gateway v2) id | `2pzqn8yih5` |
| API base (stage `prod`) | `https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod` |
| Existing capture route | `POST /captures` (Cognito-JWT-authorized) |

## 3. Design

### 3.1 New public route
Add **`POST /auth`** to the existing HTTP API `2pzqn8yih5`, on stage `prod`, so the endpoint is:

```
https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod/auth
```

**Authorizer: NONE** for this route only. The default Cognito JWT authorizer must be *overridden off* here — you don't have a token yet at login. Every other route keeps its JWT authorizer unchanged.

### 3.2 New Lambda `life-os-auth` (kept separate from the capture Lambda)
A dedicated minimal function so the proven capture Lambda (`lambda_function.py`) is **not touched**. Reference implementation (Claude Code implements test-first per `claudecode.md`):

```python
import json, os
import boto3

cognito = boto3.client("cognito-idp")
CLIENT_ID = os.environ["COGNITO_CLIENT_ID"]  # 57v25l4t62spds2qkvkhtbq0ae

def _resp(status, body):
    return {"statusCode": status,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(body)}

def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _resp(400, {"error": "request body must be valid JSON"})

    username = (body.get("username") or "").strip()
    password = body.get("password") or ""
    if not username or not password:
        return _resp(400, {"error": "username and password are required"})

    try:
        result = cognito.initiate_auth(
            AuthFlow="USER_PASSWORD_AUTH",
            ClientId=CLIENT_ID,
            AuthParameters={"USERNAME": username, "PASSWORD": password},
        )
    except (cognito.exceptions.NotAuthorizedException,
            cognito.exceptions.UserNotFoundException):
        return _resp(401, {"error": "invalid credentials"})
    except cognito.exceptions.UserNotConfirmedException:
        return _resp(403, {"error": "user not confirmed"})
    except Exception:                    # noqa: BLE001 — never leak internals to a public route
        return _resp(500, {"error": "authentication failed"})

    auth = result.get("AuthenticationResult")
    if not auth:                         # e.g. a challenge; not expected for this confirmed user
        return _resp(401, {"error": "authentication challenge not supported"})

    return _resp(200, {
        "idToken": auth["IdToken"],
        "accessToken": auth["AccessToken"],
        "expiresIn": auth.get("ExpiresIn", 3600),
        "tokenType": auth.get("TokenType", "Bearer"),
    })
```

- **Env var:** `COGNITO_CLIENT_ID = 57v25l4t62spds2qkvkhtbq0ae`.
- **IAM:** attach `cognito-idp:InitiateAuth` on resource `arn:aws:cognito-idp:us-east-1:891943683816:userpool/us-east-1_fOmtVlMih` (InitiateAuth/USER_PASSWORD_AUTH is an unauthenticated op, but grant it explicitly rather than relying on that). Plus the basic Lambda logging policy.
- **Runtime:** Python 3.10+ (match the capture Lambda). No third-party deps — `boto3` is in the Lambda runtime.

### 3.3 Contract

Request (`application/json`):
```json
{ "username": "ethanant@icloud.com", "password": "<cognito password>" }
```

Success `200` (`application/json`):
```json
{ "idToken": "eyJ…", "accessToken": "eyJ…", "expiresIn": 3600, "tokenType": "Bearer" }
```

Errors: `400` missing/invalid body · `401` `{"error":"invalid credentials"}` · `500` `{"error":"authentication failed"}`.

### 3.4 Abuse control
`/auth` is public and takes a password, so add a **per-route throttle** on `POST /auth` (suggest rate `5`/s, burst `10`) on the `prod` stage. Cognito itself rate-limits `InitiateAuth`; this just caps obvious abuse. No CORS needed (Shortcuts is not a browser). Optional hardening (not required for v1): a static `X-Auth-Proxy-Key` header the Lambda checks, to keep the endpoint from being trivially callable by anyone who learns the URL.

## 4. Shortcut changes (after the endpoint is live — Cowork will walk E through these)

The entire Cognito block in the shortcut is **replaced** by a single clean call, and the File-body / `x-amz` / response text-wrap hacks are deleted:

1. **Get value for `lifeos/cognitoPassword`** (Data Jar) → `Value` (unchanged).
2. **Get Contents of** `https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod/auth`
   - Method **POST**, **Request Body: JSON** (normal JSON body is fine — this is our own endpoint), fields `username = ethanant@icloud.com`, `password = [Value]`.
3. **Get Dictionary Value** `idToken` from **Contents of URL** → **Set variable `IdToken`**. (Works — response is `application/json`.)
4. Existing per-type `POST /captures` calls with `Authorization: Bearer [IdToken]` stay exactly as they are.

## 5. Verification (definition of done)

- `curl -sS -X POST https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod/auth -H 'Content-Type: application/json' -d '{"username":"ethanant@icloud.com","password":"<pw>"}'` → `200` with a real `idToken`.
- Wrong password → `401 {"error":"invalid credentials"}`.
- The returned `idToken` used as `Authorization: Bearer …` against `POST /captures` → `201` (proves the token the proxy returns is accepted by the existing authorizer).
- Shortcut end-to-end: a Quick Note run creates a row visible in the app's Capture Inbox.

## 6. Security follow-ups (E)

- **Rotate the Cognito password** — it appeared in this session's chat/screenshots — then update the Data Jar `lifeos/cognitoPassword` value (keep it **Text**, no trailing whitespace).
- Consider the optional `X-Auth-Proxy-Key` header hardening in 3.4 once basic flow works.
