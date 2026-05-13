# GlobalPulse HKEX And India Post-Rollup Scheduled Observation

Date: 2026-05-13 KST

This document records two successful scheduled staging observations after the latest scheduled staging rollup and the EU canary Belgium fallback/recovery follow-up.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
HKEX_POST_ROLLUP_SCHEDULED_RUN_PASS
HKEX_SCHEDULED_STAGING_RUN_COUNT_ADVANCED_TO_9
INDIA_NSE_POST_ROLLUP_SCHEDULED_RUN_PASS
INDIA_NSE_RECENT_INSPECTED_RUN_COUNT_ADVANCED_TO_8
DIGEST_FALLBACK_FALSE
TOP_N_DIGEST_TIME_WINDOW_SKEW_RECORDED
CANDIDATE_SOURCES_REMAIN_ACTIVE_FALSE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Observed Runs

| Track | Workflow run | Created UTC | Schedule | Source | Poll result | Digest result | Artifact |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HKEX | `25767950060` | `2026-05-12T22:17:14Z` | `22 */2 * * 1-5` | `hkex_latest_listed_company_information` | `202`, `fetch.mode=live`, `fetch.status_code=200`, `records_seen=5`, `records_inserted=5` | `200`, `digest_date=2026-05-13`, `item_count=12`, `metadata.fallback_to_fixture=false` | `6958040881`, `sha256:234e74f6ee56b38f2d53f4e21faacdeb01241fa80283de529ebe0f0796fb0454` |
| India NSE | `25768648399` | `2026-05-12T22:37:09Z` | `37 */2 * * 1-5` | `india_nse_announcements` | `202`, `fetch.mode=live`, `fetch.status_code=200`, `records_seen=13`, `records_inserted=13` | `200`, `digest_date=2026-05-13`, `item_count=12`, `metadata.fallback_to_fixture=false` | `6958296619`, `sha256:05047ecec4cca4fc6774f61972b67f40d634c47025bcccc1d40f13f4c239f786` |

Both runs completed successfully in the `GlobalPulse live staging poll` workflow.

## HKEX Details

```text
workflow: GlobalPulse live staging poll
run_id: 25767950060
job_id: 75684626261
event: schedule
source_key: hkex_latest_listed_company_information
run_mode: single_source
health status: 200
poll status: 202
fetch.url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 1759
records_seen: 5
records_inserted: 5
digest status: 200
digest_date: 2026-05-13
digest item_count: 12
metadata.fallback_to_fixture: false
```

The HKEX poll inserted these canonical item ids:

```text
breaking-2026-05-12-hkex-llci-2026051300069
breaking-2026-05-12-hkex-llci-2026051300067
breaking-2026-05-12-hkex-llci-2026051300065
breaking-2026-05-12-hkex-llci-2026051300063
breaking-2026-05-12-hkex-llci-2026051300034
```

This advances the HKEX scheduled staging observation gate from eight successful scheduled runs to nine successful scheduled runs. The target remains the documented 7-day / 10 successful run observation gate before any source-promotion decision.

## India NSE Details

```text
workflow: GlobalPulse live staging poll
run_id: 25768648399
job_id: 75686806955
event: schedule
source_key: india_nse_announcements
run_mode: single_source
health status: 200
poll status: 202
fetch.url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 7228
records_seen: 13
records_inserted: 13
digest status: 200
digest_date: 2026-05-13
digest item_count: 12
metadata.fallback_to_fixture: false
```

This advances the India NSE inspected recent scheduled staging run count from seven to eight. India remains inactive/manual staging-only until the source-promotion gate is approved.

## Digest Window Note

Both observations returned a successful digest with `metadata.fallback_to_fixture=false`. The latest top-N digest rows observed in these two workflow artifacts were India-heavy because the digest endpoint returns a latest-window top-N view, not a per-source completeness report.

This is not evidence that HKEX rows disappeared from ingestion. The HKEX workflow artifact recorded a successful live poll and five inserted canonical items. Digest visibility should continue to be tracked across scheduled public web smoke and source-specific staging artifacts.

## Guardrails

```text
HKEX source remains active=false
India NSE source remains active=false
production scheduled polling remains disabled
fixture fallback is not counted as live success
latest digest top-N skew is not source absence evidence
no backend JSON response shape changed
no frontend framework added
no public poll UI added
no public Source Health UI added
```
