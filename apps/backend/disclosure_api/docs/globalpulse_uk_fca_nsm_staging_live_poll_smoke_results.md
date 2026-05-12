# GlobalPulse UK FCA NSM Staging Live Poll Smoke Results

This document records the manual staging smoke for the UK FCA National Storage Mechanism regulated-information source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled polling.

## Conclusion

```text
GLOBALPULSE_UK_FCA_NSM_STAGING_DEPLOY_PASS
GLOBALPULSE_UK_FCA_NSM_SOURCE_REGISTERED_MANUAL_ONLY
GLOBALPULSE_UK_FCA_NSM_LIVE_POLL_PASS
GLOBALPULSE_UK_FCA_NSM_LATEST_DIGEST_PASS
GLOBALPULSE_UK_FCA_NSM_PUBLIC_PAGES_DOM_PASS
GLOBALPULSE_UK_FCA_NSM_SCHEDULED_POLLING_STILL_DISABLED
```

## Source

```text
source_key: uk_fca_nsm_regulated_information
display_name: UK FCA NSM Regulated Information
authority class: official national storage mechanism / regulated-information repository
base_url: https://api.data.fca.org.uk/search?index=fca-nsm-searchdata
healthcheck_url: https://www.fca.org.uk/markets/ukla/regulatory-disclosures/national-storage-mechanism
parser_key: fca_nsm_search_api_v1
active: false
candidate_status: manual_staging_only
```

## Deployment

```text
repo: suam4597-ship-it/disclosure-automation
branch: phase0-foundation
source PR: #394 Add UK FCA NSM parser candidate
merge commit: c770c886bedf8a9b30edc2488b0fc19ae0379da6
Fly app: globalpulse-backend-staging
release migration: success
deploy result: success
```

## CI Status

The #394 merge commit completed the current CI set successfully.

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
GET /api/admin/source-health/uk_fca_nsm_regulated_information
status: 200
active: false
candidate_status: manual_staging_only
parser_key: fca_nsm_search_api_v1
base_url: https://api.data.fca.org.uk/search?index=fca-nsm-searchdata
```

## Live Poll Smoke

```text
POST /api/admin/sources/uk_fca_nsm_regulated_information/poll?edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 19599
records_seen: 25
records_inserted: 25
```

The source used the bounded configured POST body:

```text
from: 0
size: 25
sort: submitted_date
sortorder: desc
```

Observed live records included:

```text
DIVERSIFIED ENERGY COMPANY LIMITED - Results of Annual General Meeting
RNS - Final Announcement Released
Inter-American Development Bank - Issue of Debt
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

Observed UK FCA NSM digest item:

```text
headline: AMUNDI SMART OVERNIGHT RETURN - Amundi Smart Overnight Return UCITS ETF USD Hedged Acc: Net Asset Value(s)
source.display_name: UK FCA NSM Regulated Information
source.source_key: uk_fca_nsm_regulated_information
regions: uk
metadata.fetch_mode: live
```

## Public Pages DOM Smoke

```text
URL: https://suam4597-ship-it.github.io/disclosure-automation/
browser: local headless Chromium via playwright-core
title: GlobalPulse
Backend ok: present
United Kingdom section: present
UK FCA NSM Regulated Information: present
UK FCA NSM headline: present
blocking API/CORS errors: none observed
```

Observed DOM snippets included:

```text
Backend ok
United Kingdom 1 items / avg 90
AMUNDI SMART OVERNIGHT RETURN - Amundi Smart Overnight Return UCITS ETF USD Hedged Acc: Net Asset Value(s)
UK FCA NSM Regulated Information
```

One generic browser console 404 message was observed, but it did not block rendering and was not tied to the GlobalPulse backend API calls.

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
Continue Europe batch candidate work before promotion.
Do not enable scheduled Europe live polling until the broader source batch is explicitly promoted.
```
