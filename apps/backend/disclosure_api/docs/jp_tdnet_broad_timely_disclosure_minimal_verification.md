# JP TDnet broad timely disclosure minimal verification

Minimal verification for the controlled JP TDnet broad timely disclosure runtime slice.

## Scope

Verify only:

```text
source_key: jp_tdnet_broad_timely_disclosure
adapter_key: jp_tdnet_broad_timely_disclosure_v1
sample_count: 3
```

Do not verify EDINET, CN broad expansion, news overlay, cross-source merge, or unbounded TDnet live pagination.

## Automated tests

Run:

```bash
mix test test/jp_tdnet_broad_timely_disclosure_runtime_idempotency_test.exs
mix test test/jp_tdnet_broad_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
both tests pass
```

## Fixture invariants

The discovery fixture must contain exactly three rows with these PDF tokens:

```text
140120260430515474
140120260430515256
140120260430514945
```

Every item must keep:

```text
source_category = null
material_category = unknown
source_category_inferred = false
```

## Storage invariants

After repeated poll:

```text
raw_events = 3
canonical_feed_items = 3
raw_documents = 6
canonical_item_sources = 6
representative source count = 3
```

## Pass condition

The runtime slice is minimally verified when automated tests pass and manual smoke confirms idempotent storage and clean dedupe SQL.
