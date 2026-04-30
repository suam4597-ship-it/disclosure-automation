# JP TDnet timely-disclosure source findings

This document records the first concrete JP source/family candidate after the JP discovery-first kickoff.

It is still a candidate-finding document, not runtime implementation.
Do not add JP runtime code, fixtures, tests, ops runner, sample YAML, or dedupe SQL from this document alone.

## Candidate recommendation

Recommended next contract-freeze candidate:

- source: `TDnet / JPX Company Announcements Disclosure Service`
- first family: `timely disclosure / material information update`
- sample class: one listed-company timely disclosure with stable detail/PDF artefact

## Why TDnet / JPX is the current preferred candidate

TDnet is the strongest first JP source candidate because JPX describes TDnet as the Timely Disclosure Network used to enable fair, prompt, and wide-ranging timely disclosure.

Observed public source facts:

- JPX says listed companies are obliged by the Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.
- JPX says information disclosed via TDnet is made available for public inspection on the Company Announcements Disclosure Service.
- JPX says the Company Announcements Disclosure Service displays timely disclosure information, date and time of disclosure, listed exchange, company code, company name, and title.
- JPX says disclosure documents are instantly available for 31 days on Company Announcements Disclosure Service.
- JPX says Listed Company Search allows users to browse timely disclosure information from the past ten years.
- JPX paid TDnet API documentation confirms index fields that would be ideal for stable identity/cursor if available in the public surface or captured fixture: security code, stock abbreviation, date/time of disclosure, handling attributes, disclosure number, disclosure history number, title, public item code, and file existence flag.

## Candidate source identity

- source key candidate: `jp_tdnet_timely_disclosure`
- display name candidate: `Japan TDnet Timely Disclosure Announcements`
- region code: `jp`
- source class: `regulatory_filing_feed`
- source tier candidate: `official_exchange_storage`
- source owner/operator candidate: `Tokyo Stock Exchange / Japan Exchange Group`
- source platform candidate: `TDnet / Company Announcements Disclosure Service`

## Candidate source surfaces

### TDnet overview / source authority

```text
https://www.jpx.co.jp/english/equities/listing/disclosure/tdnet/
```

Use this as the authority/source-model reference.

### Company Announcements Service / public latest-disclosure surface

```text
https://www.jpx.co.jp/english/listing/disclosure/
```

Use this as an English public disclosure surface candidate.

### Japanese Company Announcements Disclosure Service

```text
TODO_PUBLIC_INSPECTION_URL
```

The Japanese service is likely the primary public latest-disclosure surface for domestic timely disclosure.
Capture exact URL and request behavior during source inspection.

### Listed Company Search

```text
TODO_LISTED_COMPANY_SEARCH_URL
```

Use this as the likely historical sample capture fallback because JPX says it allows browsing past ten years of timely disclosure information.

### TDnet paid API reference

```text
https://www.jpx.co.jp/english/markets/paid-info-listing/tdnet/02.html
```

Use this only as a reference for ideal index fields, not as a public v0 runtime source unless a paid API contract exists.

## Candidate first family mapping

- event family candidate: `timely_disclosure_update`
- canonical event type candidate: `material_information_update`

Rationale:

- TDnet is directly designed for timely disclosure of corporate information.
- The public JPX surface is a natural fit for as-it-happens listed-company disclosure monitoring.
- This family should be narrowed later using a deterministic source category, public item code, title class, or one fixture sample.

## Stable identity candidate

Preferred rule if available:

```text
TDNET:<disclosure_number>:<disclosure_history_number>
```

Fallback if disclosure history number is unavailable:

```text
TDNET:<disclosure_datetime_local>:<security_code>:<document_or_pdf_token>
```

Do not use the title as the stable identity.

## Cursor candidate

Preferred cursor key:

```text
latest_disclosure_datetime_and_disclosure_number_seen
```

Preferred cursor shape:

```text
<disclosure_datetime_local>|<disclosure_number>
```

Fallback cursor shape if disclosure number is not visible:

```text
<disclosure_datetime_local>|<security_code>|<document_or_pdf_token>
```

The exact cursor must be frozen only after inspecting one public sample.

## Minimum raw-document set candidate

Preferred minimum set:

1. discovery row from TDnet/JPX public disclosure surface
2. detail page, if stable and fetchable
3. PDF attachment only if the detail page does not contain canonical facts

If the disclosure document itself is a PDF, use discovery row + PDF attachment as the minimum v0 set.

## Blocking items before freeze

The candidate is not freeze-ready until the following are captured:

```text
1. exact public discovery URL or request path
2. one deterministic sample row
3. visible disclosure number, history number, document id, or stable PDF token
4. local disclosure datetime
5. detail/PDF URL
6. sample source category or family label
7. exact minimum raw-document set
```

Do not open runtime implementation until these values are captured and stored in contract-freeze docs.
