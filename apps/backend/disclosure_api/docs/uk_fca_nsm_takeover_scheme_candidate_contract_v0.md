# UK FCA NSM takeover / scheme candidate contract v0

This is a candidate contract draft for the current preferred UK first slice.
It is still intentionally incomplete and should not be treated as a lock spec yet, but it is now anchored to one concrete public sample.

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

Current anchor sample:

- issuer: `Greencore Group PLC`
- artefact URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5726018.html`
- RNS Number: `8538P`
- paired public headline: `Result of Meeting / Results of Extraordinary General Meeting`

## Candidate discovery model

Primary discovery surface:

- public FCA NSM search interface

Candidate detail surface:

- NSM artefact pages under `data.fca.org.uk/artefacts/NSM/...`

Current sample-backed narrowing:

- `Document Text = scheme of arrangement` is a viable discovery direction
- the first sample resolves to an `NSM/RNS/<token>.html` artefact page

## Candidate runtime naming

Recommended adapter key:

- `uk_fca_nsm_takeover_scheme_updates_v1`

Recommended parser shape:

- discovery parser for search result rows
- detail parser for artefact HTML
- linked filing payload parser only if later evidence shows the artefact page is insufficient

## Candidate identity options

Evaluate in this order:

1. immutable artefact URL token
2. public unique announcement id when exposed
3. RNS number where always present

Current sample-backed recommendation:

- first external identity candidate: `NSM:RNS:5726018`
- first duplicate-group seed candidate: `NSM:RNS:<artefact_token>`

## Candidate cursor options

Evaluate in this order:

1. latest immutable artefact id seen
2. latest unique announcement id seen
3. latest published timestamp seen

Current sample-backed provisional cursor:

- `latest_artefact_token_seen`

## Candidate event mapping

Recommended first event family:

- `takeover_or_scheme_update`

Canonical event type:

- `TODO`

## Minimum raw-document assumption

Current first assumption for the initial isolated slice:

- one discovery result fixture
- one detail artefact HTML fixture
- no linked filing payload required for v0
- minimum raw-document count per item: `2`

## Must-close questions before code

- can the search surface isolate takeover / scheme items deterministically enough beyond this one sample?
- does every chosen item expose one stable immutable id?
- is one detail artefact page enough for the first fixture, or is a linked filing payload also required?
- what exact canonical event type should pair with `takeover_or_scheme_update`?
- does CSV export expose a stronger immutable id or correction/version signal than the artefact token?

## First implementation target

The first implementation PR should produce exactly one deterministic item with:

- one stable cursor value
- stable repeated-poll event identity
- source-appropriate canonical item source names
- clean dedupe SQL
