# JP TDnet timely disclosure minimal verification

Minimal verification for the isolated JP TDnet timely disclosure runtime slice.

## Scope

Verify only:

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
```

Do not verify broad TDnet pagination, EDINET, JPX Listed Company Search, news overlay, or cross-source merge.

## Automated tests

Run:

```bash
mix test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
mix test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
both tests pass
```

## Fixture invariants

The discovery fixture must contain exactly one row with:

```text
tdnetRawRowCode = 45270
normalizedSecurityCode = 4527
pdfDocumentToken = 140120260430515474
sourceCategory = null
materialCategory = unknown
```

The PDF text fixture must contain:

```text
ロート製薬株式会社
コード番号 4527
東証プライム
株主提案に関する書面受領のお知らせ
AVI JAPAN OPPORTUNITY TRUST PLC
LONGCHAMP SICAV
```

## Storage invariants

After repeated poll:

```text
raw_events = 1
canonical_feed_items(event_id) = 1
raw_documents = 2
canonical_item_sources = 2
representative canonical_item_sources = 1
```

## Cursor invariant

```text
cursor_key = latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value = 2026-04-30T19:00:00+09:00|4527|140120260430515474
```

## Category invariant

Do not infer category from title text.

```text
source_category = null
material_category = unknown
source_category_inferred = false
```

## Pass condition

The runtime slice is minimally verified when automated tests pass and manual smoke confirms idempotent storage and clean dedupe SQL.
