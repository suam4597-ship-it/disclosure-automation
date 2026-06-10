# GlobalPulse Denmark DFSA OAM Follow-up Scheduled Observation

Date: 2026-05-12 KST

This document records a follow-up automatic Denmark DFSA OAM scheduled staging canary run observed while waiting for the HKEX scheduled staging window.

This is documentation-only. It does not enable production scheduled polling, does not set any source `active=true`, does not expand canary coverage, does not change backend runtime behavior, does not change frontend runtime behavior, does not change routes or public API response shapes, and does not add public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
DENMARK_DFSA_OAM_FOLLOWUP_AUTOMATED_CRON_OBSERVED
DENMARK_DFSA_OAM_FOLLOWUP_AUTOMATED_CRON_RUN_SUCCESS
DENMARK_DFSA_OAM_FETCH_MODE_LIVE
DENMARK_DFSA_OAM_DIGEST_CONTRACT_PASS
DENMARK_DFSA_OAM_SOURCE_REMAINS_STAGING_ONLY
PRODUCTION_DENMARK_POLLING_NOT_ENABLED
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25680895829
run id: 25680895829
head sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
status: completed
conclusion: success
created_at: 2026-05-11T15:48:29Z
```

## Schedule Resolution

```text
SCHEDULE_EXPR: 47 */4 * * 1-5
SOURCE_KEY: denmark_dfsa_oam_staging_canary
RUN_MODE: denmark_dfsa_oam_canary
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

This is not the pending HKEX run. HKEX still requires a separate scheduled run with:

```text
SCHEDULE_EXPR: 22 */2 * * 1-5
SOURCE_KEY: hkex_latest_listed_company_information
RUN_MODE: single_source
```

## Artifact

```text
artifact name: globalpulse-live-staging-poll-25680895829
artifact id: 6923101510
artifact size: 4612 bytes
expired: false
created_at: 2026-05-11T15:48:44Z
expires_at: 2026-08-09T15:48:30Z
archive_download_url: https://api.github.com/repos/suam4597-ship-it/disclosure-automation/actions/artifacts/6923101510/zip
```

## Source Poll Review

The scheduled Denmark canary ran the bounded single-source canary path:

```text
source: dk_dfsa_oam_company_announcements
poll status: 202
fetch.mode: live
fetch.status_code: 200
records_seen: 25
records_inserted: 25
canonical_items: 25
```

Representative latest row from the poll payload:

```text
story key: breaking-2026-05-11-dfsa-oam-300008794
headline: TRANSACTIONS UNDER AMBU'S SHARE BUYBACK PROGRAM
issuer: AMBU A/S
published_at: 2026-05-11T17:20:15Z
regions: eu_north
source_key: dk_dfsa_oam_company_announcements
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
digest_date: 2026-05-11
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
```

The latest digest included Denmark DFSA OAM visibility:

```text
source_key: dk_dfsa_oam_company_announcements
display_name: Denmark DFSA OAM Company Announcements
headline: TRANSACTIONS UNDER AMBU'S SHARE BUYBACK PROGRAM
metadata.fetch_mode: live
regions: eu_north
```

The digest is a global top-N latest feed, so India, Switzerland, Euronext, UK, Spain, France, Belgium, and HKEX live items in the same digest are expected and do not indicate Denmark canary failure.

## Observation Window Status

This run adds another successful automatic canary observation for Denmark DFSA OAM. It does not approve production polling.

The production-promotion gate remains:

```text
minimum duration: 7 calendar days
minimum successful scheduled Denmark runs: 5
fixture fallback count: 0
unresolved parser/content-type failures: 0
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
HKEX first automated scheduled staging run: still pending
JP live polling: still blocked pending issue #339 source-authority decision
KR live source track: still deferred until the dedicated backend/source authority path exists
```

