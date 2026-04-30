# CN contract-freeze exit criteria

This document defines when the CN discovery-first stage may move to isolated runtime implementation.

## Exit condition

The CN work may leave discovery-freeze only when one source and one family satisfy all of the following:

1. the official public discovery surface is identified
2. the source tier is classified as `official_regulatory_storage` or `official_exchange_storage`
3. one first high-signal family is chosen
4. one deterministic public sample is captured or precisely specified for fixture capture
5. one stable external identity is visible in discovery, detail, or attachment metadata
6. one cursor key can be frozen without relying on title text only
7. one canonical event mapping is chosen
8. the minimum raw-document set is small enough for an isolated first lock
9. local/UTC publication timestamp rules are explicit or explicit date-only handling is documented
10. the future runtime workset remains one source, one family, one fixture item

## Current freeze candidate

The current freeze candidate satisfies the discovery-freeze package requirements, with one timestamp caveat to resolve during implementation verification.

- chosen source: `CNInfo / 巨潮资讯网`
- source key: `cn_cninfo_disclosure_announcements`
- display name: `China CNInfo Disclosure Announcements`
- region code: `cn`
- source class: `regulatory_filing_feed`
- source tier: `official_regulatory_storage`
- adapter key: `cn_cninfo_disclosure_announcements_v1`
- parser strategy: `CNInfo list/detail metadata parser + static PDF text parser`
- discovery mode: `cninfo_disclosure_list_fixture`
- hydrate mode: `cninfo_detail_page_and_static_pdf`
- cursor key: `latest_announcement_time_and_announcement_id_seen`
- cursor value shape: `<announcementTime>|<announcementId>|<stockCode>`
- stable external identity rule: `CNINFO:<announcementId>`
- stable external identity sample value: `CNINFO:1222441277`
- raw document external id rule: `CNINFO:<announcementId>:<document_role>`
- document identity rule: `CNINFO:<announcementId>:<document_role>`
- raw event key seed: `cninfo:<announcementId>`
- duplicate group seed: `CNINFO:<announcementId>`
- first event family: `major_asset_transaction_update`
- first canonical event type: `major_investment_or_asset_sale`
- minimum raw-document set: `discovery row + detail page + static PDF`
- source-appropriate canonical item source names:
  - `CNInfo Disclosure List/Search Row`
  - `CNInfo Disclosure Detail Page`
  - `CNInfo Static PDF Disclosure Artifact`

## Chosen sample candidate

- sample company / issuer: `大连华锐重工集团股份有限公司`
- sample security code: `002204`
- sample title: `关于挂牌转让大重宾馆资产的进展公告`
- sample source category: `asset transaction / asset disposal progress update candidate`
- sample publication datetime local: `2025-01-27` date-only source value
- sample publication datetime UTC: implementation must either keep date-only metadata or explicitly normalize Asia/Shanghai start-of-day to `2025-01-26T16:00:00Z`
- sample detail URL: `https://www.cninfo.com.cn/new/disclosure/detail?plate=szse&orgId=9900004001&stockCode=002204&announcementId=1222441277&announcementTime=2025-01-27`
- sample attachment URL: `https://static.cninfo.com.cn/finalpage/2025-01-27/1222441277.PDF`

## Remaining implementation-time caveat

CNInfo sample pages often expose `announcementTime` as a date-only value.
The later runtime PR must choose and test one of these approaches:

1. preserve source date-only semantics in metadata and use the filing date for deterministic identity, or
2. normalize date-only values to Asia/Shanghai start-of-day only after documenting that fallback.

Do not silently pretend the source provided an intraday publication timestamp.

## Disqualifiers for any replacement sample

Reject a replacement source or family if any of the following holds:

- public search cannot isolate it without broad ambiguity
- no stable public id, URL token, document id, or artefact id is visible
- cursor semantics require title-text heuristics
- the family is too broad for one deterministic fixture item
- the raw-document set requires many unrelated pages or attachments
- the source cannot be classified as official-regulatory or official-exchange storage

## Promotion rule if CNInfo fails fixture capture

Promote one of the exchange-specific source surfaces only if CNInfo cannot be captured deterministically:

1. SSE official exchange source for an SSE-listed issuer
2. SZSE official exchange source for an SZSE-listed issuer
3. BSE official exchange source for a BSE-listed issuer

Do not promote broad CN all-disclosures ingestion.

## Implementation boundary

Cross the phase boundary for one family only.
Do not open runtime code for two CN first-slice families in the same PR.

## Runtime PR can start after this PR if

The next runtime PR may start from this candidate only if it stays limited to:

- one source: `cn_cninfo_disclosure_announcements`
- one family: `major_asset_transaction_update`
- one canonical type: `major_investment_or_asset_sale`
- one fixture item: `CNINFO:1222441277`
- one raw-document set: discovery row, detail page, static PDF
- one timestamp rule, explicitly tested
