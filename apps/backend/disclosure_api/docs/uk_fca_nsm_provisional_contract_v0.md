# UK FCA NSM provisional contract v0

This is a provisional contract draft based on currently confirmed FCA public materials.
It is more concrete than the generic template, but it is still not a runtime lock spec.

## Direction change

The earlier AFR-first recommendation is now deprioritized.

Reason:

- the product goal is to follow important listed-company disclosures as they happen
- a periodic AFR slice is a weaker fit for that goal
- the first UK lock should prefer a narrower, higher-signal family with lower volume

Current preferred first-slice order:

1. `takeover / scheme related update`
2. `major holdings / director dealings`
3. `annual financial report`

## Provisional source identity

Recommended first source key:

- `uk_fca_nsm_takeover_scheme_updates`

Recommended display name:

- `UK FCA National Storage Mechanism Takeover and Scheme Updates`

Recommended region code:

- `uk`

Recommended source class:

- `regulatory_filing_feed`

Recommended source tier:

- `official_regulatory_storage`

## Provisional first-slice scope

Recommended first thin slice:

- takeover and scheme related updates discoverable via the FCA National Storage Mechanism

Why this is the current preferred first slice:

- it is closer to the user goal of important company disclosures in real time
- expected document volume should be lower than AFR and broader announcement streams
- event semantics should be sharper and easier to lock cleanly

Backup first slice if the above is not isolatable enough:

- major holdings / director dealings

Why the backup is still attractive:

- it is also high-signal and time-sensitive
- it maps more naturally to ownership / control-watch style event families already used elsewhere in the repo

Why AFR is now demoted:

- it is periodic rather than event-driven
- it may be heavier than needed for the first UK lock
- it is better treated as a later UK expansion once a high-signal path is stable

## Provisional discovery model

Recommended primary discovery surface:

- public NSM search interface

Recommended detail/archive surface:

- NSM artefact pages under `data.fca.org.uk/artefacts/NSM/...`

Still to confirm before implementation:

- whether the public NSM search surface can be narrowed cleanly enough for takeover / scheme related updates
- whether the first slice should use only HTML artefact pages
- whether a deterministic CSV export path should be used as the fixture source
- whether the backup family `major holdings / director dealings` is easier to isolate than takeover / scheme items

## Provisional identity model

Strong candidate identities to evaluate:

1. NSM artefact URL token
2. PIP / announcement unique id when exposed in the public result
3. RNS number where present

Current recommendation:

- prefer a public immutable artefact id if available in the detail URL or result payload
- use RNS number only if it is always present on the chosen first slice

## Provisional cursor model

Current recommendation order:

1. latest immutable artefact id seen
2. latest unique announcement id seen
3. latest published timestamp seen

Do not freeze the cursor until the public result surface is inspected directly.

## Provisional runtime naming

Recommended adapter key once implementation starts:

- `uk_fca_nsm_takeover_scheme_updates_v1`

Recommended parser strategy once implementation starts:

- discovery parser for the public result surface
- detail parser for NSM artefact HTML or downloaded filing payload

## Provisional first event mapping

Recommended first event family:

- `takeover_or_scheme_update`

Backup first event family:

- `ownership_or_director_change_watch`

Canonical event type is still open and must be aligned with the repo's canonical taxonomy before code is added.

## Phase boundary

This document is enough to start a targeted implementation PR only after one more step is complete:

- direct inspection of the public search result structure to confirm the stable identity and cursor fields for the chosen high-signal family
