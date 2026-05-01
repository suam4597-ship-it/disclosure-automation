# JP TDnet broad ingestion controlled runtime workset plan

This document defines the exact next implementation PR after JP TDnet broad ingestion contract-freeze.

Do not implement unbounded TDnet live pagination. Implement only the three frozen fixture rows.

## Implementation branch recommendation

```text
chatgpt-jp-tdnet-broad-runtime-v1
```

Base the branch on the merge commit of the broad contract-freeze close-out PR.

## Frozen contract to implement

```text
source_key: jp_tdnet_broad_timely_disclosure
adapter_key: jp_tdnet_broad_timely_disclosure_v1
region_code: jp
source_tier: official_exchange_storage
event_family: material_information_update
canonical_event_type: material_information_update
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
sample row count: 3
```

## Expected event ids

```text
jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
jp.tdnet.2871.20260430.material_information_update.material_information_update.140120260430515256
jp.tdnet.6088.20260430.material_information_update.material_information_update.140120260430514945
```

## Files to create in the runtime PR

### Source helper

```text
apps/backend/disclosure_api/lib/disclosure_automation/ops/jp_tdnet_broad_timely_disclosure_source.ex
```

### Runtime adapter

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/jp_tdnet_broad_timely_disclosure_adapter.ex
```

Also update adapter resolver only for:

```text
jp_tdnet_broad_timely_disclosure_v1
```

### Source registry sample

```text
apps/backend/disclosure_api/priv/config_samples/source_registry.jp_tdnet_broad_timely_disclosure.sample.yaml
```

Use `source_type: api` unless the DB enum has been expanded to allow another value.

### Fixtures

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_broad_timely_disclosure_discovery_20260430.json
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_broad_timely_disclosure_pdf_4527_20260430_1900_140120260430515474.txt
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_broad_timely_disclosure_pdf_2871_20260430_1700_140120260430515256.txt
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_tdnet_broad_timely_disclosure_pdf_6088_20260430_1700_140120260430514945.txt
```

### Ops runner

```text
apps/backend/disclosure_api/priv/ops/run_jp_tdnet_broad_timely_disclosure_server.exs
```

### Dedupe SQL

```text
apps/backend/disclosure_api/priv/ops/jp_tdnet_broad_timely_disclosure_dedupe_checks.sql
```

### Tests

```text
apps/backend/disclosure_api/test/jp_tdnet_broad_timely_disclosure_runtime_idempotency_test.exs
apps/backend/disclosure_api/test/jp_tdnet_broad_timely_disclosure_http_smoke_test.exs
```

### Verification docs

```text
apps/backend/disclosure_api/docs/jp_tdnet_broad_timely_disclosure_manual_smoke.md
apps/backend/disclosure_api/docs/jp_tdnet_broad_timely_disclosure_minimal_verification.md
apps/backend/disclosure_api/docs/jp_tdnet_broad_timely_disclosure_first_run_triage.md
```

## Parser requirements

The adapter must:

1. load exactly three TDnet discovery fixture rows
2. produce exactly three discovery items
3. hydrate exactly one PDF/text fixture per row
4. preserve `tdnet_raw_row_code` and `normalized_security_code` separately
5. compute stable external ids using the frozen identity rule
6. compute cursor values using the frozen cursor rule
7. emit exactly the three frozen event ids
8. keep `source_category` as `null`
9. keep `material_category` as `unknown`
10. keep `source_category_inferred` as `false`
11. avoid title/category inference

## Expected storage counts after repeated poll

```text
raw_events: 3
canonical_feed_items: 3
raw_documents: 6
canonical_item_sources: 6
representative source count: 3
```

## Locked single-fixture regression

The runtime PR must continue to pass:

```bash
mix test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
mix test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Broad runtime tests

The new broad runtime tests must assert:

```text
first poll records_seen = 3
second poll records_seen = 3
latest digest item_count = 3
all three frozen event ids are present
same-time 17:00 rows are both preserved
source health is healthy
cursor key/value are present
raw row code and normalized security code are preserved for all rows
source_category remains null
material_category remains unknown
source_category_inferred remains false
```

## Scope guardrail

The runtime PR must not add:

```text
EDINET runtime
CN broad runtime
JPX Listed Company Search adapter
TDnet live pagination beyond this fixture path
additional TDnet rows beyond the frozen three-row sample set
title/category inference
news overlay
cross-source merge
```
