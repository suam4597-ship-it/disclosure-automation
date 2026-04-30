# CN source findings worksheet

This worksheet records the first official-source inspection pass for the China regional vertical.

This is still docs-only. It does not add CN runtime code, fixtures, sample YAML, tests, ops runner, or dedupe SQL.

## Summary decision table

| Candidate | Source tier candidate | First-family fit | Stable identity visible? | Cursor candidate visible? | Minimum raw-document set | Status |
| --- | --- | --- | --- | --- | --- | --- |
| SSE disclosure pages | `official_exchange_storage` candidate | Good official exchange surface for SSE-listed issuers, but narrower market coverage than CNInfo | likely via SSE document/SEQ/pdf metadata; not frozen | likely publication date + source artefact id; not frozen | discovery page + detail/pdf | keep as fallback |
| SZSE disclosure pages | `official_exchange_storage` candidate | Good official exchange surface for SZSE-listed issuers, but narrower market coverage than CNInfo | likely via source page/pdf path; not frozen | likely publication date + source artefact id; not frozen | discovery page + detail/pdf | keep as fallback |
| BSE disclosure pages | `official_exchange_storage` candidate | Good official exchange surface for BSE-listed issuers only | unknown; needs BSE-specific capture if chosen | unknown; needs BSE-specific capture if chosen | discovery page + detail/pdf | keep as fallback |
| CNInfo / 巨潮资讯网 | `official_regulatory_storage` candidate | Best first candidate because it spans Shenzhen, Shanghai, Beijing, funds, bonds, Hong Kong, regulatory inquiry/discipline surfaces, and exposes announcement search/detail patterns | yes: `announcementId` in detail URLs and static PDF paths | yes: `announcementTime + announcementId + stockCode` | discovery row + detail page + static PDF | recommended |
| CSRC public disclosure surfaces | `official_regulatory_storage` rule source, not preferred as first issuer-announcement feed | Best as authority for disclosure rule basis, not as the first runtime feed | not selected | not selected | not selected | cite as legal/regulatory basis |

## Confirmed source observations

### CNInfo / 巨潮资讯网

Observed source properties:

- CNInfo describes itself as the Shenzhen Stock Exchange statutory information disclosure platform operated by Shenzhen Securities Information Co., Ltd.
- CNInfo's public navigation includes latest announcements, Shenzhen board, Shanghai board, STAR Market, Beijing Stock Exchange, funds, bonds, Hong Kong, inquiry letters, regulatory measures, and disciplinary actions.
- The latest-announcement surface displays company code, company short name, announcement title, and date.
- The announcement search/list surface exposes announcement title, formatted announcement time, security code, security name, category filters, and a full-text action.
- Public detail links observed in issuer pages and search results use `announcementId`, `announcementTime`, `orgId`, and `stockCode`.
- Static PDFs observed under `https://static.cninfo.com.cn/finalpage/<YYYY-MM-DD>/<announcementId>.PDF`.

Current source recommendation:

- `CNInfo / 巨潮资讯网`

Recommended source classification:

- `source_class = regulatory_filing_feed`
- `source_tier = official_regulatory_storage`

Reason:

- CNInfo is a legally relevant official disclosure platform and broad archive for A-share issuer disclosures.
- It can cover SZSE, SSE, STAR, and BSE in one first source surface.
- It exposes a visible announcement id that can seed stable external identity, raw event key, raw document identity, and duplicate group key.

### Shanghai Stock Exchange / SSE disclosure pages

Observed source properties:

- SSE has a listed-company latest announcement surface.
- SSE pages describe the listed-company announcement column as content provided by listed companies.
- SSE company-announcement pages support code/name, keyword, and date filters.

Current source recommendation:

- fallback official exchange source, not first runtime source

Reason:

- Strong official source for SSE-listed issuers.
- Narrower market coverage than CNInfo for the first CN cross-market vertical.
- Keep as later source-specific expansion or fallback if CNInfo capture fails.

### Shenzhen Stock Exchange / SZSE disclosure pages

Observed source properties:

- SZSE has `信息披露` navigation and `上市公司公告` under listed-company information.
- SZSE pages expose keyword/date filtering for official notices and listed-company information.

Current source recommendation:

- fallback official exchange source, not first runtime source

Reason:

- Strong official source for SZSE-listed issuers.
- CNInfo already serves as SZSE statutory information disclosure platform and can cover a broader market set in one source.

### Beijing Stock Exchange / BSE disclosure pages

Observed source properties:

