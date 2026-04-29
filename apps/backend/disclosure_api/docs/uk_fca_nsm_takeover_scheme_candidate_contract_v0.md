# UK FCA NSM takeover / scheme candidate contract v0

This is a candidate contract draft for the current preferred UK first slice.
It is still intentionally incomplete and should not be treated as a lock spec yet, but it is now anchored to concrete public samples.

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

## Current concrete public samples

### Public artefact-backed sample

- issuer: `Greencore Group PLC`
- artefact URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5726018.html`
- RNS Number: `8538P`
- paired public headline: `Result of Meeting / Results of Extraordinary General Meeting`

### CSV exact-category sample

Strongest exact-category row from the CSV probe:

- `Filing Date/Time`: `20/04/2026 06:13`
- `Publication Date/Time`: `20/04/2026 06:00`
- `Document Date`: `20/04/2026`
- `Source`: `Regulatory News Services (RNS)`
- `Disclosing Organisation Name`: `BRITISH LAND COMPANY PUBLIC LIMITED COMPANY(THE)`
- `Description`: `Scheme of Arrangement Becomes Effective`
- `Category`: `Scheme of Arrangement`
- `Download Link`: `https://data.fca.org.uk/artefacts/NSM/RNS/5c9e4a51-b4c6-4977-86d3-ac8567261289.html`
- `Related Organisation(s)`: `LIFE SCIENCE REIT PLC (213800RG7JNX7K8F7525)`

This CSV row is currently the strongest first deterministic fixture target because it is an exact category match and already exposes a public artefact URL.

## Candidate discovery model

Primary discovery surface:

- public FCA NSM search interface

Candidate detail surface:

- NSM artefact pages under `data.fca.org.uk/artefacts/NSM/...`

Current sample-backed narrowing:

- `Document Text = scheme of arrangement` is a viable discovery direction
- text search alone is too broad for the first implementation slice
- the first slice should rely on exported metadata such as `Category`, `Source`, and `Download Link`, not on document text alone

## Candidate runtime naming

Recommended adapter key:

- `uk_fca_nsm_takeover_scheme_updates_v1`

Recommended parser shape:

- discovery parser for CSV or search-result rows
- detail parser for artefact HTML
- linked filing payload parser only if later evidence shows the artefact page is insufficient

## Candidate identity options

Evaluate in this order:

1. immutable artefact URL token
2. public unique announcement id when exposed
3. RNS number where always present

Current sample-backed recommendation:

- first external identity candidate: `NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289`
- first duplicate-group seed candidate: `NSM:RNS:<artefact_token>`

Why this is currently best:

- it is directly visible in the public download link
- it does not depend on title text
- it is more deterministic than company + date + description combinations

## Candidate cursor options

Evaluate in this order:

1. composite `filing_datetime + artefact_uuid`
2. latest immutable artefact id seen
3. latest unique announcement id seen
4. latest published timestamp seen

Current sample-backed provisional cursor:

- `latest_filing_at_and_artefact_id_seen`

Current first candidate cursor value shape:

- `2026-04-20T06:13:00|RNS|5c9e4a51-b4c6-4977-86d3-ac8567261289`

Why:

- the CSV probe exposes `Filing Date/Time`
- the CSV probe exposes a deterministic artefact token through `Download Link`
- this avoids title-text heuristics

## Candidate event mapping

Recommended first event family:

- `takeover_or_scheme_update`

Canonical event type:

- `TODO`

## Minimum raw-document assumption

Current first assumption for the initial isolated slice:

- one discovery result fixture
- one detail artefact HTML fixture
- no linked filing payload required for v0 unless the artefact page proves insufficient
- minimum raw-document count per item: `2`

## Important implementation warning

The CSV probe shows that document-text search for `scheme of arrangement` overmatches related but broader items such as:

- `Result of Meeting`
- `Offer Update`

Therefore the first implementation slice must rely on exported metadata such as:

- `Category`
- `Source`
- `Download Link`

and not on document-text matching alone.

## Must-close questions before code

- can the search surface isolate takeover / scheme items deterministically using metadata, not just document text?
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
