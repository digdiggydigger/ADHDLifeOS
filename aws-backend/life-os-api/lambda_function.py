"""
life-os-api — the AWS backend for ADHD LifeOS's Supabase -> AWS migration, Stage B + C.6.

Single-table DynamoDB access behind API Gateway (HTTP API) with a Cognito JWT authorizer.
The authorizer validates the JWT (signature, expiry, audience, issuer) before this Lambda is
ever invoked — this function trusts `event["requestContext"]["authorizer"]["jwt"]["claims"]["sub"]`
as the authenticated Cognito user id and scopes every read/write to it. This is the RLS
equivalent described in docs/STAGE-B-COGNITO-DYNAMODB-LAMBDA.md.

Table key convention (see the design doc for the full rationale):
    PK = USER#<userId>
    SK = <ENTITY>#<id>              e.g. TASK#<uuid>, AREA#<uuid>, CAPTURE#<uuid>,
                                          LOG#<uuid>, NUDGE#<uuid>, TAG#<uuid>,
                                          TASKTAG#<taskId>#<tagId>,
                                          CAPTURETAG#<captureId>#<tagId>
    GSI1PK = USER#<userId>#AREA#<lifeAreaId>   (life-area scoping — tasks/logs/captures)
    GSI1SK = <ENTITY>#<createdAt>
    GSI2PK = USER#<userId>#STATUS#<status>     (task status filter)
    GSI2SK = TASK#<dueDate-or-createdAt>

Capture media (Stage C.6): binary media (voice audio, photo originals, link-preview images) lives
in the S3 bucket named by MEDIA_BUCKET. Capture items store only the S3 *key* (`mediaKey`,
`thumbnailKey`, `linkPreview.thumbnailKey`); read routes add short-lived presigned GET URLs
(`mediaUrl`/`thumbnailUrl`/`linkPreview.thumbnailUrl`) at response time and never persist them.
Link previews are filled in asynchronously by the UNFURL_FN Lambda (best-effort).

Life areas (Life Areas backend block, 2026-07-30): no longer read-only. The signup trigger still
seeds the starting 9 rows, but the app can now rename an area, change its emoji (`colour`), create
new areas, archive/unarchive them, and reorder the whole set — via `GET/POST /life-areas`,
`PATCH /life-areas/{id}`, and `PATCH /life-areas/reorder`. There is deliberately still NO delete
route (E chose archive over delete — archived areas stay in `GET` responses so clients can grey
them out; see docs/ARCHITECTURE.md §8).

Not implemented here (deliberately, matches live Supabase behaviour this backend replaces):
    - No DELETE route for tasks, captures, or life areas (no delete RLS policy today; life areas
      archive instead).
    - No update/delete route for logs (append-only, matches public.logs).
"""

import json
import os
import time
import traceback
import uuid
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ.get("TABLE_NAME", "LifeOS"))
s3 = boto3.client("s3")
lambda_client = boto3.client("lambda")

MEDIA_BUCKET = os.environ.get("MEDIA_BUCKET")
UNFURL_FN = os.environ.get("UNFURL_FN")

VALID_CAPTURE_KINDS = {"note", "task", "link", "voice", "photo"}
VALID_CAPTURE_STATUS = {"inbox", "needs-review", "processed"}

# Allowed upload content types → the file extension used in the S3 key. Kept deliberately small;
# photo keys must end .jpg/.jpeg/.png so the thumbnailer's S3 suffix filter (Stage C.6-INFRA-b)
# picks them up.
MEDIA_EXTENSIONS = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "audio/m4a": "m4a",
    "audio/mp4": "m4a",
    "audio/x-m4a": "m4a",
    "audio/mpeg": "mp3",
    "audio/wav": "wav",
}

UPLOAD_URL_TTL = 300     # 5 min — a presigned PUT only needs to survive one upload.
DOWNLOAD_URL_TTL = 900   # 15 min — long enough for an inbox browsing session.


def _now_iso():
    return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime())


def _user_id(event):
    return event["requestContext"]["authorizer"]["jwt"]["claims"]["sub"]


def _json_default(value):
    # boto3 reads DynamoDB Number attributes back as Decimal. json.dumps's old
    # `default=str` fallback stringified these (e.g. sortOrder 1 -> "1"), which
    # silently broke every Swift client decoding that field as Int — confirmed
    # live 2026-07-22 via a direct Lambda invoke against real seeded life-area
    # rows. Numbers must stay numbers on the wire.
    if isinstance(value, Decimal):
        return int(value) if value % 1 == 0 else float(value)
    return str(value)


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=_json_default),
    }


def _error(status, message):
    return _response(status, {"error": message})


