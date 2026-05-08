# GlobalPulse ANZ Live Endpoint Verification Scan

This document records the first ANZ exact-endpoint verification pass after APAC fixture/UI coverage, India NSE staging-live hardening, and the ASEAN endpoint scan.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Status

```text
ANZ_LIVE_SOURCE_SCAN_STARTED
ANZ_OFFICIAL_SURFACES_FOUND
ANZ_MACHINE_READABLE_ENDPOINT_NOT_ACCEPTED_YET
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
```

## Candidate Surfaces Checked

### ASX Recent And Today's Announcements

```text
authority: official Australian Securities Exchange surface
candidate URLs:
  - https://www.asx.com.au/asx/v2/statistics/announcements.do
  - https://www2.asx.com.au/markets/trade-our-cash-market/todays-announcements
  - https://www.asx.com.au/markets/trade-our-cash-market/todays-announcements.dub
category: ANZ listed-company announcements
quick result: 200 text/html
decision: official surface, but not rss_v1-ready
```

Observed:

```text
ASX exposes official market-announcement pages for recent, historical, and today's announcements.
The checked public endpoints returned HTML in this executor.
No accepted RSS, Atom, XML, JSON, or known API endpoint was verified in this pass.
Third-party ASX RSS or announcement mirrors exist, but they were not accepted as GlobalPulse source authority in this pass.
```

Decision:

```text
Do not register ASX as an rss_v1 source.
Do not treat the HTML search or today's-announcements page as live source input.
Do not use third-party ASX announcement RSS mirrors without explicit policy acceptance.
ASX remains a strong ANZ candidate, but it likely needs an official documented feed/API path or a bounded adapter around an accepted official endpoint.
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
The main NZX site displays recent NZSX announcement data, but no accepted RSS/Atom/JSON endpoint was verified.
A direct probe to a guessed public announcement API resource returned 403 in this executor.
```

Decision:

```text
Do not register NZX as an rss_v1 source from the HTML pages.
Do not infer machine-readability from the public announcements UI alone.
Continue with official documentation or a browser/network inspection before adding a source.
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
ANZ source registration remains blocked.
The safest next ANZ task is an ASX official access-path review:
- confirm whether ASX exposes an official machine-readable announcements endpoint
- confirm whether terms allow backend polling
- capture a bounded sample response shape if access is accepted
- decide whether a dedicated ASX adapter is appropriate
```

If ASX access is not acceptable, continue NZX exact-endpoint verification with the same access and response-shape gate rather than using third-party aggregators by default.
