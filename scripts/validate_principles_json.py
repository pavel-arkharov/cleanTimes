#!/usr/bin/env python3
import argparse
import calendar
import json
import re
import sys
from pathlib import Path


REQUIRED_FIELDS = {
    "id",
    "month",
    "day",
    "displayDate",
    "keyword",
    "title",
    "body",
    "page",
}
ID_RE = re.compile(r"^(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$")
ARTIFACT_MARKERS = [
    "NA World Services",
    "Not for Reproduction",
    "na.org",
    "A Spiritual Principle a Day Approval Draft",
    "Interim WSC",
    "\f",
    "\uf0ad",
    "\uf0be",
]


def expected_ids(include_february_29: bool) -> list[str]:
    ids: list[str] = []
    for month in range(1, 13):
        for day in range(1, calendar.monthrange(2000, month)[1] + 1):
            if not include_february_29 and month == 2 and day == 29:
                continue
            ids.append(f"{month:02d}-{day:02d}")
    return ids


def validate_item(item: object, index: int) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    review: list[str] = []

    if not isinstance(item, dict):
        return [f"Item {index} is not an object"], review

    missing = REQUIRED_FIELDS - set(item.keys())
    if missing:
        errors.append(f"Item {index} missing fields: {', '.join(sorted(missing))}")
        return errors, review

    entry_id = item.get("id")
    month = item.get("month")
    day = item.get("day")
    keyword = item.get("keyword")
    title = item.get("title")
    body = item.get("body")
    page = item.get("page")

    if not isinstance(entry_id, str) or not ID_RE.match(entry_id):
        errors.append(f"Item {index} has invalid id: {entry_id!r}")
    if not isinstance(month, int) or not isinstance(day, int):
        errors.append(f"{entry_id or 'Item ' + str(index)} has non-integer month/day")
    elif month < 1 or month > 12 or day < 1 or day > calendar.monthrange(2000, month)[1]:
        errors.append(f"{entry_id} has invalid month/day: {month}/{day}")
    elif isinstance(entry_id, str) and entry_id != f"{month:02d}-{day:02d}":
        errors.append(f"{entry_id} does not match month/day {month}/{day}")

    if not isinstance(item.get("displayDate"), str) or not item["displayDate"].strip():
        errors.append(f"{entry_id} has empty displayDate")
    if not isinstance(keyword, str) or not keyword.strip():
        errors.append(f"{entry_id} has empty keyword")
    if not isinstance(title, str) or not title.strip():
        errors.append(f"{entry_id} has empty title")
    if not isinstance(body, str) or not body.strip():
        errors.append(f"{entry_id} has empty body")
    if page is not None and not isinstance(page, int):
        errors.append(f"{entry_id} has non-integer page: {page!r}")

    if isinstance(body, str):
        if len(body.strip()) < 120:
            review.append(f"{entry_id}: very short body ({len(body.strip())} chars)")
        if re.search(r"[ \t]{3,}", body) or "\n\n\n" in body:
            review.append(f"{entry_id}: excessive whitespace")
        for marker in ARTIFACT_MARKERS:
            if marker in body:
                review.append(f"{entry_id}: body contains PDF artifact marker {marker!r}")

    return errors, review


def validate_entries(entries: object) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    review: list[str] = []

    if not isinstance(entries, list):
        return ["Top-level JSON value must be a list"], review

    seen: set[str] = set()
    ids: list[str] = []
    for index, item in enumerate(entries):
        item_errors, item_review = validate_item(item, index)
        errors.extend(item_errors)
        review.extend(item_review)
        if isinstance(item, dict) and isinstance(item.get("id"), str):
            entry_id = item["id"]
            if entry_id in seen:
                errors.append(f"Duplicate id: {entry_id}")
            seen.add(entry_id)
            ids.append(entry_id)

    sorted_ids = sorted(ids)
    if ids != sorted_ids:
        review.append("Entries are not sorted by month/day")

    if len(entries) == 366:
        expected = expected_ids(include_february_29=True)
        reason = "366 entries with February 29"
    elif len(entries) == 365:
        expected = expected_ids(include_february_29=False)
        reason = "365 entries without February 29"
    else:
        expected = expected_ids(include_february_29=True)
        reason = f"unexpected count {len(entries)}"
        errors.append("Expected 365 entries without February 29 or 366 entries with February 29")

    missing = sorted(set(expected) - set(ids))
    extra = sorted(set(ids) - set(expected))
    if missing:
        errors.append(f"Missing date coverage: {', '.join(missing)}")
    if extra:
        errors.append(f"Unexpected date ids: {', '.join(extra)}")

    print(f"Entries: {len(entries)} ({reason})")
    return errors, review


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate bundled principles JSON.")
    parser.add_argument("json_path", type=Path)
    args = parser.parse_args()

    try:
        data = json.loads(args.json_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"JSON file not found: {args.json_path}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as error:
        print(f"Invalid JSON: {error}", file=sys.stderr)
        return 1

    errors, review = validate_entries(data)

    if errors:
        print("Validation errors:")
        for error in errors:
            print(f"- {error}")
    else:
        print("Validation passed")

    print(f"Manual review entries: {len(review)}")
    if review:
        for item in review:
            print(f"- {item}")

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