def _query_all(user_id, sk_prefix):
    """Return every item for `user_id` whose SK begins with `{sk_prefix}#`, following
    `LastEvaluatedKey` so a result set larger than DynamoDB's 1MB page is never silently
    truncated. DynamoDB paginates a `query` at 1MB; the junction rows (`TASKTAG#`/`CAPTURETAG#`)
    are the highest-cardinality entity in this table, and a truncated read of them would
    under-count usage and, worse, orphan rows during a merge or cascade. All junction reads in
    this file go through here for that reason."""
    items = []
    key_expr = Key("PK").eq(f"USER#{user_id}") & Key("SK").begins_with(f"{sk_prefix}#")
    start_key = None
    while True:
        kwargs = {"KeyConditionExpression": key_expr}
        if start_key is not None:
            kwargs["ExclusiveStartKey"] = start_key
        resp = table.query(**kwargs)
        items.extend(resp.get("Items", []))
        start_key = resp.get("LastEvaluatedKey")
        if not start_key:
            break
    return items


def _query_entity(user_id, sk_prefix):
    # Repointed at the paginating helper (Tag Editor backend block): every existing caller
    # (tasks, areas, captures, logs, nudges, tags) now reads the full result set instead of only
    # the first 1MB page. Same signature, same return shape — a drop-in that removes the silent
    # truncation these callers had.
    return _query_all(user_id, sk_prefix)


def handler(event, context):
    route = event.get("routeKey", "")

    try:
        user_id = _user_id(event)
    except (KeyError, TypeError):
        return _error(401, "Missing or invalid JWT claims")

    params = event.get("pathParameters") or {}
    query = event.get("queryStringParameters") or {}
    try:
        body = json.loads(event["body"]) if event.get("body") else {}
    except json.JSONDecodeError:
        return _error(400, "Request body must be valid JSON")

    routes = {
        "GET /tasks": lambda: list_tasks(user_id, query),
        "POST /tasks": lambda: create_task(user_id, body),
        "GET /tasks/{id}": lambda: get_task(user_id, params.get("id")),
        "PATCH /tasks/{id}": lambda: update_task(user_id, params.get("id"), body),
        "GET /tasks/{id}/tags": lambda: list_task_tags(user_id, params.get("id")),
        "POST /tasks/{id}/tags": lambda: attach_tag(user_id, params.get("id"), body),
        "DELETE /tasks/{id}/tags/{tagId}": lambda: remove_tag(user_id, params.get("id"), params.get("tagId")),
        "GET /life-areas": lambda: list_life_areas(user_id),
        "POST /life-areas": lambda: create_life_area(user_id, body),
        # `reorder` is listed before `{id}` for readers; the Lambda dispatches on the exact
        # routeKey string API Gateway supplies, so ordering here is documentation only. The real
        # literal-over-template precedence is enforced by API Gateway's HTTP-API router (proven in
        # smoke_test_lifeareas.sh) — a `/life-areas/reorder` request arrives with routeKey
        # "PATCH /life-areas/reorder", never "PATCH /life-areas/{id}" with id="reorder".
        "PATCH /life-areas/reorder": lambda: reorder_life_areas(user_id, body),
        "PATCH /life-areas/{id}": lambda: update_life_area(user_id, params.get("id"), body),
        "POST /captures": lambda: create_capture(user_id, body),
        "POST /captures/upload-url": lambda: create_upload_url(user_id, body),
        "GET /captures": lambda: list_captures(user_id, query),
        "GET /captures/{id}": lambda: get_capture(user_id, params.get("id")),
        "PATCH /captures/{id}": lambda: update_capture(user_id, params.get("id"), body),
        "GET /captures/{id}/tags": lambda: list_capture_tags(user_id, params.get("id")),
        "POST /captures/{id}/tags": lambda: attach_capture_tag(user_id, params.get("id"), body),
        "DELETE /captures/{id}/tags/{tagId}": lambda: remove_capture_tag(user_id, params.get("id"), params.get("tagId")),
        "POST /logs": lambda: create_log(user_id, body),
        "GET /logs": lambda: list_logs(user_id),
        "GET /nudges": lambda: list_nudges(user_id),
        "POST /nudges": lambda: create_nudge(user_id, body),
        "PATCH /nudges/{id}": lambda: update_nudge(user_id, params.get("id"), body),
        "GET /tags": lambda: list_tags(user_id),
        "POST /tags": lambda: create_tag(user_id, body),
        "PATCH /tags/{id}": lambda: rename_tag(user_id, params.get("id"), body),
        "DELETE /tags/{id}": lambda: delete_tag(user_id, params.get("id")),
    }

    handler_fn = routes.get(route)
    if handler_fn is None:
        return _error(404, f"No route for {route}")

    try:
        return handler_fn()
    except KeyError as exc:
        return _error(400, f"Missing required field: {exc}")
    except Exception as exc:  # noqa: BLE001 - last-resort handler: never leak an opaque 500
        # Anything that isn't a missing-field KeyError (an IAM AccessDenied on BatchWriteItem, a
        # DynamoDB throttle, a bug) used to fall through to API Gateway as a bare 500 with no body,
        # which is exactly why the first merge/cascade failure told us nothing. Log the full
        # traceback to CloudWatch and return the exception summary so the caller sees *what* broke.
        traceback.print_exc()
        return _error(500, f"{type(exc).__name__}: {exc}")


# ---- tasks -----------------------------------------------------------------

