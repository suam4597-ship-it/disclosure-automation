# GlobalPulse India NSE Scheduled Polling Decision Gate

This document records the scheduling decision gate after the first successful Fly staging live poll for the official NSE online announcements RSS feed.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Conclusion

```text
INDIA_NSE_LIVE_CANDIDATE_VERIFIED_IN_STAGING
INDIA_NSE_SCHEDULED_POLLING_NOT_ENABLED
INDIA_NSE_PROMOTION_BLOCKED_PENDING_SAFETY_GUARDS
INDIA_NSE_MANUAL_STAGING_ONLY_REMAINS_CORRECT
```

## Baseline

```text
APAC contract PR: #350 Add GlobalPulse APAC live source verification contract
parser bounds PR: #351 Bound RSS parser records for live candidates
candidate source PR: #352 Add India NSE live candidate source
false-value fix PR: #353 Preserve false source config values
live poll smoke PR: #354 Record India NSE live poll smoke
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Current Candidate State

```text
source_key: india_nse_announcements
display_name: India NSE Announcements
authority: official NSE RSS
base_url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
parser_key: rss_v1
active: false
candidate_status: manual_staging_only
scheduled polling: disabled
```

The candidate is verified as an official, machine-readable, staging-live source. That does not automatically make it safe for scheduled polling.

## Verified Evidence

The Fly staging live smoke proved the basic live path:

```text
GET /api/health: 200
POST /api/admin/sources/india_nse_announcements/poll?use_live_fetch=true&edition=breaking: 200
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
records_seen: 100
records_inserted: 100
GET /api/feed/digest/latest?edition=breaking: 200
metadata.fallback_to_fixture: false
top source: india_nse_announcements
top region: india
```

The parser bound from PR #351 limited a high-volume NSE RSS payload to `max_items_per_poll=100`.

## Decision

Do not enable scheduled polling for `india_nse_announcements` yet.

Keep the source in this state:

```text
active: false
candidate_status: manual_staging_only
scheduled polling: disabled
```

Rationale:

```text
The candidate is high-volume.
The public digest currently returns the top 12 items by priority_rank and published_at.
A frequent scheduled NSE poll could dominate the visible digest without an explicit source/region diversity guard.
One successful live poll proves compatibility but not operational safety.
```

## Promotion Blockers

Scheduled promotion remains blocked until the following are accepted or implemented:

```text
1. Source-specific poll volume policy
   Decide whether NSE should keep the parser default cap of 100 or use a tighter source-level cap.

2. Digest diversity policy
   Ensure one high-volume source cannot crowd out SEC, EU, CN/TW, APAC generic, ASEAN, India fixture, or ANZ coverage from the public top-12 digest.

3. Duplicate handling review
   NSE can expose repeated or closely related announcement references. Confirm that raw document upsert, materialized item creation, and digest ordering remain bounded and understandable.

4. Poll cadence and rate-limit policy
   Define scheduled frequency, retry behavior, user-agent expectations, and rollback criteria before enabling live cadence.

5. Repeated live smoke
   Run at least two separated Fly staging live polls with stable 2xx responses, fetch.mode=live, and metadata.fallback_to_fixture=false.

6. Public UI impact smoke
   Confirm GlobalPulse still shows a balanced regional digest after NSE live data is present.

7. Rollback plan
   Confirm that setting active=false or disabling scheduled input removes NSE from future scheduled ingestion without breaking SEC live polling or fixture-backed regional coverage.
```

## Allowed Next PRs

```text
1. Add source-level live poll cap support or set a tighter NSE-specific cap.
2. Add a digest source/region diversity contract before scheduled high-volume feeds.
3. Add focused duplicate-handling characterization for NSE repeated announcement references.
4. Record a second India NSE live poll smoke after a separated staging run.
5. Promote India NSE only after the promotion blockers above are closed.
```

## Explicit Non-Goals

```text
Do not set india_nse_announcements active=true in this decision PR.
Do not add scheduled live polling.
Do not change public digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not add frontend framework dependencies.
Do not claim fixture fallback as live success.
Do not enable JP live polling before issue #339 source-authority decision is resolved.
```

## Current Conclusion

```text
INDIA_NSE_READY_FOR_SAFETY_HARDENING
INDIA_NSE_NOT_READY_FOR_SCHEDULED_PROMOTION
NEXT_STEP_SOURCE_CAP_OR_DIGEST_DIVERSITY_GUARD
```
