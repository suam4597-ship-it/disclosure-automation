# JP TDnet contract-freeze input sheet

Use this sheet to capture the single public sample needed to decide whether JP TDnet can move from discovery to contract-freeze.

This sheet is intentionally docs-only. Filling it does not require or imply runtime implementation.

## Scope

Candidate source:

```text
TDnet / JPX Company Announcements Disclosure Service
```

Candidate source key:

```text
jp_tdnet_timely_disclosure
```

Candidate first family:

```text
timely disclosure / material information update
```

Backup sample path:

```text
JPX Listed Company Search historical timely disclosure row
```

Backup source if TDnet fails:

```text
EDINET periodic/statutory disclosure
```

## Capture rule

Capture exactly one candidate sample first.

Do not capture a broad batch of TDnet rows.
Do not mix multiple JP families in the first fixture.
Do not use title text as the only stable identity or cursor.

## Public surface checklist

### Discovery page

- [ ] Official public discovery URL recorded
- [ ] Row can be loaded without authenticated or paid access
- [ ] Row can be reproduced deterministically for a fixture
- [ ] Current row is inside 31-day retention window or historical row is available through Listed Company Search
- [ ] No anti-automation blocker prevents fixture capture

Discovery URL:

```text
TODO
```

Historical fallback URL, if used:

```text
TODO
```

### Row fields

- [ ] disclosure date visible
- [ ] disclosure time visible
- [ ] listed exchange / market visible, if available
- [ ] company/security code visible
- [ ] company name visible
- [ ] disclosure title visible
- [ ] source category / material category visible, if available
- [ ] detail URL visible, if available
- [ ] document/PDF URL visible, if available
- [ ] stable disclosure number visible, if available
- [ ] disclosure history number visible, if available
- [ ] public item code visible, if available
- [ ] stable PDF/document token visible, if available

## Sample metadata to fill

```text
sample issuer: TODO
sample security code: TODO
sample exchange/market: TODO
sample title: TODO
sample source category/material category: TODO
sample disclosure date local: TODO
sample disclosure time local: TODO
sample publication datetime local: TODO
sample publication datetime UTC: TODO
sample discovery URL: TODO
sample detail URL: TODO
sample attachment URL: TODO
sample document MIME type: TODO
sample visible stable id field name: TODO
sample visible stable id field value: TODO
sample PDF/document token: TODO
```

## Stable identity decision

Choose the first available rule below.

### Option A: disclosure number only

```text
stable_external_id: TDNET:<disclosure_number>
raw_event_key_seed: TDNET:<disclosure_number>
duplicate_group_seed: TDNET:<disclosure_number>
```

Use if:

- [ ] disclosure number is visible or derivable from official public metadata
- [ ] value is stable across refreshes
- [ ] value does not require title matching

### Option B: disclosure number plus history number

```text
stable_external_id: TDNET:<disclosure_number>:<disclosure_history_number>
raw_event_key_seed: TDNET:<disclosure_number>:<disclosure_history_number>
duplicate_group_seed: TDNET:<disclosure_number>:<disclosure_history_number>
```

Use if:

- [ ] both numbers are visible or derivable from official public metadata
- [ ] history number is needed to distinguish correction/update sequences

### Option C: public item code plus file token

```text
stable_external_id: TDNET:<public_item_code>:<file_token>
raw_event_key_seed: TDNET:<public_item_code>:<file_token>
duplicate_group_seed: TDNET:<public_item_code>:<file_token>
```

Use if:

- [ ] public item code is visible
- [ ] document/file token is visible
- [ ] no disclosure number is available on the open public surface

### Option D: PDF/document token

```text
stable_external_id: TDNET:<pdf_or_document_token>
raw_event_key_seed: TDNET:<pdf_or_document_token>
duplicate_group_seed: TDNET:<pdf_or_document_token>
```

Use only if:

- [ ] PDF/document URL token is stable
- [ ] no stronger public ID is visible
- [ ] publication datetime plus token is enough for cursor and dedupe

### Rejected identity choices

Do not use:

```text
company code + title
publication datetime + title
title only
fuzzy title match
```

## Cursor decision

Choose one cursor and record the exact value.

### Preferred

```text
cursor_key: latest_disclosure_datetime_and_disclosure_number_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>
```

### Alternative 1

```text
cursor_key: latest_disclosure_datetime_and_disclosure_number_history_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>|<disclosure_history_number>
```

### Alternative 2

```text
cursor_key: latest_disclosure_datetime_and_public_item_code_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<public_item_code>
```

### Alternative 3

```text
cursor_key: latest_disclosure_datetime_and_pdf_token_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<pdf_or_document_token>
```

Chosen cursor:

```text
cursor_key: TODO
cursor_value: TODO
```

## Family decision

Choose exactly one.

### Preferred family

```text
event_family: material_information_update
canonical_event_type: material_information_update
```

Use if:

- [ ] sample is a general timely disclosure / material information update
- [ ] title and category do not map cleanly to a narrower canonical event type
- [ ] taxonomy supports or will explicitly accept `material_information_update`

### Narrower fallback family

```text
event_family: major_asset_transaction_update
canonical_event_type: major_investment_or_asset_sale
```

Use if:

- [ ] sample is clearly about M&A, restructuring, investment, asset sale, or major asset transaction
- [ ] the canonical taxonomy already supports this mapping better than a broad material-information mapping

### Other high-signal family

```text
event_family: TODO
canonical_event_type: TODO
```

Use only if:

- [ ] sample is clearly a tender offer, takeover, shareholding/ownership change, or other high-signal disclosure
- [ ] identity/cursor remains cleaner than the preferred family

Chosen family:

```text
event_family: TODO
canonical_event_type: TODO
```

## Raw document set decision

Preferred raw-document set:

1. discovery metadata row fixture
2. primary disclosure document fixture

Add a detail page only if required to preserve the public URL path or stable document token.

Chosen raw documents:

```text
raw_document_1_external_id: TODO
raw_document_1_role: discovery_metadata
raw_document_1_mime_type: application/json

raw_document_2_external_id: TODO
raw_document_2_role: primary_regulatory_disclosure
raw_document_2_mime_type: TODO

raw_document_3_external_id: TODO or not required
raw_document_3_role: TODO or not required
raw_document_3_mime_type: TODO or not required
```

## Expected normalized values

Fill this only after sample capture:

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
region_code: jp
source_tier: official_exchange_storage
stable_external_id: TODO
cursor_key: TODO
cursor_value: TODO
event_id: TODO
event_family: TODO
canonical_event_type: TODO
published_at_local: TODO
published_at_utc: TODO
filing_date_local: TODO
```

## Freeze decision

- [ ] source is official-exchange enough
- [ ] sample is deterministic and public
- [ ] stable identity does not use title text only
- [ ] cursor does not use title text only
- [ ] one family is isolated
- [ ] minimum raw-document set is small
- [ ] local/UTC timestamp rule is explicit
- [ ] future runtime PR can stay one source, one family, one fixture item

Decision:

```text
TODO: freeze / do not freeze / fallback to Listed Company Search / fallback to EDINET
```
