# UK FCA NSM takeover / scheme candidate contract v0

This is a candidate contract draft for the current preferred UK first slice.
It is intentionally incomplete and should not be treated as a lock spec yet.

## Candidate source identity

Recommended source key:

- `uk_fca_nsm_takeover_scheme_updates`

Recommended display name:

- `UK FCA National Storage Mechanism Takeover and Scheme Updates`

Recommended region code:

- `uk`

Recommended source class:

- `regulatory_filing_feed`

Recommended source tier:

- `official_regulatory_storage`

## Candidate scope

Target only disclosures that clearly fall into takeover / scheme related updates.
Do not widen to all regulated announcements in the first slice.

## Candidate discovery model

Primary discovery surface:

- public FCA NSM search interface

Candidate detail surface:

- NSM artefact pages under `data.fca.org.uk/artefacts/NSM/...`

## Candidate runtime naming

Recommended adapter key:

- `uk_fca_nsm_takeover_scheme_updates_v1`

Recommended parser shape:

- discovery parser for search result rows
- detail parser for artefact HTML and linked filing payload if needed

## Candidate identity options

Evaluate in this order:

1. immutable artefact URL token
2. public unique announcement id when exposed
3. RNS number where always present

## Candidate cursor options

Evaluate in this order:

1. latest immutable artefact id seen
2. latest unique announcement id seen
3. latest published timestamp seen

## Candidate event mapping

Recommended first event family:

- `takeover_or_scheme_update`

Canonical event type:

- `TODO`

## Must-close questions before code

- can the search surface isolate takeover / scheme items deterministically?
- does every chosen item expose one stable immutable id?
- is one detail artefact page enough for the first fixture, or is a linked filing payload also required?
- what is the minimum raw-document set per item?
- what exact canonical event type should pair with `takeover_or_scheme_update`?

## First implementation target

The first implementation PR should produce exactly one deterministic item with:

- one stable cursor value
- stable repeated-poll event identity
- source-appropriate canonical item source names
- clean dedupe SQL
