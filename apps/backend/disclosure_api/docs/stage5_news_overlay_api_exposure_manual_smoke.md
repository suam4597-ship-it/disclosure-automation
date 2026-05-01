# Stage 5.1 news overlay API exposure manual smoke

This manual smoke verifies the additive Stage 5.1 API route for the locked news overlay read model.

## Scope

```text
route: GET /api/events/:event_id/news-overlay
controller: DisclosureAutomationWeb.EventNewsOverlayController
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
source_key: stage5_news_overlay_fixture
mode: additive API exposure
canonical_feed_mutation: false
news_only_event_creation: false
```

## Guardrails

The API route may read the locked official TDnet canonical item and the existing raw-staged Reuters overlay rows.

It must not:

```text
poll TDnet or Reuters from a GET request
stage overlays from a GET request
write raw_documents
write raw_events
write canonical_feed_items
perform live Reuters fetches
call provider APIs
store full Reuters article text
create a Reuters CanonicalFeedItem
create news-only canonical events
change feed list endpoint behavior
```

## Environment

Run from:

```text
apps/backend/disclosure_api
```

Set local database environment variables as usual for dev smoke.

Example PowerShell shape:

```powershell
$env:POSTGRES_USER='postgres'
$env:POSTGRES_PASSWORD='4597'
$env:POSTGRES_HOST='localhost'
$env:POSTGRES_DB='disclosure_automation_dev'
$env:POSTGRES_TEST_DB='disclosure_automation_test'
```

## Step 1: run targeted API test

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
```

Expected:

```text
3 tests, 0 failures
```

## Step 2: run read model and raw-staging regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run locked TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: reset dev DB and stage official TDnet item

```powershell
$env:MIX_ENV='dev'; mix.bat ecto.reset
$env:MIX_ENV='dev'; mix.bat run --no-start priv/ops/run_jp_tdnet_timely_disclosure_server.exs
```

Expected official item:

```text
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
official_title: 株主提案に関する書面受領のお知らせ
published_at_utc: 2026-04-30T10:00:00.000000Z
canonical_event_type: material_information_update
```

## Step 5: call API before Reuters staging

Call:

```text
GET /api/events/jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474/news-overlay
```

Expected:

```text
HTTP 200
item.eventId is official TDnet event id
item.sourceKey is jp_tdnet_timely_disclosure
item.title is official TDnet title
item.publishedAt is official TDnet timestamp
item.canonicalUrl is official TDnet URL
item.overlays is []
```

## Step 6: stage Reuters overlay raw data

```powershell
$env:MIX_ENV='dev'; mix.bat run --no-start priv/ops/run_stage5_news_overlay_raw_staging.exs
```

Expected staging result:

```text
source_key: stage5_news_overlay_fixture
records_seen: 1
mode: raw_staging
canonical_feed_mutation: false
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
```

## Step 7: call API after Reuters staging

Call:

```text
GET /api/events/jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474/news-overlay
```

Expected:

```text
HTTP 200
item.eventId remains official TDnet event id
item.sourceKey remains jp_tdnet_timely_disclosure
item.title remains official TDnet title
item.publishedAt remains official TDnet timestamp
item.canonicalUrl remains official TDnet URL
item.overlays has exactly one Reuters overlay
item.overlays[0].sourceKey is stage5_news_overlay_fixture
item.overlays[0].provider is Reuters
item.overlays[0].sourceTier is reputable_news_source
item.overlays[0].documentRole is news_article
item.overlays[0].canonicalFactOverride is false
item.overlays[0].url is Reuters URL
item.overlays[0].url is not item.canonicalUrl
```

## Step 8: verify existing event endpoint remains unchanged

Call:

```text
GET /api/events/jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
```

Expected:

```text
HTTP 200
existing data.event_id remains official TDnet event id
existing data.canonical_event_type remains material_information_update
existing response is not replaced by the overlay response shape
```

## Step 9: verify missing official event

Call:

```text
GET /api/events/missing.official.event/news-overlay
```

Expected:

```text
HTTP 404
error.code: official_event_not_found
```

## Step 10: verify no canonical mutation

Expected storage state:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = Reuters overlay id: 0
official TDnet title unchanged
official TDnet published_at unchanged
official TDnet canonical_url unchanged
official TDnet stable_external_id unchanged
```

## Step 11: redaction check

The API response and logs must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
Reuters credentials
EDINET keys
signed private URLs
full Reuters article text
provider request headers
raw stack traces in JSON responses
```

## PASS criteria

```text
API exposure test: PASS
Stage 5.1 read model regression: PASS
Stage 5 raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
manual pre-staging API call: PASS
manual post-staging API call: PASS
missing official event 404: PASS
existing /api/events/:event_id unchanged: PASS
canonical no-mutation check: PASS
redaction check: PASS
no migrations added
no fixture changes
no scheduler changes
no provider/live Reuters fetch
no feed rendering implementation
```
