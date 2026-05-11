# GlobalPulse ANZ Live Endpoint Verification Scan

This document records the first ANZ exact-endpoint verification pass after APAC fixture/UI coverage, India NSE staging-live hardening, and the ASEAN endpoint scan.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Status

```text
ANZ_LIVE_SOURCE_SCAN_STARTED
ANZ_OFFICIAL_SURFACES_FOUND
ASX_OFFICIAL_JSON_ACCESS_PATH_CONFIRMED
ASX_SOURCE_REGISTRATION_PENDING_ACCESS_POLICY_AND_ADAPTER
NZX_OFFICIAL_CONTINGENCY_HTML_SURFACE_CONFIRMED
NZX_MACHINE_READABLE_ENDPOINT_NOT_ACCEPTED_YET
ANZ_SOURCE_REGISTRATION_NOT_READY
ANZ_SCHEDULED_LIVE_POLLING_BLOCKED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Baseline

```text
APAC fixture PR: #348 Add GlobalPulse APAC regional fixtures
APAC fixture smoke PR: #349 Record APAC regional public UI smoke
APAC live contract: globalpulse_apac_live_source_verification_contract.md
ASEAN scan record: globalpulse_asean_live_endpoint_verification_scan.md
scan date: 2026-05-08 UTC / 2026-05-09 KST
ASX focused follow-up: globalpulse_asx_market_announcements_access_path_review.md
```

## Latest ASX/NZX Access-Path Addendum

```text
ASX modern market-announcements page confirmed.
Official ASX/MarkitDigital JSON endpoint observed as https://asx.api.markitdigital.com/asx-research/1.0/markets/announcements.
Direct PowerShell and Node probes returned 200 application/json for a bounded page-0 query.
ASX legacy /asx/1/company/{code}/announcements endpoint returned 404 uri-not-found and should not be used.
NZX contingency announcements page confirmed as official HTML, but no machine-readable endpoint was observed.
ANZ source registration remains blocked pending ASX access-policy decision and bounded adapter.
```

## Candidate Surfaces Checked

### ASX Recent And Today's Announcements

```text
authority: official Australian Securities Exchange surface
candidate URLs:
  - https://www.asx.com.au/asx/v2/statistics/announcements.do
  - https://www.asx.com.au/markets/trade-our-cash-market/todays-announcements
  - https://www.asx.com.au/markets/trade-our-cash-market/announcements
  - https://asx.api.markitdigital.com/asx-research/1.0/markets/announcements
category: ANZ listed-company announcements
quick result: official page 200 HTML; MarkitDigital JSON endpoint 200 application/json from PowerShell/Node
decision: official JSON access path confirmed, but source registration blocked pending access-policy decision and bounded adapter
```

Observed:

```text
ASX exposes official market-announcement pages for recent, historical, and today's announcements.
The modern ASX announcements page loads a MarkitDigital announcements app.
The app calls /asx-research/1.0/markets/announcements with page, itemsPerPage, summaryCountsDate, and includeFacets query params.
The JSON response contains data.items, data.count, data.facets, and data.summaryCounts.
Direct PowerShell and Node probes returned 200 application/json for the bounded page-0 query.
The old /asx/1/company/{code}/announcements endpoint returned 404 uri-not-found.
Third-party ASX RSS or announcement mirrors exist, but they were not accepted as GlobalPulse source authority in this pass.
```

Decision:

```text
Do not register ASX as an rss_v1 source.
Do not treat the HTML search or today's-announcements page as live source input.
Do not use third-party ASX announcement RSS mirrors without explicit policy acceptance.
Do not fetch announcement documents/PDFs in the initial candidate.
Record ASX access-policy decision before adding a bounded inactive ASX JSON adapter/source candidate.
```

### NZX Public Announcements

```text
authority: official New Zealand Exchange surface
candidate URLs:
  - https://www.nzx.com/announcements
  - https://announcements.nzx.com/
category: ANZ listed-company announcements
quick result: 200 text/html
decision: official surface, but not rss_v1-ready
```

Observed:

```text
NZX public announcement pages returned HTML.
The official announcements.nzx.com contingency page states that it is operated by NZX Limited as alternative access to market announcements.
The contingency page rendered the most recent 200 announcements and a last-updated timestamp.
No RSS, Atom, JSON, or XML endpoint was observed in the browser network pass.
```

Decision:

```text
Do not register NZX as an rss_v1 source from the HTML pages.
Do not infer machine-readability from the public announcements UI alone.
Do not treat the contingency HTML table as live source input unless a dedicated HTML adapter is explicitly accepted later.
```

### NZX Data Products

```text
authority: official NZX data-products surface
candidate URL: https://www.nzx.com/products/nzx-info
category: official data access
quick result: 200 text/html
decision: useful for authority/access policy, not a direct live source
```

Observed:

```text
The NZX data-products surface describes announcement search and market-data products.
This suggests some live or delayed announcement access may be a data product rather than an unauthenticated feed.
```

Decision:

```text
Do not add a source requiring credentials, subscription, or a trial without an explicit access decision.
If NZX data products are selected later, document credentials, terms, rate limits, and response shape before any runtime integration.
```

## Rejected For This Pass

```text
third-party ASX/NZX aggregators
company-specific investor-relations mirrors
HTML announcement/search pages as rss_v1 input
guessed API endpoints returning 403
subscription/trial data products without explicit access approval
fixture fallback while claiming ANZ live success
scheduled ANZ polling
public poll UI
public Source Health UI
backend public JSON response-shape changes
JP live polling before issue #339 is resolved
```

## Acceptance Gate For Any ANZ Source

Before an ANZ source can be registered, it must pass:

```text
authority: official exchange/regulator/central-bank source or explicitly accepted third-party
endpoint: exact RSS, Atom, XML, JSON, or known API shape
http: stable 2xx from the intended runtime environment
parser: rss_v1 compatible or a bounded source-specific adapter exists
auth/access: credentials/subscription/trial status documented if required
rate limit: documented or conservatively bounded
fallback: metadata.fallback_to_fixture=false during staging smoke
source: fetch.mode=live during staging smoke
UI: ANZ item renders in public GlobalPulse Pages
rollback: disabling source does not affect SEC, India NSE, EU, CN/TW, ASEAN, or APAC fixture coverage
response_shape: public digest JSON response shape unchanged
```

## Next Step

```text
ANZ source registration remains blocked, but ASX is now the strongest first ANZ adapter candidate.
The safest next ANZ task is an ASX access-policy decision PR:
- confirm whether ASX/MarkitDigital market-announcements JSON may be polled by the staging backend
- record terms/copyright/rate-limit constraints
- decide whether a dedicated bounded ASX JSON adapter is appropriate
```

If ASX access is not acceptable, continue NZX exact-endpoint verification with the same access and response-shape gate rather than using third-party aggregators by default.
