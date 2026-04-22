# SEC SC 14D-9 minimal verification

Use this after the SC 14D-9 isolated verification path is in place.

## Goal
Verify the `sec_current_forms` plus `SC 14D-9` path one time, without repeated ad hoc checks.

## Minimal sequence
1. `mix test test/sec_sc_14d_9_runtime_idempotency_test.exs`
2. `mix test test/sec_sc_14d_9_http_smoke_test.exs`
3. run `priv/ops/sec_sc_14d_9_dedupe_checks.sql`

## Pass condition
- both tests pass
- the dedupe SQL returns no duplicate rows
- repeated poll keeps a stable `event_id`

## Rule
Do not expand to `SC 13D/A`, AFM, UK, TW, CN, JP, or overlay work until the sequence above is green.
