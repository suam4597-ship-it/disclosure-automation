# Stage 5.2 news overlay attachment read path manual smoke

This manual smoke verifies the Stage 5.2 read path preference for materialized `news_overlay_attachments` rows.

## Scope

```text
stage: Stage 5.2 PR C
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
preferred source: news_overlay_attachments visible rows
fallback source: locked Stage 5.1 raw-staging projection
API route: GET /api/events/:event_id/news-overlay
feed field: news_overlays[]
canonical_feed_mutation: false
news_only_event_creation: false
```

## Guardrails

This PR may change only:

```text
Stage5NewsOverlayReadModel read path preference
targeted read path tests
manual smoke doc
```

It must not add:

```text
migrations
schema changes
fixture changes
scheduler changes
provider/live Reuters fetch
new routes
canonical feed mutation
Reuters CanonicalFeedItem creation
news-only CanonicalFeedItem creation
full Reuters article text storage
```

## Step 1: run targeted read path test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
```

Expected:

```text
2 tests, 0 failures
```

## Step 2: run Stage 5.2 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_schema_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run Stage 5.1 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: run TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 5: manual fallback check

With official TDnet item and Reuters raw staging present, but no `news_overlay_attachments` row:

```text
Stage5NewsOverlayReadModel.get_by_event_id(event_id)
```

Expected:

```text
one overlay returned from raw-staging projection
overlay_id matches locked Reuters overlay id
canonicalFactOverride=false
```

## Step 6: manual materialized preference check

After running:

```elixir
DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer.materialize_once(event_id)
```

Call:

```text
Stage5NewsOverlayReadModel.get_by_event_id(event_id)
```

Expected:

```text
one overlay returned from news_overlay_attachments
overlay response shape remains the same as Stage 5.1
overlay_id matches locked Reuters overlay id
articleExternalId matches locked Reuters article id
canonicalFactOverride=false
```

## Step 7: verify API and feed shape stability

Expected:

```text
GET /api/events/:event_id/news-overlay returns same item.overlays[] shape
GET /api/feed/digest/latest?edition=breaking returns same news_overlays[] shape
official TDnet item fields unchanged
digest item_count unchanged
digest item_event_ids ordering unchanged
```

## Step 8: verify no canonical mutation

Expected storage state:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = Reuters overlay id: 0
official TDnet title unchanged
official TDnet published_at unchanged
official TDnet official_source_url unchanged
official TDnet stable_external_id unchanged
```

## Step 9: redaction check

Check diff, API responses, feed responses, logs, and attachment payloads.

Must not expose:

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

## PASS criteria

```text
Stage 5.2 attachment read path test: PASS
Stage 5.2 materializer regression: PASS
Stage 5.2 schema regression: PASS
Stage 5.1 feed-visible regression: PASS
Stage 5.1 API exposure regression: PASS
Stage 5.1 read model regression: PASS
Stage 5 raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
fallback to raw projection when no attachment exists: PASS
materialized attachment preference when attachment exists: PASS
API/feed response shape unchanged: PASS
canonical no-mutation check: PASS
redaction check: PASS
no migrations
no schema changes
no fixture changes
no scheduler changes
no provider/live Reuters fetch
no new routes
```
