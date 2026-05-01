# CN broad expansion readiness

This document defines the readiness gate for moving beyond the locked CNInfo ownership-change single-fixture runtime.

This is docs-only. It does not implement broad CN ingestion.

## Current locked CN baseline

```text
source_key: cn_cninfo_ownership_change
adapter_key: cn_cninfo_ownership_change_v1
event_id: cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
stable_external_id: CNINFO:1225049497
cursor_key: latest_announcement_date_and_announcement_id_seen
cursor_value: 2026-03-30|1225049497
runtime lock status: locked
```

Do not change the locked CNInfo ownership-change semantics.

## Broad CN definition choices

Before implementation, choose exactly one CN broad lane:

### Option A: CNInfo controlled announcement expansion

```text
source: CNInfo announcement query
scope: controlled additional announcement rows within CNInfo
family: selected family set, not all categories at once
identity: CNINFO:<announcementId>
cursor: announcement date/time + announcementId when available
```

This is the preferred first broad CN path because it extends the locked CNInfo lane.

### Option B: CNInfo additional family expansion

```text
source: CNInfo
scope: one additional family such as M&A/restructuring or material information
family: exactly one new family
identity: CNINFO:<announcementId>
cursor: announcement date/time + announcementId or date + announcementId
```

Use this if broad all-announcements is too wide.

### Option C: SSE/SZSE/BSE separate official surfaces

Use only after source-specific discovery and contract-freeze. Do not mix with CNInfo broad runtime.

## Broad CN implementation blockers

Do not implement broad CN until these are frozen:

```text
source surface
family scope
category filter
pagination rule
retention/backfill policy
stable identity rule
cursor rule and tie-breaker
minimum fixture set
PDF/detail hydrate policy
dedupe SQL expectations
```

## Cursor upgrade policy

The locked CNInfo ownership-change v0 uses:

```text
latest_announcement_date_and_announcement_id_seen
2026-03-30|1225049497
```

For broader CNInfo, prefer upgrading only the broad lane to:

```text
latest_announcement_datetime_and_announcement_id_seen
<YYYY-MM-DDTHH:MM:SS+08:00>|<announcementId>
```

Do not mutate the locked ownership-change cursor unless a compatibility migration is explicitly planned.

## Fixture strategy

Before broad runtime, create a fixture set with:

```text
2-3 CNInfo rows maximum
one source
one family or tightly controlled family set
stable announcementId for every row
one PDF/text fixture per row only if needed
```

Do not jump directly to broad live pagination.

## Required docs before broad runtime

```text
apps/backend/disclosure_api/docs/cn_cninfo_broad_expansion_contract_freeze_closeout.md
apps/backend/disclosure_api/docs/cn_cninfo_broad_expansion_runtime_workset_plan.md
```

## Runtime guardrails

The first broad CN runtime PR must not include:

```text
JP broad ingestion
EDINET runtime
SSE/SZSE/BSE adapters unless selected explicitly
news overlay
cross-source merge
unbounded CNInfo pagination
all CNInfo categories at once
```

## Current recommendation

After EDINET gate and JP broad-readiness, prepare CNInfo controlled announcement expansion over one additional family or a small controlled row set.
