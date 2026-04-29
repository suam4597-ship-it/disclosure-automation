# UK FCA NSM high-signal family decision

This document records why the UK first slice should prefer a narrow, high-signal family over AFR-first.

## Goal

The UK first slice should help users follow important listed-company disclosures as they happen.
It should not optimize first for periodic reporting volume.

## Candidate families

### 1) Takeover / scheme related update

Pros:

- high user value
- lower expected volume than AFR or broader announcement streams
- event semantics are comparatively sharp
- likely to produce cleaner first lock boundaries

Cons:

- may require tighter query or title filtering to isolate reliably
- stable identifiers must be checked carefully across related update chains

Current rank:

- `1`

### 2) Major holdings / director dealings

Pros:

- also high-signal and time-sensitive
- closer to shareholding / control-watch families already used in AFM and SEC work
- likely more relevant to ownership-change monitoring

Cons:

- may involve multiple adjacent subfamilies instead of one clean surface
- the first event-family naming boundary must be chosen carefully

Current rank:

- `2`

### 3) Annual Financial Reports

Pros:

- easy to explain
- officially documented in FCA guidance
- likely easy to find examples for fixtures

Cons:

- periodic rather than event-driven
- may introduce more volume than the first UK slice needs
- weaker fit for the product goal of following important developments as they happen

Current rank:

- `3`

## Decision

The UK first slice should not be AFR-first.

Recommended current priority order:

1. `takeover / scheme related update`
2. `major holdings / director dealings`
3. `annual financial report`

## Next freeze question

Before runtime code is added, confirm which of the top two families is easier to isolate from the public NSM search + artefact path with:

- one stable external identity
- one stable cursor field
- one deterministic fixture row
- one clear event-family mapping
