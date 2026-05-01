# Stage 5.1 news overlay next runtime workset

This document defines the recommended next runtime workset after the Stage 5.1 read model, feed rendering, and API response contracts are accepted.

This is a planning document only. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, feed-visible implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d4fd1b8f437f5dfe1ba879de930194f9f1ad45b3
prior lock PR: #79 Lock Stage 5 news overlay raw staging runtime
stage: Stage 5.1
status: design-only
```

## Recommended next runtime PR

The next implementation PR should be a migration-free read-only projection over existing raw staging and canonical feed data.

Recommended title:

```text
Implement Stage 5.1 news overlay read model query
```

Recommended branch:

```text
chatgpt-stage5-news-overlay-read-model-query-v1
```

## Scope

Allowed scope for the next runtime PR:

```text
read-only query/projection code
API serializer or response model additions behind the Stage 5.1 contract
unit tests for read model association and serialization
TDnet regression tests
redaction tests for overlay response payloads
manual smoke instructions
```

Disallowed scope for the next runtime PR:

```text
database migrations
dedicated news_overlay_attachments table
fixture additions
live Reuters fetch
Bloomberg fixture
provider API integration
scheduler changes
canonical_feed_items mutation
Reuters canonical feed item creation
news-only canonical event creation
full Reuters article text storage
LLM-only duplicate decisions
social scraping
rumor ingestion
```

## Implementation approach

The next runtime should build a read model from existing rows.

Preferred approach:

```text
1. Load official canonical feed item by event_id or stable_external_id.
2. Load raw-staged overlay candidate rows for source_key=stage5_news_overlay_fixture.
3. Require a direct official identifier match from the overlay payload.
4. Build overlays[] without mutating canonical_feed_items.
5. Return official item fields unchanged.
6. Return Reuters overlay fields under overlays[].
```

The implementation should not introduce a new table until the read contract is stable.

## Required association checks

A visible overlay must pass these checks:

```text
raw_event.canonical_feed_mutation == false
raw_event.news_only_event_creation == false
raw_document.document_role == news_article
raw_document.source_tier == reputable_news_source
overlay payload contains direct official event_id or stable_external_id
overlay source_key is allowed for Stage 5.1
```

If the direct official identifier is missing, the overlay should be hidden or excluded from normal feed responses.

## Required regression checks

The next runtime PR should verify that the TDnet canonical item remains unchanged.

Required checks:

```text
canonical_feed_item.source_key remains jp_tdnet_timely_disclosure
canonical_feed_item.title remains official TDnet title
canonical_feed_item.published_at remains official TDnet published_at
canonical_feed_item.canonical_url remains official TDnet canonical_url
canonical_feed_item.stable_external_id remains TDnet stable external ID
no Reuters CanonicalFeedItem is created
no news-only CanonicalFeedItem is created
```

## Required read model tests

Recommended test cases:

```text
returns official item with overlays=[] when no raw overlay exists
returns one Reuters overlay when raw overlay has direct official identifier
keeps TDnet official citation first
keeps Reuters overlay citation separate
sets canonicalFactOverride=false on overlay
sets canonicalFactOverride=false on overlayClaims
exposes source_tier and document_role for official and overlay sources
adds provider_url_not_official_url conflict flag when URLs differ
hides overlay when direct official identifier is missing
rejects or suppresses overlay if source_tier is not allowed
```

## Required API contract tests

Recommended API-level checks:

```text
item.sourceKey is jp_tdnet_timely_disclosure
item.canonicalUrl is official TDnet URL
item.publishedAt is official TDnet timestamp
item.overlays[0].provider is Reuters
item.overlays[0].sourceTier is reputable_news_source
item.overlays[0].documentRole is news_article
item.overlays[0].canonicalFactOverride is false
item.overlays[0].citations[0].isCanonicalSource is false
item.citations[0].isCanonicalSource is true
flattened citations put TDnet before Reuters
```

## Required redaction checks

The next runtime PR should include a redaction check for response payloads and logs.

The following must not appear:

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

## Manual smoke checklist

Manual smoke should verify:

```text
official TDnet item still renders without overlay mutation
overlay appears only under related news context
overlay citation is separate from TDnet citation
official TDnet citation remains first
Reuters URL is not the primary official URL
Reuters published_at is not the official item published_at
no new canonical feed item exists for Reuters
no migration was added
```

## Merge criteria

The next runtime PR should only be merged if:

```text
changed files match the allowed runtime/query/API/test scope
no migration files are present
no fixture files are added
no scheduler files are changed
no provider fetch integration is added
all targeted tests pass
TDnet regression checks pass
redaction checks pass
manual smoke evidence is recorded
PR is mergeable
```

## Stage 5.2 handoff

Only after the Stage 5.1 read-only projection is stable should Stage 5.2 consider a dedicated overlay attachment table.

Stage 5.2 should be a separate design and migration PR sequence.

Possible Stage 5.2 topics:

```text
news_overlay_attachments table design
multiple overlays per official event
cross-source duplicate_group_key materialization
provider-backed ingestion metadata
second overlay fixture policy
```

## Hard no-go list

Any future PR in this area must be stopped if it does any of the following without a separate approved design:

```text
creates Reuters canonical feed items
creates news-only canonical events
mutates official TDnet canonical fields
uses Reuters published_at as official published_at
uses Reuters URL as official canonical_url
stores full Reuters article text
uses LLM-only duplicate decisions
adds live provider fetches
adds social scraping or rumor ingestion
```
