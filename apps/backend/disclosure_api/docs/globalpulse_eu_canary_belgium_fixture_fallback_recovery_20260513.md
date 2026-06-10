# GlobalPulse EU Canary Belgium Fixture Fallback Recovery

Date: 2026-05-13 KST

This document records a post-rollup EU scheduled staging canary failure where the Belgium FSMA STORI source fell back to its fixture payload during a live canary run, followed by a later successful EU canary recovery run.

This is documentation plus source-config hardening context. It does not enable production scheduled polling, does not set any candidate source `active=true`, does not change backend digest JSON response shape, does not change frontend runtime behavior, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
EU_CANARY_BELGIUM_FIXTURE_FALLBACK_OBSERVED
FIXTURE_FALLBACK_NOT_CLAIMED_AS_LIVE_SUCCESS
EU_CANARY_WORKFLOW_FAILED_AS_EXPECTED_ON_FIXTURE_FALLBACK
EU_CANARY_LATER_RECOVERY_RUN_PASS
BELGIUM_FSMA_LATER_RECOVERY_FETCH_MODE_LIVE
BELGIUM_FSMA_LATER_RECOVERY_STATUS_200
BELGIUM_FSMA_LIVE_FIXTURE_FALLBACK_DISABLED
CANDIDATE_SOURCE_REMAINS_ACTIVE_FALSE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Failure Observation

```text
workflow: GlobalPulse live staging poll
run id: 25753561055
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
created at UTC: 2026-05-12T18:17:14Z
resolved source: eu_scheduled_staging_canary
run mode: eu_canary
backend URL: https://globalpulse-backend-staging.fly.dev
edition: breaking
artifact id: 6952296722
artifact digest: sha256:3b427878514ef81ea38a052093e89560e0a92c3b314c287a94087f77b906cec9
```

Job step summary:

| Step | Result |
| --- | --- |
| Resolve source | success |
| Show target | success |
| Health check | success |
| Poll live source | failure |
| Verify digest | skipped |
| Upload smoke outputs | success |

The failure was correctly bounded to the live-source contract check. The canary poll step rejected a fixture-backed source response instead of recording it as live evidence.

## Failure Payload Review

Artifact `globalpulse-live-staging-poll-25753561055` contained these poll outputs:

| Source | fetch.mode | fetch.status_code | fixture path | records_seen | records_inserted |
| --- | --- | ---: | --- | ---: | ---: |
| ch_six_ser_official_notices | live | 200 | n/a | 25 | 25 |
| eu_belgium_fsma_stori | fixture | n/a | source_payloads/eu_belgium_fsma_stori.json | 2 | 2 |
| eu_euronext_company_press_releases | live | 200 | n/a | 7 | 7 |
| eu_france_info_financiere_oam | live | 200 | n/a | 25 | 25 |
| eu_spain_cnmv_inside_information | live | 200 | n/a | 6 | 6 |
| eu_spain_cnmv_other_relevant_information | live | 200 | n/a | 25 | 25 |
| pt_cmvm_portal_info_privi | live | 200 | n/a | 3 | 3 |
| uk_fca_nsm_regulated_information | live | 200 | n/a | 25 | 25 |

The Belgium payload reported:

```json
{
  "fetch": {
    "bytes": 2034,
    "loaded": true,
    "mode": "fixture",
    "relative_path": "source_payloads/eu_belgium_fsma_stori.json"
  },
  "edition": "breaking",
  "source_key": "eu_belgium_fsma_stori",
  "records_inserted": 2,
  "records_seen": 2
}
```

Interpretation:

```text
Belgium FSMA did not satisfy the scheduled live canary contract in run 25753561055.
The workflow failed because fetch.mode was fixture instead of live.
The workflow also skipped digest verification for that failed run.
The fixture-backed records must not be counted as live scheduled evidence.
```

## Recovery Observation

```text
workflow: GlobalPulse live staging poll
run id: 25763799894
event: schedule
head branch: main
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
created at UTC: 2026-05-12T21:39:31Z
resolved source: eu_scheduled_staging_canary
run mode: eu_canary
backend URL: https://globalpulse-backend-staging.fly.dev
edition: breaking
artifact id: 6956498365
artifact digest: sha256:9046d4b2a84ad0e7110c86e04d54d40ee2516f78c1b6b2b102a58675aae13cfb
```

The later EU canary run passed with the same eight-source canary list:

| Source | fetch.mode | fetch.status_code | records_seen | records_inserted |
| --- | --- | ---: | ---: | ---: |
| ch_six_ser_official_notices | live | 200 | 25 | 25 |
| eu_belgium_fsma_stori | live | 200 | 25 | 25 |
| eu_euronext_company_press_releases | live | 200 | 7 | 7 |
| eu_france_info_financiere_oam | live | 200 | 25 | 25 |
| eu_spain_cnmv_inside_information | live | 200 | 6 | 6 |
| eu_spain_cnmv_other_relevant_information | live | 200 | 25 | 25 |
| pt_cmvm_portal_info_privi | live | 200 | 3 | 3 |
| uk_fca_nsm_regulated_information | live | 200 | 25 | 25 |

The recovery digest check returned:

```text
digest_date: 2026-05-13
item_count: 12
metadata.fallback_to_fixture: false
top-N source mix: india_nse_announcements=12
```

Interpretation:

```text
The Belgium FSMA fallback was not a permanent parser/source outage.
The next inspected EU canary run recovered to live/200 for Belgium FSMA.
The latest digest in that recovery run was live-backed but top-N India-only.
Top-N digest composition remains time-window dependent and must not be treated as source absence.
```

## Source Config Hardening Note

The Belgium source already has a fixture for parser/local smoke coverage and can still be used when live fetch is intentionally skipped. For scheduled live canary evidence, fixture fallback must not be accepted as live evidence.

This observation is paired with a config hardening change:

```text
source_key: eu_belgium_fsma_stori
config.disable_live_fixture_fallback: true
```

Expected effect:

```text
live fetch failure returns a bounded poll failure
fixture-backed poll output is not inserted during live canary runs
workflow still fails if Belgium live fetch is unavailable
manual fixture/local parser coverage remains possible when live fetch is not requested
```

## Candidate Progress Impact

```text
EU canary accepted success count: do not count run 25753561055
EU canary recovery evidence: count run 25763799894 as a later live/200 canary pass
Belgium FSMA promotion status: unchanged
EU canary source list: unchanged
production source promotion: not approved
production scheduled polling: not enabled
```

## Guardrails Preserved

```text
candidate source active flags: unchanged
candidate_status values: unchanged
production scheduled polling: not enabled
backend digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
fixture fallback claimed as live success: no
JP live polling: still blocked pending issue #339 source-authority decision
KR live source track: still deferred until the dedicated backend/source authority path exists
```

## Next Allowed Steps

```text
1. Keep the EU canary under scheduled staging observation.
2. Do not count run 25753561055 as live success.
3. Count run 25763799894 as recovery evidence only after preserving the failure context.
4. Harden Belgium FSMA live canary behavior by disabling live fixture fallback in source config.
5. Continue HKEX, India NSE, Denmark DFSA OAM, EU canary, SEC, and public web smoke observations without enabling production schedules.
```
