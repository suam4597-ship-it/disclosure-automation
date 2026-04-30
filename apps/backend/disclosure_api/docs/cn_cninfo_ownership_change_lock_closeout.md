# CNInfo ownership-change runtime lock close-out

This document closes out the first CN runtime lock after the isolated `cn_cninfo_ownership_change` implementation PR.

## Lock status

```text
cn_cninfo_ownership_change: locked
```

## Locked baseline preserved

Keep these locked:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

## Runtime implementation PR

- PR: `#37`
- title: `Implement CNInfo ownership-change isolated runtime slice`
- merge SHA: `c956ccb7b5bc1e076710e66aeba0271508f67514`
- verification head: `c956ccb7b5bc1e076710e66aeba0271508f67514`
- verification branch/base: latest `sec-thin-slice-reconcile-v1`
- post-verification source patch required: `none`
- post-verification worktree state: `clean`

## Locked contract

```text
source_key: cn_cninfo_ownership_change
adapter_key: cn_cninfo_ownership_change_v1
stable_external_id: CNINFO:1225049497
cursor_key: latest_announcement_date_and_announcement_id_seen
cursor_value: 2026-03-30|1225049497
event_family: ownership_change_update
canonical_event_type: major_shareholding_or_insider_trade
event_id: cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
```

## Locked observed values

```text
event_id: cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
event_family: ownership_change_update
canonical_event_type: major_shareholding_or_insider_trade
published_at_local: 2026-03-30T00:00:00+08:00
published_at_utc: 2026-03-29T16:00:00.000000Z
filing_date_local: 2026-03-30
stable_external_id: CNINFO:1225049497
cursor_key: latest_announcement_date_and_announcement_id_seen
cursor_value: 2026-03-30|1225049497
```

## Verification result

```text
runtime idempotency test: PASS
HTTP smoke test: PASS
manual isolated smoke: PASS
storage-level dedupe SQL: PASS
code patch required after verification: none
```

## Poll and digest verification

```text
poll 1 records_seen: 1
poll 2 records_seen: 1
digest 1 item_count: 1
digest 2 item_count: 1
repeated poll event_id: stable
source health: healthy
```

## Storage-level dedupe verification

`priv/ops/cn_cninfo_ownership_change_dedupe_checks.sql` result:

```text
queries 1-6: no rows
query 7:
  CNINFO:1225049497:discovery-row row_count = 1
  CNINFO:1225049497:pdf:1225049497 row_count = 1
```

Additional storage checks:

```text
raw_events: 1
canonical_feed_items(event_id): 1
canonical_item_sources: 2
representative source count: 1
```

## Locked fixture item

```text
issuer: 长虹华意压缩机股份有限公司
security_code: 000404
security_short_name: 长虹华意
announcement_id: 1225049497
title: 关于公司部分董事和高级管理人员增持公司股份计划时间过半的进展公告
local_date_cursor: 2026-03-30
pdf_path: finalpage/2026-03-30/1225049497.PDF
```

## Scope that remains out of lock

Do not treat this lock as approval for:

- broad CN all-disclosures ingestion
- CNInfo live API pagination
- additional CNInfo categories
- M&A/restructuring CN family
- material-information CN family
- SSE/SZSE/BSE separate adapters
- JP
- news overlay
- cross-source merge

## Next stage guidance

The first CN regional vertical is now locked.

Next work should either:

1. start JP discovery-first kickoff; or
2. begin another explicitly scoped regional/family discovery PR.

Do not widen the CNInfo runtime slice in-place.
