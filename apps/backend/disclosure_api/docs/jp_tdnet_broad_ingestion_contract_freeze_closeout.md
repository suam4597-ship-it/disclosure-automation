# JP TDnet broad ingestion contract-freeze close-out

This document freezes the controlled broad JP TDnet ingestion contract after JP TDnet single-fixture runtime lock and broad sample capture.

This is docs-only. It does not add broad JP runtime code, fixtures, tests, ops runner, or dedupe SQL.

## Freeze status

```text
broad source contract: frozen
sample set: frozen
runtime implementation: not started
next PR: controlled broad JP TDnet runtime implementation
```

## Current locked baseline

Keep these locked:

```text
SEC 6-K
SEC 8-K
SEC SC TO-T
SEC SC 14D-9
SEC SC 13D/A
AFM substantial holdings
UK FCA NSM takeover/scheme
TW MOPS material information
CNInfo ownership-change
JP TDnet timely disclosure single-fixture runtime
```

## Chosen broad lane

```text
source_key: jp_tdnet_broad_timely_disclosure
adapter_key: jp_tdnet_broad_timely_disclosure_v1
display_name: Japan TDnet Broad Timely Disclosure
region_code: jp
source_type: api
source_class: regulatory_filing_feed
source_tier: official_exchange_storage
source platform: TDnet / Company Announcements Disclosure Service
source scope: controlled current-list rows from one disclosure date
```

Use a new source key and adapter key so the locked single-fixture source stays unchanged.

## Chosen family

```text
event_family: material_information_update
canonical_event_type: material_information_update
```

## Chosen sample set

All rows come from:

```text
row_list_url: https://www.release.tdnet.info/inbs/I_list_001_20260430.html
row_date: 2026-04-30
```

### Sample 1

```text
publication_time_local: 19:00 JST
published_at_local: 2026-04-30T19:00:00+09:00
published_at_utc: 2026-04-30T10:00:00.000000Z
tdnet_raw_row_code: 45270
normalized_security_code: 4527
row_display_name: ロート薬
issuer_name: ロート製薬株式会社
title: 株主提案に関する書面受領のお知らせ
exchange: 東
pdf_document_token: 140120260430515474
attachment_url: https://www.release.tdnet.info/inbs/140120260430515474.pdf
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
```

### Sample 2

```text
publication_time_local: 17:00 JST
published_at_local: 2026-04-30T17:00:00+09:00
published_at_utc: 2026-04-30T08:00:00.000000Z
tdnet_raw_row_code: 28710
normalized_security_code: 2871
row_display_name: ニチレイ
issuer_name: 株式会社ニチレイ
title: インドネシアにおける低温物流企業の買収に関するお知らせ
exchange: 東
pdf_document_token: 140120260430515256
attachment_url: https://www.release.tdnet.info/inbs/140120260430515256.pdf
stable_external_id: TDNET:2871:20260430:1700:140120260430515256
cursor_value: 2026-04-30T17:00:00+09:00|2871|140120260430515256
```

### Sample 3

```text
publication_time_local: 17:00 JST
published_at_local: 2026-04-30T17:00:00+09:00
published_at_utc: 2026-04-30T08:00:00.000000Z
tdnet_raw_row_code: 60880
normalized_security_code: 6088
row_display_name: シグマクシスＨＤ
issuer_name: 株式会社シグマクシス・ホールディングス
title: 自己株式の取得状況及び取得終了並びに主要株主及び主要株主である筆頭株主の異動に関するお知らせ
exchange: 東
pdf_document_token: 140120260430514945
attachment_url: https://www.release.tdnet.info/inbs/140120260430514945.pdf
stable_external_id: TDNET:6088:20260430:1700:140120260430514945
cursor_value: 2026-04-30T17:00:00+09:00|6088|140120260430514945
```

## Identity rule

```text
stable_external_id: TDNET:<normalized_security_code>:<YYYYMMDD>:<HHMM>:<pdf_document_token>
raw_event_key_seed: stable_external_id
duplicate_group_seed: stable_external_id
```

Do not use title text in identity.

## Cursor rule

```text
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<normalized_security_code>|<pdf_document_token>
```

Rows 2 and 3 share the same disclosure timestamp, so normalized security code and PDF token act as deterministic tie-breakers.

## Raw code handling

Store both fields for every row:

```text
tdnet_raw_row_code
normalized_security_code
```

Do not overwrite the TDnet raw row code with the normalized security code.

## Category policy

For this broad v1 contract:

```text
source_category: null
material_category: unknown
source_category_inferred: false
```

The runtime must not infer category from title text or PDF text.

## Minimum raw-document set

For each row:

```text
1. discovery row metadata
2. PDF/text attachment fixture
```

For three rows, expected raw documents:

```text
6 raw documents total
```

## Expected event id shape

```text
jp.tdnet.<normalized_security_code>.<YYYYMMDD>.material_information_update.material_information_update.<pdf_document_token>
```

Expected event ids:

```text
jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
jp.tdnet.2871.20260430.material_information_update.material_information_update.140120260430515256
jp.tdnet.6088.20260430.material_information_update.material_information_update.140120260430514945
```

## Runtime guardrails

The next broad runtime PR must not add:

```text
EDINET runtime
CN broad runtime
JPX Listed Company Search adapter
TDnet live pagination beyond this fixture path
additional TDnet rows beyond this sample set
title/category inference
news overlay
cross-source merge
```

## Close-out result

JP TDnet broad ingestion contract-freeze is complete for:

```text
jp_tdnet_broad_timely_disclosure
```

Next step:

```text
JP TDnet broad ingestion controlled runtime implementation PR
```
