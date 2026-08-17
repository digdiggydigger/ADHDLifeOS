"""
Unit tests for the life-os-auth token-proxy Lambda handler.

Test-first per claudecode.md. No network / real AWS: we build a real
cognito-idp client offline (so the dynamic exception classes are genuine),
then patch only its `initiate_auth` method to return canned results or raise
real boto3 service exceptions.

Run:
    AWS_DEFAULT_REGION=us-east-1 \
    /path/to/venv/bin/python -m unittest \
    aws-backend/life-os-auth/test_lambda_function.py -v
"""

import io
import json
import os
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("COGNITO_CLIENT_ID", "test-client-id")

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lambda_function  # noqa: E402


AUTH_RESULT = {
    "IdToken": "id.eyJ.token",
    "AccessToken": "access.eyJ.token",
    "RefreshToken": "refresh-should-not-be-returned",
    "ExpiresIn": 3600,
    "TokenType": "Bearer",
}


def _svc_exc(name, message="denied"):
    """Construct a genuine boto3 service exception of the given name."""
    exc_class = getattr(lambda_function.cognito.exceptions, name)
    return exc_class(
        {"Error": {"Code": name, "Message": message}}, "InitiateAuth"
    )


def invoke(body, *, raw_body=None):
    event = {"body": raw_body if raw_body is not None else json.dumps(body)}
    return lambda_function.handler(event, None)


class SuccessTests(unittest.TestCase):
    def test_success_maps_authentication_result_to_four_fields(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            return_value={"AuthenticationResult": AUTH_RESULT},
        ):
            resp = invoke({"username": "ethanant@icloud.com", "password": "pw"})

        self.assertEqual(resp["statusCode"], 200)
        self.assertEqual(resp["headers"]["Content-Type"], "application/json")
        parsed = json.loads(resp["body"])
        self.assertEqual(parsed["idToken"], AUTH_RESULT["IdToken"])
        self.assertEqual(parsed["accessToken"], AUTH_RESULT["AccessToken"])
        self.assertEqual(parsed["expiresIn"], 3600)
        self.assertEqual(parsed["tokenType"], "Bearer")

    def test_success_does_not_leak_refresh_token(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            return_value={"AuthenticationResult": AUTH_RESULT},
        ):
            resp = invoke({"username": "u@x.com", "password": "pw"})
        self.assertNotIn("refresh", resp["body"].lower())

    def test_success_defaults_expires_and_token_type_when_absent(self):
        minimal = {"IdToken": "i", "AccessToken": "a"}
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            return_value={"AuthenticationResult": minimal},
        ):
            resp = invoke({"username": "u@x.com", "password": "pw"})
        parsed = json.loads(resp["body"])
        self.assertEqual(parsed["expiresIn"], 3600)
        self.assertEqual(parsed["tokenType"], "Bearer")

    def test_calls_cognito_with_user_password_auth_flow(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            return_value={"AuthenticationResult": AUTH_RESULT},
        ) as mock_auth:
            invoke({"username": " ethanant@icloud.com ", "password": "pw"})
        _, kwargs = mock_auth.call_args
        self.assertEqual(kwargs["AuthFlow"], "USER_PASSWORD_AUTH")
        self.assertEqual(kwargs["ClientId"], "test-client-id")
        # username is trimmed
        self.assertEqual(kwargs["AuthParameters"]["USERNAME"], "ethanant@icloud.com")
        self.assertEqual(kwargs["AuthParameters"]["PASSWORD"], "pw")


class BadRequestTests(unittest.TestCase):
    def test_invalid_json_body_returns_400(self):
        resp = invoke(None, raw_body="{not json")
        self.assertEqual(resp["statusCode"], 400)

    def test_missing_body_returns_400(self):
        resp = lambda_function.handler({}, None)
        self.assertEqual(resp["statusCode"], 400)

    def test_missing_username_returns_400(self):
        resp = invoke({"password": "pw"})
        self.assertEqual(resp["statusCode"], 400)

    def test_missing_password_returns_400(self):
        resp = invoke({"username": "u@x.com"})
        self.assertEqual(resp["statusCode"], 400)

    def test_blank_username_returns_400(self):
        resp = invoke({"username": "   ", "password": "pw"})
        self.assertEqual(resp["statusCode"], 400)


class AuthFailureTests(unittest.TestCase):
    def test_not_authorized_returns_401_invalid_credentials(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            side_effect=_svc_exc("NotAuthorizedException"),
        ):
            resp = invoke({"username": "u@x.com", "password": "wrong"})
        self.assertEqual(resp["statusCode"], 401)
        self.assertEqual(json.loads(resp["body"]), {"error": "invalid credentials"})

    def test_user_not_found_returns_401_invalid_credentials(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            side_effect=_svc_exc("UserNotFoundException"),
        ):
            resp = invoke({"username": "nobody@x.com", "password": "pw"})
        self.assertEqual(resp["statusCode"], 401)
        self.assertEqual(json.loads(resp["body"]), {"error": "invalid credentials"})

    def test_user_not_confirmed_returns_403(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            side_effect=_svc_exc("UserNotConfirmedException"),
        ):
            resp = invoke({"username": "u@x.com", "password": "pw"})
        self.assertEqual(resp["statusCode"], 403)
        self.assertEqual(json.loads(resp["body"]), {"error": "user not confirmed"})

    def test_missing_authentication_result_returns_401(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            return_value={"ChallengeName": "NEW_PASSWORD_REQUIRED", "Session": "s"},
        ):
            resp = invoke({"username": "u@x.com", "password": "pw"})
        self.assertEqual(resp["statusCode"], 401)

    def test_unexpected_exception_returns_500_without_leaking(self):
        with patch.object(
            lambda_function.cognito, "initiate_auth",
            side_effect=RuntimeError("boom internal detail secret-arn"),
        ):
            resp = invoke({"username": "u@x.com", "password": "pw"})
        self.assertEqual(resp["statusCode"], 500)
        self.assertEqual(json.loads(resp["body"]), {"error": "authentication failed"})
        self.assertNotIn("boom", resp["body"])
        self.assertNotIn("secret-arn", resp["body"])


class NoSecretLoggingTests(unittest.TestCase):
    def test_password_and_tokens_never_printed_to_stdout(self):
        buf = io.StringIO()
        with redirect_stdout(buf), patch.object(
            lambda_function.cognito, "initiate_auth",
            return_value={"AuthenticationResult": AUTH_RESULT},
        ):
            invoke({"username": "u@x.com", "password": "sup3r-secret-pw"})
        logged = buf.getvalue()
        self.assertNotIn("sup3r-secret-pw", logged)
        self.assertNotIn(AUTH_RESULT["IdToken"], logged)
        self.assertNotIn(AUTH_RESULT["AccessToken"], logged)


if __name__ == "__main__":
    unittest.main()
