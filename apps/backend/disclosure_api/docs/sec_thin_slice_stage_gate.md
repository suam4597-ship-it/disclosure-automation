# SEC thin slice stage gate

This document defines the minimum exit criteria for the sec_current_forms plus 6-K phase before expanding to additional SEC forms.

## Current target
- source key: sec_current_forms
- closed form now: 6-K
- planned next forms: 8-K, SC TO-T, SC 14D-9, SC 13D/A

## Required runtime checks
These must all pass in a local Elixir and PostgreSQL environment.

1. mix compile
2. mix phx.server
3. GET /api/health
4. POST /api/admin/sources/sec_current_forms/poll?edition=breaking&use_live_fetch=false&inline_feed=true
5. GET /api/feed/hero
6. GET /api/feed/region/us
7. GET /api/feed/digest/latest?edition=breaking
8. GET /api/events/:event_id
9. GET /api/admin/source-health/sec_current_forms
10. repeated poll with the same input must return success again

## Required invariants
Run priv/ops/sec_thin_slice_dedupe_checks.sql after first poll and repeated poll.

Required outcome:
- no duplicate raw_documents by source_registry_id plus external_id
- no duplicate raw_documents by source_registry_id plus document_identity plus document_type
- no duplicate raw_events by source_registry_id plus event_key
- no duplicate canonical_feed_items by event_id
- no duplicate canonical_item_sources by canonical_feed_item_id plus raw_event_id plus source_role
- no more than one representative authority row per canonical item

The verified 6-K fixture path must preserve these values:
- published_at_local equals 2026-04-01T06:15:02-04:00
- published_at_utc equals 2026-04-01T10:15:02Z
- filing_date_local equals 2026-04-01
- source_meta.accepted_time_fallback equals false
- stable event_id
- stable latest digest item_count equals 1 after repeated poll

Before expansion, verify these quality items too:
- fact_summary_ko does not include trailing SEC closing tags
- accepted_time_fallback is false on the verified detail-index path
- country and home_market_region_code enrichment behavior is intentional
- source-health reflects the successful runtime path clearly

## Landing order
1. existing-file runtime and read-path reconciliation
2. runtime/sec_adapter.ex hotfix reconciliation
3. pipeline.ex idempotent runtime persistence reconciliation
4. repeated-poll tests and smoke tests
5. summary, detail, and enrichment cleanup
6. only then expand supported_forms_now

## Form expansion order
After every gate above is green, expand in this order:
1. 8-K
2. SC TO-T
3. SC 14D-9
4. SC 13D/A
