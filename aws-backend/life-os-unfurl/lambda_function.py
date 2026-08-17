"""
life-os-unfurl — best-effort link-preview (unfurl) worker for ADHD LifeOS (Stage C.6-INFRA-c).

Invoked ASYNCHRONOUSLY (InvocationType="Event") by life-os-api's create_capture for kind:link.
Event payload: {"userId": "<cognito sub>", "captureId": "<uuid>", "url": "<the link>"}.

What it does (all stdlib for HTTP/parsing — no third-party deps, so the deploy is a single file):
  1. Fetches the URL (urllib, short timeout, normal User-Agent, size-capped read).
  2. Parses og:title / og:description / og:image (with <title> as a title fallback) via
     html.parser — no BeautifulSoup / lxml.
  3. If an og:image exists, downloads it (size-capped) and stores it in S3 at
     captures/{userId}/{captureId}/link-thumb.jpg.
  4. PATCHes the capture's DynamoDB item: linkPreview = {url, title?, description?, thumbnailKey?},
     keyed PK=USER#{userId}, SK=CAPTURE#{captureId}, guarded so it never resurrects a deleted item.

Fully best-effort: ANY fetch/parse/store failure is logged and swallowed. The capture create has
already succeeded; on failure the capture simply stays a bare URL and the app shows the plain link.
Read routes in life-os-api mint the presigned linkPreview.thumbnailUrl from thumbnailKey at
response time — this Lambda only ever writes the *key*.
"""

import html
import json
import os
import urllib.request
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ.get("TABLE_NAME", "LifeOS"))
s3 = boto3.client("s3")
MEDIA_BUCKET = os.environ.get("MEDIA_BUCKET", "")

USER_AGENT = "Mozilla/5.0 (compatible; ADHDLifeOS-Unfurl/1.0)"
FETCH_TIMEOUT = 8  # seconds
MAX_HTML_BYTES = 2 * 1024 * 1024  # 2 MB of HTML is plenty for <head> meta tags
MAX_IMAGE_BYTES = 5 * 1024 * 1024  # 5 MB cap on the preview image
MAX_FIELD_LEN = 2000  # defensive cap on stored title/description length


class _OpenGraphParser(HTMLParser):
    """Collects og:* meta tags and the first <title>, ignoring everything else."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.og = {}
        self.title = None
        self._in_title = False

    def handle_starttag(self, tag, attrs):
        if tag == "title" and self.title is None:
            self._in_title = True
            return
        if tag != "meta":
            return
        a = dict(attrs)
        key = a.get("property") or a.get("name")
        content = a.get("content")
        if key and content and key.lower().startswith("og:"):
            self.og.setdefault(key.lower(), content)

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False

    def handle_data(self, data):
        if self._in_title and data.strip():
            self.title = (self.title or "") + data


def _clean(value):
    if not value:
        return None
    text = html.unescape(value).strip()
    if not text:
        return None
    return text[:MAX_FIELD_LEN]


def _fetch(url, max_bytes):
    """GET a URL with a cap on bytes read. Returns (body_bytes, final_url) or raises."""
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=FETCH_TIMEOUT) as resp:
        return resp.read(max_bytes + 1)[:max_bytes], resp.geturl()


def _decode_html(body):
    for encoding in ("utf-8", "latin-1"):
        try:
            return body.decode(encoding)
        except (UnicodeDecodeError, LookupError):
            continue
    return body.decode("utf-8", errors="ignore")


def _store_preview_image(image_url, base_url, user_id, capture_id):
    """Download og:image (size-capped) and put it in S3. Returns the S3 key or None."""
    if not image_url or not MEDIA_BUCKET:
        return None
    absolute = urljoin(base_url, image_url)
    if urlparse(absolute).scheme not in ("http", "https"):
        return None
    try:
        image_bytes, _ = _fetch(absolute, MAX_IMAGE_BYTES)
    except Exception as exc:  # noqa: BLE001 - best-effort
        print(f"unfurl: image fetch failed for {absolute}: {exc}")
        return None
    if not image_bytes:
        return None
    key = f"captures/{user_id}/{capture_id}/link-thumb.jpg"
    try:
        s3.put_object(Bucket=MEDIA_BUCKET, Key=key, Body=image_bytes, ContentType="image/jpeg")
    except Exception as exc:  # noqa: BLE001 - best-effort
        print(f"unfurl: image put_object failed for {key}: {exc}")
        return None
    return key


def _patch_capture(user_id, capture_id, preview):
    """Set linkPreview on the capture item, guarded so a deleted capture is never recreated."""
    try:
        table.update_item(
            Key={"PK": f"USER#{user_id}", "SK": f"CAPTURE#{capture_id}"},
            UpdateExpression="SET linkPreview = :lp",
            ConditionExpression="attribute_exists(PK)",
            ExpressionAttributeValues={":lp": preview},
        )
    except Exception as exc:  # noqa: BLE001 - best-effort (incl. ConditionalCheckFailed)
        print(f"unfurl: update_item skipped for capture {capture_id}: {exc}")


def handler(event, _context):
    user_id = event.get("userId")
    capture_id = event.get("captureId")
    url = event.get("url")
    if not (user_id and capture_id and url):
        print(f"unfurl: missing required fields in event: {json.dumps(event)}")
        return {"ok": False, "reason": "missing-fields"}

    if urlparse(url).scheme not in ("http", "https"):
        print(f"unfurl: non-http(s) url, skipping: {url}")
        return {"ok": False, "reason": "bad-scheme"}

    try:
        body, final_url = _fetch(url, MAX_HTML_BYTES)
    except Exception as exc:  # noqa: BLE001 - best-effort; capture stays a bare URL
        print(f"unfurl: page fetch failed for {url}: {exc}")
        return {"ok": False, "reason": "fetch-failed"}

    parser = _OpenGraphParser()
    try:
        parser.feed(_decode_html(body))
    except Exception as exc:  # noqa: BLE001 - malformed HTML shouldn't fail the worker
        print(f"unfurl: html parse warning for {url}: {exc}")

    title = _clean(parser.og.get("og:title")) or _clean(parser.title)
    description = _clean(parser.og.get("og:description"))
    thumbnail_key = _store_preview_image(
        parser.og.get("og:image"), final_url, user_id, capture_id
    )

    # Nothing usable found → leave the capture as a bare URL (don't write an empty preview).
    if not (title or description or thumbnail_key):
        print(f"unfurl: no OG data found for {url}; leaving capture bare")
        return {"ok": True, "reason": "no-preview"}

    preview = {"url": url}
    if title:
        preview["title"] = title
    if description:
        preview["description"] = description
    if thumbnail_key:
        preview["thumbnailKey"] = thumbnail_key

    _patch_capture(user_id, capture_id, preview)
    return {"ok": True, "linkPreview": preview}
