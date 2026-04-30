# JP TDnet source findings

This document narrows JP discovery to a TDnet / JPX-first path and records source-level findings for the next contract-freeze decision.

This is not a runtime implementation document.

## Decision state

- preferred source path: `TDnet / JPX Company Announcements Disclosure Service`
- backup source path: `EDINET`
- preferred first-family path: `timely disclosure / material information update`
- fallback first-family path: `M&A / restructuring / major asset transaction`
- freeze decision: `pending sample capture`
- runtime status: `not started`

## Why TDnet / JPX remains preferred

TDnet is the strongest first JP source candidate because JPX/TSE documentation establishes all of the following:

1. TDnet is the Timely Disclosure Network used for fair, prompt, and wide-ranging timely disclosure.
2. Listed companies are obliged under the Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.
3. The Company Announcements Disclosure Service is a TSE-created public web service for corporate information disclosed via TDnet.
4. Information disclosed via TDnet is posted to the Company Announcements Disclosure Service when disclosed on TDnet.
5. The public service displays row-level fields useful for ingestion: disclosure date/time, listed exchange(s), company code, company name, and title.
6. Public current information is available for 31 days, while Listed Company Search provides longer historical access.

## Source authority classification

Recommended classification for TDnet / JPX first slice:

```text
source_class: regulatory_filing_feed
source_tier: official_exchange_storage
operator_or_source_owner: Tokyo Stock Exchange / Japan Exchange Group
region_code: jp
```

Rationale:

- TSE/JPX operates the source surface.
- The source serves listed-company timely disclosure.
- The public disclosure page is explicitly tied to TDnet and TSE disclosure/legal-publication workflows.

## Surface-level source map

| Surface | Role | Use for first slice? | Notes |
| --- | --- | --- | --- |
| TDnet overview | authority + source semantics | yes | establishes TDnet obligation, public posting, displayed fields, retention |
| Company Announcements Disclosure Service | current public discovery | yes, preferred | row-level sample capture still required |
| Company Announcements Service in English | secondary observation surface | maybe | English coverage may be incomplete and delayed versus Japanese |
| Listed Company Search | historical sample fallback | yes, fallback | useful if current 31-day page cannot produce deterministic fixture capture |
| TDnet API / Database / Snowflake | identity model evidence | evidence only | paid; do not depend on it for open-public v0 unless explicitly chosen later |
| EDINET | official-regulatory backup | fallback only | better fit for statutory/periodic filings than first timely-disclosure lane |

## Current blocking questions

Contract freeze still needs answers to these row-level questions:

1. Does the public Company Announcements row expose a stable `disclosure number` or `disclosure history number`?
2. If not, does the public PDF/detail URL expose a stable artefact token?
3. Can the cursor use `disclosure datetime + stable id/token` without title text?
4. Is there a public detail page, or is the PDF attachment the primary document?
5. Is the sample category/material type visible enough to isolate one first family?
6. Does the sample require Japanese-only PDF extraction, English PDF extraction, or both?

## Identity candidate ranking

Use the following order for JP TDnet identity freeze:

1. `TDNET:<disclosure_number>:<disclosure_history_number>`
2. `TDNET:<disclosure_number>`
3. `TDNET:<public_item_code>:<file_token>`
4. `TDNET:<pdf_url_token>`
5. `TDNET:<security_code>:<disclosure_datetime_jst>:<sequence_or_token>`

Do not use title-only identity.

## Cursor candidate ranking

Use the following order for JP TDnet cursor freeze:

1. `latest_disclosure_datetime_and_disclosure_number_seen`
2. `latest_disclosure_datetime_and_disclosure_number_history_seen`
3. `latest_disclosure_datetime_and_public_item_code_seen`
4. `latest_disclosure_datetime_and_pdf_token_seen`
5. `latest_disclosure_date_and_security_code_token_seen`

Do not use a cursor that requires title fuzzy matching.

## First-family candidate ranking

### 1. `material_information_update` / timely disclosure update

Use this if one row can be isolated with clear official metadata, a stable identity, and a small raw-document set.

Candidate canonical mapping:

```text
event_family: material_information_update
canonical_event_type: material_information_update
```

If the existing canonical taxonomy does not support `material_information_update`, map the sample to the closest existing canonical type only after sample inspection.

### 2. `major_asset_transaction_update`

Use this if TDnet broad timely disclosure is too broad but an M&A, restructuring, or major asset transaction row has cleaner family semantics.

Candidate canonical mapping, pending taxonomy check:

```text
event_family: major_asset_transaction_update
canonical_event_type: major_investment_or_asset_sale
```

### 3. `tender_offer_or_takeover_update`

Use this if a tender-offer disclosure provides a cleaner official source and sample than broad material-information rows.

### 4. EDINET periodic/statutory report

Use only if TDnet public sample capture fails identity/cursor requirements.

## Recommended next evidence capture

Capture one current TDnet row and one historical Listed Company Search row, then compare:

- stable ID visibility
- PDF/detail URL stability
- publication datetime precision
- category/family clarity
- raw document count
- fixture reproducibility

Freeze the simpler of the two TDnet paths if either meets the exit criteria.

## Current conclusion

TDnet / JPX should remain the first JP path, but the contract should remain unfrozen until row-level sample capture confirms stable identity and cursor semantics.
