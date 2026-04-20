# SEC SC TO-T minimal verification

Use this after the SC TO-T isolated verification path is in place.

## Goal
Verify the `sec_current_forms` plus `SC TO-T` path one time, without repeated ad hoc checks.

## Minimal sequence
1. `mix test test/sec_sc_to_t_runtime_idempotency_test.exs`
2. `mix test test/sec_sc_to_t_http_smoke_test.exs`
3. run `priv/ops/sec_sc_to_t_dedupe_checks.sql`

## Pass condition
- both tests pass
- the dedupe SQL returns no duplicate rows

## Rule
Do not expand to `SC 14D-9`, `SC 13D/A`, AFM, UK, TW, CN, JP, or overlay work until the sequence above is green.
