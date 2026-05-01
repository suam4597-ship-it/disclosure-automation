# Stage 5.1 news overlay read model design

This document defines the Stage 5.1 read model for showing raw-staged Reuters news overlay context next to an official TDnet canonical event.

This is a design document only. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, feed-visible overlay implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d4fd1b8f437f5dfe1ba879de930194f9f1ad45b3
prior lock PR: #79 Lock Stage 5 news overlay raw staging runtime
stage: Stage 5.1
status: design-only
```

## Locked input scope

Stage 5.1 starts from the locked Stage 5 v1 Reuters overlay raw-staging runtime.

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
storage_mode: raw_staging
overlay_mode: attach_only
canonical_feed_mutation: false
news_only_event_creation: false
runtime lock status: locked
```

The existing runtime can stage Reuters overlay metadata as RawDocument and RawEvent rows. It must not create a Reuters CanonicalFeedItem and must not mutate the locked TDnet official CanonicalFeedItem.

## Goal

Define a read-only model that can later let API and feed surfaces display a raw-staged Reuters overlay beside the official TDnet canonical event.

The read model must preserve the official event as the anchor of truth while making separate news-only context visible as an overlay candidate.

## Non-goals

```text
runtime implementation: out of scope
database migration: out of scope
dedicated news_overlay_attachments table: out of scope
fixture changes: out of scope
feed rendering implementation: out of scope
API code changes: out of scope
live Reuters fetch: out of scope
Bloomberg fixture: out of scope
provider API integration: out of scope
news-only canonical event creation: prohibited
LLM-only duplicate decision: prohibited
social scraping or rumor ingestion: prohibited
```

## Read model name

The logical read model is named:

```text
Stage5NewsOverlayReadModel
```

It is not a table name and does not imply a migration. The first implementation should prefer a read-only join/query projection over new storage.

## Official anchor

The read model is anchored by one existing official canonical feed item.

Required official fields:

```text
canonical_feed_item.id
canonical_feed_item.event_id
canonical_feed_item.stable_external_id
canonical_feed_item.source_key
canonical_feed_item.issuer_name
canonical_feed_item.security_code
canonical_feed_item.title
canonical_feed_item.published_at
canonical_feed_item.canonical_url
canonical_feed_item.canonical_event_type
canonical_feed_item.citations
```

The official anchor remains the only canonical feed item for the TDnet event.

## Overlay candidate source

A news overlay candidate is read from staged raw data only.

Expected staged identities:

```text
raw_document.source_key = stage5_news_overlay_fixture
raw_document.document_role = news_article
raw_document.source_tier = reputable_news_source
raw_event.event_type = news_overlay_candidate
raw_event.canonical_feed_mutation = false
raw_event.news_only_event_creation = false
```

The first implementation should derive overlays from the existing raw staging payload. It should not require a dedicated attachment table.

## Read-only association rule

The association from raw-staged overlay to official canonical event should be deterministic and explainable.

Preferred association keys, in priority order:

```text
1. raw_event payload official_event_id equals canonical_feed_item.event_id
2. raw_event payload official_stable_external_id equals canonical_feed_item.stable_external_id
3. raw_event payload official_pdf_token matches the official TDnet document token
4. raw_event payload official_source_key equals canonical_feed_item.source_key
```

The first runtime PR should require at least one direct official identifier match. It should not infer association from issuer name and timestamp alone.

## Read model shape

The logical read model returned to feed/API callers should have this shape:

```text
officialCanonicalItem:
  id
  eventId
  stableExternalId
  sourceKey
  sourceTier
  issuerName
  securityCode
  title
  publishedAt
  canonicalUrl
  canonicalEventType
  citations[]

overlays[]:
  overlayId
  overlayType
  overlayMode
  sourceKey
  provider
  sourceTier
  documentRole
  articleExternalId
  rawDocumentExternalId
  rawEventExternalId
  title
  publishedAt
  url
  language
  jurisdiction
  overlayClaims[]
  conflictFlags[]
  citations[]
  canonicalFactOverride
  displayState
```

The read model must allow zero overlays, one overlay, or multiple overlays in later stages. Stage 5.1 runtime can begin with one overlay.

## Official fact separation

Official facts and news-only context must stay separate.

Official facts are fields from TDnet or from the existing locked canonical item:

```text
issuer
security_code
official_title
official_published_at
official_pdf_token
official_canonical_url
canonical_event_type
stable_external_id
```

News-only context is metadata or summary-level context from the Reuters overlay:

```text
provider
article title or headline
article published_at
article URL
article external ID
source_tier
document_role
overlay claims
conflict flags
```

News-only context must not replace official facts.

## canonicalFactOverride

Every Stage 5.1 Reuters overlay must expose:

```text
canonicalFactOverride: false
```

This means the overlay is allowed to add context but is not allowed to overwrite the canonical event title, canonical URL, official published_at, official event type, issuer, security code, or stable external ID.

## overlayClaims policy

`overlayClaims` are displayable but non-canonical claims extracted from the overlay payload.

Allowed claim categories:

```text
context_summary
market_or_news_context
activist_or_shareholder_context
related_party_context
article_metadata
```

Each claim should include:

```text
claim_id
claim_type
text
source_key
source_tier
document_role
citation_id
canonical_fact_override: false
```

The first runtime should avoid claim extraction that requires storing full Reuters article text. Claims should come only from the fixture metadata or already staged summary fields.

## source_tier and document_role exposure

The read model must expose source quality metadata separately from the official citation.

For the locked Reuters fixture:

```text
source_tier: reputable_news_source
document_role: news_article
```

For the official TDnet anchor:

```text
source_tier: official_exchange_disclosure
document_role: official_disclosure
```

Consumers must be able to show these labels without merging the sources.

## conflict_flags

The read model should reserve `conflictFlags[]` for source disagreements or unsafe overlay states.

Initial Stage 5.1 flags:

```text
none
published_at_differs_from_official
headline_differs_from_official_title
provider_url_not_official_url
missing_direct_official_identifier
suppressed_full_text_unavailable
```

A conflict flag is informational unless a later policy marks it as suppressing. The first runtime should suppress overlays that lack a direct official identifier match.

## Citation model

The read model must keep official and overlay citations separate.

Citation ordering for a combined feed/API response:

```text
1. official TDnet citation
2. Reuters overlay citation
3. later additional overlay citations in deterministic order
```

The official citation must remain the first citation because the official event remains canonical.

Overlay citations must not be reused as the official citation and must not replace `canonical_url`.

## Sorting and determinism

When multiple overlays are later supported, sorting should be deterministic:

```text
1. direct official identifier match before weaker match
2. source_tier rank
3. provider article published_at ascending or descending per surface contract
4. provider name
5. article_external_id
```

The first Stage 5.1 implementation may only support one overlay, but should still use a deterministic list shape.

## No-go conditions

A Stage 5.1 runtime PR must fail review if it does any of the following:

```text
creates a Reuters canonical feed item
mutates the locked TDnet canonical feed item
overwrites official title with Reuters headline
overwrites official published_at with Reuters published_at
replaces official canonical_url with Reuters URL
stores full Reuters article text
adds live Reuters fetch
adds a Bloomberg fixture
adds provider API integration
adds a dedicated attachment table without a separate design/migration PR
uses LLM-only duplicate decisions
creates news-only canonical events
```

## Recommended implementation sequence

```text
1. Land this design-only PR.
2. Implement a migration-free read-only query projection.
3. Add read model tests and TDnet regression tests.
4. Add API/feed exposure behind the explicit Stage 5.1 contract.
5. Only after the contract stabilizes, design a dedicated overlay attachment table as Stage 5.2.
```