def list_tasks(user_id, query):
    items = _query_entity(user_id, "TASK")
    status = query.get("status")
    if status:
        items = [i for i in items if i.get("status") == status]
    return _response(200, {"tasks": items})


def create_task(user_id, body):
    title = (body.get("title") or "").strip()
    if not title:
        return _error(400, "title is required")

    task_id = str(uuid.uuid4())
    now = _now_iso()
    item = {
        "PK": f"USER#{user_id}",
        "SK": f"TASK#{task_id}",
        "entity": "TASK",
        "id": task_id,
        "userId": user_id,
        "title": title,
        "notes": body.get("notes"),
        "status": "open",
        "priority": body.get("priority", "p4"),
        "dueDate": body.get("dueDate"),
        "lifeAreaId": body.get("lifeAreaId"),
        "source": body.get("source", "manual"),
        "createdAt": now,
        "updatedAt": now,
    }
    _apply_task_gsi_keys(item)
    table.put_item(Item=item)
    return _response(201, item)


def get_task(user_id, task_id):
    resp = table.get_item(Key={"PK": f"USER#{user_id}", "SK": f"TASK#{task_id}"})
    item = resp.get("Item")
    if not item:
        return _error(404, "Task not found")
    return _response(200, item)


def update_task(user_id, task_id, body):
    key = {"PK": f"USER#{user_id}", "SK": f"TASK#{task_id}"}
    existing = table.get_item(Key=key).get("Item")
    if not existing:
        return _error(404, "Task not found")

    updatable = {"title", "notes", "lifeAreaId", "priority", "dueDate", "status"}
    updates = {k: v for k, v in body.items() if k in updatable}
    if "title" in updates and not updates["title"].strip():
        return _error(400, "title cannot be empty")

    merged = {**existing, **updates, "updatedAt": _now_iso()}
    _apply_task_gsi_keys(merged)
    table.put_item(Item=merged)
    return _response(200, merged)


def _apply_task_gsi_keys(item):
    if item.get("lifeAreaId"):
        item["GSI1PK"] = f"USER#{item['userId']}#AREA#{item['lifeAreaId']}"
        item["GSI1SK"] = f"TASK#{item['createdAt']}"
    else:
        item.pop("GSI1PK", None)
        item.pop("GSI1SK", None)
    item["GSI2PK"] = f"USER#{item['userId']}#STATUS#{item['status']}"
    item["GSI2SK"] = f"TASK#{item.get('dueDate') or item['createdAt']}"


# ---- task tags (task_tags junction) -----------------------------------------

def list_task_tags(user_id, task_id):
    resp = table.query(
        KeyConditionExpression=Key("PK").eq(f"USER#{user_id}") & Key("SK").begins_with(f"TASKTAG#{task_id}#")
    )
    tag_ids = [item["SK"].split("#")[-1] for item in resp.get("Items", [])]
    tags = []
    for tag_id in tag_ids:
        tag = table.get_item(Key={"PK": f"USER#{user_id}", "SK": f"TAG#{tag_id}"}).get("Item")
        if tag:
            tags.append(tag)
    return _response(200, {"tags": tags})


def attach_tag(user_id, task_id, body):
    tag_id = body.get("tagId")
    if not tag_id:
        return _error(400, "tagId is required")
    table.put_item(Item={
        "PK": f"USER#{user_id}",
        "SK": f"TASKTAG#{task_id}#{tag_id}",
        "entity": "TASKTAG",
        "taskId": task_id,
        "tagId": tag_id,
    })
    return _response(201, {"taskId": task_id, "tagId": tag_id})


def remove_tag(user_id, task_id, tag_id):
    table.delete_item(Key={"PK": f"USER#{user_id}", "SK": f"TASKTAG#{task_id}#{tag_id}"})
    return _response(204, {})


# ---- life areas -------------------------------------------------------------
#
# Editable as of the Life Areas backend block (rename, emoji, create, archive, reorder). The three
# pure functions below hold all validation / planning so they are unit-testable with plain dicts and
# zero boto3, exactly like the tag planners; the route handlers stay thin (query -> plan -> write).

LIFE_AREA_PATCH_FIELDS = {"name", "colour", "archived"}


def _is_archived(item):
    # A missing `archived` attribute means False — the 9 seeded rows predate the field and are
    # deliberately never backfilled (docs/ARCHITECTURE.md §8). This is the single place that rule
    # is applied, on both reads and no-op comparisons.
    return bool(item.get("archived", False))


def _present_life_area(item):
    # Response-only normalisation: every returned area carries an explicit `archived` boolean even
    # though the stored row may omit it. Never mutates the stored item.
    presented = dict(item)
    presented["archived"] = _is_archived(item)
    return presented


