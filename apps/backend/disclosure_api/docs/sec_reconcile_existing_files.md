# SEC reconcile map for existing files

This document tracks the required existing-file reconciliation on top of `sec-thin-slice-upload-v3`.

## Why this exists
The current branch contains additive SEC runtime files, but several required existing-file diffs are still missing. Until these land, the branch is not the authoritative pre-expansion baseline for `sec_current_forms`.

## Files that must be reconciled

### 1. lib/disclosure_automation/schemas.ex
Required outcome:
- `SourceRegistry` includes runtime spine fields such as `adapter_key`, `region_code`, `discovery_mode`, `hydrate_mode`, `default_home_market_region_code`, `source_class`, `default_source_tier`
- `RawDocument` includes additive SEC/runtime fields such as `document_identity`, `document_type`, `document_role`, `mime_type`, `source_metadata`
- `CanonicalFeedItem` includes additive runtime fields such as `event_id`, `region_code`, `home_market_region_code`, `canonical_event_type`, `event_family`, `contract_v1`
- add schema modules for `SourceCursor`, `RawEvent`, `CanonicalItemSource`, and `FeedSnapshot`
- align changesets and constraints to the migration names already present in the branch

### 2. lib/disclosure_automation_web/router.ex
Required outcome:
- add `GET /api/feed/hero`
- add `GET /api/feed/region/:region_code`
- add `GET /api/events/:event_id`
- preserve the existing health, digest, source-health, and manual poll routes

### 3. lib/disclosure_automation_web/controllers.ex
Required outcome:
- wire runtime read-path controllers used by `Feed.get_hero/0`, `Feed.get_region/1`, and `Feed.get_event/1`
- extend admin poll handling to accept `inline_feed`
- keep `inline_feed` scoped to admin, smoke, and debug usage only

### 4. lib/disclosure_automation/runtime/sec_adapter.ex
Required outcome:
- fix xmerl xpath call direction
- robustly stringify xpath tuple and string-like results
- harden fixture lookup for string and integer-like keys
- fall back to URL-derived fixture paths when config lookup misses
- preserve accepted-time parsing from detail index with deterministic atom fallback only
- remove trailing SEC closing tags from excerpt-driven summary source text

### 5. lib/disclosure_automation/pipeline.ex
Required outcome:
- open generic runtime adapter dispatch with minimal diff from the legacy path
- default missing `metadata` to an empty map before persistence
- on repeated poll, use no-op conflict handling followed by re-read for `raw_events`, `canonical_feed_items`, and `canonical_item_sources`
- ensure representative-source inserts never reference an unresolved canonical item id
- keep immutable raw-document semantics
- allow `inline_feed=true` to rebuild snapshots synchronously for smoke and admin verification

## Order of application
1. schemas
2. router and controllers
3. sec_adapter
4. pipeline
5. tests and smoke verification
6. only then expand beyond `6-K`
