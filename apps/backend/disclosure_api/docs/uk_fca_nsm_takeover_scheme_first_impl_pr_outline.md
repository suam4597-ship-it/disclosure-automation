# UK FCA NSM takeover / scheme first implementation PR outline

This document exists to make the first UK implementation PR immediate once the source contract is frozen.
It should be used only after Issue #29 is closed.

## Intended PR goal

Open the first isolated runtime slice for:

- `uk_fca_nsm_takeover_scheme_updates`

The PR should aim for one deterministic item only.

## Expected file set

### Source helper

- `apps/backend/disclosure_api/lib/disclosure_automation/ops/uk_fca_nsm_takeover_scheme_updates_source.ex`

### Sample YAML

- `apps/backend/disclosure_api/priv/config_samples/source_registry.uk_fca_nsm_takeover_scheme_updates.sample.yaml`

### Fixture payloads

Minimum target shape:

- one public discovery result fixture
- one artefact/detail fixture
- one linked filing payload fixture only if the detail page alone is not sufficient

Suggested path pattern:

- `apps/backend/disclosure_api/priv/fixtures/source_payloads/uk_fca_nsm_takeover_scheme_discovery.*`
- `apps/backend/disclosure_api/priv/fixtures/source_payloads/uk_fca_nsm_takeover_scheme_detail.*`
- optional: `apps/backend/disclosure_api/priv/fixtures/source_payloads/uk_fca_nsm_takeover_scheme_filing.*`

### Runtime code

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/uk_fca_nsm_takeover_scheme_updates_adapter.ex`
- update `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`

### Ops scripts

- `apps/backend/disclosure_api/priv/ops/bootstrap_uk_fca_nsm_takeover_scheme_updates_source.exs`
- `apps/backend/disclosure_api/priv/ops/run_uk_fca_nsm_takeover_scheme_updates_server.exs`
- `apps/backend/disclosure_api/priv/ops/uk_fca_nsm_takeover_scheme_updates_dedupe_checks.sql`

### Tests

- `apps/backend/disclosure_api/test/uk_fca_nsm_takeover_scheme_updates_runtime_idempotency_test.exs`
- `apps/backend/disclosure_api/test/uk_fca_nsm_takeover_scheme_updates_http_smoke_test.exs`

### Docs

- `apps/backend/disclosure_api/docs/uk_fca_nsm_takeover_scheme_updates_minimal_verification.md`
- `apps/backend/disclosure_api/docs/uk_fca_nsm_takeover_scheme_updates_manual_smoke.md`
- `apps/backend/disclosure_api/docs/uk_fca_nsm_takeover_scheme_updates_first_run_triage.md`

## First PR assertions to lock

Do not keep these soft after the first real green run.
Lock exact values for:

- `event_id`
- `event_family`
- `canonical_event_type`
- `published_at_local`
- `published_at_utc`
- chosen stable identity field
- chosen cursor value

## First PR guardrail

Do not widen the PR to adjacent UK families.
If takeover / scheme cannot satisfy the contract-freeze exit criteria, stop and promote the backup family instead of broadening this PR.
