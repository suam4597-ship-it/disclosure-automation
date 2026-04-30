# CNInfo ownership-change contract-freeze close-out

This document freezes the first CN implementation contract after the CN discovery-first and CNInfo preflight docs.

This is still a docs-only close-out. It does not add runtime code, sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Freeze status

- source contract: frozen
- first family: frozen
- first deterministic sample: frozen
- runtime implementation: not started
- next PR: isolated runtime implementation

## Current locked baseline

Keep these locked:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information

## Chosen source

- source key: `cn_cninfo_ownership_change`
- display name: `China CNInfo Ownership Change Announcements`
- region code: `cn`
- source type: `api`
- source class: `regulatory_filing_feed`
- source tier: `official_exchange_storage`
- operator/source owner: `Shenzhen Securities Information Co., Ltd.`
- source platform: `CNInfo / 巨潮资讯网`

## Source authority rationale

CNInfo public pages describe CNInfo as the statutory information disclosure platform of the Shenzhen Stock Exchange and say it is operated by Shenzhen Securities Information Co., Ltd., a wholly owned subsidiary of the Shenzhen Stock Exchange.

CNInfo public disclosure pages also state that listed-company announcement content in the disclosure column is provided by listed companies.

## Chosen first family

- event family: `ownership_change_update`
- canonical event type: `major_shareholding_or_insider_trade`

## Why this family won

The original provisional CN ranking preferred M&A/restructuring if it could be isolated cleanly. The CNInfo sample inspection produced a cleaner ownership-change candidate first:

- public official source surface is available
- stable PDF artefact id is visible
- listed-company issuer/security code is visible
- announcement date is visible
- one ownership-change disclosure can be isolated without broad all-disclosures ingestion
- the family maps naturally to existing ownership/shareholding semantics already locked for AFM/SEC-style work

## Chosen sample

- company / issuer: `长虹华意压缩机股份有限公司`
- security code: `000404`
- security short name: `长虹华意`
- announcement number: `2026-019`
- title: `关于公司部分董事和高级管理人员增持公司股份计划时间过半的进展公告`
- publication date local: `2026-03-30`
- publication datetime local: `2026-03-30T00:00:00+08:00`
- publication datetime UTC: `2026-03-29T16:00:00.000000Z`
- announcement id / PDF artefact id: `1225049497`
- PDF path: `finalpage/2026-03-30/1225049497.PDF`
- PDF URL: `https://static.cninfo.com.cn/finalpage/2026-03-30/1225049497.PDF`

## Source fact summary

The PDF states:

- the company previously disclosed a share-increase plan on `2026-02-05`
- the plan was halfway through as of `2026-03-28`
- participating directors and senior managers had increased shares by total amount RMB `247.62` ten-thousand yuan
- the share-increase plan had not yet completed

## Runtime contract

- adapter key: `cn_cninfo_ownership_change_v1`
- parser strategy: `CNInfo announcement query row + CNInfo static PDF attachment parser`
- discovery mode: `cninfo_announcement_query_fixture`
- hydrate mode: `cninfo_pdf_attachment`
- cursor key: `latest_announcement_date_and_announcement_id_seen`
- cursor value shape: `<YYYY-MM-DD>|<announcementId>`
- frozen cursor value: `2026-03-30|1225049497`

## Why date-only cursor is frozen

The preflight candidate preferred `announcementTime` from the CNInfo query JSON row.
In this close-out, the frozen first slice uses a date-only cursor because the public evidence available for the chosen sample consistently exposes the announcement date and stable PDF artefact id, while exact millisecond `announcementTime` was not captured in the docs.

For v0, `publication_date + announcement_id` is deterministic enough for one isolated fixture item.
A later broad or live CNInfo ingestion may upgrade to `announcementTime_ms + announcementId` after live API row capture.

## Identity rules

- stable external identity rule: `CNINFO:<announcementId>`
- stable external identity sample value: `CNINFO:1225049497`
- raw event key seed: `CNINFO:1225049497`
- duplicate group seed: `CNINFO:1225049497`
- canonical event id: `cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497`

## Raw document identity rules

### Discovery row

- raw document external id: `CNINFO:1225049497:discovery-row`
- document identity: `CNINFO:1225049497:discovery-row`
- document role: `discovery_metadata`
- MIME type: `application/json`

### PDF attachment

- raw document external id: `CNINFO:1225049497:pdf:1225049497`
- document identity: `CNINFO:1225049497:pdf:1225049497`
- document role: `primary_regulatory_disclosure`
- MIME type: `application/pdf`

## Minimum raw-document set

Use two raw documents for the v0 isolated lock:

1. one synthetic discovery JSON row derived from the public source metadata for the chosen sample
2. one PDF attachment fixture for `finalpage/2026-03-30/1225049497.PDF`

Do not require a separate detail page for v0. The PDF is the primary regulatory disclosure document.

## Source-appropriate canonical item source names

- official storage name: `CNInfo / 巨潮资讯网`
- official source name: `CNInfo Listed Company Announcement Disclosure`
- discovery source name: `CNInfo announcement metadata row`
- primary disclosure document source name: `CNInfo static PDF attachment`

## Expected normalized values

```text
source_key: cn_cninfo_ownership_change
adapter_key: cn_cninfo_ownership_change_v1
region_code: cn
source_tier: official_exchange_storage
stable_external_id: CNINFO:1225049497
cursor_key: latest_announcement_date_and_announcement_id_seen
cursor_value: 2026-03-30|1225049497
event_id: cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497
event_family: ownership_change_update
canonical_event_type: major_shareholding_or_insider_trade
published_at_local: 2026-03-30T00:00:00+08:00
published_at_utc: 2026-03-29T16:00:00.000000Z
filing_date_local: 2026-03-30
```

## Later implementation PR guardrail

The next PR may create runtime code only for this one frozen source and one fixture item.

Do not add:

- CN broad all-disclosures ingestion
- CN multiple-family implementation
- SSE/SZSE/BSE separate adapters
- JP
- news overlay
- cross-source merge

## Close-out result

CN contract-freeze is complete for:

```text
cn_cninfo_ownership_change
```

Next step:

```text
CNInfo ownership-change isolated runtime implementation PR
```
