# GlobalPulse Cyprus CSE OAM Staging Live Poll Smoke Results

This document records the first Fly staging live-poll smoke for the Cyprus Stock Exchange / XAK Public OAM regulated-information candidate.

The smoke keeps the source manual-only. It does not enable scheduled polling, does not set the source active, does not change backend digest JSON shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_CYPRUS_CSE_OAM_STAGING_DEPLOY_PASS
CYPRUS_CSE_OAM_SOURCE_HEALTH_MANUAL_ONLY_PASS
CYPRUS_CSE_OAM_LIVE_POLL_PASS
CYPRUS_CSE_OAM_LIVE_FIXTURE_FALLBACK_DISABLED_PASS
CYPRUS_CSE_OAM_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
CYPRUS_CSE_OAM_LATEST_PUBLIC_UI_VISIBILITY_PENDING
CYPRUS_CSE_OAM_SCHEDULED_POLLING_DISABLED
```

## Context

```text
source_key: eu_cyprus_cse_oam
display_name: Cyprus CSE OAM Regulated Information
parser_key: cse_oam_listing_versions_json_v1
candidate URL: https://publicoam.cse.com.cy/xak-public-pages-server/api/fetch-listing-versions?page=0&size=25&sort=ID,DESC
authority: Cyprus Stock Exchange / XAK Public OAM
PR: #469 Add Cyprus CSE OAM disclosure candidate
phase0-foundation deploy commit: 369c8247d8e6c00b0df5f4324b065fd85501b652
Fly app: globalpulse-backend-staging
smoke date: 2026-05-10
```

## Fly Deploy

```text
command: fly deploy --remote-only --app globalpulse-backend-staging
deploy: PASS
release_command: PASS
app URL: https://globalpulse-backend-staging.fly.dev/
```

## Health Check

```text
GET /api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Source Health

```text
GET /api/admin/source-health/eu_cyprus_cse_oam
status: 200
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
health_status: healthy
last_seen_published_at: 2026-04-30T05:47:11.000000Z
last_success_at: 2026-05-10T13:15:17.816717Z
last_error: null
```

## Live Poll

```text
POST /api/admin/sources/eu_cyprus_cse_oam/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 91458
records_seen: 21
records_inserted: 21
first canonical item: breaking-2024-02-05-cse-oam-211783
latest canonical item in bounded response: breaking-2026-04-30-cse-oam-223354
fixture fallback: disabled by source config and not used
```

## Digest Visibility

Latest digest remains 2026-05-09 and does not currently include Cyprus because the Cyprus public OAM page contains a mixed historical/current result window. Date-specific digest visibility passed for Cyprus rows:

```text
GET /api/feed/digest/2025-04-02/breaking
status: 200
digest_date: 2025-04-02
item_count: 8
metadata.fallback_to_fixture: false
visible Cyprus rows: yes
examples:
- Demetra Holdings Plc - Statement of Mr. Varnavas Eirinarchos in relation to the opinion of the Board of Directors of Demetra Holdings Plc
- BANK OF CYPRUS HOLDINGS PLC - Total Voting Rights & Share Buyback Progress
- LOGICOM PUBLIC LTD - Profit Warning
regions: eu_south
```

```text
GET /api/feed/digest/2025-03-31/breaking
status: 200
visible Cyprus row: BANK OF CYPRUS HOLDINGS PLC - Appointment of New Director
regions: eu_south
```

```text
GET /api/feed/digest/2024-02-05/breaking
status: 200
visible Cyprus rows:
- ACTIBOND GROWTH FUND PUBLIC COMPANY LTD - NET ASSET VALUE
- GMM Global Money Managers Ltd - Greek daily price bulletin
regions: eu_south
```

```text
GET /api/feed/digest/2023-04-13/breaking
status: 200
visible Cyprus row: LOUIS PLC - Announcement Louis plc 13 April 2023
regions: eu_south
```

## Guardrails

```text
scheduled polling enabled: no
source active=true: no
EU scheduled canary inclusion: no
backend digest JSON shape changed: no
frontend framework added: no
public poll UI added: no
audit UI added: no
public Source Health UI added: no
detail fetch / attachment fetch controls added: no
```
