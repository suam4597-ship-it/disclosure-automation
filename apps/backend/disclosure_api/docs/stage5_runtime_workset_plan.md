# Stage 5 runtime workset plan

This document defines the proposed future Stage 5 runtime workset after the design-only policy PR is merged.

This document is design-only. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Current PR scope

This PR is docs-only.

Allowed in this PR:

```text
Stage 5 design documents
news overlay design
cross-source merge policy
source precedence policy
citation policy
duplicate group policy
future runtime workset plan
```

Forbidden in this PR:

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
```

## Stage 5 implementation sequence

Stage 5 implementation must proceed in small controlled PRs.

```text
Step 1: docs-only design PR
Step 2: overlay source contract-freeze PR
Step 3: official + overlay fixture PR
Step 4: isolated runtime PR
Step 5: verification and runtime lock close-out PR
```

Do not skip directly from design to broad runtime implementation.

## Step 1: docs-only design PR

Goal:

```text
freeze Stage 5 policy boundaries before code exists
preserve locked regional official-disclosure runtimes
explicitly forbid news-only event creation in Stage 5 v1
explicitly forbid LLM-only duplicate decisions
```

Required docs:

```text
apps/backend/disclosure_api/docs/stage5_news_overlay_design.md
apps/backend/disclosure_api/docs/stage5_cross_source_merge_policy.md
apps/backend/disclosure_api/docs/stage5_source_precedence_and_citation_policy.md
apps/backend/disclosure_api/docs/stage5_duplicate_group_policy.md
apps/backend/disclosure_api/docs/stage5_runtime_workset_plan.md
```

## Step 2: overlay source contract-freeze PR

Before runtime code, choose one overlay source candidate and freeze its contract.

Example placeholder:

```text
source_key: news_overlay_fixture
adapter_key: news_overlay_fixture_v1
source_tier: reputable_news_source or secondary_overlay_source
scope: 1-2 news overlay fixtures only
```

Contract-freeze should define:

```text
source key
adapter key
source tier
document role
article external id shape
article URL shape
published_at semantics
retrieved_at semantics
claim_supported fields
redaction rules
fixture storage path
expected overlay context type
expected citation object
```

If no provider or fixture source is selected, runtime implementation must not start.

## Step 3: cross-source fixture PR

Start with one or two fixture pairs.

Recommended fixture sets:

```text
1 official JP TDnet event + 1 related news overlay
1 official CNInfo event + 1 related news overlay
```

Alternative fixture sets:

```text
1 SEC official event + 1 related news overlay
1 JP TDnet official event + 1 related news overlay
```

Fixture requirements:

```text
official event remains unchanged
overlay attaches to official event
event_id remains unchanged
stable_external_id remains unchanged
raw_document_external_id remains unchanged
citation provenance remains per source
match evidence is explicit
conflict flags are explicit when needed
```

## Step 4: isolated runtime PR

Runtime should be intentionally small.

Minimum scope:

```text
one overlay source
one official source family
one merge rule
one or two fixture pairs
no broad news ingestion
no social scraping
no production scheduler change
```

Runtime must implement:

```text
idempotent overlay attachment
source-specific citation preservation
redaction-safe metadata
explicit match evidence
conflict flag preservation
no mutation of official event identifiers
```

Runtime must not implement:

```text
news-only event creation
LLM-only merge finalization
unbounded news crawling
all-source merge
production scheduler changes
mutation of locked regional runtimes
```

## Step 5: verification and lock close-out PR

A Stage 5 runtime lock close-out should include:

```text
automated idempotency test: PASS
HTTP smoke test: PASS
regional regression tests: PASS
manual isolated smoke: PASS
storage-level dedupe or merge SQL: PASS
citation provenance check: PASS
secret redaction check: PASS
runtime code patch required after verification: no
runtime lock status: locked
```

## Required tests for future runtime PR

Future runtime PRs should include tests only after design and fixture contracts are frozen.

Suggested tests:

```text
news_overlay_runtime_idempotency_test
news_overlay_http_smoke_test
cross_source_merge_candidate_test
citation_provenance_test
duplicate_group_idempotency_test
secret_redaction_test
regional_regression_tests
```

The exact file names are deferred until implementation.

## Required manual verification for future runtime PR

Manual smoke should verify:

```text
poll 1 overlay count
poll 2 overlay count
same overlay_id across repeated poll
same official event_id across repeated poll
same stable_external_id across repeated poll
same raw_document_external_id across repeated poll
duplicate_group_key is stable if introduced
news citation is separate from official citation
official facts are not overwritten
conflict flags are preserved
source health remains healthy
secret-bearing values are redacted
```

## Stage 5 no-go guardrails

Do not implement any of the following until a later explicit policy and fixture PR allows it:

```text
news-only event creation
social scraping
rumor ingestion
LLM-only merge finalization
broad news crawl
all-source global dedupe
production scheduler mutation
EDINET broad pagination
TDnet live pagination
CNInfo unbounded pagination
all CNInfo categories
changing existing event IDs
changing existing stable IDs
changing existing raw document identities
```

## Merge readiness for this docs-only PR

This design PR is merge-ready only if:

```text
changed files are limited to Stage 5 docs
no runtime code is present
no fixture is present
no test is present
no migration is present
no production scheduler change is present
policies explicitly preserve locked regional runtimes
policies explicitly forbid news-only event creation in Stage 5 v1
policies explicitly forbid LLM-only duplicate decisions
```
