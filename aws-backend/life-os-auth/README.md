# life-os-auth — token proxy for the "E's Capture" Shortcut

Thin AWS Lambda behind the **public** `POST /auth` route on HTTP API `2pzqn8yih5`
(stage `prod`). It runs Cognito `USER_PASSWORD_AUTH` and returns the tokens as
clean `application/json`, which the iOS Shortcut can read (Cognito's native
`application/x-amz-json-1.1` is an opaque File to Shortcuts).

Full design + root cause: `docs/AUTH-PROXY-SHORTCUT-ENDPOINT.md`.

This function is **separate** from the capture Lambda (`../life-os-api/`), which
is not touched by this endpoint.

## Endpoint

```
POST https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod/auth
Content-Type: application/json
{ "username": "ethanant@icloud.com", "password": "<cognito password>" }
```

- `200` → `{ "idToken", "accessToken", "expiresIn", "tokenType" }`
- `400` missing/invalid body · `401` `{"error":"invalid credentials"}` ·
  `403` user not confirmed · `500` `{"error":"authentication failed"}`

The route's authorizer is **NONE** (public) — you have no token yet at login.
Every other route on the API keeps its Cognito JWT authorizer.

## Live AWS resources (account `891943683816`, `us-east-1`)

| Thing | Value |
|---|---|
| Function | `life-os-auth` (Python 3.13, x86_64, 128 MB, 10 s) |
| Handler | `lambda_function.handler` |
| Env var | `COGNITO_CLIENT_ID = 57v25l4t62spds2qkvkhtbq0ae` |
| Exec role | `life-os-auth-lambda-role` |
| API integration | `AWS_PROXY` payload 2.0, id `kokzb6i` |
| Route | `POST /auth`, authorizer `NONE`, throttle 5/s rate, 10 burst |

### IAM (least-privilege)

- Managed: `AWSLambdaBasicExecutionRole` (CloudWatch Logs).
- Inline `cognito-initiate-auth`: `cognito-idp:InitiateAuth` on
  `arn:aws:cognito-idp:us-east-1:891943683816:userpool/us-east-1_fOmtVlMih`.

## Security

- The password and all returned tokens are **never logged** — the handler emits
  no log lines containing them, and public error responses are generic (no
  internal detail leaks).

## Tests

Unit tests mock `boto3`'s cognito client (no network):

```bash
AWS_DEFAULT_REGION=us-east-1 python3 -m unittest \
  aws-backend/life-os-auth/test_lambda_function.py -v
# boto3 must be importable (it's provided by the Lambda runtime in prod)
```

Live smoke (never hardcodes the password — prompts silently or reads `$AUTH_PW`):

```bash
bash aws-backend/life-os-auth/smoke_test_auth.sh
```

## Redeploy the code

```bash
cd aws-backend/life-os-auth
zip auth.zip lambda_function.py
aws lambda update-function-code --function-name life-os-auth --zip-file fileb://auth.zip
```
