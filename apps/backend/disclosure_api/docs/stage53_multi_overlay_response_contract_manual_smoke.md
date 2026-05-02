# Stage 5.3 multi-overlay response contract manual smoke

This manual smoke verifies Stage 5.3 multi-overlay API/feed/read-model response ordering and citation separation after Reuters and Bloomberg overlays are materialized.

## Scope

```text
stage: Stage 5.3 PR C
scope: multi-overlay response tests and ordering guardrails
runtime changes: none expected
API shape: item.overlays[]
feed shape: news_overlays[]
official canonical item mutation: forbidden
```

## Guardrails

This PR may add only:

```text
multi-overlay response contract tests
manual smoke doc
```

It must not add:

```text
migrations
schema changes
fixture changes
runtime staging changes
materializer changes
read path changes
scheduler changes
provider/live Reuters or Bloomberg fetch
new routes
feed/controller endpoint changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Step 1: run targeted multi-overlay response test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

Expected:

```text
4 tests, 0 failures
```

## Step 2: run Stage 5.3 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_second_news_overlay_staging_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_second_news_overlay_fixture_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run Stage 5.2 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_schema_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: run Stage 5.1 regressions

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

## Step 5: run TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 6: verify read model ordering and citations

After staging Reuters, staging Bloomberg, and materializing both overlays:

```elixir
DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel.get_by_event_id(event_id)
```

Expected:

```text
item.overlays length: 2
item.overlays[0].provider: Reuters
item.overlays[0].publishedAt: 2026-04-30T10:30:00Z
item.overlays[1].provider: Bloomberg
item.overlays[1].publishedAt: 2026-04-30T10:45:00Z
canonicalFactOverride: false for both overlays
```

Flattened citation order should be:

```text
1. official TDnet citation, isCanonicalSource=true
2. Reuters overlay citation, isCanonicalSource=false
3. Bloomberg overlay citation, isCanonicalSource=false
```

## Step 7: verify event overlay API

Call:

```text
GET /api/events/:event_id/news-overlay
```

Expected:

```text
HTTP 200
item.overlays length: 2
item.overlays[0].provider: Reuters
item.overlays[1].provider: Bloomberg
item.citations remains official citations only
item.overlays[].citations remain overlay citations only
canonicalFactOverride=false for both overlays
```

## Step 8: verify feed digest

Call:

```text
GET /api/feed/digest/latest?edition=breaking
```

Expected:

```text
HTTP 200
item_count remains 1
items[0].event_id remains official TDnet event id
items[0].news_overlays length: 2
news_overlays[0].provider: Reuters
news_overlays[1].provider: Bloomberg
canonical_fact_override=false for both overlays
Reuters URL does not replace official_source_url
Bloomberg URL does not replace official_source_url
```

## Step 9: verify no canonical mutation

Expected storage state:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = Reuters overlay id: 0
canonical_feed_items where event_id = Bloomberg overlay id: 0
official TDnet title unchanged
official TDnet published_at unchanged
official TDnet official_source_url unchanged
official TDnet stable_external_id unchanged
```

## Step 10: redaction check

Check diff, logs, raw staging payloads, materialized attachments, API responses, and feed responses.

Must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
Reuters credentials
Bloomberg credentials
signed private URLs
full article text
provider request headers
```

## PASS criteria

```text
Stage 5.3 multi-overlay response contract test: PASS
Stage 5.3 staging/materializer regression: PASS
Stage 5.3 fixture policy regression: PASS
Stage 5.2 read path regression: PASS
Stage 5.2 materializer regression: PASS
Stage 5.2 schema regression: PASS
Stage 5.1 feed-visible regression: PASS
Stage 5.1 API exposure regression: PASS
Stage 5.1 read model regression: PASS
Stage 5 raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
read model overlay order Reuters then Bloomberg: PASS
API overlay order Reuters then Bloomberg: PASS
feed overlay order Reuters then Bloomberg: PASS
citation separation: PASS
canonical no-mutation check: PASS
redaction check: PASS
no runtime changes
no fixture changes
no migrations/schema changes
no routes/feed-controller endpoint changes
```
