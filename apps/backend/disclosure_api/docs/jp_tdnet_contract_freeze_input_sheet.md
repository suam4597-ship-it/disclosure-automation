# JP TDnet contract-freeze input sheet

This sheet records the single public TDnet sample used to freeze the first JP TDnet contract.

This sheet is docs-only. Filling it does not require or imply runtime implementation.

## Scope

Candidate source:

```text
TDnet / JPX Company Announcements Disclosure Service
```

Frozen source key:

```text
jp_tdnet_timely_disclosure
```

Frozen first family:

```text
material_information_update
```

Backup sample path:

```text
JPX Listed Company Search historical timely disclosure row
```

Backup source if TDnet fails:

```text
EDINET periodic/statutory disclosure
```

Status:

```text
freeze
```

## Capture rule

Capture exactly one candidate sample first.

Do not capture a broad batch of TDnet rows.
Do not mix multiple JP families in the first fixture.
Do not use title text as the only stable identity or cursor.

## Public surface checklist

### Discovery page

- [x] Official public discovery URL recorded
- [x] Row can be loaded without authenticated or paid access
- [x] Row can be reproduced deterministically for a fixture
- [x] Current row is inside 31-day retention window
- [x] No anti-automation blocker prevents fixture capture by manual browser path

Discovery URL:

```text
https://www.release.tdnet.info/inbs/I_list_001_20260430.html
```

Historical fallback URL, if used:

```text
not used
```

### Row fields

- [x] disclosure date visible
- [x] disclosure time visible
- [x] listed exchange / market visible
- [x] company/security code visible
- [x] company name visible
- [x] disclosure title visible
- [ ] source category / material category visible
- [ ] detail URL visible
- [x] document/PDF URL visible
- [ ] stable disclosure number visible
- [ ] disclosure history number visible
- [ ] public item code visible
- [x] stable PDF/document token visible

## Sample metadata

```text
sample issuer: ロート製薬株式会社
sample row display name: ロート薬
sample raw TDnet row code: 45270
sample normalized security code: 4527
sample exchange/market: 東 / TSE
sample title: 株主提案に関する書面受領のお知らせ
sample source category/material category: null / unknown; not exposed on the official TDnet current-list row
sample disclosure date local: 2026-04-30
sample disclosure time local: 19:00 JST
sample publication datetime local: 2026-04-30T19:00:00+09:00
sample publication datetime UTC: 2026-04-30T10:00:00.000000Z
sample discovery URL: https://www.release.tdnet.info/inbs/I_list_001_20260430.html
sample detail URL: not required / not captured separately
sample attachment URL: https://www.release.tdnet.info/inbs/140120260430515474.pdf
sample document MIME type: application/pdf
sample visible stable id field name: pdf_document_token
sample visible stable id field value: 140120260430515474
sample PDF/document token: 140120260430515474
sample XBRL flag: blank / none
sample update history: blank / none
sample document date shown in PDF: 2026-04-30
```

## Raw row code handling

TDnet current-list `コード` is stored separately from the normalized security code.

```text
tdnet_raw_row_code: 45270
normalized_security_code: 4527
normalization rule for this sample: strip trailing market/class suffix from TDnet list code when the PDF confirms the official security code
```

Do not overwrite the raw TDnet row code. Store both fields.

## Category handling

The official TDnet current-list row for this sample does not expose a category/material-type column.

Freeze:

```text
source_category: null
material_category: unknown
```

Do not infer a category from title text in the v0 contract. Any title or PDF-content enrichment belongs to a later enrichment layer.

## Stable identity decision

Chosen identity uses the stable PDF document token plus row date/time and normalized security code.

```text
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
raw_event_key_seed: TDNET:4527:20260430:1900:140120260430515474
duplicate_group_seed: TDNET:4527:20260430:1900:140120260430515474
```

Why this identity is frozen:

- no public disclosure number was captured on the open current-list row
- no disclosure history number was captured on the open current-list row
- no public item code was captured on the open current-list row
- the PDF/document URL exposes a stable document token
- the official row supplies publication date/time and raw/normalized security code
- the identity does not depend on title text

Rejected identity choices:

```text
company code + title
publication datetime + title
title only
fuzzy title match
```

## Cursor decision

Chosen cursor:

```text
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
```

This is preferred over date-only cursor because the official row exposes disclosure time.

The cursor does not use title text.

## Family decision

Chosen family:

```text
event_family: material_information_update
canonical_event_type: material_information_update
```

Rationale:

- the source is TDnet timely disclosure
- the official row category is not exposed
- the sample should not freeze an inferred category from title text
- the first JP runtime slice should stay one broad TDnet timely-disclosure family and one fixture item

The PDF content may later support governance/shareholder-meeting enrichment, but that enrichment is out of scope for the v0 contract.

## Raw document set decision

Preferred raw-document set:

1. discovery metadata row fixture
2. primary disclosure document fixture

Chosen raw documents:

```text
raw_document_1_external_id: TDNET:4527:20260430:1900:140120260430515474:discovery-row
raw_document_1_role: discovery_metadata
raw_document_1_mime_type: application/json

raw_document_2_external_id: TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474
raw_document_2_role: primary_regulatory_disclosure
raw_document_2_mime_type: application/pdf

raw_document_3_external_id: not required
raw_document_3_role: not required
raw_document_3_mime_type: not required
```

## Expected normalized values

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
region_code: jp
source_tier: official_exchange_storage
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
event_family: material_information_update
canonical_event_type: material_information_update
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
filing_date_local: 2026-04-30
```

## Freeze decision

- [x] source is official-exchange enough
- [x] sample is deterministic and public
- [x] stable identity does not use title text only
- [x] cursor does not use title text only
- [x] one family is isolated
- [x] minimum raw-document set is small
- [x] local/UTC timestamp rule is explicit
- [x] future runtime PR can stay one source, one family, one fixture item

Decision:

```text
freeze
```
