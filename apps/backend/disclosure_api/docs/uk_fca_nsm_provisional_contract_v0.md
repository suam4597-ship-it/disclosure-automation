# UK FCA NSM provisional contract v0

This is a provisional contract draft based on currently confirmed FCA public materials.
It is more concrete than the generic template, but it is still not a runtime lock spec.

## Provisional source identity

Recommended first source key:

- `uk_fca_nsm_annual_reports`

Recommended display name:

- `UK FCA National Storage Mechanism Annual Financial Reports`

Recommended region code:

- `uk`

Recommended source class:

- `regulatory_filing_feed`

Recommended source tier:

- `official_regulatory_storage`

## Provisional first-slice scope

Recommended first thin slice:

- Annual Financial Reports available through the FCA National Storage Mechanism

Why this is the current preferred first slice:

- official FCA materials explicitly describe Annual Financial Reports as an NSM submission path
- official FCA materials explicitly describe viewing and downloading structured AFRs on the NSM
- annual report disclosures are easy to observe in current NSM-linked examples

## Provisional discovery model

Recommended primary discovery surface:

- public NSM search interface

Recommended detail/archive surface:

- NSM artefact pages under `data.fca.org.uk/artefacts/NSM/...`

Still to confirm before implementation:

- whether the first slice will use only HTML artefact pages
- whether a deterministic CSV export path should be used as the fixture source
- whether a search query can reliably isolate Annual Financial Reports without overmatching

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

- `uk_fca_nsm_annual_reports_v1`

Recommended parser strategy once implementation starts:

- discovery parser for the public result surface
- detail parser for NSM artefact HTML or downloaded filing payload

## Provisional first event mapping

Recommended first event family:

- `annual_financial_report`

Canonical event type is still open and must be aligned with the repo's canonical taxonomy before code is added.

## Phase boundary

This document is enough to start a targeted implementation PR only after one more step is complete:

- direct inspection of the public search result structure to confirm the stable identity and cursor fields
