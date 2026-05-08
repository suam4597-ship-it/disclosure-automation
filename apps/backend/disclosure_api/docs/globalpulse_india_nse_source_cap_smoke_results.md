# GlobalPulse India NSE Source Cap Smoke Results

This document records the Fly staging smoke after adding source-level `max_items_per_poll` support and applying a tighter cap to the India NSE live candidate.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Conclusion

```text
INDIA_NSE_SOURCE_LEVEL_CAP_DEPLOYED
INDIA_NSE_MAX_ITEMS_PER_POLL_25_CONFIRMED
INDIA_NSE_STAGING_LIVE_POLL_BOUNDED_TO_25
INDIA_NSE_DIGEST_STILL_RENDER_READY
INDIA_NSE_SCHEDULED_POLLING_STILL_DISABLED
```

## Baseline

```text
decision gate PR: #355 Record India NSE scheduled polling decision gate
source cap PR: #356 Add source-level poll cap for live candidates
branch: phase0-foundation
merge commit: cc86c2da30bc932376fc845e067bf89eac882513
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

## CI Evidence

The #356 merge commit completed successfully.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Fly Staging Deploy Evidence

Fly staging was redeployed after #356.

```text
app: globalpulse-backend-staging
deploy: success
release_command: success
GET /api/health: 200
health status: ok
```

## Source Config Evidence

```text
GET /api/admin/source-health/india_nse_announcements: 200
source_key: india_nse_announcements
active: false
parser_key: rss_v1
candidate_status: manual_staging_only
max_items_per_poll: 25
base_url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
```

The source remains disabled for scheduled operation. The source-level cap only affects manual/staging poll parsing.

## Live Poll Evidence

Manual staging poll:

```text
POST /api/admin/sources/india_nse_announcements/poll?use_live_fetch=true&edition=breaking
```

Observed result:

```text
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
records_seen: 25
records_inserted: 25
```

This confirms the source-level cap reduced the previous parser output bound from 100 to 25 for the NSE candidate.

## Digest Evidence

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
top source: india_nse_announcements
top region: india
top item fetch_mode: live
```

Representative top item:

```text
headline: Greenpanel Industries Limited
source: india_nse_announcements
region: india
fetch_mode: live
published_at: 2026-05-08T19:44:35.000000Z
```

## Guardrails Preserved

```text
scheduled India NSE polling: not enabled
source active flag: false
candidate_status: manual_staging_only
public digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
```

## Current Conclusion

```text
INDIA_NSE_SOURCE_CAP_SAFETY_GUARD_PASS
INDIA_NSE_READY_FOR_NEXT_SAFETY_GATE
NEXT_STEP_DIGEST_DIVERSITY_OR_DUPLICATE_HANDLING_REVIEW
```
