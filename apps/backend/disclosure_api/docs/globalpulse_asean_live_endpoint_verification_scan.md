# GlobalPulse ASEAN Live Endpoint Verification Scan

This document records the first ASEAN exact-endpoint verification pass after APAC fixture/UI coverage and the India NSE staging-live candidate work.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Status

```text
ASEAN_LIVE_SOURCE_SCAN_STARTED
ASEAN_OFFICIAL_SURFACES_FOUND
ASEAN_MACHINE_READABLE_ENDPOINT_NOT_ACCEPTED_YET
ASEAN_SOURCE_REGISTRATION_NOT_READY
ASEAN_SCHEDULED_LIVE_POLLING_BLOCKED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Baseline

```text
APAC fixture PR: #348 Add GlobalPulse APAC regional fixtures
APAC fixture smoke PR: #349 Record APAC regional public UI smoke
APAC live contract: globalpulse_apac_live_source_verification_contract.md
India NSE staging schedule activation PR: #366 Activate India NSE staging schedule on main
current branch: phase0-foundation
scan date: 2026-05-08 UTC / 2026-05-09 KST
```

## Candidate Surfaces Checked

### SGX Company Announcements

```text
authority: official Singapore Exchange surface
candidate URL: https://www.sgx.com/securities/company-announcements
category: ASEAN listed-company announcements
quick result: 200 text/html
decision: official surface, but not rss_v1-ready
```

Observed:

```text
The public SGX company announcements page loads as HTML.
The page metadata describes latest company announcements, corporate actions, disclosures, and trading status.
The frontend bundle references an announcements service using ANNOUNCEMENTS_API_URL and an authorizationToken.
Direct unauthenticated API probes to https://api.sgx.com/announcements/v1.0/ returned 403 in this executor.
```

Decision:

```text
Do not register SGX as an rss_v1 source.
Do not treat the HTML page as live source input.
Do not treat the token-protected JSON path as accepted until access terms, required headers/token flow, parser shape, and rate limits are explicitly verified.
SGX remains a strong ASEAN candidate, but it likely needs a dedicated bounded JSON adapter or an accepted official feed/API path.
```

### Bursa Malaysia Company Announcements

```text
authority: official Bursa Malaysia announcement surface
candidate URL: https://www.bursamalaysia.com/market_information/announcements/company_announcement
disclaimer URL: https://www.bursamalaysia.com/disclaimer_company_announcement
category: ASEAN listed-company announcements
quick result: executor returned 403 for direct page/API probes
decision: official surface, exact machine endpoint still pending
```

Observed:

```text
Search-visible Bursa pages confirm official company-announcement surfaces and disclaimer language.
Direct executor probes to the company-announcement page and guessed API endpoints returned 403.
No accepted RSS/Atom/JSON endpoint was verified in this pass.
```

Decision:

```text
Do not register Bursa as an rss_v1 source.
Do not use third-party Bursa mirrors or listed-company investor-relations mirrors as GlobalPulse source authority without explicit acceptance.
Retry with browser/manual network inspection or official Bursa API documentation before adding a source.
```

### SET Thailand Company News

```text
authority: official Stock Exchange of Thailand surface
candidate URL: https://www.set.or.th/en/market/news-and-alert/news?newsType=company
category: ASEAN company news/announcements
quick result: 200 text/html
decision: official surface, but not rss_v1-ready
```

Observed:

```text
The official SET company news page returned HTML.
A guessed JSON endpoint, https://www.set.or.th/api/set/news/search?newsType=company, returned 403 in this executor.
No accepted machine-readable endpoint was verified in this pass.
```

Decision:

```text
Do not register SET as an rss_v1 source.
Investigate whether SET provides a public documented JSON/feed endpoint or requires a specific browser/session flow.
If accepted, implement a bounded adapter rather than changing the public digest response shape.
```

### IDX Indonesia Announcements

```text
authority: official Indonesia Stock Exchange surface to verify
candidate URL: https://www.idx.co.id/en/news/announcement/
category: ASEAN/Indonesia announcements
quick result: executor returned 403 for direct probes
decision: exact endpoint pending
```

Observed:

```text
Search-visible official references point to IDX announcement surfaces.
Direct executor probes to the public announcement page and a guessed Umbraco endpoint returned 403.
No accepted RSS/Atom/JSON endpoint was verified in this pass.
```

Decision:

```text
Do not register IDX as an rss_v1 source.
Do not infer machine-readability from the public page alone.
Retry with official documentation or browser inspection before adding a source.
```

## Rejected For This Pass

```text
third-party SGX/Bursa/SET/IDX aggregators
company-specific investor-relations mirrors
HTML search/listing pages as rss_v1 input
token-protected API paths without accepted access contract
fixture fallback while claiming ASEAN live success
scheduled ASEAN polling
public poll UI
public Source Health UI
backend public JSON response-shape changes
JP live polling before issue #339 is resolved
```

## Acceptance Gate For Any ASEAN Source

Before an ASEAN source can be registered, it must pass:

```text
authority: official exchange/regulator or explicitly accepted third-party
endpoint: exact RSS, Atom, XML, JSON, or known API shape
http: stable 2xx from the intended runtime environment
parser: rss_v1 compatible or a bounded source-specific adapter exists
auth/access: required headers/token/session flow documented and allowed
rate limit: documented or conservatively bounded
fallback: metadata.fallback_to_fixture=false during staging smoke
source: fetch.mode=live during staging smoke
UI: ASEAN item renders in public GlobalPulse Pages
rollback: disabling source does not affect SEC, India NSE, EU, CN/TW, APAC fixture coverage
response_shape: public digest JSON response shape unchanged
```

## Next Step

```text
ASEAN source registration remains blocked.
The safest next ASEAN task is a focused SGX access-path review:
- inspect the official SGX announcements token flow in a browser/network session
- confirm whether SGX terms allow backend polling of the JSON announcements endpoint
- capture a bounded sample response shape if access is accepted
- decide whether a dedicated SGX JSON adapter is appropriate
```

If SGX access is not acceptable, retry Bursa/SET/IDX with the same exact-endpoint gate rather than widening scope or using third-party aggregators by default.
