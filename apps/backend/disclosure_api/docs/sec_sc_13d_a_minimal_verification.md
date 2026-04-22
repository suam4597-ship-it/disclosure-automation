# SEC SC 13D/A minimal verification

Use this after the SC 13D/A isolated verification path is in place.

## Goal
Verify the `sec_current_forms` plus `SC 13D/A` path one time, without repeated ad hoc checks.

## Minimal sequence
1. `$env:MIX_ENV="test"; mix.bat test test/sec_sc_13d_a_runtime_idempotency_test.exs`
2. `$env:MIX_ENV="test"; mix.bat test test/sec_sc_13d_a_http_smoke_test.exs`
3. run `priv/ops/sec_sc_13d_a_dedupe_checks.sql`

## Pass condition
- both tests pass
- the dedupe SQL returns no duplicate rows
- repeated poll keeps a stable `event_id`
- `event_family` remains stable across repeated poll
- `canonical_event_type` remains stable across repeated poll

## Rule
Do not expand to AFM, UK, TW, CN, JP, or overlay work until the sequence above is green.
