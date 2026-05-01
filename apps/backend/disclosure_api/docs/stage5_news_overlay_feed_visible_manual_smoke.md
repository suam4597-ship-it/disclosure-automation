# Stage 5.1 news overlay feed-visible manual smoke

This manual smoke verifies that the locked Stage 5.1 Reuters news overlay is visible in feed-facing responses without changing official TDnet feed item fields.

## Scope

```text
feed field: news_overlays[]
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
source_key: stage5_news_overlay_fixture
route already locked: GET /api/events/:event_id/news-overlay
primary feed target: GET /api/feed/digest/latest?edition=breaking
mode: additive feed response decoration
canonical_feed_mutation: false
news_only_event_creation: false
```

## Guardrails

The feed-visible implementation may decorate existing feed item JSON with `news_overlays[]`.

It must not:

```text
create a Reuters CanonicalFeedItem
create a news-only CanonicalFeedItem
mutate canonical_feed_items
change digest item count
change digest item ordering
replace official TDnet fields with Reuters fields
perform live Reuters fetches
call provider APIs
store full Reuters article text
add migrations
change fixtures
change schedulers
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

## Step 1: run targeted feed-visible test

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
```

Expected:

```text
1 test, 0 failures
```

## Step 2: run Stage 5.1 API and read model regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run raw-staging and TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
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

## Step 5: call digest before Reuters staging

Call:

```text
GET /api/feed/digest/latest?edition=breaking
```

Expected:

```text
HTTP 200
item_count: 1
items[0].event_id is official TDnet event id
items[0].headline_local is official TDnet title
items[0].published_at_utc is official TDnet timestamp
items[0].source_meta.stable_external_id is TDnet stable external id
items[0].news_overlays is []
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

## Step 7: call digest after Reuters staging

Call:

```text
GET /api/feed/digest/latest?edition=breaking
```

Expected:

```text
HTTP 200
item_count remains 1
item_event_ids unchanged
items[0].event_id remains official TDnet event id
items[0].headline_local remains official TDnet title
items[0].published_at_utc remains official TDnet timestamp
items[0].canonical_event_type remains material_information_update
items[0].official_source_url remains official TDnet URL
items[0].news_overlays has exactly one Reuters overlay
```

Expected overlay:

```text
items[0].news_overlays[0].overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
items[0].news_overlays[0].source_key: stage5_news_overlay_fixture
items[0].news_overlays[0].provider: Reuters
items[0].news_overlays[0].source_tier: reputable_news_source
items[0].news_overlays[0].document_role: news_article
items[0].news_overlays[0].canonical_fact_override: false
items[0].news_overlays[0].url is Reuters URL
items[0].news_overlays[0].url is not official_source_url
```

## Step 8: verify locked API route still works

Call:

```text
GET /api/events/jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474/news-overlay
```

Expected:

```text
HTTP 200
item.eventId is official TDnet event id
item.overlays has exactly one Reuters overlay
```

## Step 9: verify existing event endpoint remains unchanged

Call:

```text
GET /api/events/jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
```

Expected:

```text
HTTP 200
data.event_id remains official TDnet event id
data.canonical_event_type remains material_information_update
response is not replaced by the overlay API shape
```

## Step 10: verify no canonical mutation

Expected storage state:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = Reuters overlay id: 0
official TDnet title unchanged
official TDnet published_at unchanged
official TDnet official_source_url unchanged
official TDnet stable_external_id unchanged
```

## Step 11: redaction check

Feed responses and logs must not expose:

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
feed-visible test: PASS
Stage 5.1 API exposure regression: PASS
Stage 5.1 read model regression: PASS
Stage 5 raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
manual pre-staging digest call: PASS
manual post-staging digest call: PASS
locked API route regression: PASS
existing /api/events/:event_id unchanged: PASS
canonical no-mutation check: PASS
redaction check: PASS
no migrations added
no fixture changes
no scheduler changes
no provider/live Reuters fetch
no new routes added
```
