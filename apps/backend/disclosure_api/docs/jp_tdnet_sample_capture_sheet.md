# JP TDnet sample capture sheet

Use this sheet to capture the exact public TDnet/JPX disclosure sample before closing the JP contract-freeze.

Do not create runtime files from this sheet alone.

## Target candidate

- target source candidate: `TDnet / JPX Company Announcements Disclosure Service`
- target source key candidate: `jp_tdnet_timely_disclosure`
- target first family candidate: `timely_disclosure_update`
- target canonical event type candidate: `material_information_update`
- target official storage candidate: `official_exchange_storage`

## Candidate public surfaces

### JPX TDnet authority page

```text
https://www.jpx.co.jp/english/equities/listing/disclosure/tdnet/
```

### JPX English Company Announcements Service

```text
https://www.jpx.co.jp/english/listing/disclosure/
```

### Japanese Company Announcements Disclosure Service

```text
TODO_PUBLIC_INSPECTION_URL
```

### Listed Company Search historical fallback

```text
TODO_LISTED_COMPANY_SEARCH_URL
```

## Exact working request or page capture

Fill after public-source inspection:

```text
method/page type: TODO
url: TODO
headers required: TODO
query params or form body: TODO
response/page status: TODO
captured at: TODO
```

## Exact sample row

Paste the exact row or normalized row for one TDnet/JPX public disclosure sample here.

```json
{
  "disclosure_datetime_local": "TODO",
  "listed_exchange": "TODO",
  "security_code": "TODO",
  "company_name": "TODO",
  "title": "TODO",
  "disclosure_number": "TODO",
  "disclosure_history_number": "TODO",
  "public_item_code": "TODO",
  "document_or_pdf_token": "TODO",
  "detail_url": "TODO",
  "pdf_url": "TODO"
}
```

Do not fill unknown fields with guessed values.
Remove fields only if the source response truly does not provide them.

## Candidate family narrowing

Record the source evidence for why the chosen item is the first JP family:

```text
source category: TODO
family decision: TODO
canonical mapping: TODO
why this is narrower than broad JP all-disclosures ingestion: TODO
```

## Derived contract values

Fill only after the exact row is captured.

### Stable external identity

Preferred:

```text
stable_external_id = TDNET:<disclosure_number>:<disclosure_history_number>
```

Fallback:

```text
stable_external_id = TDNET:<disclosure_datetime_local>:<security_code>:<document_or_pdf_token>
```

Fill after capture:

```text
stable_external_id = TODO
```

### Cursor

Preferred:

```text
cursor_key = latest_disclosure_datetime_and_disclosure_number_seen
cursor_value = <disclosure_datetime_local>|<disclosure_number>
```

Fallback:

```text
cursor_key = latest_disclosure_datetime_security_code_and_document_token_seen
cursor_value = <disclosure_datetime_local>|<security_code>|<document_or_pdf_token>
```

Fill after capture:

```text
cursor_key = TODO
cursor_value = TODO
```

### Local publication datetime

Fill after capture:

```text
published_at_local = TODO
```

### UTC publication datetime

Fill after capture:

```text
published_at_utc = TODO
```

### Event id

Candidate shape:

```text
jp.tdnet.<security_code>.<YYYYMMDD>.<canonical_event_type>.<event_family>.<stable_id_tail>
```

Fill after capture:

```text
event_id = TODO
```

## Required validation before freeze

Before the JP TDnet timely-disclosure contract can be frozen, verify:

- the row comes from TDnet/JPX official public disclosure surface
- the row has a deterministic security code and company name
- the row has a deterministic local disclosure datetime
- the row has a stable disclosure number, history number, document id, or PDF token
- the detail page or PDF URL is stable and fetchable
- the minimum raw-document set is explicit
- the source category/family mapping is narrower than broad all-disclosures ingestion

## If disclosure number is missing

Use the fallback only after documenting evidence:

```text
stable_external_id = TDNET:<disclosure_datetime_local>:<security_code>:<document_or_pdf_token>
cursor_key = latest_disclosure_datetime_security_code_and_document_token_seen
cursor_value = <disclosure_datetime_local>|<security_code>|<document_or_pdf_token>
```

Fallback use requires documenting why disclosure number/history number is unavailable or unstable.

## Guardrail

If this sheet cannot be completed with public-source evidence, do not open JP runtime implementation.
Return to source discovery and choose a different sample or source surface.
