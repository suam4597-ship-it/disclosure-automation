# CNInfo broad expansion contract gate

This document defines the contract gate for moving from CNInfo sample capture to a broad CNInfo runtime PR.

This is docs-only. It does not add broad CN runtime.

## Gate status

```text
broad CNInfo runtime: blocked until controlled sample set is captured
locked CNInfo ownership-change fixture: preserve unchanged
```

## Required contract-freeze docs before runtime

After filling the sample capture sheet, create:

```text
apps/backend/disclosure_api/docs/cn_cninfo_broad_expansion_contract_freeze_closeout.md
apps/backend/disclosure_api/docs/cn_cninfo_broad_expansion_runtime_workset_plan.md
```

Do not start runtime until both exist.

## Broad adapter strategy

The broad adapter should use a new key unless it is strictly a compatibility-preserving extension.

Preferred candidate:

```text
source_key: cn_cninfo_broad_announcement_feed
adapter_key: cn_cninfo_broad_announcement_feed_v1
source_tier: official_exchange_storage
identity rule: CNINFO:<announcementId>
```

Use the existing `cn_cninfo_ownership_change_v1` only for the locked ownership-change lane.

## Required implementation boundaries

First broad CN runtime PR must include at most:

```text
2-3 discovery rows
0-3 PDF/text fixtures, depending on whether each row requires document hydration
one source registry sample
one new adapter
one runtime idempotency test
one HTTP smoke test
one dedupe SQL file
one manual smoke doc
```

## Explicit no-go conditions

Do not implement broad CNInfo if any are true:

- no controlled 2-3 row official sample set
- no stable announcementId for each row
- no date/datetime for each row
- cursor requires title text
- family scope is broad/all categories without a contract
- implementation would mutate locked CNInfo ownership-change event id, stable id, cursor, or raw document identities
- runtime would require unbounded live pagination in v0

## Locked CNInfo regression tests

Broad CN work must continue to pass:

```bash
mix test test/cn_cninfo_ownership_change_runtime_idempotency_test.exs
mix test test/cn_cninfo_ownership_change_http_smoke_test.exs
```

## Stage 5 blocker

Do not start news overlay or cross-source merge until broad CN and broad JP gates are either:

```text
closed as locked
or explicitly deferred/no-go with reasons
```

## Current recommendation

Capture 2-3 CNInfo rows from one additional high-signal family first. If that fails, document no-go and defer broad CN rather than mutating the locked ownership-change lane.
