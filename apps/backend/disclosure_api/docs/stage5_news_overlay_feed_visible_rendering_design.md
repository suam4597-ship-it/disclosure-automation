# Stage 5.1 news overlay feed-visible rendering design

This document defines the docs-only design for making the locked Stage 5.1 news overlay API/read model visible in feed-facing responses.

This is a design document only. It does not add feed controller code, route code, renderer code, runtime code, tests, fixtures, database migrations, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f2c2091e863095b1f2781370541e269bac82da4a
base commit source: PR #85 Lock Stage 5.1 news overlay API exposure
locked API route: GET /api/events/:event_id/news-overlay
locked read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
stage: Stage 5.1 feed-visible rendering design
status: design-only
```

## Goal

Expose related Reuters overlay context in feed-visible item responses without creating a second canonical feed row and without changing official TDnet canonical facts.

Target user-visible mental model:

```text
Official TDnet disclosure item
  Related news context: Reuters
```

Not allowed:

```text
TDnet canonical item
Reuters canonical item
```

## Non-goals

```text
feed implementation: out of scope for this PR
route/controller changes: out of scope for this PR
runtime code changes: out of scope for this PR
database migration: out of scope
fixture changes: out of scope
scheduler changes: out of scope
live Reuters fetch: out of scope
provider API integration: out of scope
dedicated overlay attachment table: out of scope
news-only canonical event creation: prohibited
canonical feed item mutation: prohibited
```

## Recommended first surface

The first feed-visible implementation should be additive on detail/digest item serialization, not a new feed lane.

Preferred first target:

```text
GET /api/feed/digest/latest?edition=breaking
GET /api/feed/digest/:digest_date/:edition
```

Allowed implementation shape:

```text
add relatedNewsOverlays or newsOverlays to each affected feed item
keep existing feed item fields unchanged
reuse locked Stage5NewsOverlayReadModel for the event_id
```

Do not change ranking, hero selection, region lane ordering, digest item count, or canonical item creation.

## Why digest item first

Digest item JSON is a safer first surface because it already represents item detail within a feed response.

The first implementation should not change:

```text
hero selection logic
region lane ordering
priority ranking
canonical_feed_items rows
source polling behavior
```

## Recommended response field

Recommended additive field name:

```text
news_overlays
```

Alternative camelCase for client-facing JSON may be:

```text
newsOverlays
```

The implementation should follow existing API casing conventions. The field must clearly be an overlay field and must not be named `sources`, `citations`, or `canonicalItems` in a way that merges it with official source data.

## Feed item hierarchy

A feed item with overlay should preserve this hierarchy:

```text
feed item official fields
  event_id
  headline/title
  canonical_event_type
  published_at_utc
  canonical_url / official source URL
  source_meta
  portable_citations

news_overlays[]
  Reuters overlay context
  Reuters overlay claims
  Reuters overlay citation
  conflict flags
  canonicalFactOverride=false
```

Official fields must remain the primary feed item fields.

## Source separation

Official source metadata and news overlay metadata must remain separate.

Official TDnet source:

```text
source_key: jp_tdnet_timely_disclosure
source_tier: official_exchange_storage
document_role: official_exchange_disclosure
```

Reuters overlay source:

```text
source_key: stage5_news_overlay_fixture
source_tier: reputable_news_source
document_role: news_article
provider: Reuters
```

The feed response must not imply Reuters is the official disclosure source.

## Citation separation

Feed-visible rendering must preserve citation ordering:

```text
1. official TDnet citation
2. Reuters overlay citation
```

The implementation may either:

```text
keep item.portable_citations unchanged and place overlay citations under news_overlays[].citations[]
```

or, in a later design:

```text
provide a separate flattened display citation list with official citations first
```

The first implementation should prefer separate overlay citations to avoid breaking existing consumers.

## canonicalFactOverride policy

Every feed-visible overlay must expose or internally preserve:

```text
canonicalFactOverride: false
```

The overlay must never overwrite:

```text
item title/headline
item published_at_utc
item canonical_url / official source URL
item canonical_event_type
item event_id
item stable_external_id
item issuer/security code
```

## Display labels

Recommended labels for UI clients:

```text
official label: Official exchange disclosure
overlay section label: Related news context
overlay provider label: Reuters
overlay role label: News article
```

Avoid labels that imply Reuters is official:

```text
Reuters disclosure
Reuters filing
Reuters official update
```

## Conflict flags

Feed-visible overlay objects should carry conflict flags from the locked read model.

Initial flag expected for the Reuters fixture:

```text
provider_url_not_official_url
```

This flag means the Reuters URL is separate from the official TDnet URL. It is not a feed item error and must not suppress the official item.

## Empty overlay behavior

When no overlay exists for a feed item:

```text
news_overlays: []
```

or the field may be omitted if the existing API style avoids empty arrays.

Preferred first implementation:

```text
news_overlays: []
```

This makes client behavior deterministic.

## Multiple overlay future state

Later stages may support multiple provider overlays:

```text
news_overlays[]
  Reuters
  Bloomberg
  other allowed reputable provider
```

The first implementation may only return zero or one overlay for the locked Reuters fixture, but the response field should be a list.

## No-go conditions

A feed-visible implementation must fail review if it does any of the following:

```text
creates a Reuters feed row
creates a Reuters CanonicalFeedItem
mutates canonical_feed_items
changes digest item count due to overlay
changes hero/region ranking due to overlay
uses Reuters title as item headline
uses Reuters publishedAt as item published_at_utc
uses Reuters URL as item canonical_url
returns full Reuters article text
adds live Reuters fetch
adds provider API integration
adds a migration
changes fixtures
```

## Recommended sequence

```text
1. Land this docs-only design PR.
2. Implement feed digest item overlay field using the locked read model/API contract.
3. Add feed API tests for no-overlay and with-overlay states.
4. Run Stage 5.1 API/read model regressions and TDnet regressions.
5. Close out and lock feed-visible rendering after PASS evidence.
```
