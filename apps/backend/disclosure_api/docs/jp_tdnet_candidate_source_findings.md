# JP TDnet candidate source findings

This document records the first concrete JP source/family candidate after the JP discovery-first kickoff.

It is still a candidate-finding document, not runtime implementation.
Do not add JP runtime code, fixtures, tests, ops runner, sample YAML, or dedupe SQL from this document alone.

## Candidate recommendation

Recommended next contract-freeze candidate:

- source: `TDnet / JPX Company Announcements Disclosure Service`
- first family: `timely disclosure / material information update`
- backup narrower family: `M&A / restructuring / major asset transaction style disclosure`

## Why TDnet / JPX is the current preferred candidate

TDnet is the most direct official exchange-backed surface for timely disclosures from Japanese listed companies.

Observed public source facts:

- JPX describes TDnet as the Timely Disclosure Network provided to enable fair, prompt, and wide-ranging timely disclosure.
- JPX says listed companies are obliged by Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.
- JPX says information disclosed via TDnet is posted to the Company Announcements Disclosure Service and media simultaneously.
- JPX says Company Announcements Disclosure Service displays timely disclosure information, disclosure date/time, listed exchange, company code, company name, and title.
- JPX says the Company Announcements Disclosure Service has a 31-day publication period, while Listed Company Search can browse timely disclosure information from the past ten years.
- JPX TDnet API documentation confirms useful index fields such as security code, stock abbreviation, date of disclosure, time of disclosure, handling attributes, disclosure number, disclosure history number, title, public item code, and file existence flag.

## Candidate source identity

- source key candidate: `jp_tdnet_timely_disclosure`
- display name candidate: `Japan TDnet Timely Disclosure Updates`
- region code: `jp`
- source class: `regulatory_filing_feed`
- source tier candidate: `official_exchange_storage`
- source owner/operator candidate: `Tokyo Stock Exchange / Japan Exchange Group`

## Candidate source surfaces

### Public discovery surface candidate

```text
JPX Company Announcements Disclosure Service
```

Use this as the public latest-announcements surface if it exposes deterministic rows and links without browser-only state.

### Historical public surface candidate

```text
JPX Listed Company Search
```

Use this as the historical public sample source if the 31-day latest-announcements window does not contain a stable first fixture.

### Paid/reference API surface candidate

```text
TDnet API Service
```

Use this as source-design reference for identity/cursor semantics. Do not make the first runtime lock depend on paid API access unless a deterministic public fixture can still be captured.

## Candidate first family mapping

Preferred candidate:

- event family: `timely_disclosure_update`
- canonical event type: `material_information_update`

Backup if a narrower deterministic sample is easier to capture:

- event family: `major_transaction_update`
- canonical event type: `major_investment_or_asset_sale`

Alternative if tender-offer sample is cleaner:

- event family: `takeover_or_scheme_update`
- canonical event type: `tender_offer_or_go_private`

## Stable identity candidate

Preferred rule:

```text
TDNET:<disclosure_number>:<disclosure_history_number>
```

Fallback if public surface does not expose both fields:

```text
TDNET:<security_code>:<disclosure_datetime_jst>:<pdf_or_document_token>
```

Do not use title as the stable identity.

## Cursor candidate

Preferred cursor key:

```text
latest_disclosure_datetime_and_disclosure_number_seen
```

Preferred cursor shape:

```text
<YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>|<disclosure_history_number>
```

Fallback if only date/time and PDF token are visible:

```text
latest_disclosure_datetime_and_document_token_seen
<YYYY-MM-DDTHH:MM:SS+09:00>|<pdf_or_document_token>
```

Do not use title text as the cursor.

## Minimum raw-document set candidate

Preferred minimum set:

1. discovery row with disclosure datetime, company code, company name, title, and stable id/token
2. PDF or full-text disclosure attachment if canonical facts require document parsing

Optional detail page:

- include a detail page only if the public surface has a stable detail page that is necessary to reach the PDF/document

## Blocking items before freeze

The candidate cannot freeze until source inspection captures one deterministic public sample with:

- exact public discovery row or equivalent metadata
- exact disclosure datetime in JST
- exact company/security code
- exact title
- exact stable identity field or URL token
- exact cursor field set
- exact detail/PDF URL
- exact raw-document set
- explicit canonical event mapping

Do not open runtime implementation until those fields are captured and stored in contract-freeze docs.
