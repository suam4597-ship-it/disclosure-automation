# GlobalPulse Taiwan MOPS Material Information Endpoint Scan

Date: 2026-05-11 KST

This document records a bounded official-endpoint scan for Taiwan MOPS daily material information.

This is documentation-only. It does not add a source registry entry, runtime code, parser code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, workflows, production scheduled polling, public poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Conclusion

```text
TAIWAN_MOPS_OFFICIAL_DISCLOSURE_SURFACE_CONFIRMED
TAIWAN_MOPS_DAILY_MATERIAL_INFO_JSON_CONFIRMED
TAIWAN_MOPS_SOURCE_REGISTRATION_BLOCKED_PENDING_BOUNDED_ADAPTER
TAIWAN_MOPS_DETAIL_FETCH_NOT_PROBED
TAIWAN_MOPS_ATTACHMENT_FETCH_NOT_PROBED
TAIWAN_MOPS_ACTIVE_SOURCE_NOT_REGISTERED
TAIWAN_MOPS_SCHEDULED_POLLING_NOT_ENABLED
```

## Official Surfaces

```text
TWSE guide describing MOPS:
https://www.twse.com.tw/en/page/about/company/guide.html

MOPS optimized public shell:
https://mops.twse.com.tw/mops

MOPS legacy material-information route:
https://mops.twse.com.tw/mops/web/t05st02

MOPS daily material-information API observed by the optimized shell:
https://mops.twse.com.tw/mops/api/t05st02
```

TWSE describes MOPS as the information-disclosure platform for public companies, including TWSE and TPEx listed companies. The optimized MOPS public shell returned a Vite/Vue application at `/mops` and the legacy `/mops/web/t05st02` route redirected to that shell.

## Direct API Probe

Request:

```text
POST https://mops.twse.com.tw/mops/api/t05st02
content-type: application/json
origin: https://mops.twse.com.tw
referer: https://mops.twse.com.tw/mops/
body: {"year":"115","month":"5","day":"11"}
```

Observed:

```text
status: 200
content_type: application/json;charset=UTF-8
body.code: 200
body.message: query success
payload_bytes: 3099
```

Observed response shape:

```text
result.data: array
row shape:
  0: ROC date, for example 115/05/11
  1: time, for example 07:00:04
  2: company code, for example 1463
  3: company short name
  4: material-information headline/body text
  5: detail query descriptor
```

The row detail descriptor was bounded metadata only:

```text
apiName: t05st02_detail
parameters:
  companyId
  marketKind
  enterDate
  serialNumber
```

The detail endpoint was not fetched in this scan.

## Candidate Shape

The daily material-information list is a credible source candidate because it is:

```text
official: mops.twse.com.tw
machine_readable: JSON
bounded: one day per request
company_disclosure_scope: material information from listed/public companies
detail_fetch_required_for_v1: no
attachment_fetch_required_for_v1: no
```

However, it is not yet ready for source registration because GlobalPulse needs a bounded adapter:

```text
date-aware POST body generation using Taiwan ROC year/month/day
row-array parser to canonical disclosure records
stable external_id from companyId + enterDate + serialNumber
bounded title/headline cleanup
detail fetch disabled by default
attachment fetch disabled by default
disable_live_fixture_fallback=true
manual Fly staging smoke before any schedule
```

## Decision

```text
Do not register tw_mops_daily_material_information yet.
Do not point tw_market_disclosures at the MOPS API yet.
Do not use a static live_body date in source_registry.
Do not fetch detail documents or attachments in the first adapter.
Do not enable production scheduled polling.
Do not add public poll UI, audit UI, or public Source Health UI.
```

## Allowed Next PR

```text
Add a bounded inactive Taiwan MOPS daily material-information adapter/source candidate.
```

The next PR may add a manual-staging-only source only if it keeps:

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
max_items_per_poll bounded
detail_fetch disabled
attachment_fetch disabled
scheduled_polling disabled
```
