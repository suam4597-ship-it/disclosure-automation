# Stage 5.3 multi-overlay runtime workset

This document defines the recommended implementation sequence for adding a second news overlay fixture and verifying multi-overlay behavior on top of locked Stage 5.2 attachment storage.

This is a planning document only. It does not add fixtures, source adapters, runtime code, tests, database migrations, schedulers, provider fetches, routes, feed/controller changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: ec3d8b408e7ca15a97f5adaea72be94d4c6ee0a0
base commit source: PR #93 Lock Stage 5.2 news overlay attachment storage
locked attachment table: news_overlay_attachments
locked API shape: item.overlays[]
locked feed shape: news_overlays[]
stage: Stage 5.3 multi-overlay runtime workset
status: design-only
```

## Recommended PR sequence

Stage 5.3 should be split into small PRs:

```text
PR A: second fixture + source attrs only
PR B: raw staging/materializer support for second fixture provider
PR C: multi-overlay API/feed/read-path tests and ordering guardrails
PR D: docs-only lock close-out
```

Do not combine all four in one PR.

## PR A: second fixture + source attrs

Recommended branch:

```text
chatgpt-stage53-second-overlay-fixture-v1
```

Allowed scope:

```text
one second overlay fixture JSON
one source attrs module for the second fixture
fixture/source registration tests if needed
manual smoke doc
```

Disallowed scope:

```text
runtime materializer changes
read path changes
feed/API shape changes
migrations
schema changes
provider fetches
scheduler changes
```

Required checks:

```text
fixture has exactly one overlay
fixture contains no full article text
fixture contains no provider credentials
source_key is distinct from stage5_news_overlay_fixture
articleExternalId is distinct from Reuters fixture
canonicalEventId directly matches official TDnet event id
```

## PR B: raw staging/materializer support

Recommended branch:

```text
chatgpt-stage53-second-overlay-staging-materializer-v1
```

Allowed scope:

```text
second fixture raw staging module or generalized fixture staging helper
materializer support for second fixture provider
idempotency tests
manual smoke doc
```

Required behavior:

```text
stage second fixture raw document and raw event
create zero canonical feed items for second provider
materialize one additional news_overlay_attachments row
re-running staging/materialization remains idempotent
Reuters fixture behavior remains unchanged
```

## PR C: multi-overlay response tests

Recommended branch:

```text
chatgpt-stage53-multi-overlay-response-tests-v1
```

Allowed scope:

```text
API/feed/read model tests for multiple overlays
ordering tests
manual smoke doc
small read model ordering fix if needed
```

Required behavior:

```text
Stage5NewsOverlayReadModel returns two overlays after both fixtures are materialized
GET /api/events/:event_id/news-overlay returns item.overlays length 2
GET /api/feed/digest/latest?edition=breaking returns news_overlays length 2
digest item_count remains unchanged
official canonical feed item count remains 1
no provider canonical feed item is created
```

## PR D: lock close-out

Recommended branch:

```text
chatgpt-stage53-multi-overlay-lock-closeout-v1
```

Allowed scope:

```text
docs-only close-out
merge SHA references
PASS evidence
remaining out-of-scope list
```

## Required regression set

Runtime PRs should run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Additional Stage 5.3 tests should be added per PR.

## Manual smoke requirements

Manual smoke after implementation should verify:

```text
official TDnet item exists
Reuters overlay raw staging exists
second provider overlay raw staging exists
news_overlay_attachments has two rows for official event
API event overlay response has two overlays
feed digest response has two news_overlays entries
citation separation is preserved
official TDnet fields unchanged
no provider canonical item exists
redaction check passes
```

## Ordering requirements

The implementation must define stable ordering.

Recommended order:

```text
1. display_state
2. article published_at
3. provider
4. article_external_id
```

If this differs from existing Stage 5.2 ordering, the implementation PR must include a dedicated ordering test and explain the decision.

## Redaction checks

Every implementation PR must confirm no exposure of:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
signed private URLs
full article text
provider request headers
```

## Stop conditions

Do not merge if any implementation PR:

```text
adds live provider fetches
adds provider credentials
stores full provider article text
mutates canonical_feed_items official fields
creates provider canonical feed items
creates news-only canonical feed items
changes API/feed response top-level shape unexpectedly
changes digest item count or ordering unexpectedly
breaks locked Reuters overlay behavior
breaks Stage 5.2 attachment idempotency
```

## Future after Stage 5.3 lock

After second fixture and multi-overlay behavior are locked, possible future stages are:

```text
provider-backed ingestion design
cross-source duplicate group materialization
attachment review/admin tooling
multi-provider source health policy
```
