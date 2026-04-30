# CN contract template

This template now records the candidate CNInfo first-slice contract from source-surface inspection.
Do not treat this as a runtime lock until the later isolated runtime PR verifies it with fixtures, tests, smoke, and dedupe SQL.

## Source identity

- source key: `cn_cninfo_disclosure_announcements`
- display name: `China CNInfo Disclosure Announcements`
- region code: `cn`
- source type: `api_or_html_archive`
- source class: `regulatory_filing_feed`
- source tier: `official_regulatory_storage`

## Discovery surface

- primary discovery surface: `https://www.cninfo.com.cn/new/commonUrl?url=disclosure%2Flist%2Fnotice`
- search surface: `https://www.cninfo.com.cn/new/commonUrl/pageOfSearch?lastPage=index&url=disclosure%2Flist%2Fsearch`
- authoritative detail/archive surface: `https://www.cninfo.com.cn/new/disclosure/detail?...&announcementId=<announcementId>&announcementTime=<announcementTime>`
- primary disclosure artifact surface: `https://static.cninfo.com.cn/finalpage/<YYYY-MM-DD>/<announcementId>.PDF`
- whether a CSV/export/API path exists: `not required for v0; public list/detail/PDF capture is enough for first fixture`
- whether a detail page is stable and directly fetchable: `candidate yes; uses announcementId, announcementTime, orgId, stockCode, and plate query params`
- whether an attachment/PDF is required for canonical facts: `yes for v0; PDF is the primary regulatory disclosure artifact`
- whether category/family filters are deterministic: `candidate yes for search/list classification, but the v0 fixture should still lock one exact announcementId only`

## Runtime contract

- adapter key: `cn_cninfo_disclosure_announcements_v1`
- parser strategy: `CNInfo list/detail metadata parser + static PDF text parser`
- discovery mode: `cninfo_disclosure_list_fixture`
- hydrate mode: `cninfo_detail_page_and_static_pdf`
- cursor key: `latest_announcement_time_and_announcement_id_seen`
- cursor value shape: `<announcementTime>|<announcementId>|<stockCode>`

## Identity rules

- stable external identity rule: `CNINFO:<announcementId>`
- stable external identity sample value: `CNINFO:1222441277`
- raw document external id rule: `CNINFO:<announcementId>:<document_role>`
- document identity rule: `CNINFO:<announcementId>:<document_role>`
- raw event key seed: `cninfo:<announcementId>`
- duplicate group seed: `CNINFO:<announcementId>`
- canonical event id shape: `cn.cninfo.<stockCode>.<announcementTime>.<canonical_event_type>.<event_family>.<announcementId>`

## First thin-slice scope

Freeze one family only:

- event family: `major_asset_transaction_update`
- canonical event type: `major_investment_or_asset_sale`
- expected first fixture item count: `1`
- expected raw document count per item: `3`
- expected canonical item source count per item: `3`

## Sample facts to capture

- sample company / issuer: `大连华锐重工集团股份有限公司`
- sample security code: `002204`
- sample title: `关于挂牌转让大重宾馆资产的进展公告`
- sample source category: `asset transaction / asset disposal progress update candidate`
- sample publication datetime local: `2025-01-27` date-only source value
- sample publication datetime UTC: `2025-01-26T16:00:00Z` only if v0 normalizes date-only China local date to start-of-day Asia/Shanghai; otherwise keep date-only in metadata and defer exact UTC event timestamp to implementation review
- sample detail URL: `https://www.cninfo.com.cn/new/disclosure/detail?plate=szse&orgId=9900004001&stockCode=002204&announcementId=1222441277&announcementTime=2025-01-27`
- sample attachment URL if required: `https://static.cninfo.com.cn/finalpage/2025-01-27/1222441277.PDF`

## Source-appropriate canonical item source names

- official storage name: `CNInfo / 巨潮资讯网`
- official source name: `CNInfo Disclosure Detail Page`
- discovery source name: `CNInfo Disclosure List/Search Row`
- primary disclosure document source name: `CNInfo Static PDF Disclosure Artifact`

## Fixture plan for later implementation PR

Do not create these paths in this discovery/contract-freeze PR.
Record the intended later paths here after contract freeze:

- isolated sample YAML path: `apps/backend/disclosure_api/priv/config_samples/source_registry.cn_cninfo_disclosure_announcements.sample.yaml`
- fixture payload path(s):
  - `apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_disclosure_announcements_list_002204_20250127_1222441277.html`
  - `apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_disclosure_announcements_detail_002204_20250127_1222441277.html`
  - `apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_disclosure_announcements_pdf_002204_20250127_1222441277.pdf`
- bootstrap script path: `TODO only if needed`
- isolated server runner path: `apps/backend/disclosure_api/priv/ops/run_cn_cninfo_disclosure_announcements_server.exs`
- dedupe SQL path: `apps/backend/disclosure_api/priv/ops/cn_cninfo_disclosure_announcements_dedupe_checks.sql`
- runtime idempotency test path: `apps/backend/disclosure_api/test/cn_cninfo_disclosure_announcements_runtime_idempotency_test.exs`
- HTTP smoke test path: `apps/backend/disclosure_api/test/cn_cninfo_disclosure_announcements_http_smoke_test.exs`

## Verification target for later lock PR

Lock only after all of the following are explicit and green:

- exact `event_id`
- exact `event_family`
- exact `canonical_event_type`
- exact local/UTC published time rules or explicit date-only handling
- repeated poll idempotency
- dedupe SQL clean
- source health healthy
- cursor key/value present
- three raw documents created exactly once each
