# GlobalPulse HKEX First Automated Scheduled Staging Run Results

Date: 2026-05-12 KST

This document records the first observed automated scheduled staging run for the inactive HKEX Latest Listed Company Information source candidate.

This is documentation-only. It does not change workflows, source activation, backend runtime behavior, frontend runtime behavior, routes, public API response shapes, production polling, public poll UI, audit UI, public Source Health UI, parser behavior, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or database schema.

## Conclusion

```text
HKEX_FIRST_AUTOMATED_SCHEDULED_STAGING_RUN_RECORDED
HKEX_FIRST_AUTOMATED_SCHEDULED_STAGING_RUN_PASS
HKEX_SCHEDULE_RESOLVED_TO_HKEX_SOURCE
HKEX_POLL_FETCH_MODE_LIVE
HKEX_POLL_FIXTURE_FALLBACK_NOT_USED
HKEX_DIGEST_FALLBACK_FALSE
HKEX_DIGEST_VISIBLE_LIVE
HKEX_SOURCE_REMAINS_ACTIVE_FALSE
HKEX_CANDIDATE_STATUS_REMAINS_MANUAL_STAGING_ONLY
HKEX_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
HKEX_ATTACHMENT_BODY_FETCH_STILL_DISABLED
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow file: .github/workflows/globalpulse-live-staging-poll.yml
workflow id: 272984043
run id: 25684138207
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25684138207
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
created_at: 2026-05-11T16:48:50Z
started_at: 2026-05-11T16:48:50Z
conclusion: success
```

This run corresponds to the expected HKEX schedule:

```text
expected cron: 22 */2 * * 1-5
expected window: 2026-05-11T16:22:00Z
observed run start: 2026-05-11T16:48:50Z
observed delay: about 27 minutes
```

GitHub scheduled workflows can run later than the exact cron minute. This run is accepted because the job environment resolved:

```text
SCHEDULE_EXPR: 22 */2 * * 1-5
SOURCE_KEY: hkex_latest_listed_company_information
RUN_MODE: single_source
EDITION: breaking
BACKEND_URL: https://globalpulse-backend-staging.fly.dev
```

## Artifact

```text
artifact name: globalpulse-live-staging-poll-25684138207
artifact id: 6924498853
artifact digest: sha256:da2757d136e94258707e66ee203a9e2e279a521d215420751296bd4ffffb639e
artifact size: 3985 bytes
artifact files: health.json, poll.json, digest.json
```

The artifact was downloaded and inspected locally from the GitHub Actions artifact reference.

## Health Check

Workflow health step:

```text
GET /api/health
http_status: 200
status: ok
service: disclosure_automation
phase: phase1
repo: up
```

## Poll Result

Workflow poll step:

```text
POST /api/admin/sources/hkex_latest_listed_company_information/poll?use_live_fetch=true&edition=breaking
http_status: 202
source_key: hkex_latest_listed_company_information
edition: breaking
```

Fetch result:

```text
fetch.loaded: true
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 1957
fetch.url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
fixture fallback: not present / not used
```

Record result:

```text
records_seen: 5
records_inserted: 5
canonical_items_count: 5
raw_documents_count: 5
```

Canonical item keys:

```text
breaking-2026-05-11-hkex-llci-2026051101908
breaking-2026-05-11-hkex-llci-2026051101830
breaking-2026-05-11-hkex-llci-2026051101821
breaking-2026-05-11-hkex-llci-2026051101741
breaking-2026-05-11-hkex-llci-2026051101739
```

## Digest Result

Workflow digest step:

```text
GET /api/feed/digest/latest?edition=breaking
http_status: 200
digest_date: 2026-05-11
edition: breaking
generated_at: 2026-05-11T16:48:59Z
item_count: 12
metadata.fallback_to_fixture: false
```

HKEX visibility in digest artifact:

```text
hkex_items_in_top_12: 2
```

Representative HKEX digest items:

```text
headline: 00805 - NEW GONOW RV - VOLUNTARY...
published_at: 2026-05-11T14:57:00.000000Z
canonical_url: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051101908.pdf

headline: 00038 - FIRST TRACTOR - Cash Dividend...
published_at: 2026-05-11T12:42:00.000000Z
canonical_url: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051101368.pdf
```

This confirms HKEX live data was visible in the public digest payload while preserving `metadata.fallback_to_fixture=false`.

## Source State Follow-Up

An informational source-health read after the run returned:

```text
GET /api/admin/source-health/hkex_latest_listed_company_information
http_status: 200
source_key: hkex_latest_listed_company_information
active: false
candidate_status: manual_staging_only
last_success_at: 2026-05-11T23:13:39.851284Z
last_seen_published_at: 2026-05-11T23:06:00.000000Z
health_status: unknown
```

Interpretation:

```text
The source remains inactive and manual-staging-only.
The first scheduled run itself passed.
The health_status value should remain part of follow-up drift observation, but it does not change this scheduled-run pass record.
```

## Guardrails

```text
Do not treat this as production schedule approval.
Do not set HKEX active=true from this result.
Do not enable production HKEX polling.
Do not claim complete HKEX listed-company disclosure coverage from latest-five JSON.
Do not fetch HKEX PDF, HTM, detail, or attachment bodies.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as live success.
KR remains deferred until the dedicated backend/source path exists.
JP remains blocked until issue #339 is resolved.
```

## Next Allowed Steps

```text
1. Continue HKEX scheduled staging observation until the 7-day / 10 successful run gate is met.
2. Record a follow-up HKEX scheduled observation summary after enough runs accumulate.
3. Keep HKEX active=false and production scheduled polling disabled.
4. Continue India NSE, EU canary, and Denmark DFSA OAM observation windows in parallel.
```
