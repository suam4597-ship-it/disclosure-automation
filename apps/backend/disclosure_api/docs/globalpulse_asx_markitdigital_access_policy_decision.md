# GlobalPulse ASX MarkitDigital Access Policy Decision

Date: 2026-05-11 KST

This document records the access-policy decision for using the ASX MarkitDigital market-announcements JSON endpoint as a GlobalPulse backend live source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

This is an engineering access decision for GlobalPulse source gating. It is not legal advice.

## Decision

```text
ASX_MARKITDIGITAL_ACCESS_POLICY_DECISION_RECORDED
ASX_JSON_TECHNICAL_GATE_PASSED
ASX_PUBLIC_SITE_TERMS_DO_NOT_ACCEPT_BACKEND_POLLING_AS_SOURCE
ASX_MARKET_ANNOUNCEMENTS_COMMERCIAL_OR_BACKEND_REUSE_REQUIRES_EXPRESS_AUTHORITY_OR_APPROVED_DATA_SERVICE
ASX_MARKITDIGITAL_DELIVERY_PATH_IS_NOT_INDEPENDENT_SOURCE_AUTHORITY
ASX_SOURCE_REGISTRATION_BLOCKED_UNTIL_WRITTEN_AUTHORITY_OR_APPROVED_ASX_INFORMATION_SERVICE_PATH
ASX_ADAPTER_NOT_NEXT
SET_RUNTIME_PROBE_BECOMES_NEXT_IMPLEMENTATION_STEP
PRODUCTION_ANZ_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Reviewed Official Surfaces

```text
ASX market announcements:
https://www.asx.com.au/markets/trade-our-cash-market/announcements

ASX terms of use:
https://www.asx.com.au/legals/terms-of-use

ASX Information Services:
https://www.asx.com.au/connectivity-and-data/information-services

ASX Company News:
https://www.asx.com.au/connectivity-and-data/information-services/company-news

ASX ComNews factsheet:
https://www2.asx.com.au/content/dam/asx/connectivity-and-data/asx-comnews-factsheet.pdf
```

## Technical Context

The previous ASX access-path review confirmed a strong technical endpoint:

```text
endpoint: https://asx.api.markitdigital.com/asx-research/1.0/markets/announcements
bounded query: page=0, itemsPerPage=25, summaryCountsDate=<date>, includeFacets=true
PowerShell direct fetch: 200 application/json
Node fetch direct fetch: 200 application/json
Playwright browser network fetch: 200 application/json
top-level shape: data.items, data.count, data.facets, data.summaryCounts
```

That proves endpoint shape and basic fetchability only. It does not prove permission to run GlobalPulse backend polling, storage, digest materialization, or redistribution.

## Policy Context

The ASX market-announcements page says access to and use of ASX website information, including Market Announcements, is subject to ASX terms of use and points to market-data copyright restrictions.

The ASX terms of use describe content ownership and permitted use as personal, non-commercial use. The same terms identify spider, screen-scraper, robot, or similar automated access as prohibited unless otherwise permitted or authorized by ASX. The Market Announcements section also says Market Announcements are freely available only for investors' private and personal use, and commercial use requires ASX express written authority.

ASX Information Services describes Australian financial market data and company information access directly from ASX. The Company News surface describes ComNews as a subscription service for complete, real-time ASX-listed company news, with delayed redistribution requiring contact with ASX.

## GlobalPulse Interpretation

GlobalPulse backend polling is not a private personal-investor browsing use. It would:

```text
poll a machine endpoint from a server process
store bounded announcement metadata
materialize digest entries
serve derived public UI/API results
run repeat staging and potentially future scheduled workflows
```

Therefore, the public MarkitDigital JSON path must not be treated as enough authority to register an ASX source.

MarkitDigital is treated as the delivery implementation observed from the ASX page, not as an independent source-authority or licensing surface for GlobalPulse.

## Source Registration Decision

```text
source key proposal: au_asx_market_announcements
parser/adapter proposal: asx_markitdigital_announcements_json_v1
technical status: confirmed
policy status: blocked
registration status: blocked
activation status: not allowed
manual staging live poll: not allowed
scheduled staging polling: not allowed
production polling: not allowed
document/PDF fetching: not allowed
public digest response shape: unchanged
```

ASX can be revisited only if one of these gates is satisfied:

```text
written authority from ASX for the intended backend polling/storage/digest use
an approved ASX Information Services or Company News data-service path
explicit internal product/legal acceptance that documents scope, rate, storage, redistribution, and rollback
```

## Next Implementation Step

Because ASX is policy-blocked, the next APAC implementation step should move to SET Thailand:

```text
next PR: Add SET Fly/Elixir runtime compatibility probe
purpose: prove the existing SET browser-bootstrap JSON path can work from GlobalPulse runtime constraints
source registration: still blocked until runtime probe, adapter, rate/cadence, and staging smoke pass
```

If SET runtime probing fails or is not acceptable, continue to IDX runtime compatibility probing using the already documented bounded YYYYMMDD date-window query.

## Guardrails

```text
Do not add ASX as an rss_v1 source.
Do not add an ASX JSON adapter/source candidate until access authority is accepted.
Do not run ASX Fly staging live poll smoke from the public MarkitDigital endpoint.
Do not fetch ASX announcement documents/PDFs.
Do not use third-party ASX/NZX mirrors or aggregators by default.
Do not enable ANZ scheduled live polling.
Do not enable production APAC scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not treat fixture fallback as live success.
Keep KR deferred until the dedicated KR backend/source authority path exists.
Keep JP blocked until issue #339 source authority is resolved.
```

## Allowed Next PRs

```text
1. Add SET Fly/Elixir runtime compatibility probe.
2. Add bounded inactive SET JSON parser/source candidate only if runtime probe, access, rate/cadence, and staging-smoke gates pass.
3. Add IDX Fly/Elixir runtime compatibility probe if SET remains blocked.
4. Revisit ASX only after written authority or approved ASX Information Services path exists.
```
