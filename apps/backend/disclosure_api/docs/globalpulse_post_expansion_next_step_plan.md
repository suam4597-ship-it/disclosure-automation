# GlobalPulse Post-expansion Next Step Plan

Date: 2026-05-12 KST

This document records the next operating plan after the current Europe/APAC scheduled-observation documentation pass.

This is planning-only. It does not change frontend code, backend code, routes, public API response shapes, workflow schedules, source activation, secrets, hosting configuration, production infrastructure, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_POST_EXPANSION_NEXT_STEP_PLAN_RECORDED
BROAD_EU_SOURCE_EXPANSION_PAUSED_BY_DEFAULT
SCHEDULED_STAGING_OBSERVATION_CONTINUES
PRODUCTION_INFRA_DECISIONS_NEXT_MAJOR_GATE
SOURCE_PROMOTION_APPROVALS_REQUIRED_SOURCE_BY_SOURCE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
JP_LIVE_POLLING_STILL_BLOCKED
KR_LIVE_SOURCE_TRACK_STILL_DEFERRED
```

## Current Position

GlobalPulse has moved beyond the first source-discovery push.

Current source-observation evidence includes:

```text
SEC baseline live smoke: pass
India NSE first scheduled run: pass
India NSE interim scheduled observation: recent runs 25694981715, 25699447717, 25703573653 pass
EU canary follow-up observation: runs 25680178601 and 25698983703 pass at poll level
Denmark DFSA OAM follow-up observation: runs 25680895829 and 25699532618 pass at poll level
HKEX scheduled follow-up observation: 4 successful scheduled runs through 25702861937
public Pages + Fly staging smoke: pass
```

Important caveat:

```text
EU and Denmark latest inspected poll runs passed, but their latest inspected global top-N digest artifacts did not include EU/Denmark rows.
This is not a poll failure, but it means public digest diversity remains an observation item before promotion.
```

## Recommended Default Posture

For the next phase, default to observation and production-readiness work instead of broad source expansion.

```text
pause broad EU source discovery by default
do not add Germany/PSE/Ireland or other EU sources unless a high-confidence official machine-readable endpoint is already proven
do not start KR live-source work until the dedicated KR backend/source authority path exists
do not start JP live polling until issue #339 is resolved
do not add production schedules or set candidate sources active=true
```

Allowed source work:

```text
bug fixes for already registered inactive/manual-staging sources
source-health drift checks
scheduled observation summaries
digest diversity/public visibility checks
Ireland Dublin-only machine filter research if it proves a country-only contract
approved access-policy follow-ups for blocked official surfaces
```

## Next Work Sequence

### 1. Keep Observation Windows Running

Continue recording scheduled staging evidence for:

```text
India NSE
EU scheduled staging canary
Denmark DFSA OAM
HKEX
public web smoke
source-health drift
```

Do not promote from one successful run family alone. For each candidate, keep recording:

```text
successful scheduled run count
failure count
latest artifact id/digest
latest source-health state
latest public digest visibility
metadata.fallback_to_fixture=false
unexpected digest top-N displacement
```

### 2. Decide Production Infrastructure Values

The next major gate is not another source. It is production infrastructure approval.

Decision records already exist:

```text
globalpulse_production_deployment_decision_record.md
globalpulse_production_backend_deployment_design.md
globalpulse_production_deployment_runbook.md
globalpulse_production_fly_command_templates.md
globalpulse_frontend_production_config_templates.md
```

Open values remain:

```text
production backend app name
production backend region
production database provider/plan
production frontend URL/domain plan
production CORS origin list
rollback owner
incident contact/process
whether first production digest may be empty
```

Track operator approval in:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/561
```

### 3. Keep Source Promotion Separate

Source promotion must remain source-by-source.

Track source approvals in:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/565
```

Before any source is promoted, require:

```text
official/accepted authority
machine-readable endpoint contract
staging success count
staging failure count
latest artifact/payload review
source-health state
public digest visibility
fallback_to_fixture=false evidence
rate/cadence policy
rollback/disable path
operator approval
```

### 4. First Production Smoke Should Be Readonly

If production infrastructure is approved, the first production backend smoke should remain readonly:

```text
GET /api/health
GET /api/feed/digest/latest?edition=breaking
CORS smoke from approved frontend origin
```

Do not enable production scheduled polling just to make the first production digest look populated. A bounded empty digest is acceptable only if explicitly documented.

## Explicit Non-goals

```text
no production Fly app creation in this PR
no production database provisioning
no secret creation or rotation
no frontend config promotion
no source active=true changes
no production scheduled polling
no public poll UI
no audit UI
no public Source Health UI
no backend digest JSON shape changes
no JP live polling
no KR live-source implementation
```

## Recommended Next PR Candidates

Preferred sequence:

```text
1. Record production infrastructure decision values after operator approval.
2. Add/refresh production CORS smoke contract after frontend/backend origin choices are approved.
3. Record another scheduled-observation batch after more India/EU/Denmark/HKEX runs accumulate.
4. Record public digest diversity smoke when EU/Denmark/HKEX rows reappear in top-N digest artifacts.
5. Only after production backend smoke passes, consider frontend production config promotion.
```

Fallback if no production approvals are available yet:

```text
continue observation-window summaries
keep public web smoke healthy
investigate only high-confidence official endpoint blockers
avoid new broad source expansion
```
