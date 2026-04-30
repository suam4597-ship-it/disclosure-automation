# TW discovery inventory

This document tracks the official-source discovery work for the first Taiwan vertical.

## Confirmed initial findings

The current first-source candidate is Taiwan's Market Observation Post System / public information observation system (`MOPS`, `公開資訊觀測站`).

Initial evidence gathered:

- TWSE materials describe MOPS as an information disclosure platform established by TWSE and TPEx so investors can access material information about listed companies
- public companies, including TWSE/TPEx-listed companies, are required to disclose relevant material, periodic, and non-periodic information on MOPS
- company investor-relations pages commonly point shareholders to MOPS for `重大訊息` / material information
- common public paths observed in company guidance include:
  - `https://mops.twse.com.tw/mops/web/index`
  - `https://mops.twse.com.tw/mops/web/t05st01` for past material information by company / period

This is enough to make MOPS the current preferred TW official source candidate, but not enough to freeze a runtime contract.

## Discovery questions to close

### 1) What is the official public source?

Current best answer:

- primary official candidate: `MOPS / 公開資訊觀測站`
- likely first source family: `重大訊息 / material information`

Still to close:

- exact public query endpoint for discovery fixture
- whether the result page is HTML-only or can be exported/queried deterministically
- detail page URL stability
- whether listed/TWSE and TPEx disclosures need separate filters or can share one first source

### 2) What is the first high-signal family?

The first TW slice should not ingest every announcement type.

Current priority order:

1. material information / major announcement
2. M&A / merger / acquisition / tender-offer style update
3. shareholding / director / insider related update
4. periodic report

Current recommendation:

- start with `material information / major announcement` only if one deterministic category/sample can be isolated
- otherwise promote a narrower M&A/tender-offer style family

### 3) What is the stable external identity?

The first implementation slice needs one stable immutable identifier for:

- raw document external id
- raw event key seed
- canonical duplicate group seed
- source cursor candidate

Candidate patterns to evaluate:

- announcement id
- company code + date/time + sequence
- detail page token
- document id
- filing serial number

### 4) What should the cursor be?

Candidate cursor shapes:

- latest filing datetime + announcement id
- latest disclosure sequence id
- latest detail URL token
- latest public document id

Do not rely on title text alone.

### 5) What is the minimum raw-document set?

The first isolated slice should use the minimum deterministic set, for example:

- one discovery row
- one detail page
- linked attachment only if needed

## Implementation gate

Do not add runtime code until the following are written down in one place:

- chosen official source
- chosen source key
- chosen adapter key
- chosen parser strategy
- chosen discovery mode
- chosen hydrate mode
- chosen cursor key
- chosen document identity rule
- chosen first event family
- chosen first canonical event type
