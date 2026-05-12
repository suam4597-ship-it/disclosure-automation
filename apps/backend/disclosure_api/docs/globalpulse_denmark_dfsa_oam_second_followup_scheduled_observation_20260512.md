# GlobalPulse Denmark DFSA OAM Second Follow-up Scheduled Observation

Date: 2026-05-12 KST

This document records a later automatic Denmark DFSA OAM scheduled staging canary run after the first follow-up observation.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not expand canary coverage, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
DENMARK_DFSA_OAM_SECOND_FOLLOWUP_AUTOMATED_CRON_OBSERVED
DENMARK_DFSA_OAM_SECOND_FOLLOWUP_AUTOMATED_CRON_RUN_SUCCESS
DENMARK_DFSA_OAM_FETCH_MODE_LIVE
DENMARK_DFSA_OAM_DIGEST_CONTRACT_PASS
DENMARK_DFSA_OAM_TOP_N_DIGEST_VISIBILITY_NOT_PRESENT_IN_THIS_RUN
DENMARK_DFSA_OAM_SOURCE_REMAINS_STAGING_ONLY
PRODUCTION_DENMARK_POLLING_NOT_ENABLED
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25699532618
run id: 25699532618
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
status: completed
conclusion: success
created_at: 2026-05-11T21:53:12Z
```

## Schedule Resolution

```text
SCHEDULE_EXPR: 47 */4 * * 1-5
SOURCE_KEY: denmark_dfsa_oam_staging_canary
RUN_MODE: denmark_dfsa_oam_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Artifact

```text
artifact name: globalpulse-live-staging-poll-25699532618
artifact id: 6930757406
artifact digest: sha256:8aa1b54d8f203455f8c3699e6504243b785c5d954d1d607573b89e4b9450cde4
artifact size: 3179 bytes
expired: false
created_at: 2026-05-11T21:53:21Z
expires_at: 2026-08-09T21:53:13Z
```

The artifact was downloaded and inspected locally from the GitHub Actions artifact reference.

## Source Poll Review

The scheduled Denmark canary ran the bounded single-source canary path:

```text
source: dk_dfsa_oam_company_announcements
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 6784
records_seen: 25
records_inserted: 25
canonical_items: 25
raw_documents: 25
first canonical item: breaking-2026-05-11-dfsa-oam-300008799
```

Interpretation:

```text
the Denmark OAM canary fetched live source data
the endpoint returned HTTP 200
the canary cap stayed bounded at 25 records
the accepted response inserted canonical rows
no fixture fallback was claimed as live success
```

## Digest Review

```text
GET /api/feed/digest/latest?edition=breaking
digest_date: 2026-05-12
edition: breaking
generated_at: 2026-05-11T21:53:20Z
item_count: 10
metadata.fallback_to_fixture: false
digest contract: pass
denmark items in top-N digest: 0
```

The digest contract passed because the public digest remained live-backed with `metadata.fallback_to_fixture=false`. This specific global top-N digest did not include Denmark DFSA OAM rows, so it does not provide fresh public top-N visibility evidence for Denmark.

Interpretation:

```text
Denmark canary polling passed
digest fallback remained false
this run does not provide Denmark public top-N visibility evidence
Denmark public visibility and digest diversity need continued observation in separate smoke windows
```

## Source State Follow-up

An informational source-health read after the observed run returned:

```text
GET /api/admin/source-health/dk_dfsa_oam_company_announcements
http_status: 200
source_key: dk_dfsa_oam_company_announcements
active: false
candidate_status: manual_staging_only
source_type: api
parser_key: dfsa_oam_company_announcements_json_v1
base_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
health_status: unknown
last_success_at: 2026-05-11T21:53:20.373422Z
last_seen_published_at: 2026-05-11T19:39:00.000000Z
last_error: null
last_failure_at: null
```

Interpretation:

```text
the source remains inactive and manual-staging-only
the latest source-health timestamp matches the inspected scheduled Denmark poll window
health_status remains informational and should be tracked, but it does not change the scheduled-run pass evidence
```

## Observation Window Status

This run adds another successful automatic canary observation for Denmark DFSA OAM. It does not approve production polling.

The production-promotion gate remains:

```text
minimum duration: 7 calendar days
minimum successful scheduled Denmark runs: 5
fixture fallback count: 0
unresolved parser/content-type failures: 0
public digest visibility: continue observing because this run's top-N digest did not include Denmark
explicit source-by-source approval: required
```

## Guardrails Preserved

```text
production scheduled Denmark polling: not enabled
source active flags: unchanged
candidate_status values: unchanged
Denmark canary source list: unchanged
Germany Company Register scheduled polling: not enabled
Prague/PSE scheduled polling: not enabled
backend digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
KR live source track: still deferred until the dedicated backend/source authority path exists
```

## Next Allowed Steps

```text
1. Continue Denmark DFSA OAM scheduled staging observation across additional time windows.
2. Record public digest diversity separately when Denmark rows appear in the global top-N digest again.
3. Continue EU canary, India NSE, HKEX, public web smoke, and source-health observation windows in parallel.
4. Keep production scheduled polling disabled until explicit source-by-source approval exists.
```
