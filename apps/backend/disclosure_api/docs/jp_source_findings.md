# JP source findings worksheet

This worksheet is for recording official-source inspection results before JP contract-freeze.

Do not treat any row as frozen until a later contract-freeze decision explicitly chooses one source and one family.

## Summary decision table

| Candidate | Source tier candidate | First-family fit | Stable identity visible? | Cursor candidate visible? | Minimum raw-document set | Status |
| --- | --- | --- | --- | --- | --- | --- |
| TDnet / Timely Disclosure Network | `official_exchange_storage` candidate | strongest current fit | TODO | TODO | TODO | inspect |
| JPX Company Announcements Disclosure Service | `official_exchange_storage` candidate | strong for public latest TDnet disclosures | TODO | TODO | TODO | inspect |
| JPX Listed Company Search | `official_exchange_storage` candidate | useful for historical deterministic samples | TODO | TODO | TODO | inspect |
| EDINET | `official_regulatory_storage` candidate | likely backup for periodic/statutory reports | TODO | TODO | TODO | inspect |
| TSE listed-company disclosure pages | `official_exchange_storage` candidate | likely TDnet-adjacent | TODO | TODO | TODO | inspect |

## Confirmed initial findings

### TDnet / JPX

Initial public-source findings:

- JPX describes TDnet as the Timely Disclosure Network used to enable fair, prompt, and wide-ranging timely disclosure.
- JPX says listed companies are obliged by Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.
- JPX describes the Company Announcements Disclosure Service as a TSE-created web service for public inspection of corporate information disclosed via TDnet.
- JPX says the Company Announcements Disclosure Service displays timely disclosure information, disclosure date/time, listed exchange, company code, company name, and disclosure title.
- JPX says timely disclosure information is available for 31 days on the Company Announcements Disclosure Service, and Listed Company Search allows browsing of timely disclosure information from the past ten years.
- JPX paid TDnet API documentation lists useful index fields including security code, stock abbreviation, date/time of disclosure, handling attributes, disclosure number, disclosure history number, title, public item code, and file existence flag.

Implication:

TDnet / JPX surfaces are the current preferred first JP source candidate, but runtime contract freeze still requires one deterministic public sample and visible identity/cursor fields.

### EDINET

Initial public-source findings:

- Japanese government API catalog identifies EDINET API as an API provided by the Financial Services Agency.
- The catalog describes EDINET as an electronic disclosure system for disclosure documents such as securities reports based on the Financial Instruments and Exchange Act.
- The catalog lists JSON, ZIP, and PDF response formats and REST API style.

Implication:

EDINET is a strong official-regulatory candidate for periodic/statutory reports, but it is likely a backup rather than the first as-it-happens JP timely-disclosure lane.

## Candidate inspection blocks

### TDnet / Timely Disclosure Network

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `Tokyo Stock Exchange / Japan Exchange Group`
- source tier candidate: `official_exchange_storage`
- first high-signal family candidate: `timely disclosure / material information update`
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

### JPX Company Announcements Disclosure Service

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `Tokyo Stock Exchange / Japan Exchange Group`
- source tier candidate: `official_exchange_storage`
- first high-signal family candidate: `timely disclosure / material information update`
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

### JPX Listed Company Search

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `Tokyo Stock Exchange / Japan Exchange Group`
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

### EDINET

- public discovery URL: `TODO`
- public detail URL shape: `TODO`
- source owner/operator: `Financial Services Agency`
- source tier candidate: `official_regulatory_storage`
- first high-signal family candidate: `periodic report / statutory securities report`
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

### TSE listed-company disclosure pages

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

## Stable identity scoring

Prefer identities in this order:

1. explicit disclosure number and disclosure history number
2. document id or TDnet/JPX artefact id
3. stable PDF URL token
4. security code + disclosure date/time + sequence

Do not freeze an identity based on title text alone.

## Cursor scoring

Prefer cursors in this order:

1. disclosure datetime + disclosure number
2. disclosure datetime + document id
3. disclosure number + disclosure history number
4. stable PDF URL token plus disclosure date

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
