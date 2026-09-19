#!/usr/bin/env python3
"""
seed_audit.py — fill ONE Firestore EMULATOR account with realistic data for a UX audit of
ADHD LifeOS.

    python3 seed_audit.py --dry-run    # GETs only; prints every path + fields JSON; writes NOTHING
    python3 seed_audit.py              # writes (PATCH, create-only precondition) + records ids
    python3 seed_audit.py --cleanup    # DELETEs exactly the ids recorded in seed_audit_ids.json

SAFETY
- Talks ONLY to the local emulator at http://127.0.0.1:8080 (asserted below, proxies disabled).
- Every write is a PATCH with `currentDocument.exists=false`, so it can only CREATE a new doc and
  can never overwrite one (including the first-run seed docs).
- --dry-run refuses any non-GET request at the transport layer.
- --cleanup deletes only ids this script recorded in its own sidecar file.

Field spellings are copied from the Swift models' CodingKeys (paths relative to the repo's
`ADHD LifeOS/` app folder):
  tasks          Tasks/TaskDetailModels.swift:61-70 (TaskDetail), Tasks/TaskModels.swift:72-81
                 (TaskItem), Home/HomeModels.swift:97-103 (TaskSummary); `tag_ids` per
                 Firebase/FirebaseManager+Seed.swift:51
  captures       Capture/CaptureModels.swift:63-69
  logs           Journal/LogModels.swift:120-129
  nudges         Nudges/NudgeModels.swift:35-41 (schedule = "MIN HOUR * * DOW", Sunday=0,
                 Nudges/NudgeScheduleParsing.swift:8-14)
  focus_sessions Focus/FocusModels.swift:154-163
Dates are Firestore Timestamps (Firestore.Encoder), i.e. REST `timestampValue` in UTC with `Z`.
Optional fields that are nil are OMITTED (Firestore.Encoder omits them), never nullValue.
"""

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

# --------------------------------------------------------------------------------------------
# Hard safety constants — emulator only.
# --------------------------------------------------------------------------------------------
EMULATOR_ORIGIN = "http://127.0.0.1:8080"
assert EMULATOR_ORIGIN.startswith("http://127.0.0.1:"), "refusing: not the local emulator"
assert "googleapis" not in EMULATOR_ORIGIN, "refusing: live Firestore host"

PROJECT_ID = "adhdlifeos-acb49"
UID = "50pqew9lPwINjxf9P4p2lDyB5xL9"
DOCS_ROOT = f"{EMULATOR_ORIGIN}/v1/projects/{PROJECT_ID}/databases/(default)/documents"
USER_ROOT = f"{DOCS_ROOT}/users/{UID}"
assert USER_ROOT.startswith("http://127.0.0.1:8080/v1/projects/adhdlifeos-acb49/"), USER_ROOT

HEADERS = {"Authorization": "Bearer owner", "Content-Type": "application/json"}
SIDECAR = Path(__file__).resolve().parent / "seed_audit_ids.json"

# Proxies disabled: urllib honours HTTP(S)_PROXY and macOS system proxies otherwise.
_OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))
DRY_RUN = False

SEED_COLLECTIONS = ("tasks", "captures", "logs", "nudges", "focus_sessions")
UUID_UPPER = re.compile(r"^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$")


# --------------------------------------------------------------------------------------------
# Transport
# --------------------------------------------------------------------------------------------
def _request(method, url, body=None):
    if not url.startswith(EMULATOR_ORIGIN + "/"):
        raise SystemExit(f"refusing non-emulator URL: {url}")
    if DRY_RUN and method != "GET":
        raise SystemExit(f"refusing {method} in --dry-run: {url}")
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=HEADERS)
    try:
        with _OPENER.open(req, timeout=10) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as err:
        return err.code, {"error": err.read().decode("utf-8", "replace")}
    except urllib.error.URLError as err:
        raise SystemExit(f"emulator unreachable at {EMULATOR_ORIGIN}: {err.reason}. "
                         f"Start ./scripts/emulators.sh first.")


