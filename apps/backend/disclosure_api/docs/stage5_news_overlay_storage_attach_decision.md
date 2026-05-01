# Stage 5 news overlay storage attach decision

This document selects the storage attach path for the first Stage 5 news overlay runtime slice.

This is a docs-only decision PR. It does not add runtime code, source adapters, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 744a06c197c2418e94f232159e1f1b4399fd5853
base commit source: PR #66 Stage 5 news overlay runtime preflight
fixture payload: priv/fixtures/source_payloads/stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

## Decision

Stage 5 v1 will use Option C: raw-document-only overlay staging.

```text
selected option: Option C
implementation mode: raw-document-only overlay staging
migration required: no
canonical_feed_items mutation: forbidden
news-only canonical event creation: forbidden
runtime visibility in canonical feed: deferred
```

## Rationale

Option C is selected for the first runtime slice because it has the lowest risk of mutating locked official event contracts.

Reasons:

```text
no database migration is required
canonical_feed_items remain unchanged
locked official event_id remains unchanged
locked stable_external_id remains unchanged
locked raw document identities remain unchanged
Reuters context can be staged idempotently
future attach/query path can be designed after storage behavior is verified
```

This intentionally defers feed-visible overlay rendering until a later dedicated overlay attachment/query PR.

## Scope of the first runtime slice

The first runtime slice may stage exactly one Reuters overlay fixture.

Allowed fixture:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

Allowed source contract:

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
source_tier: reputable_news_source
document_role: news_article
overlay_mode: attach_only
```

## Stage-only storage expectations

The runtime may write:

```text
SourceRegistry row for stage5_news_overlay_fixture
RawDocument row for Reuters article metadata fixture
RawEvent row for staged overlay candidate
source cursor/health metadata for the stage5_news_overlay_fixture source
```

The runtime must not write or mutate:

```text
CanonicalFeedItem for a new news event
CanonicalFeedItem official contract_v1 fields
CanonicalItemSource rows for the official item
existing TDnet raw documents
existing TDnet raw events
existing TDnet source cursor semantics
```

## Stable staged identities

The runtime should use deterministic staged identities.

```text
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
raw_document_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
raw_event_external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
```

These IDs must be stable across repeated polls.

## Required adapter behavior

A future `stage5_news_overlay_fixture_v1` adapter should:

```text
load the fixture payload from priv/fixtures/source_payloads
return exactly one discovery item
hydrate only from the local fixture payload
parse exactly one staged overlay raw event
normalize only if the ingestion pipeline requires a normalized shape, but must not create a new canonical news item
preserve overlayClaims and citations in raw event payload
preserve matchEvidence in raw event payload
```

If the existing ingestion pipeline forces every adapter into canonical item creation, the first runtime PR must stop at raw-document/raw-event staging or introduce a safe bypass. It must not work around this by creating a Reuters canonical event.

## Required non-mutation tests

The first runtime PR must test that official canonical data stays unchanged.

Minimum assertions:

```text
existing TDnet official CanonicalFeedItem count for event_id remains 1
official event_id remains jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
official stable_external_id remains TDNET:4527:20260430:1900:140120260430515474
official published_at_local remains 2026-04-30T19:00:00+09:00
official published_at_utc remains 2026-04-30T10:00:00.000000Z
official canonical_event_type remains material_information_update
official source citations remain TDnet citations
canonical feed item count does not increase because of the Reuters overlay
```

## Required staging tests

The first runtime PR must test idempotent staging.

Minimum assertions:

```text
poll 1 staged overlay raw document count = 1
poll 2 staged overlay raw document count = 1
poll 1 staged overlay raw event count = 1
poll 2 staged overlay raw event count = 1
overlay_id is stable across repeated polls
article_external_id is stable across repeated polls
overlayClaims preserve canonicalFactOverride=false
Reuters citation remains source_tier=reputable_news_source
TDnet citation remains source_tier=official_exchange_storage
matchEvidence is preserved
conflictFlags are preserved as []
```

## Required manual smoke

Manual smoke should record:

```text
stage5_news_overlay_fixture source health: healthy
records_seen: 1
staged raw document external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
staged raw event external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
canonical feed item count unchanged
official TDnet event still returns TDnet canonical fields
no Reuters article text stored beyond supplied metadata/summary
no secrets stored
```

## Deferred work

The following are deferred until after raw-document-only staging is verified:

```text
dedicated news_overlay_attachments table
feed-visible overlay rendering
cross-source duplicate_group_key materialization
multiple news overlays per official event
Bloomberg backup fixture
live Reuters fetch
provider API integration
social/rumor sources
```

## No-go conditions

Do not implement runtime if it requires:

```text
creating a new canonical Reuters event
changing official TDnet event fields
changing official TDnet stable_external_id
changing official TDnet raw document identity
using Reuters published_at as official published_at
using Reuters source URL as official canonical_url
replacing TDnet official citations with Reuters citations
storing full Reuters article text
fetching Reuters live during tests
storing cookies, signed URLs, API keys, or private tokens
```

## Acceptance criteria for this decision PR

```text
changed files are limited to Stage 5 docs
no runtime code is added
no adapter is added
no fixture payload is added
no test is added
no migration is added
no scheduler change is added
Option C is selected explicitly for Stage 5 v1
runtime implementation remains blocked unless it follows Option C constraints
```
