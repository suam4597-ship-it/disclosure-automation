# JP TDnet timely disclosure verification ledger

This ledger is the place to record actual verification output for the JP TDnet timely disclosure runtime slice.

Do not mark runtime locked until every required row below is filled with PASS evidence.

## Runtime slice

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
```

## Current verification state

```text
automated runtime idempotency test: TODO
automated HTTP smoke test: TODO
manual isolated smoke: TODO
storage-level dedupe SQL: TODO
code patch required after verification: TODO
runtime lock status: not locked
```

## Automated tests

### Runtime idempotency test

Command:

```bash
mix test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
```

Result:

```text
TODO
```

Notes:

```text
TODO
```

### HTTP smoke test

Command:

```bash
mix test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Result:

```text
TODO
```

Notes:

```text
TODO
```

## Manual isolated smoke

Source document:

```text
apps/backend/disclosure_api/docs/jp_tdnet_timely_disclosure_manual_smoke.md
```

Required values:

```text
poll 1 records_seen: TODO
poll 2 records_seen: TODO
digest 1 item_count: TODO
digest 2 item_count: TODO
source health: TODO
cursor_key: TODO
cursor_value: TODO
event_id: TODO
```

Result:

```text
TODO
```

## Storage-level dedupe SQL

SQL file:

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql
```

Expected:

```text
queries 1-6: no rows
query 7:
  TDNET:4527:20260430:1900:140120260430515474:discovery-row row_count = 1
  TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474 row_count = 1
```

Observed:

```text
TODO
```

Result:

```text
TODO
```

## Contract invariants to re-check

- [ ] event id exactly matches frozen event id
- [ ] stable external id exactly matches frozen stable external id
- [ ] cursor key/value exactly match frozen cursor
- [ ] raw TDnet row code `45270` is preserved
- [ ] normalized security code `4527` is preserved
- [ ] source category remains `null`
- [ ] material category remains `unknown`
- [ ] `source_category_inferred` remains `false`
- [ ] raw documents are exactly discovery row plus PDF attachment
- [ ] canonical item source count is 2
- [ ] representative canonical item source count is 1

## Close-out decision

```text
TODO: locked / not locked
```

Only set to `locked` after all verification rows above are PASS.
