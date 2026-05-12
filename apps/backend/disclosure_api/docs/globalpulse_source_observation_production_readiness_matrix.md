# GlobalPulse Source Observation Production Readiness Matrix

Date: 2026-05-12 KST

This document summarizes the current source-observation state for production-promotion planning.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
SOURCE_OBSERVATION_MATRIX_RECORDED
SEC_BASELINE_STABLE
INDIA_NSE_LIVE_STAGING_OBSERVED
INDIA_NSE_INTERIM_SCHEDULED_OBSERVATION_RECORDED
POST_EXPANSION_NEXT_STEP_PLAN_RECORDED
CURRENT_PUBLIC_WEB_DIGEST_DIVERSITY_OBSERVATION_RECORDED
SOURCE_HEALTH_DRIFT_OBSERVATION_RECORDED
EU_CANARY_LIVE_STAGING_OBSERVED
EU_CANARY_SECOND_FOLLOWUP_OBSERVED
DENMARK_DFSA_OAM_SECOND_FOLLOWUP_OBSERVED
HKEX_MANUAL_STAGING_OBSERVED
HKEX_FIRST_AUTOMATED_SCHEDULED_RUN_PASS
HKEX_SCHEDULED_STAGING_FOLLOWUP_OBSERVED
PRODUCTION_SOURCE_PROMOTION_NOT_APPROVED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Current Public Smoke Evidence

The latest public web digest diversity observation recorded:

```text
doc: globalpulse_public_web_digest_diversity_observation_20260512.md
public Pages: 200
public config: 200
backend health: 200
backend digest: 200
digest date: 2026-05-12
digest item_count: 10
metadata.fallback_to_fixture: false
```

Observed latest top-N digest coverage included:

```text
source: india_nse_announcements=10
region: india=10
```

This confirms public staging reachability and live-backed digest behavior. It also records that the latest inspected top-N digest is India-only, so digest diversity remains an active observation item. It does not by itself approve production source schedules.

