# Stage 5 news overlay raw-staging runtime workset

This document defines the next implementation workset for the Stage 5 v1 news overlay runtime after selecting Option C.

This is a docs-only workset. It does not add runtime code, source adapters, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 744a06c197c2418e94f232159e1f1b4399fd5853
base commit source: PR #66 Stage 5 news overlay runtime preflight
selected storage option: Option C raw-document-only overlay staging
```

## Next implementation PR title

Suggested title:

```text
Implement Stage 5 news overlay raw-staging runtime slice
```

Suggested branch:

```text
chatgpt-stage5-news-overlay-raw-staging-runtime-v1
```

## Implementation scope

The next runtime PR may add only:

```text
stage5_news_overlay_fixture source helper
stage5_news_overlay_fixture_v1 adapter
source registry sample for stage5_news_overlay_fixture
ops runner for isolated manual smoke
idempotency test for raw-document/raw-event staging
HTTP smoke test only if existing HTTP smoke pattern supports source polling without feed mutation
minimal dedupe/staging SQL if needed
manual smoke doc
first-run triage doc
```

## Fixture scope

Only this fixture may be used:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

No additional Reuters, Bloomberg, or live provider fixtures may be added.

## Runtime behavior

The runtime should:

```text
load the Reuters fixture from local priv/fixtures/source_payloads
stage one RawDocument for article metadata
stage one RawEvent for overlay candidate
preserve overlayClaims
preserve matchEvidence
preserve separate TDnet and Reuters citations
set source health healthy after successful fixture staging
set deterministic cursor value from article_published_at and article_external_id
remain idempotent across repeated polls
```

The runtime must not:

```text
create a new CanonicalFeedItem for Reuters
mutate the existing TDnet CanonicalFeedItem
mutate TDnet RawDocument rows
mutate TDnet RawEvent rows
mutate TDnet CanonicalItemSource rows
perform live Reuters fetches
store full Reuters article text
store secrets
```

## Expected identities

```text
source_key: stage5_news_overlay_fixture
adapter_key: stage5_news_overlay_fixture_v1
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
raw_document_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata
raw_event_external_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate
cursor_key: latest_article_published_at_and_article_external_id_seen
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Required config sample

A future source registry sample should include:

```text
source_key: stage5_news_overlay_fixture
display_name: Stage 5 News Overlay Fixture
source_type: api
adapter_key: stage5_news_overlay_fixture_v1
region_code: jp
discovery_mode: fixture
hydrate_mode: local_fixture
source_class: news_overlay_feed
default_source_tier: reputable_news_source
parser_key: stage5_news_overlay_fixture_v1
active: true
config:
  overlay_mode: attach_only
  fixtures:
    overlay_result: source_payloads/stage5_news_overlay_fixture_jp_tdnet_140120260430515474_reuters_jp_article_001.json
```

## Required tests

### Idempotency test

Suggested file:

```text
test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
```

Minimum assertions:

```text
poll 1 records_seen == 1
poll 2 records_seen == 1
raw document count for raw_document_external_id == 1
raw event count for raw_event_external_id == 1
canonical feed item count for Reuters overlay event == 0
canonical feed item count for official TDnet event remains 1
official TDnet source_meta stable_external_id unchanged
official TDnet published_at_local unchanged
official TDnet canonical_event_type unchanged
overlayClaims canonicalFactOverride values are false
Reuters citation and TDnet citation remain separate in staged raw payload
source health is healthy
cursor value equals expected cursor
```

### HTTP smoke test

Suggested file:

```text
test/stage5_news_overlay_raw_staging_http_smoke_test.exs
```

Only add this if the existing HTTP smoke pattern can verify staged source health and source polling without implying feed-visible overlay output.

Minimum assertions:

```text
source can be polled through the HTTP smoke path
records_seen == 1
source health healthy
canonical feed event count unchanged
no Reuters canonical event appears in feed
```

## Required manual smoke

Suggested file:

```text
apps/backend/disclosure_api/docs/stage5_news_overlay_raw_staging_manual_smoke.md
```

Manual smoke should record:

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
staged raw document count: 1
staged raw event count: 1
official TDnet canonical event count: 1
Reuters canonical event count: 0
source health: healthy
cursor_key: latest_article_published_at_and_article_external_id_seen
cursor_value: 2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
```

## Required dedupe/staging SQL

Suggested file:

```text
apps/backend/disclosure_api/priv/ops/stage5_news_overlay_raw_staging_dedupe_checks.sql
```

Minimum checks:

```text
no duplicate raw document for article metadata external id
no duplicate raw event for overlay candidate external id
no canonical feed item with Reuters overlay_id as event_id
exactly one official TDnet canonical item remains
no duplicate source cursor for stage5_news_overlay_fixture
```

## Runtime lock boundary

The next implementation PR should not mark runtime locked.

After implementation, a separate close-out PR should record:

```text
automated idempotency test: PASS
HTTP smoke test if added: PASS
manual isolated smoke: PASS
storage-level staging/dedupe SQL: PASS
regional regression tests: PASS
secret redaction check: PASS
runtime lock status: locked
```

## Out of scope for next implementation PR

```text
dedicated overlay attachment table
feed-visible overlay rendering
cross-source duplicate_group_key materialization
Bloomberg backup fixture
live Reuters fetch
provider API integration
social scraping
rumor ingestion
news-only event creation
LLM-only merge finalization
mutation of locked official canonical facts
```

## Acceptance criteria for this workset PR

```text
changed files are limited to Stage 5 docs
no runtime code is added
no adapter is added
no fixture payload is added
no test is added
no migration is added
no scheduler change is added
next implementation PR scope is explicitly raw-document-only staging
```
