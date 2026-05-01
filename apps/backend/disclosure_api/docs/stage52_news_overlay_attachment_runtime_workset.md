# Stage 5.2 news overlay attachment runtime workset

This document defines the recommended implementation sequence for moving from Stage 5.1 migration-free raw-staging projection to Stage 5.2 dedicated overlay attachment storage.

This is a planning document only. It does not add database migrations, schemas, runtime code, tests, fixtures, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 947a516133781e110b84dabc253534324cc1cf25
base commit source: PR #88 Lock Stage 5.1 news overlay feed-visible rendering
locked Stage 5.1 feed field: news_overlays[]
locked Stage 5.1 event route: GET /api/events/:event_id/news-overlay
stage: Stage 5.2 runtime workset
status: design-only
```

## Recommended PR sequence

Stage 5.2 should be split into small PRs:

```text
PR A: Add news_overlay_attachments migration and schema
PR B: Add deterministic materializer from locked Stage 5.1 raw staging
PR C: Add optional read path preference for materialized attachments
PR D: Lock Stage 5.2 attachment storage after PASS evidence
```

Do not combine all four in one PR.

## PR A: migration and schema

Recommended branch:

```text
chatgpt-stage52-overlay-attachment-schema-v1
```

Allowed scope:

```text
one migration for news_overlay_attachments
NewsOverlayAttachment Ecto schema
changeset validations
schema/unit tests
manual smoke doc
```

Disallowed scope:

```text
runtime materializer
feed/API behavior switch
fixtures
provider fetches
scheduler changes
canonical feed mutations
```

Required tests:

```text
valid attachment changeset passes
canonical_fact_override=true rejected
overlay_mode other than attach_only rejected
unknown display_state rejected
non-news document_role rejected
non-reputable source_tier rejected
duplicate attachment rejected by unique constraint
Stage 5.1 regressions still pass
```

## PR B: deterministic materializer

Recommended branch:

```text
chatgpt-stage52-overlay-attachment-materializer-v1
```

Allowed scope:

```text
materializer module from Stage 5.1 raw staging to news_overlay_attachments
idempotency tests
manual smoke doc
redaction checks
```

Materializer behavior:

```text
load official TDnet canonical item
load Stage 5.1 raw-staged Reuters overlay candidate
require direct official identifier match
insert or update one news_overlay_attachments row
set canonical_fact_override=false
set overlay_mode=attach_only
set display_state=visible
never mutate canonical_feed_items
never create Reuters CanonicalFeedItem
```

Required tests:

```text
materializer creates one attachment row for locked Reuters fixture
materializer is idempotent on repeated runs
materializer creates zero rows without direct official identifier match
official TDnet canonical item remains unchanged
no Reuters canonical item is created
redaction check passes
Stage 5.1 API/feed regressions still pass
```

## PR C: read path preference

Recommended branch:

```text
chatgpt-stage52-overlay-attachment-read-path-v1
```

Allowed scope:

```text
read model optional preference for news_overlay_attachments
API/feed tests showing same response shape
compatibility fallback to Stage 5.1 raw projection if enabled
manual smoke doc
```

Recommended behavior:

```text
if visible attachment rows exist, read overlays from news_overlay_attachments
if no visible attachment rows exist, continue Stage 5.1 raw-staging projection behavior
preserve item.overlays[] event API shape
preserve news_overlays[] feed shape
```

Required tests:

```text
API route response unchanged after materialization
feed response unchanged after materialization
fallback path still works when no attachment rows exist
official fields unchanged
citation ordering unchanged
```

## PR D: lock close-out

Recommended branch:

```text
chatgpt-stage52-overlay-attachment-lock-closeout-v1
```

Allowed scope:

```text
docs-only close-out
verification evidence
merge SHA references
runtime lock status
remaining out-of-scope list
```

## Implementation guardrails

All Stage 5.2 implementation PRs must preserve:

```text
official TDnet canonical item is the source of truth
Reuters overlay is attach-only context
canonical_fact_override=false
no Reuters canonical feed item
no news-only canonical feed item
no official field mutation
no full Reuters article text storage
no provider secrets
```

## Required full regression set

Runtime PRs should run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Additional Stage 5.2 tests should be added per PR.

## Manual smoke requirements

Manual smoke for materializer/read path should verify:

```text
official TDnet item exists
Reuters raw staging row exists
materializer creates exactly one attachment row
re-running materializer leaves exactly one attachment row
API event overlay response still has one overlay
feed digest response still has one news_overlays[] entry
official TDnet fields unchanged
no Reuters canonical feed item exists
redaction check passes
```

## Redaction checks

All implementation PRs must confirm no new exposure of:

```text
Subscription-Key values
Authorization header values
Cookie header values
Reuters credentials
EDINET keys
signed private URLs
full Reuters article text
provider request headers
```

## Stop conditions

Stop and do not merge if any implementation PR:

```text
mutates canonical_feed_items official fields
creates Reuters CanonicalFeedItem
creates news-only CanonicalFeedItem
stores full Reuters article text
adds provider fetches without separate design
changes feed ordering/count unexpectedly
changes existing event/API response shape unexpectedly
fails Stage 5.1 regressions
```

## Future after Stage 5.2 lock

After Stage 5.2 attachment storage is locked, possible next stages are:

```text
second news overlay fixture
multiple provider overlays
provider-backed news ingestion
cross-source duplicate_group_key materialization
attachment review/admin tooling
```
