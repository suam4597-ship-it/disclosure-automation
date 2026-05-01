# Stage 5.1 news overlay read model query manual smoke

This manual smoke verifies the Stage 5.1 migration-free read-only query projection for raw-staged Reuters news overlay context.

## Scope

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
implementation mode: read-only query projection
migration required: no
canonical_feed_items mutation: forbidden
news-only canonical event creation: forbidden
```

## Guardrails

The Stage 5.1 read model may read existing official canonical feed rows and existing raw-staged Reuters overlay rows.

It must not:

```text
create a Reuters CanonicalFeedItem
mutate the locked TDnet CanonicalFeedItem
add database migrations
add dedicated overlay attachment storage
perform live Reuters fetches
store full Reuters article text
create news-only canonical events
use LLM-only duplicate decisions
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

## Step 1: run targeted tests

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
```

Expected:

```text
3 tests, 0 failures
```

## Step 2: run existing raw-staging regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
```

Expected:

```text
1 test, 0 failures
```

## Step 3: run locked TDnet regression

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
published_at_utc: 2026-04-30T10:00:00Z
canonical_event_type: material_information_update
```

## Step 5: verify empty overlay read model state

Before staging the Reuters overlay, the read model should return the official item with:

```text
overlays: []
```

Expected official fields remain:

```text
sourceKey: jp_tdnet_timely_disclosure
sourceTier: official_exchange_storage
documentRole: official_exchange_disclosure
canonicalUrl: official TDnet URL
publishedAt: official TDnet timestamp
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
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
raw_event_external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
```

## Step 7: verify visible overlay read model state

Call the read model by event id:

```elixir
DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel.get_by_event_id(
  "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
)
```

Expected:

```text
item.eventId remains official TDnet event id
item.stableExternalId remains TDnet stable external id
item.sourceKey remains jp_tdnet_timely_disclosure
item.title remains official TDnet title
item.publishedAt remains official TDnet timestamp
item.canonicalUrl remains official TDnet URL
item.overlays has exactly one Reuters overlay
item.overlays[0].displayState is visible
item.overlays[0].sourceKey is stage5_news_overlay_fixture
item.overlays[0].provider is Reuters
item.overlays[0].sourceTier is reputable_news_source
item.overlays[0].documentRole is news_article
item.overlays[0].canonicalFactOverride is false
```

## Step 8: verify citation ordering

Flattened citations should preserve:

```text
1. official TDnet citation
2. Reuters overlay citation
```

The Reuters citation must not replace the official TDnet citation.

## Step 9: verify no canonical mutation

Expected storage state:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = Reuters overlay id: 0
canonical_feed_items official title unchanged
canonical_feed_items official published_at unchanged
canonical_feed_items official canonical_url unchanged
canonical_feed_items official stable_external_id unchanged
```

## Step 10: redaction check

The read model response and logs must not expose:

```text
Subscription-Key
Authorization secret value
Cookie secret value
Reuters credential
EDINET key
signed private URL
full Reuters article text
provider request headers
```

Only safe metadata and citation URLs may appear.

## PASS criteria

```text
targeted read model test: PASS
raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
manual empty overlay state: PASS
manual visible overlay state: PASS
citation ordering: PASS
canonical no-mutation check: PASS
redaction check: PASS
no migration files added
no fixture files added
no scheduler files changed
```
