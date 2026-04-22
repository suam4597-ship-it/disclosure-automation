# SEC SC TO-T first-run triage

Use this when the first isolated SC TO-T verification run is not green.

## Goal
Classify the first failure quickly so the next patch is focused.

## Read this after
- `test/sec_sc_to_t_runtime_idempotency_test.exs`
- `test/sec_sc_to_t_http_smoke_test.exs`
- `docs/sec_sc_to_t_manual_smoke.md`
- `priv/ops/sec_sc_to_t_dedupe_checks.sql`

## Fast classification

### 1) compile error before tests start
Likely causes:
- module name typo
- file path mismatch
- missing alias or require
- syntax error in the new SC TO-T files

Check first:
- `lib/disclosure_automation/ops/sec_sc_to_t_source.ex`
- `test/sec_sc_to_t_runtime_idempotency_test.exs`
- `test/sec_sc_to_t_http_smoke_test.exs`
- `priv/ops/run_sec_sc_to_t_server.exs`

### 2) source helper loads but poll returns `records_seen = 0`
Likely causes:
- fixture feed entry does not match the SEC form filter for `SC TO-T`
- sample YAML fixture wiring is wrong
- atom entry title/link format is not accepted by the existing parser

Check first:
- `priv/config_samples/source_registry.sec_current_forms_sc_to_t.sample.yaml`
- `priv/fixtures/source_payloads/sec_current_filings_atom_sc_to_t.xml`

### 3) poll succeeds but digest is empty
Likely causes:
- hydrate path did not resolve detail/submission text as expected
- parse or normalize path dropped the item
- canonical item creation failed after raw ingestion

Check first:
- `priv/fixtures/source_payloads/sec_0000950123-26-001234_index.html`
- `priv/fixtures/source_payloads/sec_000095012326001234.txt`
- raw document and raw event rows in the database

### 4) digest item exists but `event_family` assertion fails
Likely causes:
- the existing SEC adapter does not yet map `SC TO-T` to `cash_tender_offer`
- canonical event type mapping may also be missing or different from the working assumption

This is the highest-probability logic mismatch if discovery, hydrate, storage, and read paths otherwise work.

Check first:
- SEC adapter form mapping for `SC TO-T`
- any existing `infer_event_family` or canonical event type mapping functions

### 5) first poll succeeds but second poll changes `event_id` or creates duplicates
Likely causes:
- idempotency key mismatch
- raw event key instability
- canonical item dedupe failure

Check first:
- repeated poll payloads
- `priv/ops/sec_sc_to_t_dedupe_checks.sql`
- raw event rows and canonical item rows

### 6) manual smoke runner starts but server uses the wrong sample
Likely causes:
- server was started without `--no-start`
- old dev data is still present
- the source registry path override did not apply early enough

Check first:
- start command in `docs/sec_sc_to_t_manual_smoke.md`
- `mix ecto.reset`
- `priv/ops/run_sec_sc_to_t_server.exs`

## Decision rule
- if compile fails: fix module/file wiring first
- if `records_seen = 0`: fix fixture/sample wiring first
- if raw rows exist but digest assertions fail: inspect parser/normalizer behavior
- if only `event_family` fails while storage/read are otherwise correct: patch the SEC adapter mapping next
- if repeated poll duplicates rows: treat idempotency/dedupe as the next blocker
