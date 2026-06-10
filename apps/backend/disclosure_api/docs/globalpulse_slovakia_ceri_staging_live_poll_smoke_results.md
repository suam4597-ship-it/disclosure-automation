# GlobalPulse Slovakia CERI Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Slovakia Central Register of Regulated Information candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
SLOVAKIA_CERI_SOURCE_HEALTH_PASS
SLOVAKIA_CERI_STAGING_LIVE_POLL_PASS
SLOVAKIA_CERI_CANONICAL_INSERT_PASS
SLOVAKIA_CERI_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
SLOVAKIA_CERI_PUBLIC_LATEST_UI_VISIBILITY_PENDING
SLOVAKIA_CERI_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: sk_ceri_regulated_information
display_name: Slovakia CERI Regulated Information
parser_key: ceri_regulated_information_html_v1
source URL: https://ceri.nbs.sk/search
authority: official Slovakia Central Register of Regulated Information latest issuer-regulated-information table
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #419 Add Slovakia CERI regulated information candidate
candidate merge commit: 1500c7d23ef665d7d69346e076110a9b7cc1be55
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR5BMQ727NCPJRHJBQDP9G32
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
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/sk_ceri_regulated_information
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: ceri_regulated_information_html_v1
  fixture_path: source_payloads/sk_ceri_regulated_information.html
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/sk_ceri_regulated_information/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://ceri.nbs.sk/search
fetch.bytes: 10092
records_seen: 10
records_inserted: 10
canonical_items: 10
fixture fallback: false
first observed canonical key: breaking-2026-05-08-00014660-pdf
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
slovakia_count: 0
observed source distribution: india_nse_announcements
```

Date-specific digest checks:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-07/breaking
status: 200
item_count: 12
slovakia_count: 1
first Slovakia headline: JTSEC Financing III a. s. - bond interest payment issuer notice
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-06/breaking
status: 200
item_count: 11
slovakia_count: 1
first Slovakia headline: CS Apparel Group a.s. - annual report
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-05/breaking
status: 200
item_count: 11
slovakia_count: 2
first Slovakia headline: GARFIN HOLDING, a.s. - managers' transaction notice
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2026-05-04/breaking
status: 200
item_count: 11
slovakia_count: 5
first Slovakia headline: HB REAVIS Finance SK IX s. r. o. - partial bond cancellation notice
```

Interpretation:

```text
Slovakia CERI live poll and canonical insert paths passed.
Date-specific digest visibility passed for multiple Slovakia CERI rows.
Public latest UI visibility remains pending because the current latest digest date is 2026-05-09 and is filled by newer India NSE items.
This is not a parser or live-fetch failure.
```

## Guardrails

```text
scheduled Slovakia CERI live polling remains disabled
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
Continue Europe listed-company disclosure discovery with Prague/PSE, Portugal CMVM exact endpoint discovery, OeKB issuerinfo, or other official issuer-announcement surfaces.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
