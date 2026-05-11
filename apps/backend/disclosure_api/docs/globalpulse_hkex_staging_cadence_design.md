# GlobalPulse HKEX Staging Cadence Design

Date: 2026-05-11 KST

This document records the staging-only cadence design for the inactive/manual staging-only HKEX Latest Listed Company Information source candidate.

This is a design-only gate. It does not enable scheduled polling, does not set the HKEX source active, does not change the backend public JSON shape, does not add frontend UI, and does not fetch HKEX PDF/HTM/detail document bodies.

## Conclusion

```text
HKEX_STAGING_CADENCE_DESIGN_RECORDED
HKEX_REMAINS_INACTIVE_MANUAL_STAGING_ONLY
HKEX_TWO_MANUAL_OBSERVATIONS_PASS
HKEX_PUBLIC_PAGES_BROWSER_VISIBILITY_PASS
HKEX_LIGHTWEIGHT_JSON_CANARY_DESIGNED
HKEX_LATEST_FIVE_COMPLETENESS_NOT_CLAIMED
HKEX_ATTACHMENT_BODY_FETCH_STILL_DISABLED
HKEX_PRODUCTION_SCHEDULED_POLLING_NOT_APPROVED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED_BY_THIS_DOC
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Current Evidence

```text
source_key: hkex_latest_listed_company_information
display_name: HKEX Latest Listed Company Information
authority: official HKEXnews Latest Listed Company Information JSON asset
base_url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
parser_key: hkex_latest_listed_company_info_json_v1
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
max_items_per_poll: 25
current source poll_cron metadata: */30 * * * *
```

Evidence records:

```text
runtime probe: globalpulse_hkex_fly_runtime_probe_results.md
parser/source candidate: globalpulse_hkex_inactive_source_candidate_notes.md
first manual smoke: globalpulse_hkex_manual_staging_smoke_results.md
public Pages browser smoke: globalpulse_hkex_public_pages_browser_smoke_results.md
second manual observation: globalpulse_hkex_second_manual_observation_results.md
```

Observed manual live-poll behavior:

```text
first observation:
  status: 202
  fetch.mode: live
  fetch.status_code: 200
  records_seen: 5
  records_inserted: 5
  digest visible: true

second observation:
  status: 202
  fetch.mode: live
  fetch.status_code: 200
  records_seen: 5
  records_inserted: 5
  digest visible: true
  post-poll health_status: healthy
```

## Design Scope

```text
in scope: staging-only scheduled canary design for the existing inactive HKEX source
in scope: request cadence, source-health checks, digest visibility checks, and rollback rules
in scope: explicit latest-five completeness caveat
out of scope: production scheduled polling
out of scope: active=true source promotion
out of scope: public Source Health UI, public poll UI, audit UI, or dashboard changes
out of scope: changing public feed/digest JSON response shape
out of scope: PDF/HTM/detail/attachment body fetch
out of scope: claiming full HKEX announcement completeness from homecat0_e.json alone
```

## Source Shape Caveat

`homecat0_e.json` is a lightweight latest-listed-company metadata asset. The observed response contains a small latest-submissions window.

The staging canary may prove:

```text
official JSON reachability
parser compatibility
bounded canonical item creation
source health behavior
digest visibility
rollback safety
```

The staging canary must not claim:

```text
complete HKEX listed-company disclosure coverage
capture of every announcement during high-volume windows
attachment/document text extraction
full issuer-specific search history
production-ready polling cadence
```

## Initial Staging Cadence

Recommended first scheduled-staging cadence:

```text
workflow: GlobalPulse live staging poll
source_key: hkex_latest_listed_company_information
edition: breaking
use_live_fetch: true
cadence: every 2 hours on weekdays
cron example: 22 */2 * * 1-5
timezone: UTC cron, observed as staging smoke only
source status: active=false
candidate_status: manual_staging_only or scheduled_staging_canary
```

Rationale:

```text
The JSON payload is small and official.
Two manual observations passed with health and digest visibility.
The source has latest-window semantics, so the first cadence is an endpoint stability canary, not a completeness claim.
Every two hours is conservative enough for staging while avoiding unnecessary traffic.
Weekday-only observation aligns with listed-company publication patterns and avoids first-pass weekend noise.
```

The current source-level `poll_cron` metadata is `*/30 * * * *`, but this design does not approve a 30-minute scheduled canary. A 30-minute staging cadence can be considered only after the first conservative scheduled observation window is recorded.

## Required Scheduled Staging Checks

Every scheduled staging run must record or make reviewable:

```text
GET /api/health: 2xx
POST /api/admin/sources/hkex_latest_listed_company_information/poll?use_live_fetch=true&edition=breaking: 2xx
poll.fetch.mode: live
poll.fetch.status_code: 200
poll.records_seen <= 25
poll.records_inserted <= poll.records_seen
poll.raw_documents bounded to metadata references only
poll.canonical_items bounded and unique
GET /api/feed/digest/latest?edition=breaking: 2xx
digest public JSON response shape unchanged
HKEX item visible when fresh enough for top-N
source health remains healthy
source remains active=false unless a separate PR explicitly changes it
```

## Observation Window

Before production scheduled polling can be considered, observe staging for:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs: 10
allowed unresolved parser/content-type failures: 0
allowed fallback live claims: 0
allowed attachment/detail fetches: 0
```

Failure classes:

```text
transient_network
unexpected_status
unsupported_live_content_type
unsupported_live_payload
parser_error
latest_window_staleness
digest_visibility_absent
source_health_regression
```

## Rollback Policy

Rollback immediately if any of the following occur:

```text
HKEX live poll repeatedly fails with parser/content-type errors
HKEX live poll returns fixture fallback while being claimed as live
HKEX returns HTML, captcha, login, or challenge content instead of JSON
HKEX source health changes to degraded or unhealthy without a transient explanation
public digest JSON response shape changes
public Pages GlobalPulse UI stops rendering regional digest sections
SEC, India NSE, Taiwan MOPS, SET, HNX, HSX, or Europe canaries regress after HKEX schedule changes
any implementation begins fetching HKEX PDF/HTM/detail bodies without a separate design PR
```

Rollback action:

```text
remove hkex_latest_listed_company_information from scheduled staging workflow
keep source active=false
keep candidate_status manual_staging_only or scheduled_staging_paused
re-run a known-good live staging poll such as SEC or India NSE
record rollback smoke result
```

## Production Promotion Blockers

Production scheduled polling remains blocked until a separate approval record is merged with:

```text
7-day staging schedule summary
run count and failure count
latest source health state
latest digest visibility distribution
explicit latest-five completeness caveat
explicit rollback confirmation
explicit public UI smoke confirmation
explicit decision on whether homecat0_e.json is sufficient or whether title-search/history endpoints are needed
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
Do not claim full HKEX disclosure completeness from latest-five JSON alone.
Do not fetch HKEX PDF, HTM, detail, or attachment bodies.
Do not enable JP live polling before issue #339 source-authority decision is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## Current Conclusion

```text
HKEX_READY_FOR_CONSERVATIVE_STAGING_SCHEDULE_PR
HKEX_NOT_READY_FOR_PRODUCTION_SCHEDULED_POLLING
NEXT_STEP_ADD_HKEX_TO_STAGING_WORKFLOW_ONLY
```
