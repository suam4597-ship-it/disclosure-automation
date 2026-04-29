# UK discovery + NSM isolated workset plan

This file describes the first implementation PR *after* the UK source contract is frozen.

## Required file set

### 1) Source helper

Expected path shape:

- `apps/backend/disclosure_api/lib/disclosure_automation/ops/<uk_source>_source.ex`

### 2) Sample YAML

Expected path shape:

- `apps/backend/disclosure_api/priv/config_samples/source_registry.<uk_source>.sample.yaml`

### 3) Fixture payloads

Expected path shape:

- `apps/backend/disclosure_api/priv/fixtures/source_payloads/<uk_source>_*.xml`
- or
- `apps/backend/disclosure_api/priv/fixtures/source_payloads/<uk_source>_*.html`
- or
- `apps/backend/disclosure_api/priv/fixtures/source_payloads/<uk_source>_*.json`

Use only the minimum set needed for one deterministic item.

### 4) Runtime code

Expected path shape if a runtime adapter is required:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/<uk_source>_adapter.ex`

Also update:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`

### 5) Ops scripts

Expected path shape:

- `apps/backend/disclosure_api/priv/ops/bootstrap_<uk_source>_source.exs`
- `apps/backend/disclosure_api/priv/ops/run_<uk_source>_server.exs`
- `apps/backend/disclosure_api/priv/ops/<uk_source>_dedupe_checks.sql`

### 6) Tests

Expected path shape:

- `apps/backend/disclosure_api/test/<uk_source>_runtime_idempotency_test.exs`
- `apps/backend/disclosure_api/test/<uk_source>_http_smoke_test.exs`

### 7) Docs

Expected path shape:

- `apps/backend/disclosure_api/docs/<uk_source>_minimal_verification.md`
- `apps/backend/disclosure_api/docs/<uk_source>_manual_smoke.md`
- `apps/backend/disclosure_api/docs/<uk_source>_first_run_triage.md`

## First implementation PR pass condition

- exactly one fixture item ingests
- repeated poll keeps stable event identity
- raw document identities are deterministic
- canonical item source names are source-appropriate
- source cursor semantics are explicit and tested
- dedupe SQL is clean

## Guardrail

Do not widen the UK scope inside the first implementation PR.
Freeze one thin slice first, then lock it, then expand.
