# GlobalPulse India NSE Scheduled Polling Cadence Policy

This document defines the conservative cadence policy for promoting the official NSE online announcements RSS candidate from manual Fly staging live smoke to scheduled Fly staging polling.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Conclusion

```text
INDIA_NSE_STAGING_LIVE_SOURCE_VERIFIED
INDIA_NSE_SOURCE_CAP_SAFETY_GUARD_PASS
INDIA_NSE_DIGEST_DIVERSITY_SAFETY_GUARD_PASS
INDIA_NSE_DUPLICATE_REFERENCE_BOUNDING_PASS
INDIA_NSE_ELIGIBLE_FOR_CONSERVATIVE_STAGING_SCHEDULE
INDIA_NSE_FIRST_AUTOMATED_STAGING_SCHEDULE_RUN_PASS
INDIA_NSE_PRODUCTION_SCHEDULED_POLLING_NOT_APPROVED
```

## Baseline

```text
decision gate PR: #355 Record India NSE scheduled polling decision gate
source cap PR: #356 Add source-level poll cap for live candidates
source cap smoke PR: #357 Record India NSE source cap smoke
digest diversity PR: #358 Add digest diversity guard
digest diversity smoke PR: #359 Record digest diversity guard smoke
second live smoke PR: #360 Record India NSE second live poll smoke
duplicate handling PR: #361 Bound duplicate references in poll results
duplicate handling smoke PR: #362 Record India NSE duplicate handling smoke
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

## Candidate State

```text
source_key: india_nse_announcements
display_name: India NSE Announcements
authority: official NSE RSS
base_url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
parser_key: rss_v1
active: false
candidate_status: manual_staging_only
max_items_per_poll: 25
```

The candidate is verified for staging live use, but it remains disabled for production scheduled polling.

## Promotion Scope

The next allowed promotion is only:

```text
CONSERVATIVE_STAGING_SCHEDULE
```

The next allowed promotion is not:

```text
PRODUCTION_SCHEDULED_POLLING
PUBLIC_POLL_UI
PUBLIC_SOURCE_HEALTH_UI
UNBOUNDED_PROVIDER_POLLING
```

## Conservative Staging Cadence

If NSE is added to scheduled staging polling, use the following conservative cadence:

```text
workflow: GlobalPulse live staging poll
source_key: india_nse_announcements
edition: breaking
use_live_fetch: true
max_items_per_poll: 25
cadence: every 2 hours on weekdays
cron example: 37 */2 * * 1-5
timezone: UTC cron, observed as staging smoke only
```

Rationale:

```text
NSE is high-volume.
The feed can contain repeated references.
The source cap and digest diversity guard bound impact, but a lower cadence is still safer than hourly while staging behavior is observed.
Weekday-only cadence avoids unnecessary weekend traffic during the first scheduled staging phase.
```

## Required Scheduled Staging Checks

Each scheduled staging run must verify:

```text
GET /api/health: 2xx
POST /api/admin/sources/india_nse_announcements/poll?use_live_fetch=true&edition=breaking: 2xx
poll.fetch.mode: live
poll.fetch.status_code: 200
poll.records_seen <= 25
poll.records_inserted <= poll.records_seen
poll.raw_documents contains unique IDs only
poll.canonical_items contains unique story keys only
GET /api/feed/digest/latest?edition=breaking: 2xx
digest.metadata.fallback_to_fixture: false
digest public JSON response shape unchanged
digest top-12 remains region/source diverse
```

## Observation Window

Before production scheduled polling can be considered, observe the conservative staging schedule for:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs: 10
allowed failures: 0 unresolved parser/content-type failures
allowed fallback live claims: 0
```

Failures should be classified as:

```text
transient_network
unexpected_status
unsupported_live_content_type
unsupported_live_payload
parser_error
duplicate_reference_noise
digest_diversity_regression
```

## First Scheduled Run

The first automated scheduled staging run passed after the conservative staging workflow schedule was activated on the repository default branch.

```text
result record: globalpulse_india_nse_first_scheduled_staging_run_results.md
workflow run id: 25650796284
event: schedule
cron: 37 */2 * * 1-5
resolved source_key: india_nse_announcements
fetch.mode: live
fetch.status_code: 200
records_seen: 13
records_inserted: 13
digest.metadata.fallback_to_fixture: false
```

## Rollback Policy

Rollback immediately if any of the following occur:

```text
NSE live poll repeatedly fails with parser/content-type errors
NSE poll returns fixture fallback while being claimed as live
NSE dominates the public top-12 digest despite diversity guard
records_seen exceeds max_items_per_poll
poll response exposes repeated raw_documents or canonical_items
public digest JSON response shape changes
SEC live polling breaks after NSE schedule changes
GitHub Pages GlobalPulse UI stops rendering regional digest sections
```

Rollback action:

```text
remove india_nse_announcements from scheduled staging workflow
keep source active=false
keep candidate_status manual_staging_only or scheduled_staging_paused
re-run SEC live staging poll
record rollback smoke result
```

## Production Promotion Blockers

Production scheduled polling remains blocked until the staging observation window is complete and a separate approval record is merged.

Required future approval evidence:

```text
7-day staging schedule summary
run count and failure count
latest source health state
latest digest diversity distribution
latest duplicate reference count behavior
explicit rollback confirmation
explicit public UI smoke confirmation
```

## Guardrails

```text
Do not set production scheduled polling from this policy alone.
Do not set source active=true from this policy alone.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change public digest JSON response shape.
Do not add frontend framework dependencies.
Do not claim fixture fallback as live success.
Do not enable JP live polling before issue #339 source-authority decision is resolved.
```

## Current Conclusion

```text
INDIA_NSE_READY_FOR_CONSERVATIVE_STAGING_SCHEDULE_PR
INDIA_NSE_FIRST_AUTOMATED_STAGING_SCHEDULE_RUN_PASS
INDIA_NSE_NOT_READY_FOR_PRODUCTION_SCHEDULED_POLLING
NEXT_STEP_OBSERVE_7_DAY_STAGING_WINDOW
```
