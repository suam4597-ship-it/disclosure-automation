# CNInfo broad expansion contract-freeze close-out

This document freezes the controlled CNInfo broad expansion contract after CNInfo ownership-change runtime lock and broad sample capture.

This is docs-only. It does not add broad CN runtime code, fixtures, tests, ops runner, or dedupe SQL.

## Freeze status

```text
broad source contract: frozen
sample set: frozen
runtime implementation: not started
next PR: controlled CNInfo broad runtime implementation
```

## Current locked baseline

Keep these locked:

```text
SEC 6-K
SEC 8-K
SEC SC TO-T
SEC SC 14D-9
SEC SC 13D/A
AFM substantial holdings
UK FCA NSM takeover/scheme
TW MOPS material information
CNInfo ownership-change
JP TDnet timely disclosure
JP TDnet broad contract-freeze
```

## Chosen broad lane

```text
source_key: cn_cninfo_broad_announcement_feed
adapter_key: cn_cninfo_broad_announcement_feed_v1
display_name: China CNInfo Broad Announcement Feed
region_code: cn
source_type: api
source_class: regulatory_filing_feed
source_tier: official_exchange_storage
source platform: CNInfo / 巨潮资讯网
source scope: controlled CNInfo latest announcement rows from one date
```

Use a new source key and adapter key so the locked `cn_cninfo_ownership_change` source stays unchanged.

## Chosen family scope

Controlled corporate-action / governance-style CNInfo set:

```text
ownership_change_update
shareholder_meeting_update
board_change_update
```

Do not implement all CNInfo categories in v1.

## Chosen sample set

All rows use announcement date:

```text
announcement_date: 2026-05-01
```

### Sample 1

```text
sec_code: 603660
sec_name: 苏州科达
company_name: 苏州科达
announcement_title: 关于公司股东协议转让股份过户完成的公告
announcement_id: 1225274841
org_id: 9900026447
announcement_datetime_local: 2026-05-01T00:00:00+08:00 date-only convention
published_at_utc: 2026-04-30T16:00:00.000000Z
detail_url: https://www.cninfo.com.cn/new/disclosure/detail?announcementId=1225274841&announcementTime=2026-05-01&orgId=9900026447&stockCode=603660
adjunct_url: finalpage/2026-05-01/1225274841.PDF
pdf_url: https://static.cninfo.com.cn/finalpage/2026-05-01/1225274841.PDF
stable_external_id: CNINFO:603660:20260501:1225274841
cursor_value: 2026-05-01|1225274841
event_family: ownership_change_update
canonical_event_type: major_shareholding_or_insider_trade
```

### Sample 2

```text
sec_code: 603350
sec_name: 安乃达
company_name: 安乃达
announcement_title: 2025年年度股东会决议公告
announcement_id: 1225274838
org_id: gfbj0839807
announcement_datetime_local: 2026-05-01T00:00:00+08:00 date-only convention
published_at_utc: 2026-04-30T16:00:00.000000Z
detail_url: https://www.cninfo.com.cn/new/disclosure/detail?announcementId=1225274838&announcementTime=2026-05-01&orgId=gfbj0839807&stockCode=603350
adjunct_url: finalpage/2026-05-01/1225274838.PDF
pdf_url: https://static.cninfo.com.cn/finalpage/2026-05-01/1225274838.PDF
stable_external_id: CNINFO:603350:20260501:1225274838
cursor_value: 2026-05-01|1225274838
event_family: shareholder_meeting_update
canonical_event_type: shareholder_meeting
```

### Sample 3

```text
sec_code: 300376
sec_name: 易事特
company_name: 易事特
announcement_title: 关于公司董事会换届选举的公告
announcement_id: 1225274454
org_id: GD025312
announcement_datetime_local: 2026-05-01T00:00:00+08:00 date-only convention
published_at_utc: 2026-04-30T16:00:00.000000Z
detail_url: https://www.cninfo.com.cn/new/disclosure/detail?announcementId=1225274454&announcementTime=2026-05-01&orgId=GD025312&stockCode=300376
adjunct_url: finalpage/2026-05-01/1225274454.PDF
pdf_url: https://static.cninfo.com.cn/finalpage/2026-05-01/1225274454.PDF
stable_external_id: CNINFO:300376:20260501:1225274454
cursor_value: 2026-05-01|1225274454
event_family: board_change_update
canonical_event_type: board_or_management_change
```

## Identity rule

```text
stable_external_id: CNINFO:<stockCode>:<YYYYMMDD>:<announcementId>
raw_event_key_seed: stable_external_id
duplicate_group_seed: stable_external_id
```

Do not use title text in identity.

## Cursor rule

```text
cursor_key: latest_announcement_date_and_announcement_id_seen
cursor_value: <YYYY-MM-DD>|<announcementId>
```

Why date-only is frozen:

- static latest-row/detail capture exposes date but not reliable minute-level time
- `announcementId` provides stable deterministic tie-breaker
- a future live API path may upgrade to datetime if official JSON exposes minute precision

Do not mutate the locked ownership-change cursor.

## Minimum raw-document set

For each row:

```text
1. discovery/detail metadata row fixture
2. PDF/text attachment fixture
```

For three rows, expected raw documents:

```text
6 raw documents total
```

## Expected event id shape

```text
cn.cninfo.<sec_code>.<YYYYMMDD>.<canonical_event_type>.<event_family>.<announcementId>
```

Expected event ids:

```text
cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841
cn.cninfo.603350.20260501.shareholder_meeting.shareholder_meeting_update.1225274838
cn.cninfo.300376.20260501.board_or_management_change.board_change_update.1225274454
```

## Runtime guardrails

The next broad CNInfo runtime PR must not add:

```text
JP broad runtime
EDINET runtime
SSE/SZSE/BSE adapters
unbounded CNInfo pagination
all CNInfo categories at once
news overlay
cross-source merge
```

## Close-out result

CNInfo broad expansion contract-freeze is complete for:

```text
cn_cninfo_broad_announcement_feed
```

Next step:

```text
CNInfo broad expansion controlled runtime implementation PR
```
