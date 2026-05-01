# Stage 5.3 second overlay staging and materializer manual smoke

This manual smoke verifies Stage 5.3 second-provider raw staging and attachment materialization.

## Scope

```text
stage: Stage 5.3 PR B
second source_key: stage53_news_overlay_fixture
second adapter_key: stage53_news_overlay_fixture_v1
second provider: Bloomberg fixture metadata
existing source_key: stage5_news_overlay_fixture
existing provider: Reuters
materializer: DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer
storage: news_overlay_attachments
canonical_feed_mutation: false
news_only_event_creation: false
```

## Guardrails

This PR may add or change only:

```text
Stage 5.3 second-provider raw staging module
Stage 5.2 materializer support for second fixture provider
targeted staging/materializer tests
manual smoke doc
```

It must not add:

```text
migrations
schema changes
fixture changes
scheduler changes
provider/live Reuters or Bloomberg fetch
new routes
feed/controller endpoint changes
canonical feed mutation
provider canonical feed item creation
news-only canonical feed item creation
full article text storage
```

## Step 1: run targeted Stage 5.3 test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_second_news_overlay_staging_materializer_test.exs
```

Expected:

```text
1 test, 0 failures
```

## Step 2: run Stage 5.3 fixture policy regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_second_news_overlay_fixture_test.exs
```

Expected:

```text
5 tests, 0 failures
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

## Step 6: manual staging flow

Reset a disposable DB, stage official TDnet item, stage Reuters, then stage Bloomberg.

```powershell
$env:MIX_ENV='dev'; mix.bat ecto.reset
$env:MIX_ENV='dev'; mix.bat run --no-start priv/ops/run_jp_tdnet_timely_disclosure_server.exs
```

Then run in IEx or a mix run context:

```elixir
DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging.stage_once()
DisclosureAutomation.Runtime.Stage53SecondNewsOverlayRawStaging.stage_once()
```

Expected:

```text
Reuters records_seen: 1
Bloomberg records_seen: 1
both canonical_feed_mutation: false
Reuters raw event exists
Bloomberg raw event exists
no provider canonical feed item exists
```

## Step 7: manual materializer flow

Run:

```elixir
DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer.materialize_once(
  "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
)
```

Expected:

```text
mode: materialized_attachment
attachments_seen: 2
attachments_upserted: 2
source_keys include stage5_news_overlay_fixture
source_keys include stage53_news_overlay_fixture
canonical_feed_mutation: false
news_only_event_creation: false
```

Run the same call again.

Expected:

```text
news_overlay_attachments row count remains 2
Reuters attachment remains one row
Bloomberg attachment remains one row
```

## Step 8: verify attachment values

Expected attachment rows:

```text
Reuters:
  overlay_source_key: stage5_news_overlay_fixture
  overlay_provider: Reuters
  overlay_mode: attach_only
  display_state: visible
  canonical_fact_override: false

Bloomberg:
  overlay_source_key: stage53_news_overlay_fixture
  overlay_provider: Bloomberg
  overlay_mode: attach_only
  display_state: visible
  canonical_fact_override: false
```

## Step 9: verify API/feed behavior

Expected:

```text
GET /api/events/:event_id/news-overlay returns item.overlays length 2
GET /api/feed/digest/latest?edition=breaking returns news_overlays length 2
Reuters overlay appears first by article timestamp
Bloomberg overlay appears second by article timestamp
canonicalFactOverride remains false for both overlays
```

## Step 10: verify no canonical mutation

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

## Step 11: redaction check

Check diff, logs, raw staging payloads, and materialized attachments.

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
Stage 5.3 staging/materializer test: PASS
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
multi-overlay materializer idempotency: PASS
API/feed overlay count 2: PASS
canonical no-mutation check: PASS
redaction check: PASS
no migrations
no schema changes
no fixture changes in this PR
no scheduler changes
no provider/live fetch
no new routes
```