def plan_life_area_patch(existing, body):
    """(stored area, PATCH body) -> (updates, error). Pure: no DynamoDB, no duplicate-name check
    (that needs the other rows, so the route does it). `updates` is the subset of attributes that
    actually changed — empty means the caller writes nothing and returns the item unchanged.
    `error` is (status, message) or None. Only `name`/`colour`/`archived` are accepted; any other
    key is a hard 400 (stricter than update_task, which silently drops — the block requires reject).
    """
    unknown = sorted(k for k in body if k not in LIFE_AREA_PATCH_FIELDS)
    if unknown:
        return None, (400, f"Unknown field(s): {', '.join(unknown)}")

    updates = {}

    for field in ("name", "colour"):
        if field in body:
            value = body[field]
            if not isinstance(value, str):
                return None, (400, f"{field} must be a string")
            value = value.strip()
            if not value:
                return None, (400, f"{field} cannot be empty")
            if value != existing.get(field):
                updates[field] = value

    if "archived" in body:
        value = body["archived"]
        # isinstance(True, int) is True but isinstance(1, bool) is False, so this rejects both a
        # string "true" and an int 1 while accepting a real bool.
        if not isinstance(value, bool):
            return None, (400, "archived must be a boolean")
        if value != _is_archived(existing):
            updates["archived"] = value

    return updates, None


def find_name_conflict(areas, name, exclude_id=None):
    """First area named `name` (optionally excluding `exclude_id`, so a rename never conflicts with
    itself) rendered as a 409 `conflict` descriptor, or None. Pure — both POST and PATCH build their
    409 body here so the shape, and crucially the `archived` flag, live in exactly one place.

    The reservation deliberately spans archived areas too: that is what guarantees unarchiving can
    never produce two areas sharing a name (there is no merge concept to resolve it if it did). But
    a 409 that named an area which is off the Home grid and out of the visible list would be a dead
    end, so the descriptor carries `archived` (via _is_archived, keeping missing-means-false in one
    spot) — the UI can then say "you have an archived life area called X — unarchive it instead?"."""
    for area in areas:
        if area.get("id") != exclude_id and area.get("name") == name:
            return {"id": area["id"], "name": area["name"], "archived": _is_archived(area)}
    return None


def next_sort_order(areas):
    """Max existing `sortOrder` + 1 (0 when there are no areas). Tolerates DynamoDB Decimals and a
    missing `sortOrder` (treated as 0) and always returns a plain int."""
    if not areas:
        return 0
    return max(int(a.get("sortOrder", 0)) for a in areas) + 1


def validate_reorder(order, current_ids):
    """(requested ordering, the user's current area ids) -> (status, message) error, or None when
    valid. `order` must be a list that is EXACTLY the current set — no missing id, no unknown id, no
    duplicate. A partial ordering must never write (a half-applied reorder is invisible and
    un-undoable), so any mismatch is a 400 naming the problem."""
    if not isinstance(order, list):
        return (400, "order must be a list of life-area ids")
    dupes = sorted({x for x in order if order.count(x) > 1})
    if dupes:
        return (400, f"order contains duplicate id(s): {', '.join(dupes)}")
    order_set, current_set = set(order), set(current_ids)
    missing = sorted(current_set - order_set)
    if missing:
        return (400, f"order is missing id(s): {', '.join(missing)}")
    extra = sorted(order_set - current_set)
    if extra:
        return (400, f"order contains unknown id(s): {', '.join(extra)}")
    return None


def list_life_areas(user_id):
    items = _query_entity(user_id, "AREA")
    items.sort(key=lambda i: i.get("sortOrder", 0))
    return _response(200, {"lifeAreas": [_present_life_area(i) for i in items]})


def update_life_area(user_id, area_id, body):
    key = {"PK": f"USER#{user_id}", "SK": f"AREA#{area_id}"}
    existing = table.get_item(Key=key).get("Item")
    if not existing:
        return _error(404, "Life area not found")

    updates, error = plan_life_area_patch(existing, body)
    if error:
        return _error(error[0], error[1])
    if not updates:
        # Nothing changed after trim / no-op — no write, return the item as it stands.
        return _response(200, _present_life_area(existing))

    # Rename onto a *different* existing area's name -> 409 (no merge concept for life areas), and
    # write nothing. Only relevant when the name actually changed (it is in `updates`).
    if "name" in updates:
        conflict = find_name_conflict(_query_entity(user_id, "AREA"), updates["name"], exclude_id=area_id)
        if conflict:
            return _response(409, {"error": "name already in use", "conflict": conflict})

    merged = {**existing, **updates, "updatedAt": _now_iso()}
    table.put_item(Item=merged)
    return _response(200, _present_life_area(merged))


def create_life_area(user_id, body):
    name = body.get("name")
    colour = body.get("colour")
    if not isinstance(name, str) or not name.strip():
        return _error(400, "name is required")
    if not isinstance(colour, str) or not colour.strip():
        return _error(400, "colour is required")
    name, colour = name.strip(), colour.strip()

    areas = _query_entity(user_id, "AREA")
    # Deliberately NOT dedup-and-return-existing the way POST /tags is: a life area is a structural,
    # deliberate thing, so a name clash is an honest 409, not a silent hand-back (§8). The clash is
    # checked against archived areas too (name reservation survives archiving).
    conflict = find_name_conflict(areas, name)
    if conflict:
        return _response(409, {"error": "name already in use", "conflict": conflict})

    area_id = str(uuid.uuid4())
    now = _now_iso()
    item = {
        "PK": f"USER#{user_id}",
        "SK": f"AREA#{area_id}",
        "entity": "AREA",
        "id": area_id,
        "userId": user_id,
        "name": name,
        "colour": colour,
        "sortOrder": next_sort_order(areas),
        "archived": False,
        "createdAt": now,
        "updatedAt": now,
    }
    table.put_item(Item=item)
    return _response(201, _present_life_area(item))


