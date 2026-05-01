# CNInfo broad expansion sample capture sheet

Use this sheet to capture the controlled CNInfo sample set required before broad CNInfo expansion can be implemented.

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

Preferred broad lane:

```text
source: CNInfo announcement query
scope: controlled CNInfo rows
family scope: one additional family or small controlled family set
identity: CNINFO:<announcementId>
cursor: announcement datetime/date + announcementId
```

## Required sample set

Capture 2-3 official CNInfo rows.

Preferred sample shape:

```text
row_count: 2 or 3
same source endpoint/surface: yes
same family if possible: yes
stable announcementId for every row: yes
announcement date or datetime for every row: yes
security code / issuer visible for every row: yes
PDF/document path or attachment URL for every row: yes
```

Do not capture broad batches.

## Row capture template

### Row 1

```text
source_url_or_request_shape: TODO
announcement_id: TODO
announcement_date: TODO
announcement_datetime_local: TODO or date-only
published_at_utc: TODO
sec_code: TODO
sec_name: TODO
company_name: TODO
announcement_title: TODO
announcement_type: TODO or unknown
announcement_type_name: TODO or unknown
adjunct_url: TODO
pdf_url: TODO
stable_external_id: TODO
cursor_value: TODO
candidate_event_family: TODO
candidate_canonical_event_type: TODO
```

### Row 2

```text
source_url_or_request_shape: TODO
announcement_id: TODO
announcement_date: TODO
announcement_datetime_local: TODO or date-only
published_at_utc: TODO
sec_code: TODO
sec_name: TODO
company_name: TODO
announcement_title: TODO
announcement_type: TODO or unknown
announcement_type_name: TODO or unknown
adjunct_url: TODO
pdf_url: TODO
stable_external_id: TODO
cursor_value: TODO
candidate_event_family: TODO
candidate_canonical_event_type: TODO
```

### Row 3, optional

```text
source_url_or_request_shape: TODO
announcement_id: TODO
announcement_date: TODO
announcement_datetime_local: TODO or date-only
published_at_utc: TODO
sec_code: TODO
sec_name: TODO
company_name: TODO
announcement_title: TODO
announcement_type: TODO or unknown
announcement_type_name: TODO or unknown
adjunct_url: TODO
pdf_url: TODO
stable_external_id: TODO
cursor_value: TODO
candidate_event_family: TODO
candidate_canonical_event_type: TODO
```

## Identity rule to validate

Preferred stable id shape:

```text
CNINFO:<announcementId>
```

Every sample row must have a stable id that does not use title text.

## Cursor rule to validate

Preferred broad cursor shape:

```text
<YYYY-MM-DDTHH:MM:SS+08:00>|<announcementId>
```

Fallback for date-only rows:

```text
<YYYY-MM-DD>|<announcementId>
```

Do not mutate the locked ownership-change cursor unless a compatibility migration is explicitly planned.

## Family policy

Choose exactly one first broad CN path:

```text
additional CNInfo family, one family only
or controlled CNInfo rows that all map to a stable canonical family set
```

Do not implement all CNInfo announcement categories at once.

## Freeze pass criteria

- [ ] 2-3 official CNInfo rows captured
- [ ] stable announcementId for every row
- [ ] date/datetime for every row
- [ ] issuer/security code for every row
- [ ] PDF/document path for every row if primary document required
- [ ] cursor orders rows without title text
- [ ] family scope is narrow and explicit
- [ ] locked CNInfo ownership-change semantics remain unchanged

## Freeze decision

```text
TODO: freeze / no-go / retry capture
```
