#!/usr/bin/env python3
import argparse
import json
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


MONTHS = [
    "JANUARY",
    "FEBRUARY",
    "MARCH",
    "APRIL",
    "MAY",
    "JUNE",
    "JULY",
    "AUGUST",
    "SEPTEMBER",
    "OCTOBER",
    "NOVEMBER",
    "DECEMBER",
]
MONTH_BY_NAME = {name: index + 1 for index, name in enumerate(MONTHS)}
DISPLAY_MONTHS = {
    index + 1: name.title()
    for index, name in enumerate(MONTHS)
}

DATE_HEADING_RE = re.compile(
    r"^\s*(?P<day>[1-9]|[12]\d|3[01])\s+(?P<month>"
    + "|".join(MONTHS)
    + r")\s*$"
)
INDEX_DATE_RE = re.compile(
    r"\b(?P<day>[1-9]|[12]\d|3[01])\s+(?P<month>"
    + "|".join(month.title() for month in MONTHS)
    + r")\b"
)
FOOTER_PAGE_RE = re.compile(r"Reproduction\s+(?P<page>\d+)\s+A Spiritual", re.IGNORECASE)
LEADER_RE = re.compile(r"[\s.\u2026\u2025\u22ef\u00b7\u2219\u25cf\u2022]+$")
DASH_TRANSLATION = str.maketrans({
    "\u2010": "-",
    "\u2011": "-",
    "\u2012": "-",
    "\u2013": "-",
    "\u2212": "-",
})


@dataclass
class ParsedPage:
    pdf_page: int
    printed_page: int | None
    lines: list[str]


def normalize_artifacts(text: str) -> str:
    return (
        text.replace("\u00a0", " ")
        .replace("\uf0be", "\u2014")
        .replace("\uf0ad", "*")
        .replace("\u2018", "\u2018")
        .replace("\u2019", "\u2019")
    )


def normalize_keyword(text: str) -> str:
    return re.sub(r"\s+", " ", normalize_artifacts(text).translate(DASH_TRANSLATION)).strip()


def normalize_title_for_compare(text: str) -> str:
    value = normalize_keyword(text)
    value = value.replace("\u201c", '"').replace("\u201d", '"')
    value = value.replace("\u2018", "'").replace("\u2019", "'")
    return value.casefold()


def is_footer_line(line: str) -> bool:
    stripped = line.strip()
    return (
        "NA World Services" in stripped
        or stripped.startswith("To purchase paper copies")
        or stripped.startswith("To download")
    )


def cleaned_page(pdf_page: int, text: str) -> ParsedPage:
    printed_page = None
    lines: list[str] = []
    for raw_line in text.splitlines():
        line = normalize_artifacts(raw_line).rstrip()
        footer_match = FOOTER_PAGE_RE.search(line)
        if footer_match:
            printed_page = int(footer_match.group("page"))
        if is_footer_line(line):
            continue
        lines.append(line)

    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return ParsedPage(pdf_page=pdf_page, printed_page=printed_page, lines=lines)


def extract_pages_with_pypdf(pdf_path: Path) -> list[str] | None:
    try:
        from pypdf import PdfReader  # type: ignore
    except ImportError:
        return None

    reader = PdfReader(str(pdf_path))
    return [page.extract_text() or "" for page in reader.pages]


