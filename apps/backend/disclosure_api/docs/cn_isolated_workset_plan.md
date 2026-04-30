# CN isolated workset plan

This document describes the later isolated runtime implementation PR that may follow after CN contract-freeze.

This discovery-only PR must not create the runtime workset files listed here.

## Prerequisite

Do not start the implementation workset until the CN contract-freeze package has chosen:

- one official source
- one first high-signal family
- one deterministic public sample
- one stable external identity rule
- one cursor key/value shape
- one minimum raw-document set
- one canonical event mapping

## Later implementation workset shape

The later CN runtime PR should be narrow:

- one `source_key`
- one `adapter_key`
- one source helper
- one sample YAML
- one discovery fixture
- one detail fixture
- one attachment fixture only if required
- one runtime adapter
- one isolated ops runner
- one runtime idempotency test
- one HTTP smoke test
- one dedupe SQL file
- one manual smoke doc

## Files that may be created later

Use exact paths only after contract freeze. Replace `cn_<chosen_source>` with the frozen source key.

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/cn_<chosen_source>_adapter.ex
apps/backend/disclosure_api/lib/disclosure_automation/ops/cn_<chosen_source>_source.ex
apps/backend/disclosure_api/priv/config_samples/source_registry.cn_<chosen_source>.sample.yaml
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_<chosen_source>_discovery_<sample>.html
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_<chosen_source>_detail_<sample>.html
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_<chosen_source>_attachment_<sample>.pdf
apps/backend/disclosure_api/priv/ops/run_cn_<chosen_source>_server.exs
apps/backend/disclosure_api/priv/ops/cn_<chosen_source>_dedupe_checks.sql
apps/backend/disclosure_api/test/cn_<chosen_source>_runtime_idempotency_test.exs
apps/backend/disclosure_api/test/cn_<chosen_source>_http_smoke_test.exs
apps/backend/disclosure_api/docs/cn_<chosen_source>_manual_smoke.md
apps/backend/disclosure_api/docs/cn_<chosen_source>_minimal_verification.md
```

Only create the attachment fixture if the frozen source requires an attachment/PDF to extract the canonical facts.

## Files that must not be created in this discovery PR

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/cn_*.ex
apps/backend/disclosure_api/lib/disclosure_automation/ops/cn_*_source.ex
apps/backend/disclosure_api/priv/config_samples/source_registry.cn_*.sample.yaml
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_*
apps/backend/disclosure_api/test/cn_*
apps/backend/disclosure_api/priv/ops/cn_*
```

## Later implementation phases

### Phase 1: source registry sample and helper

- add one source registry sample YAML
- add one source helper that loads the YAML
- keep `active: true` only for the isolated sample
- make the source key match the frozen contract exactly

### Phase 2: fixtures

- add one discovery fixture
- add one detail fixture
- add one attachment fixture only if required
- keep fixture payloads deterministic and public-source-derived
- do not include broad source pages unrelated to the frozen family

### Phase 3: adapter

- implement `discover/2`, `hydrate/3`, `parse/3`, and `normalize/3`
- preserve exact stable external identity and cursor semantics
- produce the frozen event id shape
- generate the minimum raw-document set only

### Phase 4: tests and manual smoke

- add runtime idempotency test
- add HTTP smoke test
- add isolated server runner
- add storage-level dedupe SQL
- document manual smoke pass conditions

## Verification target for later lock

The later runtime PR can lock only when:

- poll 1 and poll 2 see exactly the same one record
- digest 1 and digest 2 expose exactly the same `event_id`
- `event_family` matches the frozen contract
- `canonical_event_type` matches the frozen contract
- `published_at_local` and `published_at_utc` match the frozen conversion rule
- cursor key/value match the frozen contract
- source health is healthy
- dedupe SQL is clean

## Scope guardrail

The later implementation PR must not include:

- JP work
- news overlay
- cross-source merge
- broad CN all-disclosures ingestion
- multiple CN source families
- multiple CN exchange surfaces in one adapter
