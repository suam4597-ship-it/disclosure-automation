# GlobalPulse Lithuania OAM Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Lithuania OAM regulated-information candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
LITHUANIA_OAM_SOURCE_HEALTH_PASS
LITHUANIA_OAM_STAGING_LIVE_POLL_PASS
LITHUANIA_OAM_CANONICAL_INSERT_PASS
LITHUANIA_OAM_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
LITHUANIA_OAM_PUBLIC_LATEST_UI_VISIBILITY_PENDING
LITHUANIA_OAM_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: lt_oam_regulated_information
display_name: Lithuania OAM Regulated Information
parser_key: lt_oam_regulated_information_html_v1
source URL: https://www.oam.lt/?language=en
authority: official Lithuania OAM regulated-information storage for Nasdaq Vilnius listed issuers
region: eu_north
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #423 Add Lithuania OAM regulated information candidate
candidate merge commit: bf37418696df275c80b6cd0c3329c6829bafce11
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR5DAMPM3F6P00EQ3QHNENP7
Fly release_command: success
```

## Backend Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response:
  status: ok
  service: disclosure_automation
  phase: phase1
  repo: up
```

## Source Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/lt_oam_regulated_information
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: lt_oam_regulated_information_html_v1
  fixture_path: source_payloads/lt_oam_regulated_information.html
  health_status: healthy
  last_seen_published_at: 2026-05-08T13:10:00.000000Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/lt_oam_regulated_information/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.oam.lt/?language=en
fetch.bytes: 88403
records_seen: 25
records_inserted: 25
canonical_items: 25
fixture fallback: false
first observed canonical key: breaking-2026-05-08-471947
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
lithuania_count: 0
observed source distribution: india_nse_announcements
```

Date-specific digest checks:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-07/breaking
status: 200
item_count: 12
lithuania_count: 1
first Lithuania headline: INVL Technology - The decision of the management company of INVL Technology on the purchase of own shares
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-06/breaking
status: 200
item_count: 12
lithuania_count: 1
first Lithuania headline: UAB Kvartalas - NOTICE OF CONVENING OF THE REMOTE REPEATED MEETING OF BONDHOLDERS OF UAB "KVARTALAS" (ISIN CODE LT0000411167) ON 14 MAY 2026
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-05/breaking
status: 200
item_count: 12
lithuania_count: 4
first Lithuania headline: Rokiskio Suris - AB "Rokiškio sūris" dividend payment procedure for the year 2025
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-04/breaking
status: 200
item_count: 12
lithuania_count: 2
first Lithuania headline: AB Novaturas - Regarding convocation of Annual General Meeting of Shareholders of AB “Novaturas”
```

Interpretation:

```text
Lithuania OAM live poll and canonical insert paths passed.
Date-specific digest visibility passed for multiple Lithuania OAM rows.
Public latest UI visibility remains pending because the current latest digest date is 2026-05-09 and is filled by newer India NSE items.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Lithuania OAM live polling remains disabled
source remains active=false
candidate_status remains manual_staging_only
no backend JSON response shape change
no public Source Health UI
no poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Next Step

```text
Continue Europe listed-company disclosure discovery with Latvia, Prague/PSE, Portugal CMVM exact endpoint discovery, OeKB issuerinfo, or other official issuer-announcement surfaces.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
