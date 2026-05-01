# Stage 5 news overlay raw-staging manual smoke

This manual smoke verifies the Stage 5 v1 Reuters news overlay raw-staging runtime slice.

## Scope

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
storage_mode: raw_staging
selected storage option: Option C
fixture: stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

## Guardrails

This runtime slice stages Reuters overlay metadata as raw storage only.

It must not:

```text
create a Reuters CanonicalFeedItem
mutate the locked TDnet CanonicalFeedItem
perform live Reuters fetches
store full Reuters article text
create news-only canonical events
use LLM-only duplicate decisions
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

## Step 1: reset dev DB

```powershell
$env:MIX_ENV='dev'; mix.bat ecto.reset
```

## Step 2: stage the Reuters overlay fixture

```powershell
$env:MIX_ENV='dev'; mix.bat run --no-start priv/ops/run_stage5_news_overlay_raw_staging.exs
```

Expected result summary:

```text
source_key: stage5_news_overlay_fixture
records_seen: 1
mode: raw_staging
canonical_feed_mutation: false
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
raw_document_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
raw_event_external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
cursor_key: latest_article_published_at_and_article_external_id_seen
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Step 3: run the staging command again

```powershell
$env:MIX_ENV='dev'; mix.bat run --no-start priv/ops/run_stage5_news_overlay_raw_staging.exs
```

Expected:

```text
same overlay_id
same raw_document_external_id
same raw_event_external_id
records_seen: 1
no duplicate raw document
no duplicate raw event
```

## Step 4: run storage checks

Use:

```text
apps/backend/disclosure_api/priv/ops/stage5_news_overlay_raw_staging_dedupe_checks.sql
```

Expected:

```text
checks 1-5: no rows
check 6: one staged overlay row with canonical_feed_mutation=false and news_only_event_creation=false
```

## Step 5: verify source health

Expected source health:

```text
source_key: stage5_news_overlay_fixture
health_status: healthy
cursor_key: latest_article_published_at_and_article_external_id_seen
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Step 6: verify canonical no-mutation boundary

Expected:

```text
no CanonicalFeedItem exists with event_id = news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
locked TDnet CanonicalFeedItem remains unchanged if TDnet fixture is also polled
official TDnet event_id remains jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
official TDnet stable_external_id remains TDNET:4527:20260430:1900:140120260430515474
```

## PASS criteria

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
staged raw document count: 1
staged raw event count: 1
Reuters canonical event count: 0
source health: healthy
cursor value matches expected
no full Reuters article text stored
no secrets stored
```
