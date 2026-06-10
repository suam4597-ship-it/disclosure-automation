# GlobalPulse SGX Company Announcements Access Path Review

Date: 2026-05-11 KST

This document records a focused follow-up review of the official SGX company-announcements page after the first ASEAN endpoint scan left SGX as the strongest unresolved ASEAN candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
SGX_OFFICIAL_BROWSER_ACCESS_PATH_CONFIRMED
SGX_ANNOUNCEMENTS_JSON_SHAPE_CAPTURED_BOUNDED
SGX_SOURCE_REGISTRATION_BLOCKED_BY_POLICY_REVIEW
ASEAN_SOURCE_REGISTRATION_STILL_BLOCKED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Reviewed Surface

```text
official page: https://www.sgx.com/securities/company-announcements
page title: Company Announcements - Singapore Exchange (SGX)
category: Singapore / ASEAN listed-company announcements
rendered row date observed: 11 May 2026
rendered row count observed on first page: 20
```

The browser-rendered page displayed a table with:

```text
Date & Time
Issuer Name
Security Name
Title
Category
```

Observed first rows included issuer announcements, debt listing confirmations, meeting notices, trading-status related announcements, and general announcements. The page is therefore a strong official source surface, but the source boundary is broad and should be explicitly bounded before any parser/source registration.

## Browser Access Path

The page loaded these public configuration surfaces:

```text
GET https://www.sgx.com/config/appconfig.json?v=04c0b410
GET https://api2.sgx.com/content-api/?queryId=<CMS_VERSION>:we_chat_qr_validator
```

The config JSON exposed:

```text
CMS_VERSION: 70f75ec90c030bab34d750ee55d74b016f70d4b6
ANNOUNCEMENTS_API_URL: https://api.sgx.com/announcements/v1.1/
CMS_API_URL: https://api2.sgx.com/content-api
V1_CORPORATE_ANNOUNCEMENTS_DATA_URL: https://links.sgx.com/1.0.0/corporate-announcements
```

The frontend then requested the announcements API using an `authorizationToken` header derived from the CMS `qrValidator` response. The token value is intentionally not recorded here.

Observed API calls from the browser session:

```text
GET https://api.sgx.com/announcements/v1.1/companylist
GET https://api.sgx.com/announcements/v1.1/securitylist
GET https://api.sgx.com/announcements/v1.1/count?periodstart=20060510_160000&periodend=20260511_155959
GET https://api.sgx.com/announcements/v1.1/?periodstart=20060510_160000&periodend=20260511_155959&pagestart=0&pagesize=20
GET https://api2.sgx.com/content-api?queryId=<CMS_VERSION>:taxonomy_terms&variables={"vid":"company_announcements_categories","lang":"EN"}
```

## Bounded Response Shape

The first-page announcements API returned HTTP 200 JSON in a browser-compatible request context.

Observed bounded result:

```text
endpoint: https://api.sgx.com/announcements/v1.1/
params: periodstart=20060510_160000, periodend=20260511_155959, pagestart=0, pagesize=20
status: 200
meta.code: 200
data count: 20
```

Observed first item fields:

```text
ref_id: SG260511OTHRNU61
sub: ANNC18
category_name: General Announcement
title: General Announcement::QUARTERLY UPDATE ANNOUNCEMENT AND CONTINUED SUSPENSION OF TRADING
url: https://links.sgx.com/1.0.0/corporate-announcements/0E202ZPH5BY2IDQ6/4fa7a0f1ba65e39a49666d695974898b58215839c204ebbc769a2c997c5c72e5
```

Other observed support endpoints:

```text
companylist status: 200
companylist meta.totalItems: 4275
securitylist status: 200
securitylist meta.totalItems: 23821
taxonomy terms status: 200
taxonomy terms result count: 80
count endpoint status: 200
count endpoint data: 817095
```

The detail URLs are on `links.sgx.com/1.0.0/corporate-announcements/<id>/<hash>`. Do not fetch or store detail documents in an initial candidate. The safe parser boundary, if approved later, should stay on the list API metadata only.

## Executor Compatibility

Observed request behavior:

```text
browser-rendered page: pass
Playwright browser-context API request with token: 200
fresh Playwright API context with token: 200
direct unauthenticated API request: 403
PowerShell Invoke-RestMethod request with token: Akamai Access Denied
```

Implication:

```text
The official JSON shape is proven, but the exact runtime fetch path is not yet proven for the current Elixir/Fly staging adapter stack.
Before source registration, run a small runtime compatibility probe using the same HTTP client path that production polling would use.
Do not assume a browser-compatible request means the backend runtime will fetch SGX successfully.
```

## Policy Review Blocker

The SGX terms surface is material to the source decision.

Reviewed terms surfaces:

```text
https://www.sgx.com/terms-use
https://www.datadirect.sgx.com/LinkClick.aspx?fileticket=BOhAdVqTUVQ%3D&portalid=0
```

The SGX Terms and Conditions of Use of Materials document defines Market Data to include company announcements and defines Materials to include company announcements. It permits viewing and limited personal/non-commercial copying, while restricting copying, storing, distributing, broadcasting, publishing, reproducing, public display, transfer, derivative works, and certain deep links without prior written permission.

Because GlobalPulse ingestion stores source metadata and republishes derived digest rows, SGX source registration should remain blocked until one of these is true:

```text
written permission or license allows the planned use
an SGX-provided data product/API path is accepted for backend polling and redistribution
the product scope changes to a non-persistent operator-only validation that does not publish SGX-derived material
```

## Source Registration Decision

Do not register an SGX source yet.

Current decision:

```text
source key proposal: sg_sgx_company_announcements
parser/adapter proposal: sgx_company_announcements_json_v1
registration status: blocked
blocking class: policy_permission_review + backend_runtime_fetch_probe
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## If Permission Is Approved Later

If SGX access terms are accepted later, the first implementation should be bounded:

```text
source active: false
candidate_status: manual_staging_only
use_live_fetch: true only for manual staging smoke
page size: 20 or lower
page start: 0 only
lookback: narrow current-window, not the full 20-year default
detail/PDF fetch: disabled
stored fields: bounded list metadata only
token value: never logged or stored
fixture: redacted bounded list JSON only
public digest shape: unchanged
public poll UI: not added
public Source Health UI: not added
```

Required validation before any parser/source PR:

```text
Elixir/Fly runtime fetch probe passes against config, CMS token, and list endpoint
no raw token or cookie appears in logs, docs, JSON responses, or artifacts
category allowlist is selected
rate/cadence cap is documented
policy/permission result is recorded
```

## Guardrails

```text
Do not add SGX as an rss_v1 source.
Do not treat the HTML page as live source input.
Do not log, store, or document the raw authorization token.
Do not fetch detail PDFs or issuer documents in the initial candidate.
Do not claim SGX live source readiness from browser-only success.
Do not enable ASEAN scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not use third-party SGX mirrors or aggregators by default.
```

## Allowed Next PRs

```text
1. Add a docs-only SGX policy/permission decision if permission is accepted or rejected.
2. Add a runtime-only SGX fetch compatibility probe if policy allows continuing.
3. Add a bounded inactive SGX parser/source candidate only after policy and runtime fetch gates pass.
4. If SGX remains blocked, retry Bursa/SET/IDX official access-path review with the same source gate.
```
