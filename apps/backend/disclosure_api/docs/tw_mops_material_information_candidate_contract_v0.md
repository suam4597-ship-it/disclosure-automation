# TW MOPS material information candidate contract v0

This is the candidate contract draft for the preferred first TW slice.
It is intentionally incomplete and should not be treated as a lock spec yet.

## Candidate source identity

Recommended source key:

- `tw_mops_material_information`

Recommended display name:

- `Taiwan MOPS Material Information`

Recommended region code:

- `tw`

Recommended source class:

- `regulatory_filing_feed`

Recommended source tier:

- `official_regulatory_storage`

## Candidate scope

Target only a narrow material-information slice first.
Do not widen to all MOPS announcements in the first implementation PR.

## Candidate discovery model

Primary discovery surface:

- MOPS / public information observation system material information search surface

Candidate public path family:

- `https://mops.twse.com.tw/mops/web/index`
- `https://mops.twse.com.tw/mops/web/t05st01`

Still to confirm before implementation:

- exact query endpoint or HTML form parameters
- whether a deterministic export path exists
- whether the first fixture should use one result row HTML, one detail page HTML, or both
- whether TWSE/TPEx disclosures can share one first source or require separate filters

## Candidate runtime naming

Recommended adapter key after source contract freeze:

- `tw_mops_material_information_v1`

Recommended parser shape:

- discovery parser for MOPS result rows
- detail parser for material-information detail body
- linked attachment parser only if the detail page is insufficient

## Candidate identity options

Evaluate in this order:

1. public announcement id / sequence id if exposed
2. detail URL token if stable
3. company code + filing datetime + sequence
4. company code + date + title only as a last resort

## Candidate cursor options

Evaluate in this order:

1. latest filing datetime + announcement id
2. latest disclosure sequence id
3. latest detail URL token
4. latest filing datetime + company code + sequence

Do not rely on title text alone.

## Candidate event mapping

Recommended first event family:

- `material_information_update`

Candidate canonical event type:

- `major_investment_or_asset_sale` if the selected first sample is a transaction / investment / disposal disclosure
- otherwise choose the canonical event type after one concrete sample is captured

## Must-close questions before code

- can MOPS material information be queried deterministically for one listed company or date range?
- does the public surface expose one stable immutable id?
- is one detail page enough for normalization?
- what exact MOPS timestamp should drive `published_at_local`?
- how should Republic of China calendar dates, if present, be normalized to Gregorian dates?
- what exact canonical event type should pair with the first selected sample?

## First implementation target

The first implementation PR should produce exactly one deterministic item with:

- one stable cursor value
- stable repeated-poll event identity
- source-appropriate canonical item source names
- clean dedupe SQL
