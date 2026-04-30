# CNInfo ownership-change candidate contract v0

This document narrows CN discovery to one candidate source and one candidate first family.

It is not a runtime contract lock yet because the exact CNInfo query JSON row still needs to be captured.

## Candidate contract status

- status: `candidate_pre_freeze`
- runtime implementation allowed: `no`
- fixtures allowed: `no`
- tests allowed: `no`
- sample YAML allowed: `no`

## Source identity

- source key: `cn_cninfo_ownership_change`
- display name: `China CNInfo Ownership Change Announcements`
- region code: `cn`
- source type: `api`
- source class: `regulatory_filing_feed`
- source tier: `official_exchange_storage`
- operator/source owner candidate: `Shenzhen Securities Information Co., Ltd.`
- official platform rationale: CNInfo publicly describes itself as the Shenzhen Stock Exchange statutory information disclosure platform operated by a Shenzhen Stock Exchange wholly owned subsidiary.

## Discovery surface

- public discovery page: `https://www.cninfo.com.cn/new/commonUrl?url=disclosure/list/notice`
- public search page: `https://www.cninfo.com.cn/new/commonUrl/pageOfSearch?lastPage=index&url=disclosure/list/search`
- query endpoint candidate: `https://www.cninfo.com.cn/new/hisAnnouncement/query`
- detail URL shape candidate: `https://www.cninfo.com.cn/new/disclosure/detail?announcementId=<announcementId>`
- attachment URL shape candidate: `https://static.cninfo.com.cn/<adjunctUrl>`

## Runtime contract candidate

- adapter key: `cn_cninfo_ownership_change_v1`
- parser strategy: `CNInfo announcement query JSON row + CNInfo PDF attachment parser`
- discovery mode: `cninfo_his_announcement_query_fixture`
- hydrate mode: `cninfo_detail_page_and_pdf_attachment`
- cursor key: `latest_announcement_time_ms_and_announcement_id_seen`
- cursor value shape: `<announcementTime_ms>|<announcementId>`

If `announcementTime` cannot be captured with millisecond precision, use this fallback only after documenting why:

- fallback cursor key: `latest_announcement_date_and_announcement_id_seen`
- fallback cursor value shape: `<YYYY-MM-DD>|<announcementId>`

## Identity rules

- stable external identity rule: `CNINFO:<announcementId>`
- stable external identity sample value: `CNINFO:1225049497`
- raw event key seed: `CNINFO:1225049497`
- duplicate group seed: `CNINFO:1225049497`
- canonical event id shape: `cn.cninfo.<secCode>.<YYYYMMDD>.major_shareholding_or_insider_trade.ownership_change_update.<announcementId>`

## Raw document identity candidates

### Discovery row

- raw document external id rule: `CNINFO:<announcementId>:discovery-row`
- document identity rule: `CNINFO:<announcementId>:discovery-row`
- document role: `discovery_metadata`
- MIME type: `application/json`

### Detail page

- raw document external id rule: `CNINFO:<announcementId>:detail-page`
- document identity rule: `CNINFO:<announcementId>:detail-page`
- document role: `source_detail_page`
- MIME type: `text/html`

### PDF attachment

- raw document external id rule: `CNINFO:<announcementId>:pdf:<pdf-id>`
- document identity rule: `CNINFO:<announcementId>:pdf:<pdf-id>`
- document role: `primary_regulatory_disclosure`
- MIME type: `application/pdf`

## First thin-slice scope candidate

- event family: `ownership_change_update`
- canonical event type: `major_shareholding_or_insider_trade`
- expected first fixture item count: `1`
- expected raw document count per item: `2` or `3`
  - `2` if discovery row + PDF are sufficient
  - `3` if detail page is required as a separate hydrate artefact
- expected canonical item source count per item: `2`

## Candidate sample facts

- sample company / issuer: `长虹华意压缩机股份有限公司`
- sample security code: `000404`
- sample security short name: `长虹华意`
- sample title: `关于公司部分董事和高级管理人员增持公司股份计划时间过半的进展公告`
- sample announcement number: `2026-019`
- sample source category: ownership / insider or director/senior-management share increase progress
- sample publication date local: `2026-03-30`
- sample publication datetime local: `TODO_API_RESPONSE_REQUIRED`
- sample publication datetime UTC: `TODO_API_RESPONSE_REQUIRED`
- sample announcement id: `1225049497`
- sample PDF URL: `https://static.cninfo.com.cn/finalpage/2026-03-30/1225049497.PDF`

## Source-appropriate canonical item source names

- official storage name: `CNInfo / 巨潮资讯网`
- official source name: `CNInfo Listed Company Announcement Query`
- discovery source name: `CNInfo announcement query JSON row`
- primary disclosure document source name: `CNInfo static PDF attachment`

## Fixture plan for later implementation PR

Do not create these paths in this candidate PR.

- isolated sample YAML path: `apps/backend/disclosure_api/priv/config_samples/source_registry.cn_cninfo_ownership_change.sample.yaml`
- discovery fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_ownership_change_discovery_000404_20260330_1225049497.json`
- detail fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_ownership_change_detail_000404_20260330_1225049497.html`
- PDF fixture path: `apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_ownership_change_pdf_000404_20260330_1225049497.pdf`
- source helper path: `apps/backend/disclosure_api/lib/disclosure_automation/ops/cn_cninfo_ownership_change_source.ex`
- adapter path: `apps/backend/disclosure_api/lib/disclosure_automation/runtime/cn_cninfo_ownership_change_adapter.ex`
- isolated server runner path: `apps/backend/disclosure_api/priv/ops/run_cn_cninfo_ownership_change_server.exs`
- dedupe SQL path: `apps/backend/disclosure_api/priv/ops/cn_cninfo_ownership_change_dedupe_checks.sql`
- runtime idempotency test path: `apps/backend/disclosure_api/test/cn_cninfo_ownership_change_runtime_idempotency_test.exs`
- HTTP smoke test path: `apps/backend/disclosure_api/test/cn_cninfo_ownership_change_http_smoke_test.exs`

## Remaining blocker before freeze

Capture and record the exact CNInfo query JSON row for `announcementId = 1225049497`, including:

- `announcementId`
- `announcementTitle`
- `announcementTime`
- `secCode`
- `secName`
- `announcementType` or `announcementTypeName`
- `adjunctUrl`
- `adjunctType`
- `columnId` or `pageColumn`
- any source-side category fields

Without the exact JSON row, the candidate contract must not advance to runtime implementation.
