# TW MOPS material information source findings

This document records initial public-source findings for the TW first vertical.

## Current preferred official source

Current preferred source:

- `MOPS / Market Observation Post System / 公開資訊觀測站`

Current preferred material-information path family:

- `https://mops.twse.com.tw/mops/web/t05st01`

## Confirmed public usage patterns

Public company investor-relations pages commonly direct users to:

- MOPS / 公開資訊觀測站
- `重大訊息 / material information`
- `重大訊息綜合查詢 / historical material information`
- company code or abbreviation input
- year / month / date range filters

Observed public path examples include:

- `https://mops.twse.com.tw/mops/web/t05st01`
- `https://mopsov.twse.com.tw/mops/web/t05st01`

## Why this fits the product goal

The first TW vertical should prioritize important company disclosures as they happen.
`重大訊息 / material information` is currently the best fit because:

- it is high-signal
- it is company-disclosure oriented
- it is not primarily periodic reporting
- it is a common investor-facing pointer from Taiwanese listed-company pages

## Current source-contract implications

Recommended first source key:

- `tw_mops_material_information`

Recommended adapter key after freeze:

- `tw_mops_material_information_v1`

Recommended discovery mode candidate:

- `mops_material_information_result_fixture`

Recommended hydrate mode candidate:

- `mops_material_information_detail`

Recommended first event family candidate:

- `material_information_update`

## Still unresolved

Do not open runtime implementation until the following are confirmed with one concrete result:

- exact result HTML or export structure
- stable announcement identity
- detail URL or form-action parameters
- local date/time format
- ROC calendar conversion rule if the public page uses ROC years
- minimum raw-document set
- exact canonical event type for the chosen sample

## Current recommendation

Proceed with MOPS material information discovery-freeze.
Do not fall back to periodic reports unless material-information identity/cursor semantics cannot be frozen.