def list_collection(name):
    docs, token = [], None
    while True:
        url = f"{USER_ROOT}/{name}?pageSize=300" + (f"&pageToken={token}" if token else "")
        status, payload = _request("GET", url)
        if status != 200:
            raise SystemExit(f"GET {name} failed ({status}): {payload}")
        docs.extend(payload.get("documents", []))
        token = payload.get("nextPageToken")
        if not token:
            return docs


# --------------------------------------------------------------------------------------------
# Firestore REST typed values
# --------------------------------------------------------------------------------------------
def ts(dt):
    """Aware datetime -> RFC3339 UTC with Z (what Firestore.Encoder's Timestamp becomes)."""
    if dt.tzinfo is None:
        raise ValueError("naive datetime would shift silently; use an aware one")
    return {"timestampValue": dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")}


def s(value):
    return {"stringValue": value}


def i(value):
    return {"integerValue": str(int(value))}   # REST int64 is a JSON *string*


def b(value):
    return {"booleanValue": bool(value)}


def arr(values):
    return {"arrayValue": {"values": list(values)}} if values else {"arrayValue": {}}


def new_id():
    return str(uuid.uuid4()).upper()


# --------------------------------------------------------------------------------------------
# Local-time helpers (the simulator uses the Mac's time zone)
# --------------------------------------------------------------------------------------------
NOW = datetime.now().astimezone()
TODAY = NOW.replace(hour=0, minute=0, second=0, microsecond=0)


def day(offset):
    """Local start of day `offset` days from today (DST-safe: rebuilt from the calendar date)."""
    d = (TODAY + timedelta(days=offset)).date()
    return datetime(d.year, d.month, d.day).astimezone()


def at(offset, hour, minute=0):
    return day(offset).replace(hour=hour, minute=minute)


def earlier_today(minutes_ago):
    """`minutes_ago` before now, but never before 00:01 today (a run just after midnight)."""
    return max(NOW - timedelta(minutes=minutes_ago), TODAY + timedelta(minutes=1))


def cron_weekday(dt):
    return (dt.weekday() + 1) % 7   # Python Mon=0..Sun=6 -> cron Sun=0..Sat=6


# --------------------------------------------------------------------------------------------
# Model schemas (mirroring CodingKeys) used by the self-check
# --------------------------------------------------------------------------------------------
SCHEMA = {
    # TaskDetail ∪ TaskItem ∪ TaskSummary keys, plus the tag membership array.
    "tasks": {
        "required": {"id": "stringValue", "title": "stringValue", "status": "stringValue",
                     "priority": "stringValue", "created_at": "timestampValue"},
        "optional": {"notes": "stringValue", "life_area_id": "stringValue",
                     "due_date": "timestampValue", "focus_duration_seconds": "integerValue",
                     "nudges_count": "integerValue", "completed_at": "timestampValue",
                     "at_place_id": "stringValue", "place_id": "stringValue",
                     "latitude": "doubleValue", "longitude": "doubleValue",
                     "tag_ids": "arrayValue"},
        "enums": {"status": {"open", "done"}, "priority": {"p1", "p2", "p3", "p4"}},
    },
    "captures": {
        "required": {"id": "stringValue", "content": "stringValue", "kind": "stringValue",
                     "processed": "booleanValue", "created_at": "timestampValue"},
        "optional": {"title": "stringValue", "lifeAreaId": "stringValue",
                     "mediaURL": "stringValue", "mediaContentType": "stringValue",
                     "thumbnailURL": "stringValue", "linkPreview": "mapValue",
                     "aiAssessment": "stringValue", "notes": "stringValue",
                     "clearedAt": "timestampValue", "seen": "booleanValue",
                     "tag_ids": "arrayValue", "placeId": "stringValue",
                     "latitude": "doubleValue", "longitude": "doubleValue"},
        "enums": {"kind": {"note", "task", "link", "voice", "photo"}},
    },
    "logs": {
        "required": {"id": "stringValue", "type": "stringValue", "body": "stringValue",
                     "entry_date": "timestampValue", "created_at": "timestampValue"},
        "optional": {"life_area_id": "stringValue", "energy_level": "stringValue",
                     "mood_emoji": "stringValue", "tag_ids": "arrayValue",
                     "place_id": "stringValue", "latitude": "doubleValue",
                     "longitude": "doubleValue"},
        "enums": {"type": {"log", "journal"}, "energy_level": {"low", "medium", "high"},
                  "mood_emoji": {"⚡", "🔥", "🧘", "🔋", "😴", "🧠", "🌊", "🎯"}},
    },
    "nudges": {
        "required": {"id": "stringValue", "label": "stringValue", "schedule": "stringValue",
                     "active": "booleanValue", "created_at": "timestampValue",
                     "updated_at": "timestampValue"},
        "optional": {"last_fired_at": "timestampValue", "completion_dates": "arrayValue"},
        "enums": {},
    },
    "focus_sessions": {
        "required": {"id": "stringValue", "task_title": "stringValue",
                     "life_area_emoji": "stringValue", "planned_seconds": "integerValue",
                     "focused_seconds": "integerValue", "checkpoints_reached": "integerValue",
                     "completed_naturally": "booleanValue", "started_at": "timestampValue",
                     "ended_at": "timestampValue"},
        "optional": {"task_id": "stringValue", "place_id": "stringValue",
                     "latitude": "doubleValue", "longitude": "doubleValue",
                     "confirmed_at": "timestampValue"},
        "enums": {},
    },
}
UUID_FIELDS = {"id", "life_area_id", "lifeAreaId", "task_id", "at_place_id", "place_id", "placeId"}
PAST_ONLY = {"created_at", "completed_at", "entry_date", "clearedAt", "started_at", "ended_at",
             "confirmed_at", "last_fired_at", "updated_at"}
CRON = re.compile(r"^(\d{1,2}) (\d{1,2}) \* \* ([0-6](,[0-6])*|\*)$")


def parse_ts(value):
    return datetime.strptime(value, "%Y-%m-%dT%H:%M:%S.%fZ").replace(tzinfo=timezone.utc)


def self_check(collection, doc_id, fields, area_ids, task_ids, tag_ids):
    """Raise on anything the Swift decoder would reject or silently ignore."""
    problems = []
    schema = SCHEMA[collection]
    allowed = {**schema["required"], **schema["optional"]}
    if not UUID_UPPER.match(doc_id):
        problems.append(f"doc id not UPPERCASE uuid: {doc_id}")
    for key, kind in schema["required"].items():
        if key not in fields:
            problems.append(f"missing required key {key}")
    for key, value in fields.items():
        if key not in allowed:
            problems.append(f"key {key!r} is not in the model's CodingKeys")
            continue
        (vtype, raw), = value.items()
        if vtype != allowed[key]:
            problems.append(f"{key}: {vtype} but model expects {allowed[key]}")
        if vtype == "nullValue":
            problems.append(f"{key}: nullValue (omit instead)")
        if vtype == "integerValue" and not isinstance(raw, str):
            problems.append(f"{key}: integerValue must be a JSON string")
        if vtype == "timestampValue":
            if not raw.endswith("Z"):
                problems.append(f"{key}: timestamp not UTC Z")
            elif key in PAST_ONLY and parse_ts(raw) > NOW + timedelta(seconds=5):
                problems.append(f"{key}: {raw} is in the future")
        if key in UUID_FIELDS and not UUID_UPPER.match(raw):
            problems.append(f"{key}: not an UPPERCASE uuid string: {raw}")
        if key in schema["enums"] and raw not in schema["enums"][key]:
            problems.append(f"{key}: {raw!r} not in {sorted(schema['enums'][key])}")
    if fields.get("id", {}).get("stringValue") != doc_id:
        problems.append("fields.id != document id")
    for key in ("life_area_id", "lifeAreaId"):
        if key in fields and fields[key]["stringValue"] not in area_ids:
            problems.append(f"{key} {fields[key]['stringValue']} is not an existing life area")
    if "task_id" in fields and fields["task_id"]["stringValue"] not in task_ids:
        problems.append("task_id does not reference a seeded/existing task")
    if "tag_ids" in fields:
        for v in fields["tag_ids"]["arrayValue"].get("values", []):
            if v.get("stringValue") not in tag_ids:
                problems.append(f"tag id {v} is not an existing tag")
    if collection == "tasks":
        done = fields["status"]["stringValue"] == "done"
        if done != ("completed_at" in fields):
            problems.append("status/completed_at disagree (done needs a stamp, open must not have one)")
    if collection == "nudges" and not CRON.match(fields["schedule"]["stringValue"]):
        problems.append(f"schedule {fields['schedule']['stringValue']!r} would not parse")
    if collection == "focus_sessions":
        start, end = parse_ts(fields["started_at"]["timestampValue"]), parse_ts(fields["ended_at"]["timestampValue"])
        if int((end - start).total_seconds()) != int(fields["focused_seconds"]["integerValue"]):
            problems.append("ended_at - started_at != focused_seconds")
    if problems:
        raise SystemExit(f"SELF-CHECK FAILED {collection}/{doc_id}:\n  - " + "\n  - ".join(problems))


# --------------------------------------------------------------------------------------------
# Content
# --------------------------------------------------------------------------------------------
def resolve_existing():
    areas = {}
    for doc in list_collection("life_areas"):
        f = doc["fields"]
        areas[f["name"]["stringValue"]] = {
            "id": doc["name"].rsplit("/", 1)[1],
            "emoji": f.get("colour", {}).get("stringValue", "🎯"),
            "archived": f.get("archived", {}).get("booleanValue", False),
        }
    needed = ["Health", "Work", "Home", "Money", "Relationships", "Growth"]
    missing = [n for n in needed if n not in areas or areas[n]["archived"]]
    if missing:
        raise SystemExit(f"expected first-run life areas missing/archived: {missing}; found {sorted(areas)}")
    tags = {doc["fields"]["name"]["stringValue"]: doc["name"].rsplit("/", 1)[1]
            for doc in list_collection("tags")}
    task_ids = {doc["name"].rsplit("/", 1)[1] for doc in list_collection("tasks")}
    return areas, tags, task_ids


def build_tasks(areas, tags):
    """Returns [(doc_id, fields)] and a name->id map for focus-session links."""
    out, by_key = [], {}

    def task(key, title, area, priority, created, *, due=None, notes=None, done_at=None,
             focus=None, nudges=None, tag_names=()):
        tid = new_id()
        f = {"id": s(tid), "title": s(title), "status": s("done" if done_at else "open"),
             "priority": s(priority), "created_at": ts(created),
             "life_area_id": s(areas[area]["id"])}
        if notes:
            f["notes"] = s(notes)
        if due is not None:
            f["due_date"] = ts(due)
        if done_at is not None:
            f["completed_at"] = ts(done_at)
        if focus is not None:
            f["focus_duration_seconds"] = i(focus)
        if nudges is not None:
            f["nudges_count"] = i(nudges)
        tag_list = [s(tags[n]) for n in tag_names if n in tags]
        if tag_list:
            f["tag_ids"] = arr(tag_list)
        out.append((tid, f))
        by_key[key] = {"id": tid, "title": title, "emoji": areas[area]["emoji"]}

    # --- open: overdue (due = local start of that day, TaskDueChoice convention) ---
    task("council_tax", "Pay the council tax instalment", "Money", "p1", at(-9, 20, 10),
         due=day(-2), notes="Reference number is on the letter in the kitchen drawer.",
         tag_names=("urgent",))
    task("parcel", "Return the Amazon parcel", "Home", "p3", at(-8, 12, 40), due=day(-4))
    # --- open: due today ---
    task("priya", "Reply to Priya about the Q4 roadmap", "Work", "p2", at(-3, 9, 15),
         due=day(0), notes="Two lines is enough: yes to the date, ask who owns the spec.",
         focus=900, nudges=2)
    task("prescription", "Order repeat prescription", "Health", "p4", at(-2, 18, 5),
         due=day(0), tag_names=("quick-win",))
    # --- open: future ---
    task("mum", "Call Mum back", "Relationships", "p3", at(-1, 21, 30), due=day(1))
    task("python", "Finish chapter 3 of the Python course", "Growth", "p2", at(-6, 19, 0),
         due=day(5), focus=1500, nudges=2)
    # --- open: undated ---
    task("onboarding", "Draft the onboarding checklist for new starters on support",
         "Work", "p3", at(-5, 10, 20))
    task("kettle", "Descale the kettle", "Home", "p4", at(-4, 8, 0),
         notes="White vinegar is under the sink. Run it twice.")
    task("dentist", "Book a dentist check-up", "Health", "p1", at(-7, 13, 45),
         tag_names=("urgent",))

    # --- done: today, then a 5-day run yesterday..-5 (current streak reads 6), then -9/-10 ---
    done_today = earlier_today(40)
    task("stretch", "Ten minutes of morning stretches", "Health", "p4",
         min(at(-1, 22, 0), done_today - timedelta(hours=1)), done_at=done_today)
    task("bins", "Put the bins out", "Home", "p3", at(-2, 9, 0), due=day(-1), done_at=at(-1, 19, 40))
    task("invoice", "Send the freelance invoice", "Money", "p2", at(-4, 11, 0), done_at=at(-2, 10, 25))
    task("standup", "Prep notes for Monday stand-up", "Work", "p3", at(-5, 16, 0), done_at=at(-3, 15, 5))
    task("birthday", "Order Jo's birthday card", "Relationships", "p2", at(-6, 20, 0), done_at=at(-4, 8, 50))
    task("run", "Go for a 20-minute run", "Health", "p3", at(-6, 7, 0), done_at=at(-5, 7, 35))
    task("recycling", "Sort out the recycling", "Home", "p4", at(-12, 9, 0), done_at=at(-9, 18, 15))
    task("course_signup", "Sign up for the Python course", "Growth", "p3", at(-13, 20, 0),
         done_at=at(-10, 21, 5))
    return out, by_key


def build_captures(areas):
    out = []

    def capture(content, kind, created, **extra):
        cid = new_id()
        f = {"id": s(cid), "content": s(content), "kind": s(kind), "processed": b(False),
             "created_at": ts(created)}
        f.update(extra)
        out.append((cid, f))

    # Untriaged inbox (processed=false, no `seen`).
    capture("Book the car in for its MOT", "note", earlier_today(25))
    capture("ok so the thing with the garden fence — the panel by the shed is loose again and "
            "if it goes in the wind it'll hit next door's car, so either I ring the landlord "
            "Monday or just buy the brackets myself (B&Q had them?) but then do I get the money "
            "back off the rent, need to check the tenancy agreement first",
            "note", earlier_today(70))
    capture("https://www.nhs.uk/conditions/attention-deficit-hyperactivity-disorder-adhd/",
            "link", earlier_today(110))
    capture("Ask Sam about the spare key", "task", at(-1, 17, 50))
    # Already triaged via Sorted (CaptureInboxService+Triage.swift:47): seen + filed + stamped,
    # processed stays false. clearedAt yesterday so it doesn't feed today's ring.
    capture("Look into switching energy supplier", "note", at(-2, 21, 10),
            seen=b(True), lifeAreaId=s(areas["Money"]["id"]), clearedAt=ts(at(-1, 9, 30)))
    return out


def build_logs(areas):
    out = []

    def log(kind, body, when, *, energy=None, mood=None, area=None):
        lid = new_id()
        f = {"id": s(lid), "type": s(kind), "body": s(body), "entry_date": ts(when),
             "created_at": ts(when)}
        if energy:
            f["energy_level"] = s(energy)
        if mood:
            f["mood_emoji"] = s(mood)
        if area:
            f["life_area_id"] = s(areas[area]["id"])
        out.append((lid, f))

    log("journal", "Woke up before the alarm for once. Stretched, then did the Priya reply in my "
        "head in the shower — writing it is the easy part now.", earlier_today(15),
        energy="medium", mood="🧠")
    log("journal", "Flat afternoon. Got the bins out and nothing else after 3pm. Not beating myself "
        "up about it — tomorrow's list is short.", at(-1, 21, 45), energy="low", mood="😴",
        area="Health")
    # A quick `.log` never carries energy/mood (LogValidation enforces it).
    log("log", "Stand-up notes done early. Hyperfocus window 2–4pm again.", at(-3, 16, 30))
    return out


def build_nudges():
    out = []
    # DUE NOW: daily, fire time ~60 min ago; last fired (dismissed) yesterday, so the next fire
    # after last_fired_at is today's, which has elapsed -> NudgeDueness.isNudgeDue == true.
    fire = NOW - timedelta(minutes=60)
    fire = fire.replace(minute=(fire.minute // 5) * 5, second=0, microsecond=0)
    last_fired = fire - timedelta(days=1) + timedelta(minutes=4)
    nid = new_id()
    out.append((nid, {
        "id": s(nid), "label": s("Drink a glass of water"),
        "schedule": s(f"{fire.minute} {fire.hour} * * *"), "active": b(True),
        "last_fired_at": ts(last_fired),
        "completion_dates": arr([ts(last_fired - timedelta(days=1)), ts(last_fired)]),
        "created_at": ts(day(-10).replace(hour=8)), "updated_at": ts(last_fired),
    }))
    # UPCOMING: weekly on tomorrow's weekday at 18:30; created now, never fired -> the first
    # occurrence after created_at is tomorrow 18:30 -> not due, listed under "upcoming".
    tomorrow = day(1)
    created = NOW - timedelta(minutes=5)
    nid = new_id()
    out.append((nid, {
        "id": s(nid), "label": s("Plan the week ahead"),
        "schedule": s(f"30 18 * * {cron_weekday(tomorrow)}"), "active": b(True),
        "created_at": ts(created), "updated_at": ts(created),
    }))
    return out


def build_focus_sessions(task_refs):
    """Six completed sprints on three days of the CURRENT Monday-anchored week
    (FocusAnalytics.currentWeek, Focus/FocusAnalytics.swift:31-41)."""
    out = []
    # Today, yesterday and 3 days ago all sit inside the Mon-anchored week from Thursday on.
    # Run Mon-Wed and the older day(s) fall into LAST week — warned, not silently reshaped.
    past_offsets = (-1, -3) if NOW.weekday() >= 3 else (-1, -2)
    if NOW.weekday() < 2:
        print("WARNING: early in the week; some focus sessions land in last week's chart",
              file=sys.stderr)

    def session(ref_key, minutes, ended):
        sid = new_id()
        secs = minutes * 60
        ref = task_refs[ref_key]
        started = ended - timedelta(seconds=secs)
        out.append((sid, {
            "id": s(sid), "task_id": s(ref["id"]), "task_title": s(ref["title"]),
            "life_area_emoji": s(ref["emoji"]), "planned_seconds": i(secs),
            "focused_seconds": i(secs), "checkpoints_reached": i(2),
            "completed_naturally": b(True), "started_at": ts(started), "ended_at": ts(ended),
            "confirmed_at": ts(ended + timedelta(seconds=20)),
        }))

    # Today: one 15-min sprint on the best-next-move task (lights focusLoggedTodayLabel), one 25.
    today_end_1 = max(NOW - timedelta(minutes=20), TODAY + timedelta(minutes=16))
    today_end_2 = max(NOW - timedelta(minutes=50), TODAY + timedelta(minutes=16))
    d1, d2 = past_offsets
    for ref_key, minutes, ended in [
        ("priya", 15, today_end_1), ("python", 25, today_end_2),
        ("python", 25, at(d1, 14, 30)), ("bins", 15, at(d1, 19, 35)),
        ("standup", 25, at(d2, 14, 45)), ("priya", 15, at(d2, 16, 10)),
    ]:
        session(ref_key, minutes, min(ended, NOW - timedelta(minutes=1)))
    return out


# --------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------
def load_sidecar():
    if SIDECAR.exists():
        return json.loads(SIDECAR.read_text())
    return {"emulator": EMULATOR_ORIGIN, "uid": UID, "docs": []}


def save_sidecar(data):
    SIDECAR.write_text(json.dumps(data, indent=2, ensure_ascii=False))


def cleanup():
    data = load_sidecar()
    if data.get("emulator") != EMULATOR_ORIGIN or data.get("uid") != UID:
        raise SystemExit("sidecar targets a different emulator/uid; refusing")
    remaining = []
    for entry in data["docs"]:
        coll, doc_id = entry["collection"], entry["id"]
        if coll not in SEED_COLLECTIONS or not UUID_UPPER.match(doc_id):
            raise SystemExit(f"sidecar entry looks wrong, refusing: {entry}")
        status, payload = _request("DELETE", f"{USER_ROOT}/{coll}/{doc_id}")
        if status == 200:
            print(f"deleted  {coll}/{doc_id}")
        else:
            print(f"FAILED   {coll}/{doc_id} ({status}): {payload}", file=sys.stderr)
            remaining.append(entry)
    data["docs"] = remaining
    save_sidecar(data)
    print(f"cleanup done; {len(remaining)} left in {SIDECAR}")


def main():
    global DRY_RUN
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="GETs only; print docs; write nothing")
    mode.add_argument("--cleanup", action="store_true", help="delete ids recorded in the sidecar")
    args = parser.parse_args()
    DRY_RUN = args.dry_run

    if args.cleanup:
        cleanup()
        return

    print(f"now (local): {NOW.isoformat()}   emulator: {USER_ROOT}")
    areas, tags, existing_task_ids = resolve_existing()
    print("life areas:", {n: a["id"] for n, a in sorted(areas.items())})
    print("tags:", tags)

    tasks, task_refs = build_tasks(areas, tags)
    plan = [("tasks", tasks), ("captures", build_captures(areas)), ("logs", build_logs(areas)),
            ("nudges", build_nudges()), ("focus_sessions", build_focus_sessions(task_refs))]

    area_ids = {a["id"] for a in areas.values()}
    task_ids = existing_task_ids | {tid for tid, _ in tasks}
    tag_ids = set(tags.values())
    for collection, docs in plan:
        for doc_id, fields in docs:
            self_check(collection, doc_id, fields, area_ids, task_ids, tag_ids)
    total = sum(len(d) for _, d in plan)
    print(f"self-check passed for {total} documents")

    sidecar = load_sidecar()
    for collection, docs in plan:
        print(f"\n== {collection} ({len(docs)})")
        for doc_id, fields in docs:
            path = f"users/{UID}/{collection}/{doc_id}"
            if DRY_RUN:
                print(f"[dry-run] PATCH {path}")
                print(json.dumps({"fields": fields}, ensure_ascii=False))
                continue
            url = f"{USER_ROOT}/{collection}/{doc_id}?currentDocument.exists=false"
            status, payload = _request("PATCH", url, {"fields": fields})
            if status != 200:
                raise SystemExit(f"write failed {path} ({status}): {payload}")
            sidecar["docs"].append({"collection": collection, "id": doc_id})
            save_sidecar(sidecar)   # after every write, so a partial run is still cleanable
            print(f"wrote {path}")

    if DRY_RUN:
        print(f"\n[dry-run] {total} documents NOT written. Nothing sent but GETs.")
    else:
        print(f"\nwrote {total} documents; ids recorded in {SIDECAR}")


if __name__ == "__main__":
    main()
