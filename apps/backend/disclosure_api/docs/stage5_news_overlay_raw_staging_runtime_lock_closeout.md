# Stage 5 news overlay raw-staging runtime lock close-out

This document locks the Stage 5 v1 Reuters news overlay raw-staging runtime slice after local verification.

This is a close-out document only. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, feed-visible overlay rendering, or changes to locked official regional runtimes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 7833d98cac8b94d4d5fd0bd335b14c4278712786
base commit source: PR #78 Fix Stage 5 raw staging JSON params
implementation PR: #68
verification fix PRs: #70, #71, #72, #73, #74, #75, #76, #77, #78
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
storage option: Option C raw-document-only overlay staging
```

## Locked scope

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
fixture: stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
storage_mode: raw_staging
overlay_mode: attach_only
canonical_feed_mutation: false
news_only_event_creation: false
runtime lock status: locked
```

## Official anchor preserved

The runtime attaches the Reuters overlay candidate to the locked TDnet official event only as staged raw data.

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

## Staged overlay identities

```text
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
raw_document_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
raw_event_external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
cursor_key: latest_article_published_at_and_article_external_id_seen
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Verification summary

Local verification was rerun at PR #78 merge commit:

```text
merge_sha: 7833d98cac8b94d4d5fd0bd335b14c4278712786
working_tree: clean after verification
```

Results:

```text
stage5 raw-staging idempotency test: PASS
TDnet runtime idempotency test: PASS
TDnet HTTP smoke test: PASS
manual smoke: PASS
dedupe SQL: PASS
redaction check: PASS
runtime code patch required after verification: no
runtime lock status: locked
```

## Manual smoke evidence

Manual smoke ran twice successfully.

Observed values:

```text
records_seen: 1
source_key: stage5_news_overlay_fixture
source health: healthy
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Storage-level dedupe evidence

Storage SQL completed successfully.

Observed values:

```text
checks 1-5: []
check 6: one expected staged overlay payload row
source_tier: reputable_news_source
document_role: news_article
canonical_feed_mutation: false
news_only_event_creation: false
```

## Redaction evidence

Redaction check passed.

Observed values:

```text
non-redacted Subscription-Key: not detected
Authorization header literal with secret value: not detected
Cookie header literal with secret value: not detected
Reuters credential: not detected
EDINET key: not detected
signed private URL: not detected
```

## Lock decision

The Stage 5 Reuters news overlay raw-staging runtime slice is locked.

Locked means:

```text
fixture-backed Reuters overlay can be staged as raw document and raw event
repeated staging is idempotent
official TDnet canonical item remains unchanged
no Reuters canonical event is created
no feed-visible overlay rendering is added
no dedicated overlay attachment table is added
no live Reuters fetch is added
no full Reuters article text is stored
no secrets are stored
```

## Still out of scope

The following remain out of scope after this lock:

```text
feed-visible overlay rendering
dedicated news_overlay_attachments table
database migrations
live Reuters fetch
provider API integration
Bloomberg backup fixture
multiple news overlays per official event
cross-source duplicate_group_key materialization
news-only canonical event creation
LLM-only duplicate decisions
social scraping
rumor ingestion
```

## Future work

The next stage may start only after a new design or implementation PR defines one of these separately:

```text
feed-visible overlay query/rendering path
dedicated overlay attachment table
second news overlay fixture
provider-backed news ingestion
cross-source duplicate group materialization
```
