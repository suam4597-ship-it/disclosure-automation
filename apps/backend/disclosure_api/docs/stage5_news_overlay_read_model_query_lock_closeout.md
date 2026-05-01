# Stage 5.1 news overlay read model query lock close-out

This document locks the Stage 5.1 migration-free read-only query projection for exposing raw-staged Reuters news overlay context beside the official TDnet canonical event.

This is a close-out document only. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, feed-visible rendering implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 111bf2f6e50317a31d40390b96539915a8e3b4dd
base commit source: PR #80 Stage 5.1 news overlay read model and rendering design
implementation PR: #81 Implement Stage 5.1 news overlay read model query
implementation head SHA: 7dce9410efc4589835507b77cdd72a313d5f4e17
implementation merge SHA: 84088345804f247b0d0af9ff43886b6a96988601
runtime lock status: locked by this close-out
```

## Locked implementation scope

```text
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
storage_mode: raw_staging
read_mode: migration_free_read_only_projection
overlay_mode: attach_only
canonical_feed_mutation: false
news_only_event_creation: false
canonicalFactOverride: false
```

## Added implementation files

PR #81 added exactly these files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage5_news_overlay_read_model.ex
apps/backend/disclosure_api/test/stage5_news_overlay_read_model_query_test.exs
apps/backend/disclosure_api/docs/stage5_news_overlay_read_model_query_manual_smoke.md
```

No migration, fixture, scheduler, provider fetch, or feed rendering implementation files were added.

## Behavior locked

The Stage 5.1 read model query locks these behaviors:

```text
official TDnet canonical item is read by event_id or stable external id
raw-staged Reuters overlay candidates are read from existing raw_events rows
a visible overlay requires direct official identifier match
Reuters context is returned only under item.overlays[]
Reuters fields are not copied into official item fields
canonicalFactOverride remains false for overlays and overlay claims
official TDnet citations remain before Reuters overlay citations in flattened citation order
```

## Official anchor preserved

The official TDnet canonical item remains the anchor of truth.

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

The read model must not overwrite these official values with Reuters values.

## Overlay projection preserved

The Reuters overlay remains an attach-only raw-staged context projection.

```text
source_key: stage5_news_overlay_fixture
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
raw_document_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
raw_event_external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
source_tier: reputable_news_source
document_role: news_article
overlay_display_state: visible when direct official identifier match passes
```

## Verification summary

Verification was recorded on PR #81 after the timestamp assertion fix.

```text
verified branch: chatgpt-stage5-news-overlay-read-model-query-v1
verified head SHA: 7dce9410efc4589835507b77cdd72a313d5f4e17
verification comment id: 4360021897
```

Results:

```text
stage5 read model query test: PASS
stage5 raw-staging idempotency regression: PASS
TDnet runtime idempotency regression: PASS
TDnet HTTP smoke regression: PASS
no migrations: PASS
no fixture changes: PASS
no scheduler changes: PASS
no provider/live Reuters fetch: PASS
no feed rendering implementation: PASS
canonical no-mutation check: PASS
redaction check: PASS
```

Command results:

```text
test/stage5_news_overlay_read_model_query_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_http_smoke_test.exs: 1 test, 0 failures
```

## Verification fix recorded

The first verification run found a timestamp assertion mismatch in the new read model test:

```text
left:  2026-04-30T10:00:00.000000Z
right: 2026-04-30T10:00:00Z
```

The test was fixed to expect the canonical contract value:

```text
2026-04-30T10:00:00.000000Z
```

The fix commit was:

```text
7dce9410efc4589835507b77cdd72a313d5f4e17
```

After the fix, all targeted tests and regressions passed.

## No-mutation evidence

The verification confirmed:

```text
no Reuters CanonicalFeedItem is created
official TDnet canonical fields remain unchanged
Reuters overlay appears only under item.overlays[]
canonicalFactOverride remains false
official TDnet citation remains before Reuters overlay citation
```

## Redaction evidence

The verification recorded:

```text
non-redacted Subscription-Key: not detected
Authorization header literal with secret value: not detected
Cookie header literal with secret value: not detected
secret-bearing files added in new head: no
full Reuters article text storage: not added
provider request headers: not added
```

## Lock decision

The Stage 5.1 read model query slice is locked.

Locked means:

```text
migration-free read-only projection is accepted
raw-staged Reuters overlay can be projected next to the official TDnet item
official TDnet canonical item remains unchanged
Reuters overlay remains namespaced under item.overlays[]
no Reuters canonical event is created
no news-only canonical event is created
no dedicated overlay attachment table is added
no feed rendering implementation is added
no live Reuters fetch is added
no full Reuters article text is stored
```

## Still out of scope

The following remain out of scope after this lock:

```text
feed-visible rendering implementation
API route/controller exposure
dedicated news_overlay_attachments table
database migrations
live Reuters fetch
provider API integration
Bloomberg backup fixture
multiple provider overlays
cross-source duplicate_group_key materialization
news-only canonical event creation
LLM-only duplicate decisions
social scraping
rumor ingestion
```

## Future work

The next stage may start only after a new design or implementation PR defines one of these separately:

```text
Stage 5.1 API route/controller exposure for the read model
Stage 5.1 feed-visible rendering implementation using the locked contract
Stage 5.2 dedicated overlay attachment table design
second news overlay fixture
provider-backed news ingestion
cross-source duplicate group materialization
```
