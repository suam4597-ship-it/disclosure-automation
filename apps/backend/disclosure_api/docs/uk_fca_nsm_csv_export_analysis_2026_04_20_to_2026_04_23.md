# UK FCA NSM CSV export analysis (2026-04-20 to 2026-04-23)

This file records direct analysis of the user-supplied NSM CSV export for the query:

- document text: `scheme of arrangement`
- match mode: `All words match`
- date basis: `Filing Date`
- date range: `2026-04-20 00:00` to `2026-04-23 08:29`

## File shape

Observed shape:

- rows: `58`
- columns: `11`

Columns:

- `Filing Date/Time`
- `Publication Date/Time`
- `Document Date`
- `Source`
- `Disclosing Organisation LEI`
- `Disclosing Organisation Name`
- `Description`
- `Category`
- `ESEF Type`
- `Download Link`
- `Related Organisation(s)`

## Category distribution

Observed category counts:

| Category | Count |
| --- | ---: |
| Annual Financial Report | 17 |
| Final Terms | 7 |
| Publication of a Prospectus | 5 |
| Result of Meeting | 4 |
| Final Results | 4 |
| Miscellaneous | 4 |
| Preliminary Results | 2 |
| Notice of AGM | 2 |
| Base Prospectus | 2 |
| FTSE | 1 |
| Scheme of Arrangement | 1 |
| Form 8.3 | 1 |
| Letter of Intent Signed | 1 |
| Strategy/Company/ Operations Update | 1 |
| Form 8 (Opening Position Disclosure) | 1 |
| Director Declaration | 1 |
| Half-year Financial Report | 1 |
| Doc re. | 1 |
| Offer Update | 1 |
| Notice of Results | 1 |

## Source distribution

Observed source counts:

| Source | Count |
| --- | ---: |
| Direct Upload | 31 |
| Regulatory News Services (RNS) | 20 |
| FCA | 5 |
| PR Newswire (PRN) | 1 |
| EQS Group (EQS) | 1 |

## Exact scheme row

The exact `Scheme of Arrangement` category row is:

- `Filing Date/Time`: `20/04/2026 06:13`
- `Publication Date/Time`: `20/04/2026 06:00`
- `Document Date`: `20/04/2026`
- `Source`: `Regulatory News Services (RNS)`
- `Disclosing Organisation LEI`: `RV5B68J2GV3QGMRPW209`
- `Disclosing Organisation Name`: `BRITISH LAND COMPANY PUBLIC LIMITED COMPANY(THE)`
- `Description`: `Scheme of Arrangement Becomes Effective`
- `Category`: `Scheme of Arrangement`
- `Download Link`: `https://data.fca.org.uk/artefacts/NSM/RNS/5c9e4a51-b4c6-4977-86d3-ac8567261289.html`
- `Related Organisation(s)`: `LIFE SCIENCE REIT PLC (213800RG7JNX7K8F7525)`

## Contract implications

### Discovery filter

Do not use document text alone as the first-slice family boundary.

Recommended first-slice discovery filter for this fixture:

- text query: `scheme of arrangement`
- match mode: `All words match`
- category filter after export: `Scheme of Arrangement`
- source filter after export: `Regulatory News Services (RNS)`
- detail URL namespace filter: `/artefacts/NSM/RNS/`

### Stable identity

Recommended first stable identity:

- `NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289`

Derivation:

- namespace: `NSM`
- source namespace: `RNS`
- artefact token: `5c9e4a51-b4c6-4977-86d3-ac8567261289`

### Cursor

Recommended first cursor key:

- `latest_filing_at_and_artefact_id_seen`

Recommended first cursor value:

- `2026-04-20T06:13:00|RNS|5c9e4a51-b4c6-4977-86d3-ac8567261289`

## Remaining blocker

The CSV is enough to freeze the discovery-row identity and cursor candidate.

The remaining blocker before opening runtime code is direct inspection of the exact artefact page to confirm:

- whether the artefact page exposes RNS number or another public id
- whether the artefact page alone is sufficient for normalization
- whether a linked filing payload is required
