# Stage 5 news overlay raw-staging verification ledger

This ledger tracks verification for the Stage 5 v1 Reuters news overlay raw-staging runtime slice.

This PR is a verification preflight. It does not mark the runtime locked because automated and manual PASS evidence has not been recorded yet.

## Scope

```text
implementation PR: #68
implementation merge SHA: ed0026e96f79ee580802d9b5221350b1987486ec
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
storage option: Option C raw-document-only overlay staging
fixture: stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

## Expected staged identities

```text
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
raw_document_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
raw_event_external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
cursor_key: latest_article_published_at_and_article_external_id_seen
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Official anchor that must remain unchanged

```text
official_source_key: jp_tdnet_timely_disclosure
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
issuer: ロート製薬株式会社
security_code: 4527
official_title: 株主提案に関する書面受領のお知らせ
official_pdf_token: 140120260430515474
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
canonical_event_type: material_information_update
```

## Current verification status

```text
automated raw-staging idempotency test: NOT RECORDED
automated HTTP smoke test: NOT APPLICABLE in PR #68
manual isolated smoke: NOT RECORDED
storage-level staging/dedupe SQL: NOT RECORDED
regional regression tests: NOT RECORDED
secret redaction check: NOT RECORDED
runtime code patch required after verification: UNKNOWN
runtime lock status: not locked
```

## Required automated test

Run from `apps/backend/disclosure_api`:

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

The test must prove:

```text
poll 1 records_seen = 1
poll 2 records_seen = 1
staged raw document count = 1
staged raw event count = 1
Reuters overlay does not create a CanonicalFeedItem
locked TDnet canonical event remains exactly one
TDnet stable_external_id is unchanged
TDnet published_at values are unchanged
overlayClaims preserve canonicalFactOverride=false
Reuters and TDnet citations remain separate
stage5_news_overlay_fixture source health is healthy
cursor value matches expected
```

## Required manual smoke

Follow:

```text
apps/backend/disclosure_api/docs/stage5_news_overlay_raw_staging_manual_smoke.md
```

Required observed values:

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
staged raw document count: 1
staged raw event count: 1
Reuters canonical event count: 0
official TDnet canonical event count: 1
source health: healthy
cursor_key: latest_article_published_at_and_article_external_id_seen
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Required SQL verification

Use:

```text
apps/backend/disclosure_api/priv/ops/stage5_news_overlay_raw_staging_dedupe_checks.sql
```

Expected:

```text
checks 1-5: no rows
check 6: one row showing:
  source_tier = reputable_news_source
  document_role = news_article
  canonical_feed_mutation = false
  news_only_event_creation = false
```

## Required regional regression tests

At minimum, rerun the locked official sources most likely to be affected:

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Recommended full JP/CN regional regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_broad_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_broad_timely_disclosure_http_smoke_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_ownership_change_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_ownership_change_http_smoke_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_broad_announcement_feed_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/cn_cninfo_broad_announcement_feed_http_smoke_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_edinet_statutory_report_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_edinet_statutory_report_http_smoke_test.exs
```

## Required redaction check

Run from repo root or `apps/backend/disclosure_api` as appropriate:

```powershell
git grep -n "Subscription-Key=" -- apps/backend/disclosure_api | Select-String -NotMatch '<redacted>'
git grep -n "Authorization:" -- apps/backend/disclosure_api
git grep -n "Cookie:" -- apps/backend/disclosure_api
```

Expected:

```text
no secret-bearing Reuters, EDINET, Authorization, Cookie, signed URL, or API key values are present
```

## Lock close-out rule

Do not mark the runtime locked until all required verification evidence is recorded.

A later close-out PR may set:

```text
runtime lock status: locked
```

only after:

```text
automated raw-staging idempotency test: PASS
manual isolated smoke: PASS
storage-level staging/dedupe SQL: PASS
regional regression tests: PASS
secret redaction check: PASS
runtime code patch required after verification: no
```
