#!/usr/bin/env python3
"""
Stage C.6-INFRA-a, Step 5 — one-off, idempotent backfill of `status` on existing
capture rows in the DynamoDB `LifeOS` table.

Existing capture items were written with only `processed` (bool) and no `status`.
This sets:  status = "processed" if processed else "inbox",  and keeps the
`processed` mirror coupled (processed == (status == "processed")).

Safe to re-run: it recomputes the same value every time. It only ever touches
items whose SK begins with "CAPTURE#" (real captures) — never CAPTURETAG# junction
rows, tasks, logs, nudges, tags, or life areas.

Run:  python3 backfill_capture_status.py
Add:  --dry-run   to preview without writing.
"""
import argparse

import boto3
from boto3.dynamodb.conditions import Attr

TABLE_NAME = "LifeOS"
VALID = {"inbox", "needs-review", "processed"}


def main(dry_run: bool) -> None:
    table = boto3.resource("dynamodb", region_name="us-east-1").Table(TABLE_NAME)

    scanned = 0
    updated = 0
    skipped_ok = 0
    start_key = None
    while True:
        kwargs = {
            # Only real capture items. "CAPTURETAG#..." does NOT begin with "CAPTURE#".
            "FilterExpression": Attr("SK").begins_with("CAPTURE#"),
        }
        if start_key:
            kwargs["ExclusiveStartKey"] = start_key
        resp = table.scan(**kwargs)

        for item in resp.get("Items", []):
            scanned += 1
            processed = bool(item.get("processed", False))
            desired = "processed" if processed else "inbox"

            current = item.get("status")
            # If a valid non-default status is already set (e.g. needs-review), leave it,
            # but still ensure the processed mirror is coupled.
            if current in VALID:
                if bool(processed) == (current == "processed"):
                    skipped_ok += 1
                    continue
                desired = current  # keep the explicit status, fix the mirror below

            new_processed = (desired == "processed")
            print(
                f"{'[dry-run] ' if dry_run else ''}"
                f"{item['PK']} / {item['SK']}  "
                f"status -> {desired}, processed -> {new_processed}"
            )
            if not dry_run:
                table.update_item(
                    Key={"PK": item["PK"], "SK": item["SK"]},
                    UpdateExpression="SET #s = :st, #p = :pr",
                    ExpressionAttributeNames={"#s": "status", "#p": "processed"},
                    ExpressionAttributeValues={":st": desired, ":pr": new_processed},
                )
            updated += 1

        start_key = resp.get("LastEvaluatedKey")
        if not start_key:
            break

    print(
        f"\nDone. Scanned {scanned} capture item(s); "
        f"{updated} {'would be ' if dry_run else ''}updated, "
        f"{skipped_ok} already correct."
    )


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="preview without writing")
    main(ap.parse_args().dry_run)
