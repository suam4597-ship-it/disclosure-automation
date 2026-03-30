#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "apps/backend/config/source_registry.sample.yaml",
    "apps/backend/config/delivery_windows.sample.yaml",
    "apps/backend/config/parser_capabilities.sample.yaml",
    "apps/backend/sql/0001_phase0_core_schema.sql",
    "apps/backend/sql/0001_phase0_core_schema.rollback.sql",
    "apps/backend/openapi/feed-digest.openapi.yaml",
    "apps/backend/openapi/admin-source-health.openapi.yaml",
    "apps/backend/fixtures/daily_feed.sample.json",
]


def fail(message: str) -> int:
    print(f"[phase0-validate] ERROR: {message}")
    return 1


def validate_files() -> list[str]:
    missing: list[str] = []
    for relative in REQUIRED_FILES:
        path = ROOT / relative
        if not path.exists():
            missing.append(relative)
    return missing


def validate_fixture() -> str | None:
    fixture_path = ROOT / "apps/backend/fixtures/daily_feed.sample.json"
    try:
        payload = json.loads(fixture_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return "fixture file missing"
    except json.JSONDecodeError as exc:
        return f"fixture json invalid: {exc}"

    required_top_level = [
        "digest_date",
        "edition",
        "timezone",
        "generated_at",
        "generated_by",
        "item_count",
        "items",
    ]
    missing = [key for key in required_top_level if key not in payload]
    if missing:
        return f"fixture missing top-level keys: {', '.join(missing)}"

    items = payload.get("items")
    if not isinstance(items, list) or not items:
        return "fixture items must be a non-empty list"

    required_item_keys = [
        "story_key",
        "priority_rank",
        "headline",
        "summary",
        "canonical_url",
        "published_at",
        "source",
    ]
    for index, item in enumerate(items, start=1):
        if not isinstance(item, dict):
            return f"fixture item #{index} is not an object"
        missing_item_keys = [key for key in required_item_keys if key not in item]
        if missing_item_keys:
            return f"fixture item #{index} missing keys: {', '.join(missing_item_keys)}"

    if payload.get("item_count") != len(items):
        return "fixture item_count does not match items length"

    return None


def main() -> int:
    missing = validate_files()
    if missing:
        return fail("missing required files: " + ", ".join(missing))

    fixture_error = validate_fixture()
    if fixture_error:
        return fail(fixture_error)

    print("[phase0-validate] OK")
    print("[phase0-validate] Required files present and sample fixture shape looks consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
