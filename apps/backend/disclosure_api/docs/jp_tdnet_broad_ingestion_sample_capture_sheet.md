# JP TDnet broad ingestion sample capture sheet

Use this sheet to capture the controlled TDnet sample set required before broad JP TDnet ingestion can be implemented.

This is docs-only. It does not add broad JP runtime.

## Current locked baseline

The locked TDnet single-fixture runtime must remain unchanged:

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
runtime lock status: locked
```

## Broad target

Preferred broad lane:

```text
source: TDnet Company Announcements Disclosure Service current-list rows
scope: controlled current-list rows from one disclosure date
family: material_information_update
identity: publication datetime + normalized security code + PDF/document token
cursor: latest disclosure datetime + normalized security code + PDF/document token
```

## Required sample set

Capture 2-3 official TDnet rows from one current-list date.

Preferred sample shape:

```text
row_count: 2 or 3
same row list URL/date: yes
all rows have official PDF/document links: yes
at least one row shares timestamp with another row: preferred, not required
all rows have raw TDnet row code: yes
normalized security code confirmed by PDF or official document: yes
category column absent or official category captured exactly: yes
```

Do not capture broad batches.

## Row capture template

### Row 1

```text
row_list_url: TODO
row_date: TODO
disclosure_time_local: TODO
tdnet_raw_row_code: TODO
normalized_security_code: TODO
row_display_name: TODO
issuer_full_name_from_document: TODO
official_title: TODO
exchange: TODO
xbrl: TODO or null
update_history: TODO or null
source_category: TODO or null
material_category: TODO or unknown
attachment_url: TODO
pdf_document_token: TODO
published_at_local: TODO
published_at_utc: TODO
stable_external_id: TODO
cursor_value: TODO
```

### Row 2

```text
row_list_url: TODO
row_date: TODO
disclosure_time_local: TODO
tdnet_raw_row_code: TODO
normalized_security_code: TODO
row_display_name: TODO
issuer_full_name_from_document: TODO
official_title: TODO
exchange: TODO
xbrl: TODO or null
update_history: TODO or null
source_category: TODO or null
material_category: TODO or unknown
attachment_url: TODO
pdf_document_token: TODO
published_at_local: TODO
published_at_utc: TODO
stable_external_id: TODO
cursor_value: TODO
```

### Row 3, optional

```text
row_list_url: TODO
row_date: TODO
disclosure_time_local: TODO
tdnet_raw_row_code: TODO
normalized_security_code: TODO
row_display_name: TODO
issuer_full_name_from_document: TODO
official_title: TODO
exchange: TODO
xbrl: TODO or null
update_history: TODO or null
source_category: TODO or null
material_category: TODO or unknown
attachment_url: TODO
pdf_document_token: TODO
published_at_local: TODO
published_at_utc: TODO
stable_external_id: TODO
cursor_value: TODO
```

## Identity rule to validate

Preferred stable id shape:

```text
TDNET:<normalized_security_code>:<YYYYMMDD>:<HHMM>:<pdf_document_token>
```

Every sample row must have a stable id that does not use title text.

## Cursor rule to validate

Preferred cursor shape:

```text
<YYYY-MM-DDTHH:MM:SS+09:00>|<normalized_security_code>|<pdf_document_token>
```

The captured sample set must prove this cursor can order all sample rows deterministically.

## Raw code handling

Store both:

```text
tdnet_raw_row_code
normalized_security_code
```

Do not overwrite raw TDnet row code with normalized security code.

## Category policy

If the official TDnet row does not expose category:

```text
source_category: null
material_category: unknown
source_category_inferred: false
```

Do not infer category from title text or PDF body in the broad v1 contract.

## Freeze pass criteria

- [ ] 2-3 official TDnet rows captured
- [ ] all rows use same source/list-date scope
- [ ] every row has a stable PDF/document token or equivalent official token
- [ ] every row has publication date and time
- [ ] every row has raw TDnet row code and normalized security code
- [ ] cursor orders rows without title text
- [ ] category policy is explicit
- [ ] fixture count is small and bounded
- [ ] locked single-fixture TDnet semantics remain unchanged

## Freeze decision

```text
TODO: freeze / no-go / retry capture
```
