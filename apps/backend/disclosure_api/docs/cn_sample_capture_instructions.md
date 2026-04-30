# CN sample capture instructions

These instructions record the CNInfo sample selected during the first CN source-surface inspection pass.

This discovery/contract-freeze PR must not add the sample YAML, fixtures, runtime adapter, tests, ops runner, or dedupe SQL.

## Capture goal

Capture exactly one public disclosure sample that can support a later isolated runtime lock.

The sample should prove:

- official source identity
- stable external identity
- cursor semantics
- publication timestamp semantics
- minimum raw-document set
- first event family mapping
- first canonical event type mapping

## Chosen sample candidate

- chosen source candidate: `CNInfo / 巨潮资讯网`
- chosen source key: `cn_cninfo_disclosure_announcements`
- chosen source tier: `official_regulatory_storage`
- chosen first family: `major_asset_transaction_update`
- chosen canonical event type: `major_investment_or_asset_sale`
- chosen issuer: `大连华锐重工集团股份有限公司`
- chosen security code: `002204`
- chosen sample title: `关于挂牌转让大重宾馆资产的进展公告`
- chosen publication date/time: `2025-01-27` date-only source value
- chosen announcement id: `1222441277`
- chosen org id: `9900004001`
- chosen plate: `szse`

Do not widen from this exact sample in the later implementation PR.

## Capture checklist

For the chosen sample, record:

- source home/search URL: `https://www.cninfo.com.cn/new/commonUrl/pageOfSearch?lastPage=index&url=disclosure%2Flist%2Fsearch`
- discovery/list URL: `https://www.cninfo.com.cn/new/commonUrl?url=disclosure%2Flist%2Fnotice`
- exact query URL or request parameters: `stockCode=002204`, `announcementId=1222441277`, `announcementTime=2025-01-27`, `orgId=9900004001`, `plate=szse`
- discovery row HTML or JSON excerpt: capture later as a fixture, but do not add it in this PR
- detail page URL: `https://www.cninfo.com.cn/new/disclosure/detail?plate=szse&orgId=9900004001&stockCode=002204&announcementId=1222441277&announcementTime=2025-01-27`
- detail page HTML or JSON excerpt: capture later as a fixture, but do not add it in this PR
- attachment/PDF URL: `https://static.cninfo.com.cn/finalpage/2025-01-27/1222441277.PDF`
- attachment filename: `1222441277.PDF`
- local publication datetime exactly as displayed: `2025-01-27` date-only
- UTC publication datetime conversion: `2025-01-26T16:00:00Z` only if implementation normalizes date-only Asia/Shanghai to start-of-day; otherwise retain date-only metadata and defer exact event timestamp
- source category/family label exactly as displayed: `TODO capture from list/detail surface if visible`
- issuer/company name exactly as displayed: `大连华锐重工集团股份有限公司`
- issuer/security code exactly as displayed: `002204`
- visible stable id fields: `announcementId`, `stockCode`, `orgId`, `announcementTime`, `plate`
- cursor field candidates: `announcementTime`, `announcementId`, `stockCode`

## Stable identity evidence

Record the source field that will become the stable external identity.

Preferred evidence:

```text
source field name: announcementId
source field value: 1222441277
stable_external_id rule: CNINFO:<announcementId>
stable_external_id sample: CNINFO:1222441277
```

Do not use title text as the stable external identity.

## Cursor evidence

Record the source fields that will become the cursor.

Preferred evidence:

```text
cursor_key: latest_announcement_time_and_announcement_id_seen
cursor_value shape: <announcementTime>|<announcementId>|<stockCode>
cursor sample value: 2025-01-27|1222441277|002204
```

The cursor should be monotonic or deterministic across repeated discovery calls.

Do not use title text as the cursor.

## Raw-document set decision

The recommended minimum raw-document set for the later runtime PR is:

```text
1. discovery row / listing item
2. detail page
3. static PDF disclosure artifact
```

For each raw document, record:

### Discovery row

- raw document external id rule: `CNINFO:<announcementId>:discovery-row`
- document identity rule: `CNINFO:<announcementId>:discovery-row`
- document role: `discovery_metadata`
- MIME type: `text/html` or `application/json`, depending on capture mode
- source URL: `https://www.cninfo.com.cn/new/commonUrl?url=disclosure%2Flist%2Fnotice`

### Detail page

- raw document external id rule: `CNINFO:<announcementId>:detail-page`
- document identity rule: `CNINFO:<announcementId>:detail-page`
- document role: `source_detail_page`
- MIME type: `text/html`
- source URL: `https://www.cninfo.com.cn/new/disclosure/detail?plate=szse&orgId=9900004001&stockCode=002204&announcementId=1222441277&announcementTime=2025-01-27`

### Static PDF

- raw document external id rule: `CNINFO:<announcementId>:static-pdf`
- document identity rule: `CNINFO:<announcementId>:static-pdf`
- document role: `primary_regulatory_disclosure`
- MIME type: `application/pdf`
- source URL: `https://static.cninfo.com.cn/finalpage/2025-01-27/1222441277.PDF`

## Timestamp conversion

Record:

- source timezone assumption: `Asia/Shanghai`
- local timestamp field: `announcementTime`
- local timestamp sample value: `2025-01-27`
- UTC conversion rule: `date-only values should either remain date-only in metadata or normalize to Asia/Shanghai start-of-day only if the implementation explicitly documents that fallback`
- UTC sample value if normalized: `2025-01-26T16:00:00Z`
- date-only fallback rule: `prefer explicit date-only metadata over pretending source provided an intraday timestamp`

## Family and canonical mapping

Record:

- source category label: `TODO capture if visible during later fixture capture`
- event family candidate: `major_asset_transaction_update`
- canonical event type candidate: `major_investment_or_asset_sale`
- why this mapping is narrower than broad all-disclosures ingestion: the selected sample is an asset-disposal progress announcement with one exact CNInfo announcement id, not a multi-category latest-announcements feed
- whether the source category includes unrelated subtypes: `TODO confirm before runtime lock`

## Save instructions for later runtime PR

After contract freeze, the later runtime PR may save fixtures under these exact paths:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_disclosure_announcements_list_002204_20250127_1222441277.html
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_disclosure_announcements_detail_002204_20250127_1222441277.html
apps/backend/disclosure_api/priv/fixtures/source_payloads/cn_cninfo_disclosure_announcements_pdf_002204_20250127_1222441277.pdf
```

Do not create those files in this discovery/contract-freeze PR.

## Capture rejection rules

Reject any replacement sample if:

- it comes from a non-official mirror without CNInfo or exchange-source backing
- it lacks `announcementId`
- it lacks deterministic cursor fields
- it requires broad all-disclosures ingestion to find again
- it requires multiple unrelated disclosure families
- it cannot be reduced to a small raw-document set

## Completion criteria

The sample capture phase is complete only when the contract template has no `TODO` for:

- chosen source
- chosen source tier
- chosen family
- chosen sample
- stable external identity rule and sample
- cursor key and sample value
- local/UTC timestamp rule or explicit date-only fallback
- minimum raw-document set
- first event family
- first canonical event type

Remaining TODOs that must be resolved in the runtime PR before lock:

- capture exact list/detail category label if visible
- confirm whether date-only values should remain date-only or normalize to start-of-day UTC in canonical output