def reorder_life_areas(user_id, body):
    areas = _query_entity(user_id, "AREA")
    error = validate_reorder(body.get("order"), [a["id"] for a in areas])
    if error:
        return _error(error[0], error[1])

    order = body["order"]
    by_id = {a["id"]: a for a in areas}
    now = _now_iso()
    # One request, one batch — never N sequential single-item PATCHes (commit 8e19a08's race).
    with table.batch_writer() as batch:
        for index, area_id in enumerate(order):
            area = by_id[area_id]
            area["sortOrder"] = index
            area["updatedAt"] = now
            batch.put_item(Item=area)

    ordered = [by_id[area_id] for area_id in order]
    return _response(200, {"lifeAreas": [_present_life_area(a) for a in ordered]})


# ---- captures ----------------------------------------------------------------

def _presigned_get(key):
    """Short-lived presigned GET URL for an S3 media key, or None if there's no key/bucket."""
    if not key or not MEDIA_BUCKET:
        return None
    return s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": MEDIA_BUCKET, "Key": key},
        ExpiresIn=DOWNLOAD_URL_TTL,
    )


def _present_capture(item):
    """Return a copy of a capture item with ephemeral presigned GET URLs added. Never mutates the
    stored item; the raw `*Key` attributes stay, the `*Url` fields are response-only."""
    presented = dict(item)
    media_url = _presigned_get(item.get("mediaKey"))
    if media_url:
        presented["mediaUrl"] = media_url
    thumb_url = _presigned_get(item.get("thumbnailKey"))
    if thumb_url:
        presented["thumbnailUrl"] = thumb_url
    link_preview = item.get("linkPreview")
    if isinstance(link_preview, dict):
        preview = dict(link_preview)
        preview_thumb = _presigned_get(link_preview.get("thumbnailKey"))
        if preview_thumb:
            preview["thumbnailUrl"] = preview_thumb
        presented["linkPreview"] = preview
    return presented


def _apply_capture_gsi_keys(item):
    # Life-area scoping for captures (reuses GSI1, mirrors tasks/logs). Forward-compat with the
    # future Life Area -> Sub-area hierarchy; no sub-areas are implemented here.
    if item.get("lifeAreaId"):
        item["GSI1PK"] = f"USER#{item['userId']}#AREA#{item['lifeAreaId']}"
        item["GSI1SK"] = f"CAPTURE#{item['createdAt']}"
    else:
        item.pop("GSI1PK", None)
        item.pop("GSI1SK", None)


def _invoke_unfurl(user_id, capture_id, url):
    # Best-effort async link unfurl (Stage C.6-INFRA-c). Never fails the capture create — an
    # unreachable UNFURL_FN just leaves the capture as a bare URL.
    try:
        lambda_client.invoke(
            FunctionName=UNFURL_FN,
            InvocationType="Event",
            Payload=json.dumps({"userId": user_id, "captureId": capture_id, "url": url}).encode("utf-8"),
        )
    except Exception:  # noqa: BLE001 - deliberately swallow; unfurl is best-effort
        pass


def create_upload_url(user_id, body):
    kind = body.get("kind", "note")
    if kind not in VALID_CAPTURE_KINDS:
        return _error(400, f"Unknown capture kind: {kind}")
    if kind not in ("photo", "voice"):
        return _error(400, "upload-url is only for photo or voice captures")

    content_type = body.get("contentType")
    if not content_type:
        return _error(400, "contentType is required")
    ext = MEDIA_EXTENSIONS.get(content_type)
    if not ext:
        return _error(400, f"Unsupported contentType: {content_type}")
    if not MEDIA_BUCKET:
        return _error(500, "media storage is not configured")

    upload_id = str(uuid.uuid4())
    prefix = f"captures/{user_id}/{upload_id}"
    if kind == "photo":
        media_key = f"{prefix}/original.{ext}"
        thumbnail_key = f"{prefix}/thumb.jpg"
    else:  # voice
        media_key = f"{prefix}/audio.{ext}"
        thumbnail_key = None

    upload_url = s3.generate_presigned_url(
        "put_object",
        Params={"Bucket": MEDIA_BUCKET, "Key": media_key, "ContentType": content_type},
        ExpiresIn=UPLOAD_URL_TTL,
    )
    result = {"uploadUrl": upload_url, "mediaKey": media_key}
    if thumbnail_key:
        result["thumbnailKey"] = thumbnail_key
    return _response(200, result)


