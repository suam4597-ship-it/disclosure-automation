# TW isolated workset plan

This file describes the first TW implementation PR after source contract freeze.

## Required file set

### 1) Source helper

Expected path shape:

- `apps/backend/disclosure_api/lib/disclosure_automation/ops/tw_<family>_source.ex`

### 2) Sample YAML

Expected path shape:

- `apps/backend/disclosure_api/priv/config_samples/source_registry.tw_<family>.sample.yaml`

### 3) Fixture payloads

Expected path shape:

- `apps/backend/disclosure_api/priv/fixtures/source_payloads/tw_<family>_discovery.*`
- `apps/backend/disclosure_api/priv/fixtures/source_payloads/tw_<family>_detail.*`
- optional linked document fixture if required

Use only one deterministic item for the first TW lock.

### 4) Runtime code

Expected path shape if a runtime adapter is required:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/tw_<family>_adapter.ex`

Also update:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`

### 5) Ops scripts

Expected path shape:

- `apps/backend/disclosure_api/priv/ops/bootstrap_tw_<family>_source.exs`
- `apps/backend/disclosure_api/priv/ops/run_tw_<family>_server.exs`
- `apps/backend/disclosure_api/priv/ops/tw_<family>_dedupe_checks.sql`

### 6) Tests

Expected path shape:

- `apps/backend/disclosure_api/test/tw_<family>_runtime_idempotency_test.exs`
- `apps/backend/disclosure_api/test/tw_<family>_http_smoke_test.exs`

### 7) Docs

Expected path shape:

- `apps/backend/disclosure_api/docs/tw_<family>_minimal_verification.md`
- `apps/backend/disclosure_api/docs/tw_<family>_manual_smoke.md`
- `apps/backend/disclosure_api/docs/tw_<family>_first_run_triage.md`

## First implementation PR pass condition

- exactly one fixture item ingests
- repeated poll keeps stable event identity
- raw document identities are deterministic
- canonical item source names are source-appropriate
- source cursor semantics are explicit and tested
- dedupe SQL is clean

## Guardrail

Do not widen the TW scope inside the first implementation PR.
Freeze one thin slice first, then lock it, then expand.
