# Stage 5.2 news overlay attachment materializer manual smoke

This manual smoke verifies the deterministic Stage 5.2 materializer that creates `news_overlay_attachments` rows from the locked Stage 5.1 raw-staged Reuters overlay.

## Scope

```text
stage: Stage 5.2 PR B
materializer: DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer
source: locked Stage 5.1 raw staging
storage: news_overlay_attachments
mode: deterministic idempotent materialization
canonical_feed_mutation: false
news_only_event_creation: false
```

## Guardrails

This PR may add only:

```text
materializer module
targeted materializer tests
manual smoke doc
```

It must not add:

```text
new migrations
schema changes
fixture changes
scheduler changes
provider/live Reuters fetch
new routes
feed/API read path switch
Reuters CanonicalFeedItem creation
news-only CanonicalFeedItem creation
canonical feed mutation
full Reuters article text storage
```

## Step 1: run targeted materializer test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
```

Expected:

```text
1 test, 0 failures
```

## Step 2: run Stage 5.2 schema regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_schema_test.exs
```

Expected:

```text
8 tests, 0 failures
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

## Step 5: manual materialization flow

Reset a disposable dev/test DB, stage the official TDnet item, then run Reuters raw staging.

```powershell
$env:MIX_ENV='dev'; mix.bat ecto.reset
$env:MIX_ENV='dev'; mix.bat run --no-start priv/ops/run_jp_tdnet_timely_disclosure_server.exs
$env:MIX_ENV='dev'; mix.bat run --no-start priv/ops/run_stage5_news_overlay_raw_staging.exs
```

Then run the materializer in an IEx or mix run context:

```elixir
DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer.materialize_once(
  "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
)
```

Expected result:

```text
mode: materialized_attachment
attachments_seen: 1
attachments_upserted: 1
canonical_feed_mutation: false
news_only_event_creation: false
```

## Step 6: verify idempotency

Run the same materializer call again.

Expected:

```text
news_overlay_attachments row count remains 1
same official_event_id
same overlay_id
same overlay_external_id
```

## Step 7: verify attachment row

Expected attachment values:

```text
official_event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
official_stable_external_id: TDNET:4527:20260430:1900:140120260430515474
overlay_source_key: stage5_news_overlay_fixture
overlay_provider: Reuters
overlay_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
overlay_mode: attach_only
display_state: visible
canonical_fact_override: false
source_tier: reputable_news_source
document_role: news_article
```

## Step 8: verify existing API/feed behavior remains unchanged

The materializer does not switch read paths.

Expected:

```text
GET /api/events/:event_id/news-overlay still returns the locked Stage 5.1 overlay response
GET /api/feed/digest/latest?edition=breaking still returns news_overlays[] from locked Stage 5.1 behavior
```

## Step 9: verify no canonical mutation

Expected storage state:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = Reuters overlay id: 0
official TDnet title unchanged
official TDnet published_at unchanged
official TDnet official_source_url unchanged
official TDnet stable_external_id unchanged
```

## Step 10: redaction check

Check diff, logs, and materialized row payloads.

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
Stage 5.2 materializer test: PASS
Stage 5.2 schema regression: PASS
Stage 5.1 feed-visible regression: PASS
Stage 5.1 API exposure regression: PASS
Stage 5.1 read model regression: PASS
Stage 5 raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
materializer idempotency: PASS
canonical no-mutation check: PASS
redaction check: PASS
no new migrations
no schema changes
no fixture changes
no scheduler changes
no provider/live Reuters fetch
no new routes
no feed/API read path switch
```
