# SEC 8-K minimal verification

Use this after the 8-K isolated verification path is in place.

## Goal
Verify the `sec_current_forms` plus `8-K` path one time, without repeated ad hoc checks.

## Minimal sequence
1. `mix test test/sec_8k_runtime_idempotency_test.exs`
2. `mix test test/sec_8k_http_smoke_test.exs`
3. run `priv/ops/sec_8k_dedupe_checks.sql`

## Pass condition
- both tests pass
- the dedupe SQL returns no duplicate rows

## Rule
Do not expand to `SC TO-T`, `SC 14D-9`, or `SC 13D/A` until the sequence above is green.
