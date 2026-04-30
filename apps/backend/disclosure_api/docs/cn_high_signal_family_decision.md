# CN high-signal family decision

This document records the first-family decision from the initial China source-surface inspection pass.

## Goal

The CN first slice should help users follow important official listed-company disclosures as they happen.
It should not start with broad all-announcements ingestion.

## Decision status

The discovery-freeze candidate is now:

- source: `CNInfo / 巨潮资讯网`
- source key: `cn_cninfo_disclosure_announcements`
- first family: `major_asset_transaction_update`
- first canonical event type: `major_investment_or_asset_sale`
- first fixture item: `CNINFO:1222441277`

This is still not a runtime lock. The later runtime PR must verify the candidate with one fixture item, tests, manual smoke, and dedupe SQL.

## Candidate families

### 1) M&A / restructuring / major asset transaction style disclosure

Pros:

- high-signal and generally narrower than a broad announcement feed
- maps naturally to existing canonical families around major investment, asset sale, merger, acquisition, or restructuring
- can lock one deterministic CNInfo sample using `announcementId`
- the selected sample is an asset-disposal progress announcement, which fits this family without ingesting all CN announcements

Cons:

- may appear under different source-specific category names across SSE, SZSE, BSE, CNInfo, or regulator surfaces
- requires static PDF capture because the PDF is the primary disclosure artifact
- the selected CNInfo sample currently has date-only `announcementTime`, so timestamp handling must be explicit in runtime verification

Current rank:

- `1`

Decision:

- selected as first CN family via `major_asset_transaction_update`

### 2) Material information / major announcement

Pros:

- close fit to the product goal of important as-it-happens company disclosures
- likely useful as a later user-facing CN disclosure lane

Cons:

- broader and potentially high-volume
- may include many subtypes that require source-specific classification before runtime lock

Current rank:

- `2`

Decision:

- keep for later expansion after the first CNInfo major-asset-transaction slice is locked

### 3) Shareholding / ownership change

Pros:

- high-signal for control and ownership monitoring
- maps naturally to AFM substantial holdings and SEC ownership-related work

Cons:

- may require a different source surface or separate category taxonomy
- stable identity/cursor still must be confirmed directly

Current rank:

- `3`

Decision:

- keep for later expansion

### 4) Takeover / tender-offer style update

Pros:

- high-signal and close to prior SEC/UK tender-offer/scheme semantics
- likely low volume if the source exposes this family cleanly

Cons:

- may be too sparse for deterministic sample capture during initial discovery
- may not be a first-class category on all candidate CN surfaces

Current rank:

- `4`

Decision:

- keep for later expansion or fallback if a better source-specific sample emerges

### 5) Periodic report

Pros:

- likely easy to identify and sample
- may have stable document identifiers and predictable publication dates

Cons:

- weaker fit for as-it-happens major disclosure monitoring
- likely broad and less urgent than transaction/control-change disclosures

Current rank:

- `5`

Decision:

- not selected for first CN lock

## Selected sample

- issuer: `大连华锐重工集团股份有限公司`
- security code: `002204`
- title: `关于挂牌转让大重宾馆资产的进展公告`
- announcement date: `2025-01-27`
- announcement id: `1222441277`
- detail URL: `https://www.cninfo.com.cn/new/disclosure/detail?plate=szse&orgId=9900004001&stockCode=002204&announcementId=1222441277&announcementTime=2025-01-27`
- static PDF URL: `https://static.cninfo.com.cn/finalpage/2025-01-27/1222441277.PDF`

## Why this family wins first

`major_asset_transaction_update` is selected because it satisfies the first-lock constraints better than broad material-information ingestion:

- one exact `announcementId`
- one exact issuer/security code
- one exact detail page URL
- one exact static PDF URL
- one narrow canonical event type
- one deterministic cursor candidate
- no need for broad all-disclosures ingestion

## Disqualification rules for replacing this decision

A replacement family should not become the first CN implementation slice if:

- the public search cannot isolate it without broad ambiguity
- no stable public id, URL token, or document id is visible
- cursor semantics require title text or fuzzy matching
- the first sample requires ingesting multiple unrelated announcement families
- the raw-document set cannot be reduced to one deterministic item

## Implementation rule

Do not open runtime code for multiple CN families at once.
Freeze one source and one family, lock it, then expand.

The next runtime PR must stay limited to:

- source: `cn_cninfo_disclosure_announcements`
- family: `major_asset_transaction_update`
- canonical event type: `major_investment_or_asset_sale`
- sample: `CNINFO:1222441277`
