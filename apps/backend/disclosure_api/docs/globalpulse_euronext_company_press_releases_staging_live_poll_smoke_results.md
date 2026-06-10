# GlobalPulse Euronext Company Press Releases Staging Live Poll Smoke Results

This document records the manual staging smoke for the official Euronext company press release RSS candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled polling.

## Conclusion

```text
GLOBALPULSE_EURONEXT_COMPANY_PR_STAGING_DEPLOY_PASS
GLOBALPULSE_EURONEXT_COMPANY_PR_SOURCE_REGISTERED_MANUAL_ONLY
GLOBALPULSE_EURONEXT_COMPANY_PR_LIVE_POLL_PASS
GLOBALPULSE_EURONEXT_COMPANY_PR_LATEST_DIGEST_PASS
GLOBALPULSE_EURONEXT_COMPANY_PR_PUBLIC_PAGES_DOM_PASS
GLOBALPULSE_EURONEXT_COMPANY_PR_SCHEDULED_POLLING_STILL_DISABLED
```

## Source

```text
source_key: eu_euronext_company_press_releases
display_name: Euronext Company Press Releases
authority class: official exchange / issuer-announcement surface
base_url: https://live.euronext.com/rss/company-pr-release
healthcheck_url: https://live.euronext.com/en/products/equities/company-news
parser_key: euronext_company_pr_rss_v1
active: false
candidate_status: manual_staging_only
```

## Deployment

```text
repo: suam4597-ship-it/disclosure-automation
branch: phase0-foundation
source PR: #390 Add Euronext company press release RSS candidate
merge commit: 4c01977deca998a9e1629b83325aceafc45582f2
Fly app: globalpulse-backend-staging
release migration: success
deploy result: success
```

## CI Status

The #390 merge commit completed the current CI set successfully.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Health Smoke

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response.status: ok
response.service: disclosure_automation
response.phase: phase1
```

## Source Registration Smoke

```text
GET /api/admin/source-health/eu_euronext_company_press_releases
status: 200
active: false
candidate_status: manual_staging_only
parser_key: euronext_company_pr_rss_v1
base_url: https://live.euronext.com/rss/company-pr-release
```

## Live Poll Smoke

```text
POST /api/admin/sources/eu_euronext_company_press_releases/poll?edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 119260
records_seen: 6
records_inserted: 6
```

Canonical item keys included:

```text
breaking-2026-05-08-12884375-at-https-live-euronext-com
breaking-2026-05-08-12884371-at-https-live-euronext-com
breaking-2026-05-08-12884368-at-https-live-euronext-com
breaking-2026-05-08-12884367-at-https-live-euronext-com
breaking-2026-05-08-12884362-at-https-live-euronext-com
breaking-2026-05-08-12884363-at-https-live-euronext-com
```

## Latest Digest Smoke

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
```

Observed Euronext digest item:

```text
headline: Rapid Nutrition - Notice of Annual General Meeting
source.display_name: Euronext Company Press Releases
source.source_key: eu_euronext_company_press_releases
regions: eu
metadata.fetch_mode: live
```

## Public Pages DOM Smoke

```text
URL: https://suam4597-ship-it.github.io/disclosure-automation/
browser: local headless Chromium via playwright-core
title: GlobalPulse
Backend ok: present
Europe section: present as EU Europe
Euronext Company Press Releases: present
Euronext headline: present
fatal console errors: none observed
```

Observed DOM snippets included:

```text
Backend ok
EU Europe 1 items / avg 90
Rapid Nutrition - Notice of Annual General Meeting
Euronext Company Press Releases
```

## Guardrails

```text
scheduled polling: still disabled
source.active: false
candidate_status: manual_staging_only
fixture fallback claim: not used for live success
backend JSON response shape: unchanged
frontend framework: unchanged
poll UI: not added
audit UI: not added
public Source Health UI: not added
provider/materializer/canonical behavior: unchanged
JP scheduled live polling: untouched and still blocked by source authority decision
```

## Next Step

```text
Continue EU batch candidate work before promotion.
Recommended next candidate: Germany Unternehmensregister or another official national OAM/exchange issuer-announcement endpoint with machine-readable access.
Do not enable scheduled EU live polling until the broader EU candidate batch is explicitly promoted.
```
