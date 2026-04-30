# CN source findings worksheet

This worksheet is for recording official-source inspection results before CN contract-freeze.

Do not treat any row as frozen until a later contract-freeze decision explicitly chooses one source and one family.

## Summary decision table

| Candidate | Source tier candidate | First-family fit | Stable identity visible? | Cursor candidate visible? | Minimum raw-document set | Status |
| --- | --- | --- | --- | --- | --- | --- |
| SSE disclosure pages | `official_exchange_storage` candidate | TODO | TODO | TODO | TODO | inspect |
| SZSE disclosure pages | `official_exchange_storage` candidate | TODO | TODO | TODO | TODO | inspect |
| BSE disclosure pages | `official_exchange_storage` candidate | TODO | TODO | TODO | TODO | inspect |
| CNInfo / 巨潮资讯网 | `official_regulatory_storage` or archive candidate; needs classification | TODO | TODO | TODO | TODO | inspect |
| CSRC public disclosure surfaces | `official_regulatory_storage` candidate | TODO | TODO | TODO | TODO | inspect |

## Candidate inspection blocks

### Shanghai Stock Exchange / SSE disclosure pages

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `TODO`
- source tier candidate: `official_exchange_storage`
- first high-signal family candidate: `TODO`
- category/filter field: `TODO`
- stable external identity field: `TODO`
- cursor field candidate: `TODO`
- local publication timestamp field: `TODO`
- UTC conversion rule: `TODO`
- minimum raw-document set: `TODO`
- sample issuer/security code: `TODO`
- sample title: `TODO`
- sample detail URL: `TODO`
- sample attachment URL, if required: `TODO`
- blocking issues: `TODO`

### Shenzhen Stock Exchange / SZSE disclosure pages

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `TODO`
- source tier candidate: `official_exchange_storage`
- first high-signal family candidate: `TODO`
- category/filter field: `TODO`
- stable external identity field: `TODO`
- cursor field candidate: `TODO`
- local publication timestamp field: `TODO`
- UTC conversion rule: `TODO`
- minimum raw-document set: `TODO`
- sample issuer/security code: `TODO`
- sample title: `TODO`
- sample detail URL: `TODO`
- sample attachment URL, if required: `TODO`
- blocking issues: `TODO`

### Beijing Stock Exchange / BSE disclosure pages

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `TODO`
- source tier candidate: `official_exchange_storage`
- first high-signal family candidate: `TODO`
- category/filter field: `TODO`
- stable external identity field: `TODO`
- cursor field candidate: `TODO`
- local publication timestamp field: `TODO`
- UTC conversion rule: `TODO`
- minimum raw-document set: `TODO`
- sample issuer/security code: `TODO`
- sample title: `TODO`
- sample detail URL: `TODO`
- sample attachment URL, if required: `TODO`
- blocking issues: `TODO`

### CNInfo / 巨潮资讯网

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `TODO`
- source tier candidate: `TODO`
- first high-signal family candidate: `TODO`
- category/filter field: `TODO`
- stable external identity field: `TODO`
- cursor field candidate: `TODO`
- local publication timestamp field: `TODO`
- UTC conversion rule: `TODO`
- minimum raw-document set: `TODO`
- sample issuer/security code: `TODO`
- sample title: `TODO`
- sample detail URL: `TODO`
- sample attachment URL, if required: `TODO`
- blocking issues: `TODO`

### CSRC public disclosure / regulatory filing surfaces

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `TODO`
- source tier candidate: `official_regulatory_storage`
- first high-signal family candidate: `TODO`
- category/filter field: `TODO`
- stable external identity field: `TODO`
- cursor field candidate: `TODO`
- local publication timestamp field: `TODO`
- UTC conversion rule: `TODO`
- minimum raw-document set: `TODO`
- sample issuer/security code: `TODO`
- sample title: `TODO`
- sample detail URL: `TODO`
- sample attachment URL, if required: `TODO`
- blocking issues: `TODO`

## Stable identity scoring

Prefer identities in this order:

1. explicit announcement/document/disclosure id from the source
2. exchange artefact id or URL token that is stable across repeated fetches
3. company/security code + publication datetime + sequence number
4. company/security code + filing date + attachment id

Do not freeze an identity based on title text alone.

## Cursor scoring

Prefer cursors in this order:

1. monotonic publication datetime + stable id
2. monotonic filing datetime + stable id
3. source sequence id
4. stable detail URL token

Do not freeze a cursor that requires fuzzy title matching.

## Freeze recommendation section

Fill this only after inspection:

- recommended source: `TODO`
- recommended source tier: `TODO`
- recommended first family: `TODO`
- recommended sample: `TODO`
- recommended stable external identity rule: `TODO`
- recommended cursor key/value shape: `TODO`
- recommended minimum raw-document set: `TODO`
- reason this beats alternatives: `TODO`
