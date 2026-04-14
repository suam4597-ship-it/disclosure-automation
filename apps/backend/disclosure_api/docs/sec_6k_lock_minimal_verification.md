# SEC 6-K lock minimal verification

Use this only after the existing-file reconcile is in place.

## Goal
Verify the `sec_current_forms` plus `6-K` path one time, without repeated ad hoc checks.

## Minimal sequence
1. `mix test test/sec_6k_runtime_idempotency_test.exs`
2. `mix test test/sec_6k_http_smoke_test.exs`
3. run `priv/ops/sec_thin_slice_dedupe_checks.sql`

## Pass condition
- both tests pass
- the dedupe SQL returns no duplicate rows

## Rule
Do not expand to `8-K`, `SC TO-T`, `SC 14D-9`, or `SC 13D/A` until the sequence above is green.
