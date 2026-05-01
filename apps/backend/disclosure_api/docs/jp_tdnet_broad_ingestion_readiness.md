# JP TDnet broad ingestion readiness

This document defines the readiness gate for moving from the locked JP TDnet single-fixture runtime to broader JP TDnet ingestion.

This is docs-only. It does not implement broad JP ingestion.

## Current locked JP baseline

```text
source_key: jp_tdnet_timely_disclosure
adapter_key: jp_tdnet_timely_disclosure_v1
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
cursor_key: latest_disclosure_datetime_security_code_and_pdf_token_seen
cursor_value: 2026-04-30T19:00:00+09:00|4527|140120260430515474
runtime lock status: locked
```

Do not change the locked single-fixture semantics.

## Broad JP definition choices

Before implementation, choose exactly one broad lane:

### Option A: TDnet current-list controlled broad ingestion

```text
source: TDnet Company Announcements Disclosure Service
scope: current-list rows inside public retention window
family: material_information_update
identity: publication datetime + normalized security code + PDF token
cursor: latest disclosure datetime + security code + PDF token
```

This is the preferred broad JP first expansion because it extends the locked TDnet path.

### Option B: JPX Listed Company Search historical TDnet ingestion

```text
source: JPX Listed Company Search
scope: historical timely disclosure rows
family: material_information_update or selected family subset
identity: historical row stable ID or PDF/document token
cursor: historical date + stable token
```

Use this only if current-list retention makes sample reproducibility too weak.

### Option C: EDINET statutory reports

EDINET is not TDnet broad ingestion. It must stay a separate source and contract.

## Broad JP implementation blockers

Do not implement broad JP until these are frozen:

```text
row pagination/list traversal rule
retention-window handling
maximum rows per poll
PDF/document hydrate policy
stable identity rule for rows missing PDF token
cursor tie-breaker for same-time rows
raw code -> normalized security code rule
category handling policy
backfill/no-backfill policy
```

## Category policy

The locked TDnet sample has no official category column on the current-list row.

For broad v1:

```text
source_category: keep official row category only if exposed
material_category: unknown unless official category is captured
source_category_inferred: false
```

Do not infer category from title or PDF text in the first broad PR.

## Cursor policy

Preferred broad cursor:

```text
latest_disclosure_datetime_security_code_and_pdf_token_seen
<YYYY-MM-DDTHH:MM:SS+09:00>|<normalized_security_code>|<pdf_document_token>
```

If multiple rows share same disclosure timestamp, use the security code and PDF token as deterministic tie-breakers.

## Fixture strategy

Before broad runtime, create a fixture set with:

```text
2-3 TDnet current-list rows maximum
same disclosure date
at least two rows with same timestamp if available
at least one row without XBRL
only official row metadata and PDF text fixtures
```

Do not jump from one fixture row to full live pagination.

## Required docs before broad runtime

```text
apps/backend/disclosure_api/docs/jp_tdnet_broad_ingestion_contract_freeze_closeout.md
apps/backend/disclosure_api/docs/jp_tdnet_broad_ingestion_runtime_workset_plan.md
```

## Runtime guardrails

The first broad JP runtime PR must not include:

```text
EDINET runtime
CN broad expansion
JPX Listed Company Search adapter unless explicitly chosen as the broad lane
news overlay
cross-source merge
title/category inference
unbounded pagination
```

## Current recommendation

After EDINET sample-capture gate, prepare Option A as a controlled TDnet current-list broad ingestion contract.