Production source-promotion approvals are tracked in:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/565
```

Latest source-health drift observation:

```text
doc: globalpulse_source_health_drift_observation_20260512.md
real source keys checked: sec_press_releases, india_nse_announcements, hkex_latest_listed_company_information, eu_france_info_financiere_oam, eu_spain_cnmv_other_relevant_information, dk_dfsa_oam_company_announcements
real source key route status: 200
candidate active flags: false for checked non-SEC candidates
workflow canary aliases: eu_scheduled_staging_canary and denmark_dfsa_oam_staging_canary are not registered source-health keys
```

## Readiness Matrix

| Track | Current status | Evidence | Production gate |
| --- | --- | --- | --- |
| SEC baseline | Stable live baseline | Initial SEC live polling smoke and runtime smoke history | May remain baseline, but production schedule still needs production deployment approval |
| India NSE | Live staging observed through scheduled workflow and current public digest; interim scheduled observation recorded | `india_nse_announcements` occupies the latest inspected top-N digest with `metadata.fallback_to_fixture=false`; interim scheduled observation recorded recent runs `25694981715`, `25699447717`, and `25703573653` in `globalpulse_india_nse_interim_scheduled_observation_20260512.md` | Continue 7-day observation window and record final run counts/failures before source-promotion decision |
| EU canary batch | Live staging canary observed through scheduled workflow; latest inspected digest top-N was India-only | `globalpulse_eu_scheduled_staging_canary_first_cron_observation.md`; later payload review recorded; follow-up run `25680178601` recorded in `globalpulse_eu_scheduled_staging_canary_followup_observation_20260511.md`; second follow-up run `25698983703` recorded in `globalpulse_eu_scheduled_staging_canary_second_followup_observation_20260512.md` | Continue multi-day scheduled observation and digest-diversity checks; do not add Germany/PSE to first canary automatically |
| Denmark DFSA OAM | Live EU northern coverage observed, but latest inspected digest top-N did not include Denmark | Public smoke digest includes `dk_dfsa_oam_company_announcements` with `eu_north`; follow-up scheduled run `25680895829` recorded in `globalpulse_denmark_dfsa_oam_followup_scheduled_observation_20260511.md`; second follow-up run `25699532618` recorded in `globalpulse_denmark_dfsa_oam_second_followup_scheduled_observation_20260512.md` | Keep inside EU observation path and continue digest-diversity checks; no production schedule yet |
| HKEX | Manual, first automated, and follow-up scheduled staging runs observed; public digest visibility observed but not guaranteed in every global top-N digest | `globalpulse_hkex_second_manual_observation_results.md`; first scheduled run `25684138207` recorded in `globalpulse_hkex_first_automated_scheduled_run_results.md`; follow-up observation recorded 4 successful scheduled runs through `25702861937` in `globalpulse_hkex_scheduled_staging_followup_observation_20260512.md` | Continue 7-day / 10-run staging observation before any promotion |
| ASEAN/Vietnam | Live staging visible in public digest | Public smoke digest includes `vn_hnx_issuer_disclosures` with `asean` | Continue candidate observation; do not claim complete ASEAN coverage |
| Switzerland SIX | Live staging visible in public digest | Public smoke digest includes `ch_six_ser_official_notices` | Continue EU/source-specific observation; no production approval yet |
| UK FCA NSM | Live staging visible in public digest | Public smoke digest includes `uk_fca_nsm_regulated_information` | Continue source-specific observation; no production approval yet |
| Spain CNMV | Live staging visible in public digest | Public smoke digest includes `eu_spain_cnmv_other_relevant_information` | Continue EU/source-specific observation; no production approval yet |
| Belgium FSMA | Live staging visible in public digest | Public smoke digest includes `eu_belgium_fsma_stori` | Continue EU/source-specific observation; no production approval yet |
| Euronext company releases | Live staging visible in public digest | Public smoke digest includes `eu_euronext_company_press_releases` | Treat as company-news/regulatory source; continue observation |
| JP | Blocked | Source authority decision is unresolved | Do not enable JP live polling before the authority decision |
| KR | Deferred | Needs dedicated backend/source path | Do not start KR live-source implementation in this track |

## Promotion Requirements

Before any candidate source is promoted to production scheduled polling, record:

```text
source key
official/accepted source authority
machine-readable endpoint contract
staging run count
staging failure count
latest successful run id
latest artifact/payload review
source-health status
public digest visibility
metadata.fallback_to_fixture=false evidence
rate/cadence policy
rollback/disable path
operator approval
```

Minimum recommended observation window:

```text
at least 5 successful scheduled staging runs for simple single-source schedules
at least 5 successful canary schedule runs for EU batch members
no unresolved parser/runtime failures
no unexpected public response shape changes
```

## Current Blockers

```text
production backend app/database/frontend URL not approved
production source schedule policy not approved
HKEX needs continued scheduled staging observation after 4 successful scheduled runs; target remains 7-day / 10 successful runs
JP source authority unresolved
KR dedicated backend/source path not designed
Germany Company Register and Prague/PSE remain design/staging-only paths
```

## Recommended Next Sequence

```text
1. Use globalpulse_post_expansion_next_step_plan.md as the next queue.
2. Continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate.
3. Continue India/EU/HKEX public smoke, digest diversity, and source-health observation.
4. Record a new digest diversity observation when non-India rows reappear in the latest top-N digest.
5. Use source-health drift checks as context if scheduled observations fail or last_error becomes populated.
6. Record follow-up scheduled observation summaries as runs accumulate.
7. Keep public web smoke daily running.
8. Decide production backend app/database/frontend URL only after operator approval.
9. Only after production infrastructure smoke, decide source-by-source production schedules.
```

Use issue #565 to collect those source-by-source approvals. Do not treat matrix visibility as approval.

## Guardrails

```text
Do not set candidate sources active=true in this track.
Do not enable production scheduled polling.
Do not claim latest-window feeds are complete market coverage.
Do not use fixture fallback as live success.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch PDF/attachment/detail bodies as part of observation.
Do not start JP live polling before source authority is resolved.
Do not start KR until a dedicated backend/source path exists.
```
