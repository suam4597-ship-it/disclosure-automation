# JP TDnet timely disclosure runtime lock preflight

This document records the lock preflight after the isolated JP TDnet runtime implementation PR.

This is docs-only. It does not claim final runtime lock because automated test execution, manual smoke, and storage-level dedupe verification have not been observed in this environment.

## Current status

- implementation PR: #45 `Implement JP TDnet timely disclosure isolated runtime slice`
- implementation merge SHA: `2f6ec8f22689e20b67ab62d604f593347ec85664`
- runtime implementation: merged
- lock status: `not locked yet`
- reason: test/manual-smoke/dedupe execution evidence is still required

## Current locked baseline

Keep these locked:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

## Implemented JP contract under verification

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
region_code: jp
source_tier: official_exchange_storage
event_family: material_information_update
canonical_event_type: material_information_update
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
```

## Implementation files to verify

```text
apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_tdnet_timely_disclosure_source.ex
apps/backend/disclosure_api/lib/disclosure_automation/runtime/jp_tdnet_timely_disclosure_adapter.ex
apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex
apps/backend/disclosure_api/priv/config_samples/source_registry.jp_tdnet_timely_disclosure.sample.yaml
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_discovery_4527_20260430_1900_140120260430515474.json
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_timely_disclosure_pdf_4527_20260430_1900_140120260430515474.txt
apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
apps/backend/disclosure_api/test/jp_tdnet_timely_disclosure_http_smoke_test.exs
apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql
apps/backend/disclosure_api/priv/ops/run_jp_tdnet_timely_disclosure_server.exs
```

## Code-review checks already satisfied by PR content

- adapter resolver includes only `jp_tdnet_timely_disclosure_v1`
- runtime scope is one source, one family, one fixture item
- discovery fixture contains one row only
- PDF fixture contains one text representation only
- source registry filter limits runtime to normalized security code `4527`, row date `2026-04-30`, and PDF token `140120260430515474`
- raw TDnet row code `45270` and normalized security code `4527` are preserved separately
- `source_category` stays `null`
- `material_category` stays `unknown`
- `source_category_inferred` stays `false`
- no EDINET runtime, JPX Listed Company Search adapter, TDnet broad pagination, news overlay, or cross-source merge was added

## Required automated verification before lock

Run from `apps/backend/disclosure_api`:

```bash
mix test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
mix test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected result:

```text
both tests pass
```

## Required manual smoke before lock

Use:

```text
apps/backend/disclosure_api/docs/jp_tdnet_timely_disclosure_manual_smoke.md
```

Required observations:

```text
poll 1 records_seen = 1
poll 2 records_seen = 1
digest item_count = 1
digest event_id = jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
source health = healthy
cursor_key = latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value = 2026-04-30T19:00:00+09:00|4527|140120260430515474
raw row code = 45270
normalized security code = 4527
source_category = null
material_category = unknown
source_category_inferred = false
```

## Required storage-level dedupe before lock

Run:

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_timely_disclosure_dedupe_checks.sql
```

Expected:

```text
queries 1-6 return no rows
query 7 returns row_count = 1 for:
  TDNET:4527:20260430:1900:140120260430515474:discovery-row
  TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474
```

## Lock blockers

Do not mark JP TDnet runtime locked if any are true:

- automated tests were not run
- runtime idempotency test fails
- HTTP smoke test fails
- manual smoke was not run
- source health is not healthy
- dedupe SQL returns duplicates
- raw row code `45270` is lost or replaces normalized security code
- normalized security code is not `4527`
- source category is inferred from title or PDF text
- extra TDnet rows are added
- EDINET runtime is mixed into this slice

## Lock close-out requirements

A future lock close-out PR may mark JP TDnet runtime locked only after it records:

```text
automated test result: PASS
manual isolated smoke: PASS
storage-level dedupe SQL: PASS
code patch required after verification: yes/no
final merge SHA used for verification
```

## Current recommendation

Next PR should run or record verification, then produce a true runtime lock close-out if all checks pass.
