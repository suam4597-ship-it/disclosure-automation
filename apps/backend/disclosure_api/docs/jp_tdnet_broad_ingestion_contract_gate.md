# JP TDnet broad ingestion contract gate

This document defines the contract gate for moving from sample capture to a broad JP TDnet runtime PR.

This is docs-only. It does not add broad runtime.

## Gate status

```text
broad JP TDnet runtime: blocked until sample set is captured
locked single fixture: preserve unchanged
```

## Required contract-freeze docs before runtime

After filling the sample capture sheet, create:

```text
apps/backend/disclosure_api/docs/jp_tdnet_broad_ingestion_contract_freeze_closeout.md
apps/backend/disclosure_api/docs/jp_tdnet_broad_ingestion_runtime_workset_plan.md
```

Do not start runtime until both exist.

## Broad adapter strategy

The broad adapter may either:

```text
reuse jp_tdnet_timely_disclosure_v1 with a broadened fixture mode
```

or create:

```text
jp_tdnet_broad_timely_disclosure_v1
```

Decision rule:

- reuse existing adapter key only if locked single-fixture semantics and tests remain unchanged
- create new adapter key if broad behavior needs pagination, multi-row ordering, or new cursor semantics

## Preferred contract values

```text
source_key candidate: jp_tdnet_broad_timely_disclosure
adapter_key candidate: jp_tdnet_broad_timely_disclosure_v1
source_tier: official_exchange_storage
family: material_information_update
canonical_event_type: material_information_update
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
identity rule: TDNET:<normalized_security_code>:<YYYYMMDD>:<HHMM>:<pdf_document_token>
```

## Required implementation boundaries

First broad runtime PR must include at most:

```text
2-3 discovery rows
2-3 PDF/text fixtures
one source registry sample
one adapter or carefully isolated adapter extension
one runtime idempotency test
one HTTP smoke test
one dedupe SQL file
one manual smoke doc
```

## Explicit no-go conditions

Do not implement broad JP TDnet if any are true:

- no controlled 2-3 row official sample set
- no stable PDF/document token for each row
- no publication time for each row
- cursor cannot order same-time rows deterministically
- category requires title inference
- broad implementation would mutate the locked single-fixture event id or cursor
- runtime would require live pagination in v0

## Locked single-fixture regression tests

Broad JP work must continue to pass:

```bash
mix test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
mix test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Stage 5 blocker

Do not start news overlay or cross-source merge until broad JP and broad CN gates are either:

```text
closed as locked
or explicitly deferred/no-go with reasons
```
