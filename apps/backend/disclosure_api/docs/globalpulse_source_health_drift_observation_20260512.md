# GlobalPulse Source Health Drift Observation

Date: 2026-05-12 KST

This document records a readonly source-health drift check for the main staging-observed GlobalPulse sources while waiting for the next matching scheduled source run.

This is documentation-only. It does not change source-health runtime behavior, frontend code, backend code, routes, public API response shapes, workflow schedules, source activation, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_SOURCE_HEALTH_DRIFT_OBSERVATION_RECORDED
SOURCE_HEALTH_ROUTE_REACHABLE_FOR_REAL_SOURCE_KEYS
WORKFLOW_CANARY_ALIAS_KEYS_ARE_NOT_SOURCE_HEALTH_KEYS
CANDIDATE_SOURCE_ACTIVE_FLAGS_REMAIN_FALSE
NO_SOURCE_HEALTH_LAST_ERROR_OBSERVED_FOR_CHECKED_CANDIDATES
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Scope

Checked readonly internal source-health targets on Fly staging:

```text
backend: https://globalpulse-backend-staging.fly.dev
route shape: GET /api/admin/source-health/:source_key
```

## Source Health Results

Real source keys:

```text
source_key: sec_press_releases
status_code: 200
active: true
health_status: unknown
last_success_at: 2026-05-12T00:03:38.141215Z
last_failure_at: 2026-05-08T01:37:31.997911Z
last_error: null

source_key: india_nse_announcements
status_code: 200
active: false
health_status: unknown
last_success_at: 2026-05-11T23:32:24.620542Z
last_failure_at: null
last_error: null

source_key: hkex_latest_listed_company_information
status_code: 200
active: false
health_status: unknown
last_success_at: 2026-05-11T23:13:39.851284Z
last_failure_at: null
last_error: null

source_key: eu_france_info_financiere_oam
status_code: 200
active: false
health_status: unknown
last_success_at: 2026-05-11T21:41:33.603205Z
last_failure_at: null
last_error: null

source_key: eu_spain_cnmv_other_relevant_information
status_code: 200
active: false
health_status: unknown
last_success_at: 2026-05-11T21:41:36.815057Z
last_failure_at: 2026-05-08T16:29:19.311900Z
last_error: null

source_key: dk_dfsa_oam_company_announcements
status_code: 200
active: false
health_status: unknown
last_success_at: 2026-05-11T21:53:20.373422Z
last_failure_at: null
last_error: null
```

Workflow canary alias keys:

```text
source_key: eu_scheduled_staging_canary
status_code: 404
interpretation: workflow routing alias, not a registered source-health source key

source_key: denmark_dfsa_oam_staging_canary
status_code: 404
interpretation: workflow routing alias, not a registered source-health source key
```

## Interpretation

The checked real source keys are reachable through the source-health route and preserve the expected staging posture:

```text
SEC baseline remains active=true.
India NSE, HKEX, EU candidate, and Denmark candidate sources remain active=false.
Checked candidate sources have last_success_at values from recent staging observations.
Checked candidate sources did not expose last_error values.
The health_status field currently reports unknown for these rows; use last_success_at/last_error with scheduled artifacts when interpreting observation state.
```

The workflow canary aliases are not source-health keys. Observation docs should reference both levels explicitly:

```text
workflow alias: eu_scheduled_staging_canary
real source keys: eu_france_info_financiere_oam, eu_spain_cnmv_inside_information, eu_spain_cnmv_other_relevant_information, ...

workflow alias: denmark_dfsa_oam_staging_canary
real source key: dk_dfsa_oam_company_announcements
```

## Follow-Up

```text
Continue recording scheduled artifacts as the source-of-truth for run success.
Use source-health as a drift/context check, not as a replacement for workflow logs.
Do not mark workflow alias 404s as source failures.
Record source-health again if a scheduled observation fails or if last_error becomes populated.
```

## Guardrails

```text
Do not set candidate sources active=true.
Do not enable production scheduled polling.
Do not change source-health route behavior.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim source-health unknown as healthy without artifact evidence.
Do not claim workflow alias 404s as registered source failures.
```
