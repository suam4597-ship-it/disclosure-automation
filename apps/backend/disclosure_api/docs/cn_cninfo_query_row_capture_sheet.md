# CNInfo query row capture sheet

Use this sheet to capture the exact CNInfo query JSON row before closing the CN contract-freeze.

Do not create runtime files from this sheet alone.

## Target sample

- target source candidate: `CNInfo / 巨潮资讯网`
- target source key candidate: `cn_cninfo_ownership_change`
- target first family candidate: `ownership_change_update`
- target canonical event type candidate: `major_shareholding_or_insider_trade`
- target announcement id candidate: `1225049497`
- target security code: `000404`
- target security short name: `长虹华意`
- target title: `关于公司部分董事和高级管理人员增持公司股份计划时间过半的进展公告`
- target PDF URL: `https://static.cninfo.com.cn/finalpage/2026-03-30/1225049497.PDF`

## Query endpoint candidate

```text
https://www.cninfo.com.cn/new/hisAnnouncement/query
```

## Candidate request parameters

These parameters are candidates and must be verified during source inspection.

```text
pageNum=1
pageSize=30
column=szse
tabName=fulltext
stock=000404,gssz0000404
searchkey=增持公司股份计划时间过半
seDate=2026-03-30~2026-03-30
isHLtitle=true
```

If the row does not return with the candidate request, inspect the public CNInfo UI request payload and record the exact working parameters below.

## Exact working request

Fill after live inspection:

```text
method: TODO
url: TODO
headers required: TODO
form/body/query params: TODO
response status: TODO
captured at: TODO
```

## Exact JSON row

Paste the exact row for `announcementId = 1225049497` here.

```json
{
  "announcementId": "TODO",
  "announcementTitle": "TODO",
  "announcementTime": "TODO",
  "secCode": "TODO",
  "secName": "TODO",
  "announcementType": "TODO",
  "announcementTypeName": "TODO",
  "adjunctUrl": "TODO",
  "adjunctType": "TODO",
  "adjunctSize": "TODO",
  "columnId": "TODO",
  "pageColumn": "TODO",
  "orgId": "TODO"
}
```

Do not fill unknown fields with guessed values.
Remove fields only if the source response truly does not provide them.

## Derived contract values

Fill only after the exact JSON row is captured.

### Stable external identity

```text
stable_external_id = CNINFO:<announcementId>
```

Expected candidate:

```text
CNINFO:1225049497
```

### Cursor

Preferred cursor:

```text
cursor_key = latest_announcement_time_ms_and_announcement_id_seen
cursor_value = <announcementTime_ms>|<announcementId>
```

Fill after capture:

```text
cursor_value = TODO
```

### Local publication datetime

Fill after capture:

```text
published_at_local = TODO
```

### UTC publication datetime

Fill after capture:

```text
published_at_utc = TODO
```

### Event id

Candidate shape:

```text
cn.cninfo.<secCode>.<YYYYMMDD>.major_shareholding_or_insider_trade.ownership_change_update.<announcementId>
```

Fill after capture:

```text
event_id = TODO
```

## Required validation before freeze

Before the CNInfo ownership-change contract can be frozen, verify:

- the row `announcementId` equals `1225049497`
- the row `secCode` equals `000404`
- the row title matches the target title or source-normalized title
- `adjunctUrl` resolves to `finalpage/2026-03-30/1225049497.PDF` or an equivalent stable source path
- `announcementTime` is present and can produce a deterministic cursor
- the detail page for `announcementId = 1225049497` is stable, or the contract documents why the PDF is the primary hydrate artefact

## If announcementTime is missing

Use the fallback only after documenting evidence:

```text
cursor_key = latest_announcement_date_and_announcement_id_seen
cursor_value = 2026-03-30|1225049497
```

Fallback use requires documenting why millisecond `announcementTime` is unavailable or unstable.

## Guardrail

If this sheet cannot be completed with public-source evidence, do not open CN runtime implementation.
Return to source discovery and choose a different sample or source surface.
