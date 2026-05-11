# GlobalPulse EU Scheduled Staging Canary First Cron Observation

This document records the first observed automatic schedule run that matches the EU staging canary cron window.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not expand the canary source list, does not change backend response shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
EU_CANARY_FIRST_AUTOMATED_CRON_OBSERVED
EU_CANARY_FIRST_AUTOMATED_CRON_RUN_SUCCESS
EU_CANARY_ARTIFACT_METADATA_RECORDED
EU_CANARY_SUBSEQUENT_CRON_PAYLOAD_REVIEW_RECORDED
EU_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Observed Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25566582421
run id: 25566582421
job id: 75051439330
head branch: main
head sha: 386562000fc0bc3bebeb3d8bd116c51343d71fbf
status: completed
conclusion: success
created_at: 2026-05-08T16:19:59Z
job started_at: 2026-05-08T16:20:11Z
job completed_at: 2026-05-08T16:21:55Z
```

## Why This Is The EU Cron Observation

The workflow currently has three scheduled routes:

```text
SEC cron: 7 * * * *
India NSE cron: 37 */2 * * 1-5
EU canary cron: 17 */4 * * 1-5
```

The observed schedule run was created at `2026-05-08T16:19:59Z`, matching the weekday EU canary cron window `17 */4 * * 1-5` with normal GitHub Actions scheduling delay.

The job ran for roughly 104 seconds. This is consistent with the multi-source EU canary path and materially longer than the nearby single-source schedule runs that completed in only a few seconds.

## Artifact Metadata

```text
artifact name: globalpulse-live-staging-poll-25566582421
artifact id: 6883667700
artifact digest: sha256:b16bbb95c6f58fdacba5dc3432731101c17d1e14d26637b14e043c86d4c18d58
artifact size: 4284 bytes
expired: false
created_at: 2026-05-08T16:20:20Z
expires_at: 2026-08-06T16:19:59Z
artifact URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25566582421/artifacts/6883667700
```

## Local Review Limitation For This First Run

The GitHub REST metadata endpoints were readable from the local Codex environment, but the artifact zip download returned `401 Unauthorized` without a GitHub Actions artifact download token.

Therefore this document records the automatic cron run and artifact metadata, but does not duplicate the per-source `poll-<source>.json` payloads. The earlier manual-dispatch smoke remains the detailed per-source payload baseline until an authenticated artifact review is performed.

## Subsequent Payload Review

A later automatic EU cron run was reviewed through the GitHub connector and recorded in:

```text
globalpulse_eu_scheduled_staging_canary_cron_payload_review.md
```

That follow-up run confirmed:

```text
run id: 25650523685
event: schedule
cron: 17 */4 * * 1-5
resolved source_key: eu_scheduled_staging_canary
run_mode: eu_canary
health: success
all source poll steps: success
digest: success
metadata.fallback_to_fixture: false
```

## Existing Per-Source Baseline

The first manual-dispatch EU canary smoke already recorded the per-source poll contract for the same first-canary source list:

```text
eu_france_info_financiere_oam
eu_spain_cnmv_inside_information
eu_spain_cnmv_other_relevant_information
eu_belgium_fsma_stori
uk_fca_nsm_regulated_information
ch_six_ser_official_notices
eu_euronext_company_press_releases
pt_cmvm_portal_info_privi
```

That manual-dispatch baseline passed all source polls, health, digest, and artifact recording. This cron observation confirms that the automatic schedule path fired and completed successfully from the default branch.

## Guardrails Preserved

```text
production scheduled EU polling: not enabled
source active flags: unchanged
candidate_status: unchanged
EU canary source list: unchanged
Germany Company Register scheduled polling: not enabled
Prague/PSE scheduled polling: not enabled
backend digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
```

## Next Step

Continue the multi-day observation window until at least 5 successful scheduled runs per included source are recorded before any production-scheduled-polling decision.
