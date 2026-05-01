# JP TDnet broad ingestion sample capture sheet

This sheet records the controlled TDnet sample set required before broad JP TDnet ingestion can be implemented.

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

Frozen broad lane:

```text
source: TDnet Company Announcements Disclosure Service current-list rows
scope: controlled current-list rows from one disclosure date
row_list_url: https://www.release.tdnet.info/inbs/I_list_001_20260430.html
family: material_information_update
identity: publication datetime + normalized security code + PDF/document token
cursor: latest disclosure datetime + normalized security code + PDF/document token
```

## Captured sample set

```text
row_count: 3
same row list URL/date: yes
all rows have official PDF/document links: yes
at least one row shares timestamp with another row: yes, rows 2 and 3 both use 17:00 JST
all rows have raw TDnet row code: yes
normalized security code confirmed by PDF or official document: yes
category column absent or official category captured exactly: category absent; freeze null/unknown
```

## Captured rows

### Row 1

```text
row_list_url: https://www.release.tdnet.info/inbs/I_list_001_20260430.html
row_date: 2026-04-30
disclosure_time_local: 19:00 JST
tdnet_raw_row_code: 45270
normalized_security_code: 4527
row_display_name: ロート薬
issuer_full_name_from_document: ロート製薬株式会社
official_title: 株主提案に関する書面受領のお知らせ
exchange: 東
xbrl: null
update_history: null
source_category: null
material_category: unknown
attachment_url: https://www.release.tdnet.info/inbs/140120260430515474.pdf
pdf_document_token: 140120260430515474
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
```

### Row 2

```text
row_list_url: https://www.release.tdnet.info/inbs/I_list_001_20260430.html
row_date: 2026-04-30
disclosure_time_local: 17:00 JST
tdnet_raw_row_code: 28710
normalized_security_code: 2871
row_display_name: ニチレイ
issuer_full_name_from_document: 株式会社ニチレイ
official_title: インドネシアにおける低温物流企業の買収に関するお知らせ
exchange: 東
xbrl: null
update_history: null
source_category: null
material_category: unknown
attachment_url: https://www.release.tdnet.info/inbs/140120260430515256.pdf
pdf_document_token: 140120260430515256
published_at_local: 2026-04-30T17:00:00+09:00
published_at_utc: 2026-04-30T08:00:00.000000Z
stable_external_id: TDNET:2871:20260430:1700:140120260430515256
cursor_value: 2026-04-30T17:00:00+09:00|2871|140120260430515256
```

### Row 3

```text
row_list_url: https://www.release.tdnet.info/inbs/I_list_001_20260430.html
row_date: 2026-04-30
disclosure_time_local: 17:00 JST
tdnet_raw_row_code: 60880
normalized_security_code: 6088
row_display_name: シグマクシスＨＤ
issuer_full_name_from_document: 株式会社シグマクシス・ホールディングス
official_title: 自己株式の取得状況及び取得終了並びに主要株主及び主要株主である筆頭株主の異動に関するお知らせ
exchange: 東
xbrl: null
update_history: null
source_category: null
material_category: unknown
attachment_url: https://www.release.tdnet.info/inbs/140120260430514945.pdf
pdf_document_token: 140120260430514945
published_at_local: 2026-04-30T17:00:00+09:00
published_at_utc: 2026-04-30T08:00:00.000000Z
stable_external_id: TDNET:6088:20260430:1700:140120260430514945
cursor_value: 2026-04-30T17:00:00+09:00|6088|140120260430514945
```

## Identity rule validated

Frozen stable id shape:

```text
TDNET:<normalized_security_code>:<YYYYMMDD>:<HHMM>:<pdf_document_token>
```

Every sample row has a stable id that does not use title text.

## Cursor rule validated

Frozen cursor shape:

```text
<YYYY-MM-DDTHH:MM:SS+09:00>|<normalized_security_code>|<pdf_document_token>
```

Rows 2 and 3 prove the cursor can deterministically order same-time rows using normalized security code and PDF token tie-breakers.

## Raw code handling

Store both:

```text
tdnet_raw_row_code
normalized_security_code
```

Do not overwrite raw TDnet row code with normalized security code.

## Category policy

The official TDnet current-list rows do not expose a category column for these captured rows.

Freeze:

```text
source_category: null
material_category: unknown
source_category_inferred: false
```

Do not infer category from title text or PDF body in the broad v1 contract.

## Freeze pass criteria

- [x] 2-3 official TDnet rows captured
- [x] all rows use same source/list-date scope
- [x] every row has a stable PDF/document token or equivalent official token
- [x] every row has publication date and time
- [x] every row has raw TDnet row code and normalized security code
- [x] cursor orders rows without title text
- [x] category policy is explicit
- [x] fixture count is small and bounded
- [x] locked single-fixture TDnet semantics remain unchanged

## Freeze decision

```text
freeze
```
