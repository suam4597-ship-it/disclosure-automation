# GlobalPulse Denmark DFSA OAM First Automated Scheduled Run Results

Date: 2026-05-11 KST

This document records the first observed automated scheduled staging run for the Denmark DFSA OAM company-announcements canary.

This is documentation-only. It does not enable production scheduled polling, does not set the source active, does not change backend response shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
DENMARK_DFSA_OAM_FIRST_AUTOMATED_SCHEDULED_RUN_PASS
DENMARK_DFSA_OAM_SCHEDULE_CRON_47_EVERY_4H_WEEKDAY_CONFIRMED
DENMARK_DFSA_OAM_SCHEDULED_RUN_FETCH_MODE_LIVE
DENMARK_DFSA_OAM_LATEST_DIGEST_VISIBILITY_PASS
DENMARK_DFSA_OAM_SOURCE_HEALTH_UPDATED_BY_SCHEDULED_RUN
DENMARK_DFSA_OAM_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
DENMARK_DFSA_OAM_SOURCE_REMAINS_ACTIVE_FALSE
```

## Workflow Run

```text
workflow: GlobalPulse live staging poll
workflow path: .github/workflows/globalpulse-live-staging-poll.yml
event: schedule
run URL: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25668194957
run id: 25668194957
run number: 62
head branch: main
head sha: 8445ae20f87432f58602482dcea772e994702a6c
status: completed
conclusion: success
created_at: 2026-05-11T11:47:04Z
updated_at: 2026-05-11T11:47:38Z
```

Artifact metadata:

```text
artifact name: globalpulse-live-staging-poll-25668194957
artifact id: 6917580639
artifact size: 4838 bytes
artifact expired: false
artifact payload review: pending authenticated download
```

The run succeeded at the first observed schedule slot matching the Denmark DFSA OAM staging canary path after default-branch activation.

## Schedule Contract

The default-branch workflow contains this Denmark canary schedule:

```text
cron: 47 */4 * * 1-5
resolved run mode: denmark_dfsa_oam_canary
source list: dk_dfsa_oam_company_announcements
edition: breaking
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Backend Source Health Evidence

Post-run source health from Fly staging:

```text
GET /api/admin/source-health/dk_dfsa_oam_company_announcements
source_key: dk_dfsa_oam_company_announcements
display_name: Denmark DFSA OAM Company Announcements
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
parser_key: dfsa_oam_company_announcements_json_v1
base_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
last_success_at: 2026-05-11T11:47:18.381358Z
last_seen_published_at: 2026-05-11T13:36:00.000000Z
last_error: null
last_failure_at: null
```

Interpretation:

```text
The scheduled run updated the Denmark source health at the scheduled run time.
The latest observed DFSA OAM row was published at 2026-05-11T13:36:00Z.
The source remains inactive/manual staging-only.
```

## Latest Digest Evidence

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-11
generated_at: 2026-05-11T12:04:47Z
item_count: 12
metadata.fallback_to_fixture: false
```

Representative Denmark row in the latest digest:

```text
source_key: dk_dfsa_oam_company_announcements
display_name: Denmark DFSA OAM Company Announcements
headline: Reporting of transactions made by persons discharging managerial responsibilities and persons closely associated with them in Gubra A/S' shares
canonical_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/details/300008771
published_at: 2026-05-11T13:36:00.000000Z
regions: eu_north
metadata.fetch_mode: live
metadata.source_type: api
metadata.category: Issuer
story_key: breaking-2026-05-11-dfsa-oam-300008771
```

This closes the previous latest-public-visibility pending state for the Denmark DFSA OAM canary.

## Guardrails Preserved

```text
source active flag: false
candidate_status: manual_staging_only
production scheduled Denmark polling: not enabled
page remains 1
pageSize remains 25
category allowlist unchanged
ShortSelling remains excluded
Shareholder remains excluded
details/document fetch disabled
backend digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
KR live source: still deferred until the dedicated backend/source authority path exists
```

## Next Gate

Continue observing the Denmark DFSA OAM staging schedule before any production decision:

```text
minimum duration: 7 calendar days
minimum successful scheduled Denmark runs: 5
fixture fallback count: 0
unresolved parser/content-type failures: 0
rate-limit/captcha/login observations: 0 unresolved
digest visibility: monitor latest and date-specific windows
```

This result does not approve production scheduled polling.
