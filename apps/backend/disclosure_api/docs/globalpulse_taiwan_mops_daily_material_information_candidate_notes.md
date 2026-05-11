# GlobalPulse Taiwan MOPS Daily Material Information Candidate Notes

Date: 2026-05-11 KST

This document records the bounded inactive source candidate for Taiwan MOPS daily material information.

This PR adds a parser/source candidate only. It does not enable production scheduled polling, activate the source, fetch detail records, fetch attachments, add routes, add controllers, change backend response shapes, change frontend shell behavior, add poll UI, add audit UI, add public Source Health UI, or modify provider/materializer/canonical behavior beyond parsing this source shape.

## Source

```text
source_key: tw_mops_daily_material_information
display_name: Taiwan MOPS Daily Material Information
authority: official MOPS/TWSE public disclosure surface
base_url: https://mops.twse.com.tw/mops/api/t05st02
healthcheck_url: https://mops.twse.com.tw/mops
parser_key: tw_mops_daily_material_info_json_v1
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
```

## Endpoint Contract

The source uses the official MOPS optimized-shell API observed in the endpoint scan:

```text
POST https://mops.twse.com.tw/mops/api/t05st02
content-type: application/json
origin: https://mops.twse.com.tw
referer: https://mops.twse.com.tw/mops/
body:
  year: Taiwan ROC year
  month: numeric month
  day: numeric day
```

The runtime adapter builds the request body from the current Taiwan local date. A registry `live_query_date` override may be used only for bounded manual validation.

## Parser Contract

Accepted response shape:

```text
code: 200
result.data: array
row[0]: ROC date, for example 115/05/11
row[1]: local time, for example 07:00:04
row[2]: company code
row[3]: company short name
row[4]: material-information headline/body text
row[5].parameters.companyId
row[5].parameters.marketKind
row[5].parameters.enterDate
row[5].parameters.serialNumber
```

Canonical mapping:

```text
external_id: tw-mops:{companyId}:{enterDate}:{serialNumber}
title: {company code} - {company short name} - {headline}
url: https://mops.twse.com.tw/mops/#/web/t05st02?year={roc_year}&month={month}&day={day}
published_at: ROC date plus local Taiwan time converted to UTC
category: material_information
summary: bounded company/date/market metadata only
```

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
max_items_per_poll=25
detail_fetch_disabled=true
attachment_fetch_disabled=true
production scheduled polling not enabled
public poll UI not added
audit UI not added
public Source Health UI not added
backend digest JSON response shape unchanged
```

## Manual Staging Plan

After this PR was merged and deployed to Fly staging, a bounded manual source poll was recorded:

```text
smoke record: globalpulse_taiwan_mops_manual_staging_poll_smoke_results.md
result: TAIWAN_MOPS_MANUAL_STAGING_LIVE_POLL_PASS
```

The smoke path:

```text
GET /api/health
POST /api/admin/sources/tw_mops_daily_material_information/poll?use_live_fetch=true&edition=breaking
GET /api/admin/source-health/tw_mops_daily_material_information
GET /api/feed/digest/latest?edition=breaking
```

Acceptance:

```text
fetch.mode=live
metadata.fallback_to_fixture=false
records_seen > 0
records_inserted bounded by max_items_per_poll
source remains active=false
candidate_status remains manual_staging_only
digest includes Taiwan MOPS material-information items when fresh records are present
```

## Next Allowed PR

```text
Repeat Taiwan MOPS manual staging smoke in another observation window.
```
