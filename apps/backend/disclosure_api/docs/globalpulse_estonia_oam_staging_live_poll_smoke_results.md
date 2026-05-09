# GlobalPulse Estonia OAM Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Estonia OAM market-announcements candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
ESTONIA_OAM_SOURCE_HEALTH_PASS
ESTONIA_OAM_STAGING_LIVE_POLL_PASS
ESTONIA_OAM_CANONICAL_INSERT_PASS
ESTONIA_OAM_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
ESTONIA_OAM_PUBLIC_LATEST_UI_VISIBILITY_PENDING
ESTONIA_OAM_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: ee_oam_market_announcements
display_name: Estonia OAM Market Announcements
parser_key: ee_oam_market_announcements_html_v1
source URL: https://oam.fi.ee/en/borsiteated?limit=50&n=1&order=Date&page=0&sort=desc
authority: official Estonia central storage market-announcement register
region: eu_north
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #421 Add Estonia OAM market announcements candidate
candidate merge commit: 0ddadb5b6ee6f116eda4fccfc6ae3ca434174127
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR5CB1716F5M38CGMX64CM66
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
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/ee_oam_market_announcements
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: ee_oam_market_announcements_html_v1
  fixture_path: source_payloads/ee_oam_market_announcements.html
  health_status: healthy
  last_seen_published_at: 2026-05-08T15:00:00.000000Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/ee_oam_market_announcements/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://oam.fi.ee/en/borsiteated?limit=50&n=1&order=Date&page=0&sort=desc
fetch.bytes: 58985
records_seen: 25
records_inserted: 25
canonical_items: 25
fixture fallback: false
first observed canonical key: breaking-2026-05-08-18562
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
estonia_count: 0
observed source distribution: india_nse_announcements
```

Date-specific digest checks:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-06/breaking
status: 200
item_count: 12
estonia_count: 3
first Estonia headline: aktsiaselts TALLINNA SADAM - Changes in the debt obligations of AS Tallinna Sadam
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-05/breaking
status: 200
item_count: 12
estonia_count: 1
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-04/breaking
status: 200
item_count: 12
estonia_count: 2
```

Interpretation:

```text
Estonia OAM live poll and canonical insert paths passed.
Date-specific digest visibility passed for multiple Estonia OAM rows.
Public latest UI visibility remains pending because the current latest digest date is 2026-05-09 and is filled by newer India NSE items.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Estonia OAM live polling remains disabled
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
Continue Europe listed-company disclosure discovery with Latvia, Lithuania, Prague/PSE, Portugal CMVM exact endpoint discovery, OeKB issuerinfo, or other official issuer-announcement surfaces.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
