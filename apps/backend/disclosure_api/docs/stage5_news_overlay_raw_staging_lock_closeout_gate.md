# Stage 5 news overlay raw-staging lock close-out gate

This document gates the future lock close-out for the Stage 5 v1 Reuters news overlay raw-staging runtime slice.

This PR is docs-only. It does not mark the runtime locked.

## Baseline

```text
implementation PR: #68
implementation merge SHA: ed0026e96f79ee580802d9b5221350b1987486ec
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
storage option: Option C raw-document-only overlay staging
runtime lock status: not locked
```

## Lock close-out requirements

A future close-out PR may mark the runtime locked only after recording PASS evidence for all required checks.

Required:

```text
automated raw-staging idempotency test: PASS
manual isolated smoke: PASS
storage-level staging/dedupe SQL: PASS
regional regression tests: PASS
secret redaction check: PASS
runtime code patch required after verification: no
```

## Required commands

Run from `apps/backend/disclosure_api`.

### Stage 5 raw-staging idempotency

```powershell
$env:POSTGRES_USER='postgres'
$env:POSTGRES_PASSWORD='4597'
$env:POSTGRES_HOST='localhost'
$env:POSTGRES_DB='disclosure_automation_dev'
$env:POSTGRES_TEST_DB='disclosure_automation_test'
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
```

Expected:

```text
1 test, 0 failures
```

### Minimal official-regression tests

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
each file: 1 test, 0 failures
```

### Manual smoke

Follow:

```text
apps/backend/disclosure_api/docs/stage5_news_overlay_raw_staging_manual_smoke.md
```

Expected:

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
staged raw document count: 1
staged raw event count: 1
Reuters canonical event count: 0
official TDnet canonical event count: 1
source health: healthy
```

### Storage SQL

Use:

```text
apps/backend/disclosure_api/priv/ops/stage5_news_overlay_raw_staging_dedupe_checks.sql
```

Expected:

```text
checks 1-5: no rows
check 6: one row with canonical_feed_mutation=false and news_only_event_creation=false
```

### Redaction

```powershell
git grep -n "Subscription-Key=" -- apps/backend/disclosure_api | Select-String -NotMatch '<redacted>'
git grep -n "Auth""orization:" -- apps/backend/disclosure_api
git grep -n "Cook""ie:" -- apps/backend/disclosure_api
```

Expected:

```text
no secret-bearing values
```

## Non-mutation requirements

Before lock, evidence must show that the Reuters overlay staging did not mutate the locked TDnet official canonical item.

Must remain unchanged:

```text
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
canonical_event_type: material_information_update
source_tier: official_exchange_storage
official TDnet citations
```

Must not exist:

```text
CanonicalFeedItem event_id = news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
```

## Staging requirements

Must exist exactly once:

```text
RawDocument external_id = NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
RawEvent external_event_key = news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
SourceCursor cursor_key = latest_article_published_at_and_article_external_id_seen
SourceCursor cursor_value = 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Out of scope for lock close-out

The close-out PR must not add:

```text
feed-visible overlay rendering
dedicated overlay attachment table
database migrations
live Reuters fetch
full Reuters article text
Bloomberg fixture
provider API integration
social scraping
news-only canonical event creation
LLM-only duplicate decisions
```

## Lock close-out template

A future lock close-out PR should include:

```text
## Verification summary
- automated raw-staging idempotency test: PASS
- minimal official-regression tests: PASS
- manual isolated smoke: PASS
- storage-level staging/dedupe SQL: PASS
- secret redaction check: PASS
- runtime code patch required after verification: no
- runtime lock status: locked

## Observed values
- records_seen: 1 on repeated staging
- raw document count: 1
- raw event count: 1
- Reuters canonical event count: 0
- official TDnet canonical event count: 1
- source health: healthy
- cursor value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Current status

```text
runtime lock status: not locked
```
