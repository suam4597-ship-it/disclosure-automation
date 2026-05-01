# CNInfo broad announcement feed minimal verification

Minimal verification for the controlled CNInfo broad announcement feed runtime slice.

## Scope

Verify only:

```text
source_key: cn_cninfo_broad_announcement_feed
adapter_key: cn_cninfo_broad_announcement_feed_v1
sample_count: 3
```

Do not verify JP broad runtime, EDINET runtime, SSE/SZSE/BSE adapters, news overlay, cross-source merge, or unbounded CNInfo live pagination.

## Automated tests

Run:

```bash
mix test test/cn_cninfo_broad_announcement_feed_runtime_idempotency_test.exs
mix test test/cn_cninfo_broad_announcement_feed_http_smoke_test.exs
```

Expected:

```text
both tests pass
```

## Fixture invariants

The discovery fixture must contain exactly three rows with these announcement ids:

```text
1225274841
1225274838
1225274454
```

Every item must preserve:

```text
stable_external_id
cursor_value
announcement_id
sec_code
sec_name
company_name
org_id
detail_url
adjunct_url
pdf_url
date_only_cursor = true
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

## Cursor invariant

The v0 broad fixture uses date-only cursor values:

```text
2026-05-01|1225274841
2026-05-01|1225274838
2026-05-01|1225274454
```

Do not mutate the locked CNInfo ownership-change cursor.

## Pass condition

The runtime slice is minimally verified when automated tests pass and manual smoke confirms idempotent storage and clean dedupe SQL.
