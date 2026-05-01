# JP EDINET statutory report minimal verification

Minimal verification for the isolated JP EDINET statutory report runtime slice.

## Scope

Verify only:

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
stable_external_id: EDINET:S100XZXO
```

Do not verify EDINET broad pagination, TDnet changes, CNInfo changes, news overlay, or cross-source merge.

## Automated tests

Run:

```bash
mix test test/jp_edinet_statutory_report_runtime_idempotency_test.exs
mix test test/jp_edinet_statutory_report_http_smoke_test.exs
```

Expected:

```text
both tests pass
```

## Fixture invariants

The discovery fixture must contain exactly one row with:

```text
docID = S100XZXO
edinetCode = E12460
docTypeCode = 180
submitDateTimeLocal = 2026-04-30T09:00:00+09:00
submitDateTimeUtc = 2026-04-30T00:00:00.000000Z
docDescription = 臨時報告書（内国特定有価証券）
```

The primary document text fixture must contain:

```text
野村アセットマネジメント株式会社
E12460
S100XZXO
臨時報告書（内国特定有価証券）
１【提出理由】
２【報告内容】
野村日本債券インデックスファンド
```

## API key invariant

Committed request shapes must use:

```text
Subscription-Key=<redacted>
```

No actual API key may appear in:

```text
fixtures
source registry sample
adapter metadata
portable citations
raw documents
test assertions
docs
```

## Storage invariants

After repeated poll:

```text
raw_events = 1
canonical_feed_items(event_id) = 1
raw_documents = 2
canonical_item_sources = 2
representative source count = 1
```

## Cursor invariant

```text
cursor_key = latest_submit_datetime_and_doc_id_seen
cursor_value = 2026-04-30T09:00:00+09:00|S100XZXO
```

## Pass condition

The runtime slice is minimally verified when automated tests pass and manual smoke confirms idempotent storage, redacted API-key handling, and clean dedupe SQL.
