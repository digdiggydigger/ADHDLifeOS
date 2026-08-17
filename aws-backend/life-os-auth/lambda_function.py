"""
life-os-auth — token-proxy Lambda for the "E's Capture" iOS Shortcut.

Performs Cognito USER_PASSWORD_AUTH and returns the resulting tokens as clean
`application/json`. This exists because iOS Shortcuts cannot read Cognito's
native `application/x-amz-json-1.1` response (see
docs/AUTH-PROXY-SHORTCUT-ENDPOINT.md §1).

Fronted by the public `POST /auth` route (authorizer NONE) on HTTP API
2pzqn8yih5, stage prod. This function is intentionally separate from the
capture Lambda (`life-os-api/lambda_function.py`) — that one is not touched.

Security: never log the password or any returned token. Errors returned to the
public route are generic — internal exception detail is never leaked.
"""

import json
import os

import boto3

# In Lambda, AWS_REGION is set by the runtime; fall back to us-east-1 (the
# pool's region) for local/offline test runs.
cognito = boto3.client(
    "cognito-idp",
    region_name=os.environ.get("AWS_REGION", os.environ.get("AWS_DEFAULT_REGION", "us-east-1")),
)

CLIENT_ID = os.environ["COGNITO_CLIENT_ID"]  # 57v25l4t62spds2qkvkhtbq0ae


def _resp(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _resp(400, {"error": "request body must be valid JSON"})
    if not isinstance(body, dict):
        return _resp(400, {"error": "request body must be a JSON object"})

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
    except (
        cognito.exceptions.NotAuthorizedException,
        cognito.exceptions.UserNotFoundException,
    ):
        return _resp(401, {"error": "invalid credentials"})
    except cognito.exceptions.UserNotConfirmedException:
        return _resp(403, {"error": "user not confirmed"})
    except Exception:  # noqa: BLE001 — never leak internals to a public route
        return _resp(500, {"error": "authentication failed"})

    auth = result.get("AuthenticationResult")
    if not auth:  # e.g. a challenge; not expected for this confirmed user
        return _resp(401, {"error": "authentication challenge not supported"})

    return _resp(200, {
        "idToken": auth["IdToken"],
        "accessToken": auth["AccessToken"],
        "expiresIn": auth.get("ExpiresIn", 3600),
        "tokenType": auth.get("TokenType", "Bearer"),
    })