- BSE has a public `上市公司公告` page.
- The page supports company short name/pinyin/code, keyword, and date filters.
- The page states that it defaults to the most recent month of announcements.
- It supports announcement category filtering.

Current source recommendation:

- fallback official exchange source, not first runtime source

Reason:

- Strong official source for BSE-listed issuers.
- Narrower market coverage than CNInfo.
- Keep as later BSE-specific expansion or fallback.

### CSRC public disclosure / regulatory filing surfaces

Observed source properties:

- CSRC's listed-company disclosure rules state that information disclosure documents include periodic reports and interim reports.
- The rules state that the full text of information disclosure documents should be disclosed on securities exchange websites and qualified media sites.
- The rules also state that securities exchanges supervise and urge listed companies and other information disclosure obligors to disclose accurately and timely.

Current source recommendation:

- legal/regulatory authority source, not first runtime feed

Reason:

- CSRC is essential for source-tier justification and legal framing.
- The first runtime feed should use a public issuer-announcement surface with stable item-level ids; CNInfo is cleaner for that first slice.

## Recommended first source

- source: `CNInfo / 巨潮资讯网`
- source key: `cn_cninfo_disclosure_announcements`
- display name: `China CNInfo Disclosure Announcements`
- region code: `cn`
- source class: `regulatory_filing_feed`
- source tier: `official_regulatory_storage`

## Recommended first family

Use a narrow major-asset-transaction / asset-sale progress item as the first fixture.

Recommended event family:

- `major_asset_transaction_update`

Recommended canonical event type:

- `major_investment_or_asset_sale`

Reason:

- It is narrower than broad `latest announcements` ingestion.
- It maps to existing product semantics around major investment / asset sale.
- It allows one deterministic CNInfo announcement id and PDF to be locked before broader CN expansion.

## Recommended sample

Chosen deterministic sample candidate:

- issuer: `大连华锐重工集团股份有限公司`
- security code: `002204`
- source: `CNInfo / 巨潮资讯网`
- title: `关于挂牌转让大重宾馆资产的进展公告`
- announcement date: `2025-01-27`
- detail URL: `https://www.cninfo.com.cn/new/disclosure/detail?plate=szse&orgId=9900004001&stockCode=002204&announcementId=1222441277&announcementTime=2025-01-27`
- static PDF URL: `https://static.cninfo.com.cn/finalpage/2025-01-27/1222441277.PDF`

Why this sample:

- The title is an asset-disposal progress update, which fits the preferred high-signal family.
- The URL exposes `announcementId = 1222441277`.
- The URL exposes `announcementTime = 2025-01-27`.
- The URL exposes `stockCode = 002204` and `orgId = 9900004001`.
- The static PDF URL can be derived from date + announcement id.

## Stable identity scoring

Recommended stable external identity:

```text
CNINFO:1222441277
```

Preferred identity rule:

```text
CNINFO:<announcementId>
```

Do not freeze identity based on title text.

## Cursor scoring

Recommended cursor key:

```text
latest_announcement_time_and_announcement_id_seen
```

Recommended cursor value shape:

```text
<announcementTime>|<announcementId>|<stockCode>
```

Recommended sample cursor:

```text
2025-01-27|1222441277|002204
```

Do not freeze a cursor that requires fuzzy title matching.

## Minimum raw-document set

Recommended first lock raw-document set:

1. discovery row / listing item
2. CNInfo detail page
3. CNInfo static PDF

Reason:

- The discovery row gives source-level item metadata.
- The detail page gives stable routing parameters and user-facing source URL.
- The PDF is the primary disclosure artifact for canonical text extraction.

## Freeze recommendation section

- recommended source: `CNInfo / 巨潮资讯网`
- recommended source tier: `official_regulatory_storage`
- recommended first family: `major_asset_transaction_update`
- recommended first canonical event type: `major_investment_or_asset_sale`
- recommended sample: `002204 / 1222441277 / 关于挂牌转让大重宾馆资产的进展公告`
- recommended stable external identity rule: `CNINFO:<announcementId>`
- recommended cursor key/value shape: `latest_announcement_time_and_announcement_id_seen = <announcementTime>|<announcementId>|<stockCode>`
- recommended minimum raw-document set: `discovery row + detail page + static PDF`
- reason this beats alternatives: CNInfo provides the broadest official/official-regulatory-enough CN market coverage with visible item identity and deterministic PDF artifact paths, while exchange-specific pages are better kept as later source-specific expansions.