def extract_pages_with_pdftotext(pdf_path: Path) -> list[str]:
    pdftotext = shutil.which("pdftotext")
    if not pdftotext:
        raise RuntimeError(
            "Could not import pypdf and could not find pdftotext. "
            "Install pypdf or Poppler pdftotext, then rerun extraction."
        )
    result = subprocess.run(
        [pdftotext, "-layout", str(pdf_path), "-"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    pages = result.stdout.split("\f")
    if pages and not pages[-1].strip():
        pages.pop()
    return pages


def extract_pages(pdf_path: Path) -> tuple[list[str], str]:
    pypdf_pages = extract_pages_with_pypdf(pdf_path)
    if pypdf_pages is not None:
        return pypdf_pages, "pypdf"
    return extract_pages_with_pdftotext(pdf_path), "pdftotext"


def find_date_heading(lines: list[str]) -> tuple[int, re.Match[str]] | None:
    for index, line in enumerate(lines):
        match = DATE_HEADING_RE.match(line)
        if match:
            return index, match
    return None


def leading_spaces(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def clean_title_segment(segment: str) -> str:
    value = normalize_artifacts(segment)
    value = LEADER_RE.sub("", value.strip())
    value = re.sub(r"\s+", " ", value)
    return value.translate(DASH_TRANSLATION).strip()


def parse_index_entries_from_line(line: str, keyword: str) -> list[dict[str, str | int]]:
    matches = list(INDEX_DATE_RE.finditer(line))
    entries: list[dict[str, str | int]] = []
    segment_start = 0
    for match in matches:
        title = clean_title_segment(line[segment_start:match.start()])
        segment_start = match.end()
        if not title:
            continue
        month = MONTH_BY_NAME[match.group("month").upper()]
        day = int(match.group("day"))
        entries.append({
            "id": f"{month:02d}-{day:02d}",
            "month": month,
            "day": day,
            "title": title,
            "keyword": keyword,
        })
    return entries


def parse_principle_index(pages: list[str]) -> tuple[dict[str, dict[str, str | int]], list[str]]:
    index_by_id: dict[str, dict[str, str | int]] = {}
    review: list[str] = []
    current_keyword: str | None = None
    in_index = False

    for pdf_page, page_text in enumerate(pages, start=1):
        page = cleaned_page(pdf_page, page_text)
        if any("List of Principles, Titles, and Dates" in line for line in page.lines):
            in_index = True
        if not in_index:
            continue

        for line in page.lines:
            stripped = line.strip()
            if not stripped or "List of Principles, Titles, and Dates" in stripped:
                continue
            if INDEX_DATE_RE.search(line):
                if current_keyword is None:
                    review.append(f"Index entry before principle heading on PDF page {pdf_page}: {stripped}")
                    continue
                for entry in parse_index_entries_from_line(line, current_keyword):
                    entry_id = str(entry["id"])
                    if entry_id in index_by_id:
                        review.append(f"Duplicate index mapping for {entry_id}")
                    index_by_id[entry_id] = entry
                continue

            if len(stripped) < 60 and not any(marker in stripped for marker in ("...", "\u2026")):
                current_keyword = normalize_keyword(stripped)

    return index_by_id, review


def paragraph_text(lines: list[str]) -> str:
    paragraphs: list[str] = []
    current: list[str] = []

    def flush() -> None:
        nonlocal current
        if current:
            paragraphs.append(re.sub(r"\s+", " ", "".join(current)).strip())
            current = []

    for raw_line in lines:
        if is_footer_line(raw_line):
            continue
        line = normalize_artifacts(raw_line).strip()
        if not line:
            flush()
            continue
        if line.startswith("\u2014") and current:
            flush()
        if current and current[-1].endswith("-"):
            current.append(line)
        elif current:
            current.append(" " + line)
        else:
            current.append(line)
        if line.startswith("\u2014"):
            flush()

    flush()
    return "\n\n".join(paragraphs).strip()


def parse_daily_entry(page: ParsedPage, index_by_id: dict[str, dict[str, str | int]]) -> tuple[dict[str, object] | None, list[str]]:
    review: list[str] = []
    heading = find_date_heading(page.lines)
    if heading is None:
        return None, review

    heading_index, match = heading
    month = MONTH_BY_NAME[match.group("month")]
    day = int(match.group("day"))
    entry_id = f"{month:02d}-{day:02d}"

    cursor = heading_index + 1
    while cursor < len(page.lines) and not page.lines[cursor].strip():
        cursor += 1

    title_lines: list[str] = []
    while cursor < len(page.lines):
        line = page.lines[cursor]
        stripped = line.strip()
        if not stripped:
            cursor += 1
            if title_lines:
                break
            continue
        if leading_spaces(line) >= 20 and not stripped.startswith("\u2014"):
            title_lines.append(stripped)
            cursor += 1
            continue
        break

    if not title_lines and cursor < len(page.lines):
        title_lines.append(page.lines[cursor].strip())
        cursor += 1

    title = clean_title_segment(" ".join(title_lines))
    body = paragraph_text(page.lines[cursor:])
    index_entry = index_by_id.get(entry_id)
    keyword = title
    if index_entry:
        keyword = str(index_entry["keyword"])
        indexed_title = str(index_entry["title"])
        if normalize_title_for_compare(title) != normalize_title_for_compare(indexed_title):
            review.append(
                f"{entry_id}: title differs from index on PDF page {page.pdf_page}: "
                f"daily={title!r}, index={indexed_title!r}"
            )
    else:
        review.append(f"{entry_id}: missing principle keyword mapping; using title as keyword")

    if not body:
        review.append(f"{entry_id}: empty body")
    if page.printed_page is None:
        review.append(f"{entry_id}: missing printed page number")

    entry = {
        "id": entry_id,
        "month": month,
        "day": day,
        "displayDate": f"{DISPLAY_MONTHS[month]} {day}",
        "keyword": keyword,
        "title": title,
        "body": body,
        "page": page.printed_page,
    }
    return entry, review


def parse_entries(pages: list[str]) -> tuple[list[dict[str, object]], list[str], dict[str, int]]:
    index_by_id, index_review = parse_principle_index(pages)
    entries: list[dict[str, object]] = []
    review: list[str] = list(index_review)

    for pdf_page, page_text in enumerate(pages, start=1):
        page = cleaned_page(pdf_page, page_text)
        entry, entry_review = parse_daily_entry(page, index_by_id)
        review.extend(entry_review)
        if entry:
            entries.append(entry)

    entries.sort(key=lambda item: (int(item["month"]), int(item["day"])))
    stats = {
        "index_mappings": len(index_by_id),
        "entries": len(entries),
        "manual_review": len(review),
    }
    return entries, review, stats


def accepted_count_reason(entries: list[dict[str, object]]) -> str:
    ids = {str(entry["id"]) for entry in entries}
    if len(entries) == 366 and "02-29" in ids:
        return "accepted: 366 entries with February 29"
    if len(entries) == 365 and "02-29" not in ids:
        return "accepted: 365 entries without February 29"
    return "unexpected entry count"


def write_json(entries: list[dict[str, object]], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(entries, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract daily principles from the source PDF.")
    parser.add_argument("pdf", type=Path, help="Input PDF path")
    parser.add_argument("output_json", type=Path, help="Output principles.json path")
    args = parser.parse_args()

    if not args.pdf.exists():
        print(f"Input PDF not found: {args.pdf}", file=sys.stderr)
        return 2

    pages, extractor = extract_pages(args.pdf)
    entries, review, stats = parse_entries(pages)

    if extractor == "pypdf" and len(entries) not in (365, 366) and shutil.which("pdftotext"):
        pages = extract_pages_with_pdftotext(args.pdf)
        extractor = "pdftotext"
        entries, review, stats = parse_entries(pages)

    write_json(entries, args.output_json)

    print(f"Extractor: {extractor}")
    print(f"PDF pages read: {len(pages)}")
    print(f"Principle index mappings: {stats['index_mappings']}")
    print(f"Entries extracted: {len(entries)} ({accepted_count_reason(entries)})")
    print(f"Manual review entries: {len(review)}")
    if review:
        for item in review:
            print(f"- {item}")
    print(f"Wrote: {args.output_json}")
    return 0 if len(entries) in (365, 366) else 1


if __name__ == "__main__":
    raise SystemExit(main())
