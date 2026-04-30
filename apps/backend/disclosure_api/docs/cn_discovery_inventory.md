# CN discovery inventory

This document tracks official-source discovery work for the first China regional vertical.

## Status

The first inspection pass recommends CNInfo as the first CN source candidate.
This is still not a runtime lock.

Current recommendation:

- source: `CNInfo / 巨潮资讯网`
- source key: `cn_cninfo_disclosure_announcements`
- source tier: `official_regulatory_storage`
- first family: `major_asset_transaction_update`
- first canonical event type: `major_investment_or_asset_sale`
- first sample: `CNINFO:1222441277`

## Candidate source surfaces

| Candidate | Why inspect | First questions | Freeze status |
| --- | --- | --- | --- |
| Shanghai Stock Exchange / SSE disclosure pages | Primary exchange disclosure surface for SSE-listed issuers | Are detail URLs stable? Is there a visible announcement id/document id? Can one high-signal family be isolated? | fallback |
| Shenzhen Stock Exchange / SZSE disclosure pages | Primary exchange disclosure surface for SZSE-listed issuers | Are category filters deterministic? Can one sample be captured without broad ingestion? | fallback |
| Beijing Stock Exchange / BSE disclosure pages | Primary exchange disclosure surface for BSE-listed issuers | Does the public surface expose stable detail/document ids and usable publication timestamps? | fallback |
| CNInfo / 巨潮资讯网 | Broad disclosure platform with latest announcements, search, detail pages, and static PDF artifacts | Can one exact announcement id support a one-item first fixture? | recommended |
| CSRC public disclosure / regulatory filing surfaces | Regulator-level source surface and legal basis for disclosure-file handling | Does it provide a better item-level issuer announcement feed than CNInfo? | legal basis, not first feed |

## Discovery findings

### 1) What is the official public source?

Current answer:

- preferred first source: `CNInfo / 巨潮资讯网`
- source key candidate: `cn_cninfo_disclosure_announcements`
- source class: `regulatory_filing_feed`
- source tier: `official_regulatory_storage`

CNInfo is preferred because it exposes cross-market announcement navigation and search surfaces and presents itself as the Shenzhen Stock Exchange statutory information disclosure platform.

Exchange-specific pages remain valid fallback candidates, but they would likely produce separate SSE/SZSE/BSE first-source slices rather than a single first CN cross-market source.

### 2) What is the first high-signal family?

Do not ingest every CN announcement type.

Current first-family candidate:

- `major_asset_transaction_update`

Current canonical event type candidate:

- `major_investment_or_asset_sale`

Reason:

- the selected sample is an asset-disposal progress announcement
- the family is narrower than broad latest-announcements ingestion
- it maps to existing product semantics around major investments, asset sales, and transaction updates

### 3) What is the stable external identity?

Recommended stable external identity:

```text
CNINFO:<announcementId>
```

Sample:

```text
CNINFO:1222441277
```

The first implementation slice should use `announcementId`, not title text, for:

- raw document external id
- raw event key seed
- canonical duplicate group seed
- source cursor candidate

### 4) What should the cursor be?

Recommended cursor key:

```text
latest_announcement_time_and_announcement_id_seen
```

Recommended cursor value shape:

```text
<announcementTime>|<announcementId>|<stockCode>
```

Sample:

```text
2025-01-27|1222441277|002204
```

The cursor must remain deterministic and should not require title-text heuristics.

### 5) What is the minimum raw-document set?

Recommended first isolated raw-document set:

- one discovery row / listing item
- one detail page
- one static PDF disclosure artifact

The static PDF is included because it is the primary disclosure artifact and should support canonical fact extraction.

## Selected sample candidate

- issuer: `大连华锐重工集团股份有限公司`
- security code: `002204`
- title: `关于挂牌转让大重宾馆资产的进展公告`
- announcement date: `2025-01-27`
- announcement id: `1222441277`
- org id: `9900004001`
- plate: `szse`
- detail URL: `https://www.cninfo.com.cn/new/disclosure/detail?plate=szse&orgId=9900004001&stockCode=002204&announcementId=1222441277&announcementTime=2025-01-27`
- static PDF URL: `https://static.cninfo.com.cn/finalpage/2025-01-27/1222441277.PDF`

## Source inspection checklist

For the later runtime PR, confirm and capture:

- sample issuer/company exact display name
- sample security code exact display code
- sample title exact display title
- publication date/time local; currently date-only `2025-01-27`
- UTC conversion rule or explicit date-only fallback
- detail URL
- attachment URL
- visible stable id fields
- cursor field candidates
- category/family filter behavior
- pagination behavior
- whether anti-bot or session behavior blocks deterministic capture

## Implementation gate

The next runtime PR may start only for the recommended CNInfo slice and only if it remains limited to:

- one chosen official source
- one source key
- one adapter key
- one parser strategy
- one discovery mode
- one hydrate mode
- one cursor key
- one document identity rule
- one first event family
- one first canonical event type
- one exact sample item

Do not add broad CN all-disclosures ingestion or multiple CN families in the runtime PR.
