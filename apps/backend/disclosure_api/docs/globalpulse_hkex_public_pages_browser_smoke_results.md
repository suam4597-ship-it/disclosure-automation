# GlobalPulse HKEX Public Pages Browser Smoke Results

Date: 2026-05-11 KST

This document records a public Pages browser smoke after the HKEX inactive/manual staging-only source candidate was deployed to Fly staging and manually live-polled.

This is a browser observation record. It does not activate HKEX, enable production scheduled polling, add public poll UI, add audit UI, add public Source Health UI, change the backend digest JSON response shape, add a frontend framework, or fetch HKEX PDF/HTM/detail bodies.

## Conclusion

```text
GLOBALPULSE_PUBLIC_PAGES_BROWSER_SMOKE_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
HKEX_PUBLIC_DIGEST_VISIBLE_PASS
GREATER_CHINA_REGION_VISIBLE_PASS
SOURCE_HEALTH_LINK_PRESENT
HKEX_SOURCE_ACTIVE_FALSE
HKEX_CADENCE_NOT_APPROVED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Environment

```text
public Pages UI: https://suam4597-ship-it.github.io/disclosure-automation/
backend staging: https://globalpulse-backend-staging.fly.dev
backend deployed commit: 6473fbc79e668a7c2207effd45aa51d151ba07b2
HKEX manual staging smoke record: globalpulse_hkex_manual_staging_smoke_results.md
```

## HTTP Smoke

```text
GET https://suam4597-ship-it.github.io/disclosure-automation/
status: 200
GlobalPulse shell present: true
config.js reference present: true
operator Source Health link present: true

GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}

GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
edition: breaking
digest_date: 2026-05-11
item_count: 12
HKEX item present: true
```

## Browser DOM Smoke

Observed public page:

```text
title: GlobalPulse
url: https://suam4597-ship-it.github.io/disclosure-automation/
GlobalPulse heading visible: true
Backend ok visible: true
Backend digest live visible: true
Greater China / CN-TW region visible: true
HKEX live digest text visible: true
Source Health link visible: true
```

Visible DOM sample included:

```text
Backend ok
Backend digest live
CN/TW Greater China 1 items / avg 90
All 12
공시 12
High Importance 12
Fly backend digest 2026-05-11
```

The digest included the HKEX manually live-polled item through the Fly staging backend.

## Boundary Confirmation

```text
source remains active=false
candidate remains manual_staging_only
production scheduled polling remains disabled
backend digest JSON response shape unchanged
frontend shell unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
HKEX PDF body fetch not added
HKEX HTM/detail body fetch not added
attachment extraction not added
CN/TW scheduled polling remains disabled
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Gate

```text
1. Run one additional HKEX manual observation window.
2. Confirm digest diversity with HKEX present beside Europe, India, ASEAN, Taiwan, and SEC items.
3. Record rollback behavior for HKEX unavailable or disabled.
4. Consider a staging-only cadence design only after repeated manual observations remain healthy.
```
