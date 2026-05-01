# Stage 5 news overlay design

Stage 5 introduces a news overlay layer on top of the locked official-disclosure ingestion layer.

This document is design-only. It does not introduce runtime code, source adapters, fixtures, tests, database migrations, schedulers, scraping, or changes to any locked regional runtime.

## Baseline

Stage 5 starts after the regional official-disclosure ingestion layer has been locked.

Locked official sources include:

```text
SEC 6-K
SEC 8-K
SEC SC TO-T
SEC SC 14D-9
SEC SC 13D/A
AFM substantial holdings
UK FCA NSM takeover/scheme
TW MOPS material information
CNInfo ownership-change
CNInfo broad announcement feed
JP TDnet timely disclosure
JP TDnet broad timely disclosure
JP EDINET statutory report
```

The Stage 5 design baseline is:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 7983785bb04d9ad3718117ab24f807599046ee96
base commit source: PR #61 JP EDINET statutory report runtime lock close-out
```

## Goal

Stage 5 adds secondary context to canonical official events without weakening the locked official-source contracts.

News overlay may attach:

```text
context
narrative
market reaction
secondary confirmation
reported background
related article citations
```

News overlay must not replace official filing facts.

## Non-goals

Stage 5 v1 must not create news-only canonical events.

Out of scope for this design PR:

```text
news overlay runtime code
cross-source merge runtime code
new source adapters
new fixtures
new tests
ops runner
dedupe SQL
production scheduler changes
database migrations
mutation of locked regional runtimes
EDINET broad pagination
TDnet live pagination
CNInfo unbounded pagination
all CNInfo categories
news scraping
social scraping
LLM-only merge decisions
```

## Canonical source rule

Official regulatory, exchange, and statutory filing sources remain canonical for legal filing facts.

News overlay must not overwrite:

```text
event_id
stable_external_id
raw_document_external_id
raw document identity
published_at from official source
filing date from official source
issuer identifiers from official source
filing facts from official source
official source citation
```

News overlay may add separate fields or related records that are explicitly marked as overlay-derived.

## Stage 5 v1 creation policy

Stage 5 v1 is attach-only.

```text
news-only event creation: forbidden
overlay attaches to existing official canonical event: allowed
news article becomes canonical event source: forbidden
news article becomes related source/citation: allowed
```

News-only event creation is deferred to a later stage after explicit contract-freeze, fixture, verification, and lock policies exist.

## Overlay attachment model

A news overlay attachment should preserve source-specific provenance and should be reversible without changing the official canonical event.

Suggested logical shape:

```text
overlay_id
canonical_event_id
source_key
source_tier
source_name
source_url
article_external_id
article_title
article_published_at
article_retrieved_at
claim_supported
overlay_summary
overlay_context_type
match_evidence
conflict_flags
created_at
```

The attachment model must support multiple news items for one canonical event.

## Overlay context types

Initial context types:

```text
secondary_confirmation
market_reaction
reported_background
issuer_comment
analyst_comment
transaction_context
discrepancy_note
```

A context type does not change the canonical event type.

## Conflict handling

When news conflicts with official data, the official filing wins for filing facts.

The overlay may record a discrepancy, but it must not silently mutate official values.

Candidate conflict flags:

```text
news_official_timestamp_conflict
news_official_amount_conflict
news_official_parties_conflict
news_unconfirmed_claim
official_update_supersedes_news
```

## Security and secret handling

Stage 5 design must preserve existing secret guardrails.

```text
Do not commit API keys.
Do not paste API keys into PR bodies.
Do not store API keys in fixtures.
Do not store API keys in docs.
Do not store API keys in test output.
Do not store API keys in runtime metadata.
Do not store API keys in portable citations.
```

EDINET request shapes, when referenced, must remain redacted:

```text
Subscription-Key=<redacted>
```

## Acceptance criteria for this docs-only PR

```text
only Stage 5 docs are added
no runtime code is added
no tests are added
no fixtures are added
no database migrations are added
no locked event IDs are changed
no locked stable_external_ids are changed
no locked raw document identities are changed
news-only event creation remains forbidden
LLM-only duplicate decisions remain forbidden
```
