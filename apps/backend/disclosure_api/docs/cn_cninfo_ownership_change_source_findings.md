# CNInfo ownership-change source findings

This document records the first concrete CN source/family candidate after the CN discovery-first kickoff.

It is still a candidate-finding document, not runtime implementation.
Do not add CN runtime code, fixtures, tests, ops runner, sample YAML, or dedupe SQL from this document alone.

## Candidate recommendation

Recommended next contract-freeze candidate:

- source: `CNInfo / 巨潮资讯网`
- first family: `shareholding / ownership change / director and senior-management share increase/decrease updates`
- sample class: director/senior-management share-increase plan progress announcement

## Why CNInfo is the current preferred candidate

CNInfo is a strong first source candidate because the public site identifies itself as Shenzhen Stock Exchange's statutory information disclosure platform and says it is operated by Shenzhen Securities Information Co., Ltd., a wholly owned subsidiary of the Shenzhen Stock Exchange.

Observed public source facts:

- CNInfo home/latest-announcement pages expose latest listed-company announcements with company code, company short name, title, and date.
- CNInfo public disclosure page exposes latest announcements and says the column content is provided by listed companies.
- CNInfo footer/about text says CNInfo is the statutory information disclosure platform of the Shenzhen Stock Exchange and is operated by Shenzhen Securities Information Co., Ltd.
- CNInfo links include Shenzhen Stock Exchange, Shanghai Stock Exchange, and Shenzhen Securities Information Co., Ltd.

## Candidate source identity

- source key: `cn_cninfo_ownership_change`
- display name: `China CNInfo Ownership Change Announcements`
- region code: `cn`
- source class: `regulatory_filing_feed`
- source tier candidate: `official_exchange_storage`
- source owner/operator candidate: `Shenzhen Securities Information Co., Ltd.`
- exchange backing candidate: `Shenzhen Stock Exchange wholly owned subsidiary operator`

## Candidate source surfaces

### Discovery page

```text
https://www.cninfo.com.cn/new/commonUrl?url=disclosure/list/notice
```

Use this as the human/public latest-announcements surface.

### Query endpoint candidate

```text
https://www.cninfo.com.cn/new/hisAnnouncement/query
```

Use this only as a candidate runtime discovery endpoint until verified directly in a later contract-freeze close-out.

Candidate fields expected from the query JSON based on public technical inspection:

- `announcementId`
- `announcementTitle`
- `announcementTime`
- `secCode`
- `secName`
- `announcementType`
- `announcementTypeName`
- `adjunctUrl`
- `adjunctType`
- `adjunctSize`
- `columnId`
- `pageColumn`
- `orgId`

### Detail page candidate

```text
https://www.cninfo.com.cn/new/disclosure/detail?announcementId=<announcementId>
```

### Attachment/PDF candidate

```text
https://static.cninfo.com.cn/<adjunctUrl>
```

For the candidate sample below, the observed static PDF URL is:

```text
https://static.cninfo.com.cn/finalpage/2026-03-30/1225049497.PDF
```

## Candidate sample

Observed deterministic sample:

- company / issuer: `长虹华意压缩机股份有限公司`
- sec code: `000404`
- sec name: `长虹华意`
- announcement number: `2026-019`
- title: `关于公司部分董事和高级管理人员增持公司股份计划时间过半的进展公告`
- source date: `2026-03-30`
- PDF artefact id candidate: `1225049497`
- PDF URL: `https://static.cninfo.com.cn/finalpage/2026-03-30/1225049497.PDF`

The PDF text states that the company previously disclosed a share-increase plan on `2026-02-05`, that the plan is halfway through as of `2026-03-28`, and that participating directors/senior managers had increased shares by a total of RMB `247.62` ten-thousand yuan.

## Candidate first family mapping

- event family: `ownership_change_update`
- canonical event type: `major_shareholding_or_insider_trade`

Rationale:

- The announcement concerns director/senior-management share-increase activity.
- The subject is ownership/insider-related rather than broad periodic reporting.
- It maps closer to the already locked AFM/SEC ownership semantics than to M&A/restructuring.

## Stable identity candidate

Preferred rule:

```text
CNINFO:<announcementId>
```

Candidate sample value:

```text
CNINFO:1225049497
```

Fallback if API metadata does not expose `announcementId` cleanly:

```text
CNINFO:PDF:<finalpage-date>:<pdf-id>
```

Candidate fallback sample:

```text
CNINFO:PDF:2026-03-30:1225049497
```

Do not use the title as the stable identity.

## Cursor candidate

Preferred cursor key:

```text
latest_announcement_time_ms_and_announcement_id_seen
```

Preferred cursor shape:

```text
<announcementTime_ms>|<announcementId>
```

Candidate sample value:

```text
TODO_API_RESPONSE_REQUIRED|1225049497
```

The exact `announcementTime` millisecond value must be captured from the CNInfo query JSON before contract-freeze is closed.

Date-only fallback if the public response exposes date but not time:

```text
latest_announcement_date_and_announcement_id_seen
2026-03-30|1225049497
```

Use the date-only fallback only if the API cannot provide `announcementTime`.

## Minimum raw-document set candidate

Preferred minimum set:

1. discovery JSON row for `announcementId = 1225049497`
2. detail page for `announcementId = 1225049497`, if stable and fetchable
3. PDF attachment `finalpage/2026-03-30/1225049497.PDF`

If the discovery JSON row and PDF are sufficient, the detail page can be source metadata rather than a required canonical fact source.

## Blocking item before freeze

The candidate is nearly freeze-ready, but one field remains unresolved:

```text
Exact CNInfo query JSON row for announcementId 1225049497, including announcementTime.
```

Do not open runtime implementation until that row is captured and stored in the contract-freeze docs.