def create_capture(user_id, body):
    kind = body.get("kind", "note")
    if kind not in VALID_CAPTURE_KINDS:
        return _error(400, f"Unknown capture kind: {kind}")

    content = (body.get("content") or "").strip()
    # A photo may have an empty caption; every other kind requires content (voice carries its
    # on-device transcription, link carries the URL, note/task carry text).
    if not content and kind != "photo":
        return _error(400, "content is required")

    status = body.get("status", "inbox")
    if status not in VALID_CAPTURE_STATUS:
        return _error(400, f"Unknown status: {status}")

    capture_id = str(uuid.uuid4())
    item = {
        "PK": f"USER#{user_id}",
        "SK": f"CAPTURE#{capture_id}",
        "entity": "CAPTURE",
        "id": capture_id,
        "userId": user_id,
        "content": content,
        "kind": kind,
        "status": status,
        "processed": status == "processed",
        "createdAt": _now_iso(),
    }
    for field in ("title", "lifeAreaId", "aiAssessment", "mediaKey", "mediaContentType", "thumbnailKey"):
        value = body.get(field)
        if value is not None:
            item[field] = value
    _apply_capture_gsi_keys(item)
    table.put_item(Item=item)

    if kind == "link" and UNFURL_FN:
        _invoke_unfurl(user_id, capture_id, content)

    return _response(201, _present_capture(item))


def list_captures(user_id, query):
    items = _query_entity(user_id, "CAPTURE")
    if query.get("processed") == "false":
        items = [i for i in items if not i.get("processed")]
    status = query.get("status")
    if status:
        items = [i for i in items if i.get("status") == status]
    return _response(200, {"captures": [_present_capture(i) for i in items]})


def get_capture(user_id, capture_id):
    resp = table.get_item(Key={"PK": f"USER#{user_id}", "SK": f"CAPTURE#{capture_id}"})
    item = resp.get("Item")
    if not item:
        return _error(404, "Capture not found")
    return _response(200, _present_capture(item))


def update_capture(user_id, capture_id, body):
    key = {"PK": f"USER#{user_id}", "SK": f"CAPTURE#{capture_id}"}
    existing = table.get_item(Key=key).get("Item")
    if not existing:
        return _error(404, "Capture not found")

    # Status is the canonical field; `processed` stays coupled for back-compat. If a caller sends
    # the legacy `processed` boolean instead, derive status from it.
    if "status" in body:
        status = body["status"]
        if status not in VALID_CAPTURE_STATUS:
            return _error(400, f"Unknown status: {status}")
        existing["status"] = status
        existing["processed"] = status == "processed"
    elif "processed" in body:
        processed = bool(body["processed"])
        existing["processed"] = processed
        existing["status"] = "processed" if processed else "inbox"

    for field in ("title", "lifeAreaId", "aiAssessment", "linkPreview"):
        if field in body:
            if body[field] is None:
                existing.pop(field, None)
            else:
                existing[field] = body[field]

    _apply_capture_gsi_keys(existing)
    table.put_item(Item=existing)
    return _response(200, _present_capture(existing))


# ---- capture tags (capture_tags junction — mirrors task_tags) ----------------

def list_capture_tags(user_id, capture_id):
    resp = table.query(
        KeyConditionExpression=Key("PK").eq(f"USER#{user_id}") & Key("SK").begins_with(f"CAPTURETAG#{capture_id}#")
    )
    tag_ids = [item["SK"].split("#")[-1] for item in resp.get("Items", [])]
    tags = []
    for tag_id in tag_ids:
        tag = table.get_item(Key={"PK": f"USER#{user_id}", "SK": f"TAG#{tag_id}"}).get("Item")
        if tag:
            tags.append(tag)
    return _response(200, {"tags": tags})


def attach_capture_tag(user_id, capture_id, body):
    tag_id = body.get("tagId")
    if not tag_id:
        return _error(400, "tagId is required")
    table.put_item(Item={
        "PK": f"USER#{user_id}",
        "SK": f"CAPTURETAG#{capture_id}#{tag_id}",
        "entity": "CAPTURETAG",
        "captureId": capture_id,
        "tagId": tag_id,
    })
    return _response(201, {"captureId": capture_id, "tagId": tag_id})


def remove_capture_tag(user_id, capture_id, tag_id):
    table.delete_item(Key={"PK": f"USER#{user_id}", "SK": f"CAPTURETAG#{capture_id}#{tag_id}"})
    return _response(204, {})


# ---- logs (append-only — no update/delete route, by design) ------------------

def create_log(user_id, body):
    log_body = (body.get("body") or "").strip()
    if not log_body:
        return _error(400, "body is required")

    log_id = str(uuid.uuid4())
    now = _now_iso()
    item = {
        "PK": f"USER#{user_id}",
        "SK": f"LOG#{log_id}",
        "entity": "LOG",
        "id": log_id,
        "userId": user_id,
        "lifeAreaId": body.get("lifeAreaId"),
        "type": body.get("type", "log"),
        "body": log_body,
        "entryDate": now,
        "createdAt": now,
    }
    if item.get("lifeAreaId"):
        item["GSI1PK"] = f"USER#{user_id}#AREA#{item['lifeAreaId']}"
        item["GSI1SK"] = f"LOG#{now}"
    table.put_item(Item=item)
    return _response(201, item)


