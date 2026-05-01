# Stage 5.1 news overlay feed-visible rendering lock close-out

This document locks the Stage 5.1 additive feed-visible rendering slice for the locked Reuters news overlay read model and API route.

This is a close-out document only. It does not add feed code, route code, controller code, runtime code, tests, fixtures, database migrations, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 08d708a049b0db9d43c1ca71de92022c800c71e3
base commit source: PR #86 Stage 5.1 news overlay feed-visible rendering design
implementation PR: #87 Expose Stage 5.1 news overlay in feed responses
implementation head SHA: 807065bf08c09e01371cad93f0c7ca9ab0753b3c
implementation merge SHA: 70537aa18ea85c8c4443b364c9564fa8c16a49ae
runtime lock status: locked by this close-out
```

## Locked implementation scope

```text
feed field: news_overlays[]
primary feed target: GET /api/feed/digest/latest?edition=breaking
locked event overlay route: GET /api/events/:event_id/news-overlay
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
mode: additive feed response decoration
overlay_mode: attach_only
canonical_feed_mutation: false
news_only_event_creation: false
canonicalFactOverride: false
```

## Changed implementation files

PR #87 changed exactly these files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/feed.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
apps/backend/disclosure_api/test/stage5_news_overlay_feed_visible_test.exs
apps/backend/disclosure_api/docs/stage5_news_overlay_feed_visible_manual_smoke.md
```

No migration, fixture, scheduler, provider fetch, new route, dedicated overlay table, or storage mutation files were added.

## Behavior locked

The Stage 5.1 feed-visible implementation locks these behaviors:

```text
feed item payloads include news_overlays[]
news_overlays[] is [] before Reuters raw staging
news_overlays[] contains one Reuters overlay after Reuters raw staging
digest item_count remains unchanged
digest item_event_ids ordering remains unchanged
official TDnet feed item fields remain unchanged
Reuters overlay context appears only under news_overlays[]
locked /api/events/:event_id/news-overlay behavior remains unchanged
existing /api/events/:event_id behavior remains unchanged
```

## Digest response boundary

The implementation records that digest responses are produced through:

```text
DisclosureAutomation.Digest
DisclosureAutomationWeb.FeedDigestJSON
```

A first verification run found that only decorating `DisclosureAutomation.Feed` was not enough for `/api/feed/digest/latest`.

The implementation was fixed so `FeedDigestJSON.show/1` decorates every digest item with:

```text
news_overlays[]
```

This guarantees the expected empty state is explicit:

```json
{
  "news_overlays": []
}
```

## Official anchor preserved

The official TDnet canonical item remains the parent and source of official feed facts.

```text
official_source_key: jp_tdnet_timely_disclosure
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
issuer: ロート製薬株式会社
security_code: 4527
official_title: 株主提案に関する書面受領のお知らせ
published_at_utc: 2026-04-30T10:00:00.000000Z
canonical_event_type: material_information_update
```

The feed-visible implementation must not replace these official values with Reuters values.

## Overlay response preserved

The Reuters overlay is exposed only under:

```text
items[].news_overlays[]
```

Locked overlay properties:

```text
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
source_key: stage5_news_overlay_fixture
provider: Reuters
source_tier: reputable_news_source
document_role: news_article
canonical_fact_override: false
display_state: visible when direct official identifier match passes
```

The Reuters URL remains an overlay URL and must not replace the official source URL.

## Verification summary

Verification was recorded on PR #87 after the digest response decoration fix.

```text
verified branch: chatgpt-stage5-news-overlay-feed-visible-v1
verified head SHA: 807065bf08c09e01371cad93f0c7ca9ab0753b3c
verification comment id: 4360457194
```

Results:

```text
stage5 feed-visible test: PASS
stage5 API exposure regression: PASS
stage5 read model query regression: PASS
stage5 raw-staging idempotency regression: PASS
TDnet runtime idempotency regression: PASS
TDnet HTTP smoke regression: PASS
no migrations: PASS
no fixture changes: PASS
no scheduler changes: PASS
no provider/live Reuters fetch: PASS
no new routes: PASS
canonical no-mutation check: PASS
redaction check: PASS
existing /api/events/:event_id/news-overlay unchanged: PASS
existing /api/events/:event_id unchanged: PASS
digest item_count unchanged: PASS
digest item ordering unchanged: PASS
```

Command results:

```text
test/stage5_news_overlay_feed_visible_test.exs: 1 test, 0 failures
test/stage5_news_overlay_api_exposure_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_read_model_query_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_http_smoke_test.exs: 1 test, 0 failures
```

## No-mutation evidence

The verification confirmed:

```text
no Reuters CanonicalFeedItem is created
official TDnet canonical fields remain unchanged
Reuters overlay appears only under news_overlays[] in feed responses
Reuters overlay appears only under item.overlays[] in the event overlay API
canonicalFactOverride remains false
official TDnet citation ordering remains preserved
digest item_count remains unchanged
digest item_event_ids ordering remains unchanged
existing /api/events/:event_id remains unchanged
```

## Redaction evidence

The verification recorded:

```text
non-redacted Subscription-Key: not detected
Authorization header literal with secret value: not detected
Cookie header literal with secret value: not detected
secret-bearing files added: no
full Reuters article text storage: not added
provider request headers: not added
```

## Lock decision

The Stage 5.1 feed-visible rendering slice is locked.

Locked means:

```text
news_overlays[] is accepted as the additive feed-visible overlay field
feed digest responses expose empty overlay state deterministically
feed digest responses expose one Reuters overlay after raw staging
official TDnet feed item fields remain unchanged
feed item count and ordering remain unchanged
no Reuters canonical event is created
no news-only canonical event is created
no live Reuters fetch is added
no full Reuters article text is stored
```

## Still out of scope

The following remain out of scope after this lock:

```text
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
Stage 5.2 dedicated overlay attachment table design
second news overlay fixture
provider-backed news ingestion
cross-source duplicate group materialization
multiple overlay providers in feed responses
```
