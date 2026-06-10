# GlobalPulse Source Health Post-Rollup Snapshot

Date: 2026-05-13 KST

This document records a Fly staging source-health snapshot after the post-rollup EU canary recovery and the HKEX/India scheduled observation update.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
SOURCE_HEALTH_POST_ROLLUP_SNAPSHOT_RECORDED
SOURCE_HEALTH_REAL_SOURCE_KEYS_HTTP_200
SOURCE_HEALTH_LAST_ERROR_NULL_FOR_CHECKED_KEYS
CANDIDATE_SOURCES_REMAIN_ACTIVE_FALSE
SEC_BASELINE_REMAINS_ACTIVE_TRUE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Endpoint

```text
backend: https://globalpulse-backend-staging.fly.dev
route: GET /api/admin/source-health/:source_key
```

## Snapshot

| Source key | HTTP | health_status | active | last_error | last_success_at | last_seen_published_at | disable_live_fixture_fallback |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `sec_press_releases` | `200` | `unknown` | `true` | `null` | `2026-05-12T23:07:48.335992Z` | `2026-05-06T19:24:19.000000Z` | `null` |
| `india_nse_announcements` | `200` | `unknown` | `false` | `null` | `2026-05-12T23:38:33.862789Z` | `2026-05-13T00:57:20.000000Z` | `null` |
| `hkex_latest_listed_company_information` | `200` | `unknown` | `false` | `null` | `2026-05-12T23:19:29.264088Z` | `2026-05-12T23:15:00.000000Z` | `true` |
| `eu_belgium_fsma_stori` | `200` | `unknown` | `false` | `null` | `2026-05-12T21:39:57.665626Z` | `2026-05-12T18:00:00.000000Z` | `null` |
| `eu_france_info_financiere_oam` | `200` | `unknown` | `false` | `null` | `2026-05-12T21:39:48.096510Z` | `2026-05-12T18:51:17.000000Z` | `null` |
| `eu_spain_cnmv_inside_information` | `200` | `unknown` | `false` | `null` | `2026-05-12T21:39:50.245418Z` | `2026-05-12T16:18:26.000000Z` | `null` |
| `eu_spain_cnmv_other_relevant_information` | `200` | `unknown` | `false` | `null` | `2026-05-12T21:39:51.305451Z` | `2026-05-12T17:44:48.000000Z` | `null` |
| `uk_fca_nsm_regulated_information` | `200` | `unknown` | `false` | `null` | `2026-05-12T21:39:59.555354Z` | `2026-05-12T19:10:35.000000Z` | `null` |
| `ch_six_ser_official_notices` | `200` | `unknown` | `false` | `null` | `2026-05-12T21:40:01.277263Z` | `2026-05-12T18:00:27.000000Z` | `null` |
| `dk_dfsa_oam_company_announcements` | `200` | `unknown` | `false` | `null` | `2026-05-12T21:56:00.092838Z` | `2026-05-12T19:46:33.000000Z` | `true` |

## Interpretation

All checked real source keys returned bounded source-health JSON with HTTP 200 and `last_error=null`.

The `health_status=unknown` values are the current runtime response shape for these entries and are not treated here as a new failure. The useful evidence in this snapshot is that the checked source keys are registered, reachable, bounded, and have recent `last_success_at` values from staging observations.

The snapshot keeps the production distinction intact:

```text
sec_press_releases: active=true baseline
candidate scheduled-observation sources: active=false
production scheduled polling: not enabled
```

## Guardrails

```text
do not infer production approval from source-health reachability
do not set candidate sources active=true
do not enable production scheduled polling
do not treat health_status=unknown as a promotion blocker without a separate runtime decision
do not add public Source Health UI
do not add public poll UI
```