def list_logs(user_id):
    return _response(200, {"logs": _query_entity(user_id, "LOG")})


# ---- nudges --------------------------------------------------------------

def list_nudges(user_id):
    return _response(200, {"nudges": _query_entity(user_id, "NUDGE")})


def create_nudge(user_id, body):
    label = (body.get("label") or "").strip()
    schedule = body.get("schedule")
    if not label or not schedule:
        return _error(400, "label and schedule are required")

    nudge_id = str(uuid.uuid4())
    now = _now_iso()
    item = {
        "PK": f"USER#{user_id}",
        "SK": f"NUDGE#{nudge_id}",
        "entity": "NUDGE",
        "id": nudge_id,
        "userId": user_id,
        "label": label,
        "schedule": schedule,
        "active": body.get("active", True),
        "lastFiredAt": None,
        "createdAt": now,
        "updatedAt": now,
    }
    table.put_item(Item=item)
    return _response(201, item)


def update_nudge(user_id, nudge_id, body):
    key = {"PK": f"USER#{user_id}", "SK": f"NUDGE#{nudge_id}"}
    existing = table.get_item(Key=key).get("Item")
    if not existing:
        return _error(404, "Nudge not found")
    for field in ("label", "schedule", "active", "lastFiredAt"):
        if field in body:
            existing[field] = body[field]
    existing["updatedAt"] = _now_iso()
    table.put_item(Item=existing)
    return _response(200, existing)


# ---- tags ------------------------------------------------------------------

# The junction sort keys put the tag id LAST — `TASKTAG#<taskId>#<tagId>`,
# `CAPTURETAG#<captureId>#<tagId>` — so there is no way to `begins_with` your way to "all rows for
# tag X". Every count / merge / cascade below sweeps the whole `TASKTAG#`/`CAPTURETAG#` space for
# the user (two `_query_all` reads) and filters on the last SK segment in memory. These three pure
# functions hold that logic so it is unit-testable with plain dicts and zero boto3; the route
# handlers stay thin (query -> plan -> batch_writer).

def _sk_tag_id(item):
    return item["SK"].split("#")[-1]


def _sk_owner_id(item):
    # The middle segment: the taskId in TASKTAG#<taskId>#<tagId>, the captureId in CAPTURETAG#...#.
    return item["SK"].split("#")[1]


def tally_tag_usage(tasktag_items, capturetag_items):
    """junction items in -> `{tagId: {"taskCount": n, "captureCount": m}}` out. Tags with no
    joins simply do not appear in the dict; callers substitute zeros."""
    counts = {}
    for item in tasktag_items:
        counts.setdefault(_sk_tag_id(item), {"taskCount": 0, "captureCount": 0})["taskCount"] += 1
    for item in capturetag_items:
        counts.setdefault(_sk_tag_id(item), {"taskCount": 0, "captureCount": 0})["captureCount"] += 1
    return counts


def plan_tag_merge(user_id, tasktag_items, capturetag_items, loser_id, survivor_id):
    """(all junction rows, loser id, survivor id) -> the exact rows to WRITE and DELETE for the
    junction rewrite, plus a stats summary. The loser `TAG#` item itself is NOT part of this plan
    — the route deletes it last, after these junction rows land, so a mid-way crash leaves the
    rows already moved and re-running the merge is a no-op-safe repair.

    For each junction row pointing at the loser: if the same task/capture already carries the
    survivor, delete the loser row only (dedup — never write a duplicate junction row); otherwise
    write the equivalent survivor row and delete the loser row."""
    writes = []
    deletes = []
    stats = {
        "tasksRepointed": 0, "tasksDeduped": 0,
        "capturesRepointed": 0, "capturesDeduped": 0,
    }

    def _plan(items, prefix, repointed_key, deduped_key):
        survivor_owners = {
            _sk_owner_id(i) for i in items if _sk_tag_id(i) == survivor_id
        }
        for i in items:
            if _sk_tag_id(i) != loser_id:
                continue
            owner_id = _sk_owner_id(i)
            deletes.append({"PK": f"USER#{user_id}", "SK": i["SK"]})
            if owner_id in survivor_owners:
                stats[deduped_key] += 1
            else:
                writes.append({
                    "PK": f"USER#{user_id}",
                    "SK": f"{prefix}#{owner_id}#{survivor_id}",
                    "entity": i.get("entity"),
                    ("taskId" if prefix == "TASKTAG" else "captureId"): owner_id,
                    "tagId": survivor_id,
                })
                stats[repointed_key] += 1

    _plan(tasktag_items, "TASKTAG", "tasksRepointed", "tasksDeduped")
    _plan(capturetag_items, "CAPTURETAG", "capturesRepointed", "capturesDeduped")
    return {"writes": writes, "deletes": deletes, "stats": stats}


