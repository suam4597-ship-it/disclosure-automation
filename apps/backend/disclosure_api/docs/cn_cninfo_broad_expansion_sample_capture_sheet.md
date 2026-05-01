# CNInfo broad expansion sample capture sheet

This sheet records the controlled CNInfo sample set required before broad CNInfo expansion can be implemented.

This is docs-only. It does not add broad CN runtime.

## Current locked CN baseline

The locked CNInfo ownership-change runtime must remain unchanged:

```text
source_key: cn_cninfo_ownership_change
adapter_key: cn_cninfo_ownership_change_v1
event_id: cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
stable_external_id: CNINFO:1225049497
cursor_key: latest_announcement_date_and_announcement_id_seen
cursor_value: 2026-03-30|1225049497
runtime lock status: locked
```

## Broad target

Frozen broad lane:

```text
source: CNInfo latest announcement row + official PDF
scope: controlled CNInfo latest-announcement rows from one date
family scope: controlled corporate-action / governance-style announcement rows
identity: CNINFO:<stockCode>:<YYYYMMDD>:<announcementId>
cursor: announcement_date + announcementId
```

## Captured sample set

```text
row_count: 3
same source endpoint/surface: yes
stable announcementId for every row: yes
announcement date for every row: yes
security code / issuer visible for every row: yes
PDF/document path or attachment URL for every row: yes
minute-level datetime exposed in static capture: no
cursor decision: date + announcementId
```

## Captured rows

### Row 1

```text
source_url_or_request_shape: CNInfo latest announcement row + official PDF
announcement_id: 1225274841
announcement_date: 2026-05-01
announcement_datetime_local: 2026-05-01T00:00:00+08:00 date-only convention
published_at_utc: 2026-04-30T16:00:00.000000Z
sec_code: 603660
sec_name: 苏州科达
company_name: 苏州科达
announcement_title: 关于公司股东协议转让股份过户完成的公告
announcement_type: unknown
announcement_type_name: unknown
org_id: 9900026447
detail_url: https://www.cninfo.com.cn/new/disclosure/detail?announcementId=1225274841&announcementTime=2026-05-01&orgId=9900026447&stockCode=603660
adjunct_url: finalpage/2026-05-01/1225274841.PDF
pdf_url: https://static.cninfo.com.cn/finalpage/2026-05-01/1225274841.PDF
stable_external_id: CNINFO:603660:20260501:1225274841
cursor_value: 2026-05-01|1225274841
candidate_event_family: ownership_change_update
candidate_canonical_event_type: major_shareholding_or_insider_trade
```

### Row 2

```text
source_url_or_request_shape: CNInfo latest announcement row + official PDF
announcement_id: 1225274838
announcement_date: 2026-05-01
announcement_datetime_local: 2026-05-01T00:00:00+08:00 date-only convention
published_at_utc: 2026-04-30T16:00:00.000000Z
sec_code: 603350
sec_name: 安乃达
company_name: 安乃达
announcement_title: 2025年年度股东会决议公告
announcement_type: unknown
announcement_type_name: unknown
org_id: gfbj0839807
detail_url: https://www.cninfo.com.cn/new/disclosure/detail?announcementId=1225274838&announcementTime=2026-05-01&orgId=gfbj0839807&stockCode=603350
adjunct_url: finalpage/2026-05-01/1225274838.PDF
pdf_url: https://static.cninfo.com.cn/finalpage/2026-05-01/1225274838.PDF
stable_external_id: CNINFO:603350:20260501:1225274838
cursor_value: 2026-05-01|1225274838
candidate_event_family: shareholder_meeting_update
candidate_canonical_event_type: shareholder_meeting
```

### Row 3

```text
source_url_or_request_shape: CNInfo latest announcement row + official PDF
announcement_id: 1225274454
announcement_date: 2026-05-01
announcement_datetime_local: 2026-05-01T00:00:00+08:00 date-only convention
published_at_utc: 2026-04-30T16:00:00.000000Z
sec_code: 300376
sec_name: 易事特
company_name: 易事特
announcement_title: 关于公司董事会换届选举的公告
announcement_type: unknown
announcement_type_name: unknown
org_id: GD025312
detail_url: https://www.cninfo.com.cn/new/disclosure/detail?announcementId=1225274454&announcementTime=2026-05-01&orgId=GD025312&stockCode=300376
adjunct_url: finalpage/2026-05-01/1225274454.PDF
pdf_url: https://static.cninfo.com.cn/finalpage/2026-05-01/1225274454.PDF
stable_external_id: CNINFO:300376:20260501:1225274454
cursor_value: 2026-05-01|1225274454
candidate_event_family: board_change_update
candidate_canonical_event_type: board_or_management_change
```

## Identity rule validated

Frozen broad stable id shape:

```text
CNINFO:<stockCode>:<YYYYMMDD>:<announcementId>
```

Every sample row has a stable id that does not use title text.

## Cursor rule validated

Frozen broad cursor shape:

```text
<YYYY-MM-DD>|<announcementId>
```

Minute-level `announcementTime` is not exposed in the static latest-row/detail capture. The broad v1 fixture uses date plus `announcementId` as a deterministic cursor. A future live API path may upgrade to datetime if official row JSON exposes minute precision.

## Family policy

The captured sample set covers a small controlled corporate-action/governance-style CNInfo set:

```text
ownership_change_update
shareholder_meeting_update
board_change_update
```

Do not implement all CNInfo categories at once.

## Freeze pass criteria

- [x] 2-3 official CNInfo rows captured
- [x] stable announcementId for every row
- [x] date/datetime for every row
- [x] issuer/security code for every row
- [x] PDF/document path for every row if primary document required
- [x] cursor orders rows without title text
- [x] family scope is narrow and explicit
- [x] locked CNInfo ownership-change semantics remain unchanged

## Freeze decision

```text
freeze
```
