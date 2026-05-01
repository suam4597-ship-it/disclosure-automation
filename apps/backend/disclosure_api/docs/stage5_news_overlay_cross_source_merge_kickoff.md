# Stage 5 news overlay / cross-source merge kickoff

This document starts Stage 5 planning after regional runtime locks and controlled broad slices.

This is docs-only. It does not add news overlay code, cross-source merge code, new adapters, fixtures, tests, ops runner, or dedupe SQL.

## Current locked regional baseline

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
JP TDnet timely disclosure
JP TDnet broad timely disclosure
CNInfo broad announcement feed
```

## Deferred regional lane

```text
EDINET statutory report runtime: deferred
reason: type=1 primary document access/payload fixture not yet available
contract-freeze status: frozen from document-list row
runtime status: blocked pending primary document evidence
```

EDINET must not be silently skipped. It remains a frozen but blocked source candidate.

## Stage 5 goals

Stage 5 may start with docs and design only for:

```text
news overlay planning
cross-source merge design
duplicate-group policy across official regulatory sources
citation precedence policy
official-source-first ranking policy
source-freshness and source-tier conflict handling
```

## What Stage 5 must not do yet

Do not add:

```text
production news overlay runtime
cross-source merge runtime
new paid-data adapters
social/news scraping
LLM-only duplicate decisions
EDINET runtime without primary document fixture
broad live pagination for TDnet or CNInfo
mutation of locked event ids or stable ids
```

## Required Stage 5 design decisions

Before implementation, freeze the design for:

```text
how official-source items and news-overlay items join
whether official source or news source owns canonical event id
which sources can create duplicate_group_key
how to merge sources without losing raw document provenance
how to rank official filings vs news writeups
how to preserve per-source citations
how to show conflicts between official and media reports
how to handle region-specific duplicate semantics
```

## Candidate source precedence

Initial precedence proposal:

```text
1. official regulatory/exchange storage
2. official company or issuer release
3. reputable news source
4. secondary aggregator
```

Within this proposal, EDINET/TDnet/CNInfo/SEC/AFM/UK/TW official source records should remain source-of-truth for legal filing facts.

## Candidate merge rule

For Stage 5 design, do not merge official records into news records.

Prefer:

```text
official event remains canonical
news overlay attaches as contextual citation / narrative overlay
```

Do not replace official timestamps, issuer ids, stable ids, or raw document identities with news-derived values.

## Required next PR

Create a Stage 5 design PR before implementation:

```text
apps/backend/disclosure_api/docs/stage5_news_overlay_design.md
apps/backend/disclosure_api/docs/stage5_cross_source_merge_policy.md
apps/backend/disclosure_api/docs/stage5_source_precedence_and_citation_policy.md
```

## Current decision

Stage 5 may begin as design-only while EDINET runtime remains blocked.

Runtime implementation for Stage 5 should wait until the design docs are merged and the locked regional baselines are explicitly preserved.