def plan_tag_cascade(user_id, tasktag_items, capturetag_items, tag_id):
    """(all junction rows, tag id) -> every junction row to DELETE for a cascade delete. As with
    the merge, the loser `TAG#` item is deleted by the route last, not here."""
    deletes = [
        {"PK": f"USER#{user_id}", "SK": i["SK"]}
        for i in tasktag_items + capturetag_items
        if _sk_tag_id(i) == tag_id
    ]
    return {"deletes": deletes}


def _tag_usage_counts(user_id):
    """The whole request's usage tally in EXACTLY two junction queries (one TASKTAG# sweep, one
    CAPTURETAG# sweep) — never one query per tag."""
    return tally_tag_usage(
        _query_all(user_id, "TASKTAG"),
        _query_all(user_id, "CAPTURETAG"),
    )


def _usage_count_for(counts, tag_id):
    c = counts.get(tag_id, {"taskCount": 0, "captureCount": 0})
    return c["taskCount"] + c["captureCount"]


def list_tags(user_id):
    tags = _query_entity(user_id, "TAG")
    counts = _tag_usage_counts(user_id)
    for tag in tags:
        c = counts.get(tag["id"], {"taskCount": 0, "captureCount": 0})
        tag["taskCount"] = c["taskCount"]
        tag["captureCount"] = c["captureCount"]
        tag["usageCount"] = c["taskCount"] + c["captureCount"]
    return _response(200, {"tags": tags})


def rename_tag(user_id, tag_id, body):
    key = {"PK": f"USER#{user_id}", "SK": f"TAG#{tag_id}"}
    tag = table.get_item(Key=key).get("Item")
    if not tag:
        return _error(404, "Tag not found")

    new_name = (body.get("name") or "").strip()
    if not new_name:
        return _error(400, "name is required")

    on_conflict = body.get("onConflict")
    if on_conflict is not None and on_conflict != "merge":
        return _error(400, f"Unrecognised onConflict: {on_conflict}")

    # Unchanged name (after trim) -> no writes, return the tag as-is.
    if new_name == tag.get("name"):
        return _response(200, tag)

    # Does a *different* existing tag already own this name? That is the merge case.
    survivor = next(
        (t for t in _query_entity(user_id, "TAG")
         if t.get("name") == new_name and t.get("id") != tag_id),
        None,
    )

    if survivor is None:
        # Plain rename — junction rows are untouched, they point at this tag id which is unchanged.
        tag["name"] = new_name
        table.put_item(Item=tag)
        return _response(200, tag)

    # Name collides with a different tag. Never silent in either direction.
    if on_conflict != "merge":
        counts = _tag_usage_counts(user_id)
        return _response(409, {
            "error": "name already in use",
            "conflict": {
                "id": survivor["id"],
                "name": survivor["name"],
                "usageCount": _usage_count_for(counts, survivor["id"]),
            },
        })

    # Explicit merge: re-point every junction row from the loser (this tag) to the survivor,
    # dedup where an item already carries both, then delete the loser TAG# item LAST.
    tasktags = _query_all(user_id, "TASKTAG")
    capturetags = _query_all(user_id, "CAPTURETAG")
    plan = plan_tag_merge(user_id, tasktags, capturetags, tag_id, survivor["id"])

    with table.batch_writer() as batch:
        for item in plan["writes"]:
            batch.put_item(Item=item)
        for del_key in plan["deletes"]:
            batch.delete_item(Key=del_key)
    # Junction rows have landed; only now remove the loser tag itself.
    table.delete_item(Key=key)

    return _response(200, {"tag": survivor, "merge": plan["stats"]})


def delete_tag(user_id, tag_id):
    key = {"PK": f"USER#{user_id}", "SK": f"TAG#{tag_id}"}
    tag = table.get_item(Key=key).get("Item")
    if not tag:
        return _error(404, "Tag not found")

    tasktags = _query_all(user_id, "TASKTAG")
    capturetags = _query_all(user_id, "CAPTURETAG")
    plan = plan_tag_cascade(user_id, tasktags, capturetags, tag_id)

    with table.batch_writer() as batch:
        for del_key in plan["deletes"]:
            batch.delete_item(Key=del_key)
    # Junction rows gone; delete the TAG# item last (same recoverability ordering as the merge).
    table.delete_item(Key=key)

    return _response(204, {})


def create_tag(user_id, body):
    name = (body.get("name") or "").strip()
    if not name:
        return _error(400, "name is required")

    # Server-side dedup mirrors the app's own client-side dedup rule, and stands in for
    # DynamoDB's lack of a native unique constraint outside the key (Supabase enforced this via
    # `unique(user_id, name)`). Not airtight under concurrent identical creates from two clients
    # at once — acceptable for a single-user v1 app; flag if this ever becomes multi-user.
    existing_matches = [t for t in _query_entity(user_id, "TAG") if t.get("name") == name]
    if existing_matches:
        return _response(200, existing_matches[0])

    tag_id = str(uuid.uuid4())
    item = {
        "PK": f"USER#{user_id}",
        "SK": f"TAG#{tag_id}",
        "entity": "TAG",
        "id": tag_id,
        "userId": user_id,
        "name": name,
        "createdAt": _now_iso(),
    }
    table.put_item(Item=item)
    return _response(201, item)
