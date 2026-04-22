# UK FCA NSM holdings / director-dealings backup contract v0

This is the backup contract draft for the UK first-slice decision.
Use it only if the current preferred family cannot satisfy the contract-freeze exit criteria.

## Candidate source identity

Recommended source key:

- `uk_fca_nsm_holdings_director_dealings`

Recommended display name:

- `UK FCA National Storage Mechanism Holdings and Director Dealings Updates`

Recommended region code:

- `uk`

Recommended source class:

- `regulatory_filing_feed`

Recommended source tier:

- `official_regulatory_storage`

## Candidate scope

Do not widen to all announcement types.
Freeze one narrow ownership / director-change family first.

## Candidate runtime naming

Recommended adapter key:

- `uk_fca_nsm_holdings_director_dealings_v1`

## Candidate event mapping

Recommended first event family:

- `ownership_or_director_change_watch`

Canonical event type:

- `TODO`

## Promotion trigger

Promote this backup candidate only if takeover / scheme fails the first-slice contract-freeze exit criteria and this family is demonstrably better on:

- isolatability in public discovery
- stable public immutable identity
- simpler minimum raw-document set
- clearer canonical mapping

## First implementation target

The first implementation PR should still produce exactly one deterministic item with:

- one stable cursor value
- stable repeated-poll event identity
- source-appropriate canonical item source names
- clean dedupe SQL
