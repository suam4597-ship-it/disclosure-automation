# SEC repeated poll idempotency contract

This file records the minimum expected behavior for running the same `sec_current_forms` poll twice.

## API expectations
- first poll succeeds
- second poll also succeeds
- latest digest stays readable
- event endpoint stays readable
- source-health stays readable

## Storage expectations
After the second poll there should still be:
- one logical raw document per source and external accession
- one logical raw event per source and event key
- one logical canonical item per event id
- one representative canonical source row per canonical item
- no duplicate authority mapping rows for the same item, event, and role

## Runtime values that must stay stable for the verified 6-K path
- item_count stays 1
- event_id stays stable
- published_at_local stays 2026-04-01T06:15:02-04:00
- published_at_utc stays 2026-04-01T10:15:02Z
- filing_date_local stays 2026-04-01
- accepted_time_fallback stays false

## Implementation note
Conflict no-op paths must re-read the existing row instead of assuming a fresh insert exists.

## Expansion gate
Do not expand beyond 6-K until this contract and the dedupe SQL checks are green.
