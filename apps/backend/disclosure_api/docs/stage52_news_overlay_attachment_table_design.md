# Stage 5.2 news overlay attachment table design

This document defines the docs-only design for a future dedicated overlay attachment table that can materialize relationships between official canonical feed items and reputable news overlay context.

This is a design document only. It does not add database migrations, schemas, runtime code, source adapters, fixtures, tests, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 947a516133781e110b84dabc253534324cc1cf25
base commit source: PR #88 Lock Stage 5.1 news overlay feed-visible rendering
locked Stage 5.1 raw staging: PR #79
locked Stage 5.1 read model query: PR #82
locked Stage 5.1 API exposure: PR #85
locked Stage 5.1 feed-visible rendering: PR #88
stage: Stage 5.2 attachment storage design
status: design-only
```

## Motivation

Stage 5.1 intentionally avoided a migration and exposed Reuters overlay context through a migration-free read-only projection over raw staging rows.

Stage 5.2 may add a dedicated attachment table only after the Stage 5.1 behavior is locked.

The table should make overlay relationships durable, queryable, and extensible while preserving the official canonical event as the source of truth.

## Non-goals

```text
migration implementation: out of scope for this PR
Ecto schema implementation: out of scope for this PR
runtime materialization implementation: out of scope for this PR
fixture changes: out of scope
provider fetch integration: out of scope
Bloomberg fixture: out of scope
full Reuters article text storage: prohibited
Reuters CanonicalFeedItem creation: prohibited
news-only CanonicalFeedItem creation: prohibited
canonical_feed_items mutation: prohibited
LLM-only duplicate decisions: prohibited
social scraping or rumor ingestion: prohibited
```

## Proposed table

Recommended table name:

```text
news_overlay_attachments
```

The table stores an attachment edge from one official canonical feed item to one staged or provider-backed news overlay object.

It is not a canonical feed item table.

## Core identity columns

Recommended core columns:

```text
id uuid primary key
official_canonical_feed_item_id uuid not null references canonical_feed_items(id)
official_event_id text not null
official_stable_external_id text null
overlay_source_registry_id uuid null references source_registry(id)
overlay_source_key text not null
overlay_provider text not null
overlay_external_id text not null
overlay_raw_document_id uuid null references raw_documents(id)
overlay_raw_event_id uuid null references raw_events(id)
overlay_id text not null
overlay_mode text not null
display_state text not null
canonical_fact_override boolean not null default false
source_tier text not null
document_role text not null
published_at timestamptz null
url text null
title text null
language text null
jurisdiction text null
overlay_payload jsonb not null default '{}'
conflict_flags jsonb not null default '[]'
overlay_claims jsonb not null default '[]'
citations jsonb not null default '[]'
created_at timestamptz not null
updated_at timestamptz not null
```

## Identity rules

Each attachment row must be anchored to one official canonical feed item.

Required official anchor identity:

```text
official_canonical_feed_item_id
official_event_id
```

Recommended official stable identity:

```text
official_stable_external_id
```

Required overlay identity:

```text
overlay_source_key
overlay_provider
overlay_external_id
overlay_id
```

For the locked Reuters fixture:

```text
overlay_source_key: stage5_news_overlay_fixture
overlay_provider: Reuters
overlay_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
```

## Association rule

A materialized attachment must only be created if the overlay has a direct official identifier match.

Allowed direct match evidence:

```text
overlay payload canonical_event_id equals official event_id
overlay payload matchedCanonicalEventId equals official event_id
overlay payload matchedOfficialStableExternalId equals official stable external id
overlay payload official_anchor.stableExternalId equals official stable external id
```

Do not materialize attachments from issuer name and timestamp alone.

## Constraint recommendations

Recommended uniqueness constraints:

```text
unique(official_canonical_feed_item_id, overlay_source_key, overlay_external_id)
unique(official_event_id, overlay_id)
```

Recommended check constraints:

```text
canonical_fact_override = false for Stage 5.2 v1
overlay_mode in ('attach_only')
display_state in ('visible', 'hidden_missing_direct_official_identifier', 'hidden_conflict_requires_review', 'hidden_full_text_policy', 'hidden_source_not_allowed')
document_role in ('news_article') for Stage 5.2 v1
source_tier in ('reputable_news_source') for Stage 5.2 v1
```

A future provider-backed implementation may widen allowed source tiers and document roles through a separate design PR.

## Index recommendations

Recommended indexes:

```text
news_overlay_attachments_official_item_idx on official_canonical_feed_item_id
news_overlay_attachments_official_event_idx on official_event_id
news_overlay_attachments_overlay_identity_idx on overlay_source_key, overlay_external_id
news_overlay_attachments_display_idx on official_canonical_feed_item_id, display_state
news_overlay_attachments_published_at_idx on published_at
```

## Official fact separation

The attachment table must not duplicate or overwrite official canonical facts.

Official facts remain in `canonical_feed_items.contract_v1` and related canonical feed fields:

```text
official title
official published_at
official canonical URL
official event type
official issuer/security code
official stable external id
```

The attachment table may cache overlay metadata for display, but those values must remain overlay-scoped.

## Overlay payload policy

`overlay_payload` may store safe normalized metadata required for display and debugging.

Allowed:

```text
provider
article title/headline
article published_at
article URL
language
jurisdiction
match evidence summary
display metadata
```

Prohibited:

```text
full Reuters article text
provider credentials
subscription keys
authorization headers
cookies
signed private URLs
raw provider request headers
unredacted secrets
```

## Citation policy

Official citations remain official item citations.

Overlay citations live on the attachment row:

```text
citations jsonb
```

Feed/API renderers must preserve ordering:

```text
1. official TDnet citation
2. overlay citations from news_overlay_attachments
```

Overlay citations must not replace official citations.

## canonical_fact_override policy

For Stage 5.2 v1, all rows must be:

```text
canonical_fact_override = false
```

Any design requiring `canonical_fact_override=true` is outside Stage 5.2 v1 and requires separate review.

## Display state policy

A row can be materialized even if hidden, but normal feed/API responses should only show visible overlays unless an explicit debug/detail mode is designed.

Allowed display states:

```text
visible
hidden_missing_direct_official_identifier
hidden_conflict_requires_review
hidden_full_text_policy
hidden_source_not_allowed
```

The first materialization implementation should only create visible rows for overlays with direct official identifier match.

## Backfill policy

The first backfill should be deterministic and limited to the locked Stage 5.1 Reuters fixture path.

Allowed first backfill scope:

```text
stage5_news_overlay_fixture only
one locked Reuters article fixture
one locked TDnet official event
no live provider fetch
no new fixture payload
```

The backfill must be idempotent.

## Read path policy

After materialization, read paths may prefer the attachment table over raw staging.

Recommended order:

```text
1. read visible news_overlay_attachments rows
2. fall back to Stage 5.1 raw-staging projection only if no attachment rows exist and fallback is explicitly enabled
```

The first implementation may keep the Stage 5.1 raw-staging read model unchanged and introduce the table as an optional materialized source behind a separate PR.

## No-go conditions

A Stage 5.2 implementation must fail review if it does any of the following:

```text
creates Reuters canonical feed items
creates news-only canonical feed items
mutates official TDnet canonical feed item fields
uses Reuters URL as official canonical URL
uses Reuters timestamp as official published_at
uses Reuters headline as official title
stores full Reuters article text
adds live Reuters fetch
adds provider API integration without separate design
adds Bloomberg fixture without separate fixture policy
uses LLM-only duplicate decisions
adds social scraping or rumor ingestion
```

## Recommended sequence

```text
1. Land this docs-only design PR.
2. Create migration design close-out or migration implementation PR for news_overlay_attachments.
3. Add Ecto schema and changeset guardrails.
4. Add deterministic materializer from locked Stage 5.1 raw staging.
5. Add attachment read path tests.
6. Run Stage 5.1 regressions and TDnet no-mutation checks.
7. Close out and lock Stage 5.2 attachment storage after PASS evidence.
```
