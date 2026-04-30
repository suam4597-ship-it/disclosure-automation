# CN first-run triage placeholder

This document is a placeholder for the first CN runtime implementation PR.

Do not use this document as evidence that CN runtime exists.
CN runtime is not started in this discovery-first PR.

## Current status

- CN source contract: not frozen
- CN source helper: not created
- CN sample YAML: not created
- CN fixtures: not created
- CN runtime adapter: not created
- CN tests: not created
- CN ops runner: not created
- CN dedupe SQL: not created

## Triage sections to fill after contract freeze

### If the source does not upsert

Later runtime PR should check:

- source helper path
- sample YAML path
- frozen `source_key`
- frozen `adapter_key`
- source registry defaults

### If adapter resolution fails

Later runtime PR should check:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`
- exact frozen adapter key
- exact adapter module name

### If discovery returns zero rows

Later runtime PR should check:

- discovery fixture path
- source query parameters
- family/category filter
- sample issuer/security code
- sample publication date range
- visible stable id fields

### If detail hydrate fails

Later runtime PR should check:

- detail URL shape
- fixture map
- attachment URL, if required
- source-specific headers or query params, if documented

### If cursor is missing

Later runtime PR should check that the discovery row or detail metadata exposes the frozen cursor components.

Expected placeholder:

```text
TODO: frozen cursor key
TODO: frozen cursor value shape
```

### If published time is wrong

Later runtime PR should check:

- source timezone assumption
- local publication timestamp display format
- UTC conversion rule
- date-only fallback behavior, if any

### If exact event_id drifts

Later runtime PR should inspect:

- issuer/security code source
- filing/publication date source
- canonical event type
- event family
- stable external identity seed
- sequence/document id field

### If raw document counts are wrong

Later runtime PR should compare actual raw documents to the frozen minimum raw-document set.

Expected placeholder:

```text
TODO: discovery row document identity
TODO: detail page document identity
TODO: attachment document identity, if required
```

## Guardrail

Do not backfill this document with runtime-specific values until CN contract-freeze has selected one source, one family, and one deterministic sample.
