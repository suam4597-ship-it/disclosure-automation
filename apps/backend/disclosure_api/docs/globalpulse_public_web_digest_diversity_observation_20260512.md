# GlobalPulse Public Web Digest Diversity Observation

Date: 2026-05-12 KST

This document records a local public web smoke and latest digest diversity observation after the remaining website implementation workflow was recorded.

This is documentation-only. It does not change frontend code, backend code, routes, public API response shapes, workflow schedules, source activation, secrets, hosting configuration, production infrastructure, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_PASS
PUBLIC_PAGES_CONFIG_STAGING_BACKEND_PASS
FLY_STAGING_HEALTH_PASS
FLY_STAGING_DIGEST_LIVE_BACKED_PASS
LATEST_DIGEST_TOP_N_INDIA_ONLY_OBSERVED
DIGEST_DIVERSITY_REQUIRES_CONTINUED_OBSERVATION
FORBIDDEN_PUBLIC_FRAGMENT_CHECK_PASS
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Baseline

```text
repo: suam4597-ship-it/disclosure-automation
branch: phase0-foundation
latest merged workflow PR: #580 Record GlobalPulse web remaining implementation workflow
merge commit: fc83edb03b35220fd0abc9fae4f6177b827d1610
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
Fly staging backend URL: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

The #580 merge commit completed successfully:

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Local Smoke Evidence

Checked from a local Windows PowerShell environment:

```text
GET https://suam4597-ship-it.github.io/disclosure-automation/: 200
public shell contains GlobalPulse marker: true
GET https://suam4597-ship-it.github.io/disclosure-automation/config.js: 200
config contains https://globalpulse-backend-staging.fly.dev: true
GET https://globalpulse-backend-staging.fly.dev/api/health: 200
health.status: ok
health.service: disclosure_automation
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking: 200
digest.edition: breaking
digest.digest_date: 2026-05-12
digest.item_count: 10
digest.metadata.fallback_to_fixture: false
forbidden public response fragments: none found
```

Forbidden fragment check covered:

```text
actor_permissions
session_id
request_id
authorization
password
secret
token
DATABASE_URL
SECRET_KEY_BASE
```

## Latest Digest Distribution

Observed source distribution:

```text
india_nse_announcements: 10
```

Observed region distribution:

```text
india: 10
```

Representative top-N rows:

```text
1 / india_nse_announcements / india / Archean Chemical Industries Limited
2 / india_nse_announcements / india / Archean Chemical Industries Limited
3 / india_nse_announcements / india / Archean Chemical Industries Limited
4 / india_nse_announcements / india / Archean Chemical Industries Limited
5 / india_nse_announcements / india / Archean Chemical Industries Limited
6 / india_nse_announcements / india / Archean Chemical Industries Limited
7 / india_nse_announcements / india / Archean Chemical Industries Limited
8 / india_nse_announcements / india / Archean Chemical Industries Limited
9 / india_nse_announcements / india / Archean Chemical Industries Limited
10 / india_nse_announcements / india / Brookfield India Real Estate Trust
```

## Interpretation

The public website and Fly staging backend are reachable and the latest digest is live-backed:

```text
metadata.fallback_to_fixture=false
```

However, the latest inspected public top-N digest is India-only. This is not a public website outage and it is not a poll failure, but it means digest diversity remains an active observation item before any production source promotion or production scheduled polling decision.

This observation should be read alongside the source-specific scheduled observations:

```text
India NSE: visible in the inspected top-N digest
EU canary: scheduled poll evidence exists, but not visible in this inspected top-N digest
Denmark DFSA OAM: scheduled poll evidence exists, but not visible in this inspected top-N digest
HKEX: scheduled poll evidence exists, but not visible in this inspected top-N digest
```

## Follow-Up

```text
Continue public web smoke daily observation.
Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate.
Continue EU canary, Denmark DFSA OAM, and India NSE scheduled observations.
Record a new digest diversity observation when EU, Denmark, HKEX, SEC, or other regions reappear in the latest top-N digest.
Do not promote production config or production scheduled polling from this observation alone.
```

## Later Update

A later scheduled public web smoke run observed a live-backed, region-diverse top-N digest:

```text
workflow: GlobalPulse public web smoke
run id: 25712711038
event: schedule
conclusion: success
digest item_count: 12
metadata.fallback_to_fixture: false
observed sources: hkex_latest_listed_company_information, eu_euronext_company_press_releases, india_nse_announcements
observed regions: greater_china, eu, india
```

That recovery is recorded in:

```text
globalpulse_public_web_smoke_first_daily_schedule_run_results_20260512.md
```

## Guardrails

```text
Production backend URL is not configured.
Production frontend config is not promoted.
Production scheduled polling is not enabled.
Candidate sources are not promoted active=true.
Backend digest JSON response shape is unchanged.
Frontend framework dependencies are not added.
Public poll UI is not added.
Audit UI is not added.
Public Source Health UI is not added.
JP live polling remains blocked pending issue #339.
KR live-source implementation remains deferred to a dedicated backend/source path.
```
