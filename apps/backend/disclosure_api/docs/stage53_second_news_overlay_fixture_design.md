# Stage 5.3 second news overlay fixture design

This document defines the docs-only design for introducing a second news overlay fixture after Stage 5.2 attachment storage was locked.

This is a design document only. It does not add fixtures, source adapters, runtime code, tests, database migrations, schedulers, provider fetches, routes, feed/controller changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: ec3d8b408e7ca15a97f5adaea72be94d4c6ee0a0
base commit source: PR #93 Lock Stage 5.2 news overlay attachment storage
locked table: news_overlay_attachments
locked read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
locked materializer: DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer
stage: Stage 5.3 second overlay fixture design
status: design-only
```

## Goal

Define a safe policy for adding a second news overlay fixture that can coexist with the locked Reuters overlay without creating new canonical feed items or mutating official TDnet facts.

The second fixture should prove that the Stage 5.2 attachment model supports multiple overlay candidates attached to one official canonical event.

## Non-goals

```text
fixture implementation: out of scope for this PR
adapter implementation: out of scope for this PR
provider API integration: out of scope
live news fetch: out of scope
new database migration: out of scope
new routes: out of scope
feed rendering redesign: out of scope
canonical feed mutation: prohibited
Reuters canonical feed item creation: prohibited
news-only canonical feed item creation: prohibited
full article text storage: prohibited
```

## Recommended provider policy

The second fixture should use a reputable news source distinct from Reuters.

Allowed fixture provider candidates:

```text
Bloomberg
Nikkei
Dow Jones
Financial Times
```

Recommended first candidate:

```text
provider: Bloomberg
source_key: stage53_news_overlay_fixture
adapter_key: stage53_news_overlay_fixture_v1
```

The actual fixture should remain synthetic/safe and should not include full article text.

## Why a second provider

The current locked path proves one Reuters overlay can attach to an official TDnet event.

A second provider fixture should prove:

```text
multiple overlays can attach to the same official canonical event
provider identity is preserved
citation separation remains stable
feed/API response shape remains list-based
attachment uniqueness works by provider/article identity
materialized attachment read path remains deterministic
```

## Official anchor

The second fixture should attach to the same locked official TDnet event first.

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

Using the same official event isolates multi-overlay behavior without expanding official source coverage.

## Required fixture shape

The second fixture should mirror the Stage 5.1 overlay shape but use distinct provider identities.

Required fields:

```text
overlayId
articleExternalId
canonicalEventId
sourceKey
sourceTier
documentRole
sourceName
sourceUrl
articleTitle
articlePublishedAt
articleRetrievedAt
overlayContextType
overlayClaims
matchEvidence
citations
conflictFlags
officialFactsPreserved
```

Required values:

```text
sourceTier: reputable_news_source
documentRole: news_article
canonical_feed_mutation: false
news_only_event_creation: false
canonicalFactOverride: false
```

## Identity policy

The second fixture must use distinct overlay identity values.

Recommended pattern:

```text
overlay_id: news_overlay:<official_event_id>:<provider-lowercase>-jp-article-001
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:<provider-lowercase>-jp-article-001
raw_document_external_id: <article_external_id>:article-metadata
raw_event_external_id: <overlay_id>:overlay-candidate
```

Do not reuse the Reuters overlay id or article external id.

## Direct match evidence

The second fixture must include direct official identifier evidence.

Allowed evidence:

```text
canonicalEventId equals official event_id
matchEvidence.matchedCanonicalEventId equals official event_id
matchEvidence.matchedOfficialStableExternalId equals official stable external id
official_anchor.stableExternalId equals official stable external id
```

Do not rely on issuer name or timestamp alone.

## Claim policy

Overlay claims must remain non-canonical context.

Allowed claim kinds:

```text
secondary_confirmation
news_only_context
article_metadata
market_or_news_context
```

Disallowed claims:

```text
official fact override
new official event type
uncited accusation
rumor/social claim
full article body excerpt
```

Every claim should preserve:

```text
canonicalFactOverride=false
source_tier=reputable_news_source
document_role=news_article
citation linkage
```

## Citation policy

The second provider citation must remain separate from official TDnet and Reuters citations.

Expected display order after materialization:

```text
1. official TDnet citation
2. Reuters overlay citation
3. second provider overlay citation
```

If ordering uses provider/article published time, document it in the implementation PR.

## Attachment storage policy

The second fixture should materialize into `news_overlay_attachments` as a second row for the same official canonical feed item.

Expected after Reuters + second fixture materialization:

```text
news_overlay_attachments row count for official event: 2
canonical_feed_items row count for official TDnet event: 1
canonical_feed_items row count for second provider overlay: 0
```

## Feed/API response policy

After implementation, response shape remains list-based:

```text
item.overlays[]
news_overlays[]
```

Expected overlay count after both fixtures are staged/materialized:

```text
2
```

The official TDnet feed item must remain one item, not duplicated.

## Redaction policy

The second fixture must not include:

```text
provider credentials
Subscription-Key values
Authorization headers
Cookie headers
signed private URLs
full article text
provider request headers
```

Only safe metadata, summary-level claims, and citation URLs may be included.

## No-go conditions

A second fixture implementation must fail review if it does any of the following:

```text
creates provider canonical feed item
creates news-only canonical feed item
mutates official TDnet canonical fields
changes official title, timestamp, event type, or URL
stores full provider article text
adds live provider fetch
adds provider API credentials
changes feed item count for official event
breaks existing Reuters overlay behavior
breaks Stage 5.2 attachment idempotency
```

## Recommended implementation sequence

```text
1. Land this docs-only design PR.
2. Add the second fixture and source attrs in a fixture-only PR.
3. Extend raw staging/materializer to support the second fixture provider.
4. Add multi-overlay tests for raw staging, attachment materialization, API, and feed responses.
5. Close out and lock Stage 5.3 second fixture behavior after PASS evidence.
```
