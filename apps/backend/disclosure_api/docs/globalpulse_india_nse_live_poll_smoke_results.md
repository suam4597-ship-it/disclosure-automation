# GlobalPulse India NSE Live Poll Smoke Results

This document records the first India/APAC live candidate smoke for the official NSE online announcements RSS feed.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled live polling.

## Conclusion

```text
GLOBALPULSE_INDIA_NSE_LIVE_CANDIDATE_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
INDIA_NSE_RSS_AUTHORITY_PASS
INDIA_NSE_RSS_MACHINE_READABLE_PASS
INDIA_NSE_RSS_BOUNDED_PARSER_PASS
INDIA_NSE_STAGING_LIVE_POLL_PASS
INDIA_NSE_DIGEST_RENDER_READY
INDIA_NSE_SCHEDULED_POLLING_STILL_DISABLED
```

## Baseline

```text
APAC contract PR: #350 Add GlobalPulse APAC live source verification contract
parser bounds PR: #351 Bound RSS parser records for live candidates
candidate source PR: #352 Add India NSE live candidate source
false-value fix PR: #353 Preserve false source config values
branch: phase0-foundation
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Candidate Source

```text
source_key: india_nse_announcements
display_name: India NSE Announcements
authority: official NSE RSS
base_url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
healthcheck_url: https://www.nseindia.com/static/rss-feed
parser_key: rss_v1
active: false
candidate_status: manual_staging_only
scheduled polling: disabled
```

The source remains `active: false`. This smoke does not enable scheduled live polling.

## CI Evidence

The #353 merge commit completed successfully after fixing explicit `false` source config normalization.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Fly Staging Evidence

Fly staging was redeployed from the latest `phase0-foundation` after #353.

```text
app: globalpulse-backend-staging
deploy: success
release_command: success
GET /api/health: 200
health status: ok
repo status: up
```

Source registry check:

```text
GET /api/admin/source-health/india_nse_announcements: 200
active: false
parser_key: rss_v1
candidate_status: manual_staging_only
base_url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
```

## Live Poll Evidence

Manual staging poll:

```text
POST /api/admin/sources/india_nse_announcements/poll?use_live_fetch=true&edition=breaking
```

Observed result:

```text
status: 200
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 566098
fetch.url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
records_seen: 100
records_inserted: 100
```

The NSE RSS payload contains more than 100 items, but parser bounds from PR #351 limited ingestion to `max_items_per_poll=100`.

## Digest Evidence

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
top source: india_nse_announcements
top region: india
```

Representative source ordering observed:

```text
india_nse_announcements
sec_press_releases
apac_policy_news
asean_market_news
cn_mainland_disclosures
tw_market_disclosures
india_market_disclosures
hk_market_news
eu_north_disclosures
anz_market_news
```

## Public Pages Shell Evidence

Static Pages shell/config check:

```text
GET https://suam4597-ship-it.github.io/disclosure-automation/: 200
GlobalPulse shell present: true
config.js referenced: true
GET /disclosure-automation/config.js: 200
config.js points to globalpulse-backend-staging.fly.dev: true
```

The backend digest now includes the India NSE live candidate as a top source. A separate browser visual smoke can be recorded if a screenshot is needed, but the backend/API readiness criteria are met.

## Guardrails Preserved

```text
scheduled India NSE polling: not enabled
source active flag: false
fixture fallback live claim: not made
backend JSON response shape change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
```

## Current Conclusion

```text
INDIA_NSE_OFFICIAL_RSS_VERIFIED_IN_STAGING
INDIA_NSE_LIVE_POLL_FETCH_MODE_LIVE_CONFIRMED
INDIA_NSE_RECORDS_BOUNDED_TO_100_CONFIRMED
INDIA_NSE_DIGEST_TOP_SOURCE_CONFIRMED
INDIA_NSE_READY_FOR_NEXT_DECISION_GATE
```

## Next Decision Gate

The next PR should decide whether to keep `india_nse_announcements` as manual/staging-only or promote it toward scheduled live polling.

Promotion should remain blocked until the following are explicitly accepted:

```text
rate-limit policy
user-agent policy
poll frequency
retention/duplicate handling for high-volume announcements
public UI ordering impact
rollback plan
```
