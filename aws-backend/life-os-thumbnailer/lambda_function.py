"""
Stage C.6-INFRA-b — life-os-thumbnailer.

Triggered by S3 ObjectCreated on the media bucket, suffix-filtered to photo originals
(`original.jpg` / `original.jpeg` / `original.png`). Reads the original, resizes to a max
~400px thumbnail with Pillow, and writes the sibling `thumb.jpg`.

Deliberately never touches DynamoDB: the capture record already stores `thumbnailKey`
deterministically at create time, so there is nothing to PATCH here (avoids a race where the
capture row may not exist yet when the thumbnail is written). Best-effort per record — a bad
image is logged and skipped, never crashing the batch.
"""
import io
import os
from urllib.parse import unquote_plus

import boto3
from PIL import Image, ImageOps

s3 = boto3.client("s3")

MAX_SIZE = int(os.environ.get("THUMB_MAX_PX", "400"))
JPEG_QUALITY = int(os.environ.get("THUMB_JPEG_QUALITY", "85"))


def _thumb_key(original_key: str) -> str:
    # captures/{userId}/{uploadId}/original.<ext>  ->  captures/{userId}/{uploadId}/thumb.jpg
    return original_key.rsplit("/", 1)[0] + "/thumb.jpg"


def handler(event, _context):
    processed = 0
    for record in event.get("Records", []):
        try:
            bucket = record["s3"]["bucket"]["name"]
            key = unquote_plus(record["s3"]["object"]["key"])

            # Defensive guards (the S3 suffix filter should already ensure this):
            # only ever act on a photo original, never on a thumb (prevents recursion).
            base = key.rsplit("/", 1)[-1]
            if not base.startswith("original.") or base == "thumb.jpg":
                print(f"skip (not an original): s3://{bucket}/{key}")
                continue

            thumb_key = _thumb_key(key)

            body = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
            img = Image.open(io.BytesIO(body))
            img = ImageOps.exif_transpose(img)  # honour camera rotation
            img = img.convert("RGB")            # drop alpha/palette so JPEG save is safe
            img.thumbnail((MAX_SIZE, MAX_SIZE))  # in-place, preserves aspect ratio

            buf = io.BytesIO()
            img.save(buf, format="JPEG", quality=JPEG_QUALITY, optimize=True)
            buf.seek(0)

            s3.put_object(
                Bucket=bucket,
                Key=thumb_key,
                Body=buf.getvalue(),
                ContentType="image/jpeg",
            )
            processed += 1
            print(f"thumbnail written: s3://{bucket}/{thumb_key}")
        except Exception as exc:  # noqa: BLE001 - best-effort; log and continue
            print(f"ERROR thumbnailing record {record.get('s3', {}).get('object', {})}: {exc}")

    return {"processed": processed}
